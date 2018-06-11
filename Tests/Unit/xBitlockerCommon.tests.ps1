$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Misc' -ChildPath 'xBitlockerCommon.psm1')) -Force

# Begin Testing
try
{
    InModuleScope 'xBitlockerCommon' {

        function Get-BitlockerVolume
        {
            param
            (
                [Parameter()]
                [System.String]
                $MountPoint
            )
        }

        Describe 'xBitlockerCommon\TestBitlocker' {

            Context 'When OS Volume is not Encrypted and No Key Protectors Assigned' {
                Mock `
                    -CommandName Get-BitlockerVolume `
                    -ModuleName 'xBitlockerCommon' `
                    -MockWith {
                    # Decrypted with no Key Protectors
                    return @{
                        VolumeType           = 'OperatingSystem'
                        MountPoint           = $MountPoint
                        CapacityGB           = 500
                        VolumeStatus         = 'FullyDecrypted'
                        EncryptionPercentage = 0
                        KeyProtector         = @()
                        AutoUnlockEnabled    = $null
                        ProtectionStatus     = 'Off'
                    }
                }

                It 'Should Fail The Test (TPM and RecoveryPassword Protectors)' {
                    TestBitlocker -MountPoint 'C:' -PrimaryProtector 'TPMProtector' -RecoveryPasswordProtector $true | Should -Be $false
                }
            }

            Context 'When OS Volume is Encrypted using TPM and Recovery Password Protectors' {
                Mock `
                    -CommandName Get-BitlockerVolume `
                    -ModuleName 'xBitlockerCommon' `
                    -MockWith {
                    # Encrypted with TPM and Recovery Password Key Protectors
                    return @{
                        VolumeType           = 'OperatingSystem'
                        MountPoint           = $MountPoint
                        CapacityGB           = 500
                        VolumeStatus         = 'FullyEncrypted'
                        EncryptionPercentage = 100
                        KeyProtector         = @(
                            @{
                                KeyProtectorType = 'Tpm'
                            },
                            @{
                                KeyProtectorType = 'RecoveryPassword'
                            }
                        )
                        AutoUnlockEnabled    = $null
                        ProtectionStatus     = 'On'
                    }
                }

                It 'Should Pass The Test (TPM and RecoveryPassword Protectors)' {
                    TestBitlocker -MountPoint 'C:' -PrimaryProtector 'TPMProtector' -RecoveryPasswordProtector $true -verbose | Should -Be $true
                }
            }

            Context 'When OS Volume is Decrypted, but has TPM and Recovery Password Protectors assigned' {
                Mock `
                    -CommandName Get-BitlockerVolume `
                    -ModuleName 'xBitlockerCommon' `
                    -MockWith {
                    # Encrypted with TPM and Recovery Password Key Protectors
                    return @{
                        VolumeType           = 'OperatingSystem'
                        MountPoint           = $MountPoint
                        CapacityGB           = 500
                        VolumeStatus         = 'FullyDecrypted'
                        EncryptionPercentage = 0
                        KeyProtector         = @(
                            @{
                                KeyProtectorType = 'Tpm'
                            },
                            @{
                                KeyProtectorType = 'RecoveryPassword'
                            }
                        )
                        AutoUnlockEnabled    = $null
                        ProtectionStatus     = 'Off'
                    }
                }

                It 'Should Fail The Test (TPM and RecoveryPassword Protectors)' {
                    TestBitlocker -MountPoint 'C:' -PrimaryProtector 'TPMProtector' -RecoveryPasswordProtector $true | Should -Be $false
                }
            }
        }

        Describe 'xBitlockerCommon\CheckForPreReqs' {
            function Get-WindowsFeature
            {
                param
                (
                    [string]
                    $FeatureName
                )
            }

            function Get-OSEdition
            {

            }

            Context 'When OS is Server Core and all required features are installed' {
                Mock -CommandName Get-OSEdition -MockWith {
                    'Server Core'
                }

                Mock -CommandName Get-WindowsFeature -MockWith {
                    if ($FeatureName -eq 'RSAT-Feature-Tools-BitLocker-RemoteAdminTool')
                    {
                        return $null
                    }
                    else
                    {
                        return @{
                            DisplayName  = $FeatureName
                            Name         = $FeatureName
                            InstallState = 'Installed'
                        }
                    }
                }

                It 'Should not generate any error messages' {
                    Mock -CommandName Write-Error
                    CheckForPreReqs
                    Assert-MockCalled -Command Write-Error -Exactly -Times 0 -Scope It
                }

                It 'Should run the CheckForPreReqs function without exceptions' {
                    {CheckForPreReqs} | Should -Not -Throw
                }
            }

            Context 'When OS is Full Server and all required features are installed' {
                Mock -CommandName Get-OSEdition -MockWith {
                    return 'Server'
                }

                Mock -CommandName Get-WindowsFeature -MockWith {
                    param
                    (
                        [string]
                        $FeatureName
                    )

                    return @{
                        DisplayName  = $FeatureName
                        Name         = $FeatureName
                        InstallState = 'Installed'
                    }
                }

                It 'Should not generate any error messages' {
                    Mock -CommandName Write-Error
                    CheckForPreReqs
                    Assert-MockCalled -Command Write-Error -Exactly -Times 0 -Scope It
                }

                It 'Should run the CheckForPreReqs function without exceptions' {
                    {CheckForPreReqs} | Should -Not -Throw
                }
            }

            Context 'When OS is Full Server without the required features installed' {
                Mock -CommandName Get-OSEdition -MockWith {
                    return 'Server'
                }

                Mock -CommandName Get-WindowsFeature -MockWith {
                    return @{
                        DisplayName  = $FeatureName
                        Name         = $FeatureName
                        InstallState = 'Available'
                    }
                }

                Mock -CommandName Write-Error

                It 'Should give an error that Bitlocker Windows Feature needs to be installed' {
                    {CheckForPreReqs} | Should -Throw
                    Assert-MockCalled -Command Write-Error -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Message -eq 'The Bitlocker feature needs to be installed before the xBitlocker module can be used'
                    }
                }

                It 'Should give an error that RSAT-Feature-Tools-BitLocker Windows Feature needs to be installed' {
                    {CheckForPreReqs} | Should -Throw
                    Assert-MockCalled -Command Write-Error -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Message -eq 'The RSAT-Feature-Tools-BitLocker feature needs to be installed before the xBitlocker module can be used'
                    }
                }

                It 'Should give an error that RSAT-Feature-Tools-BitLocker-RemoteAdminTool Windows Feature needs to be installed' {
                    {CheckForPreReqs} | Should -Throw
                    Assert-MockCalled -Command Write-Error -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Message -eq 'The RSAT-Feature-Tools-BitLocker-RemoteAdminTool feature needs to be installed before the xBitlocker module can be used'
                    }
                }

                It 'The CheckForPreReqs function should throw an exceptions about missing required Windows Features' {
                    {CheckForPreReqs} | Should -Throw 'Required Bitlocker features need to be installed before xBitlocker can be used'
                }
            }

            Context 'When OS is Server Core without the required features installed' {
                Mock -CommandName Get-OSEdition -MockWith {
                    return 'Server Core'
                }

                Mock -CommandName Get-WindowsFeature -MockWith {
                    param
                    (
                        [string]
                        $FeatureName
                    )

                    if ($FeatureName -eq 'RSAT-Feature-Tools-BitLocker-RemoteAdminTool')
                    {
                        return $null
                    }
                    else
                    {

                        return @{
                            DisplayName  = $FeatureName
                            Name         = $FeatureName
                            InstallState = 'Available'
                        }
                    }
                }

                Mock -CommandName Write-Error

                It 'Should give an error that Bitlocker Windows Feature needs to be installed' {
                    {CheckForPreReqs} | Should -Throw
                    Assert-MockCalled -Command Write-Error -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Message -eq 'The Bitlocker feature needs to be installed before the xBitlocker module can be used'
                    }
                }

                It 'Should give an error that RSAT-Feature-Tools-BitLocker Windows Feature needs to be installed' {
                    {CheckForPreReqs} | Should -Throw
                    Assert-MockCalled -Command Write-Error -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Message -eq 'The RSAT-Feature-Tools-BitLocker feature needs to be installed before the xBitlocker module can be used'
                    }
                }

                It 'Should not give an error that RSAT-Feature-Tools-BitLocker-RemoteAdminTool Windows Feature needs to be installed as this Windows Features is not available on Server Core.' {
                    {CheckForPreReqs} | Should -Throw
                    Assert-MockCalled -Command Write-Error -Exactly -Times 0 -Scope It -ParameterFilter {
                        $Message -eq 'The RSAT-Feature-Tools-BitLocker-RemoteAdminTool feature needs to be installed before the xBitlocker module can be used'
                    }
                }

                It 'The CheckForPreReqs function should throw an exceptions about missing required Windows Features' {
                    {CheckForPreReqs} | Should -Throw 'Required Bitlocker features need to be installed before xBitlocker can be used'
                }
            }
        }

        Describe 'xBitLockerCommon\Get-OSEdition' {
            It 'Should return "Server Core" if the OS is Windows Server Core' {
                Mock -CommandName Get-ItemProperty -MockWith {
                    [PSCustomObject]@{
                        InstallationType = 'Server Core'
                        PSPath           = 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\software\microsoft\windows nt\currentversion'
                        PSParentPath     = 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\software\microsoft\windows nt'
                        PSChildName      = 'currentversion'
                        PSDrive          = 'HKLM'
                        PSProvider       = 'Microsoft.PowerShell.Core\Registry'
                    }
                }

                $OSVersion = Get-OSEdition
                $OSVersion | Should -Be 'Server Core'
            }

            It 'Should return "Server" if the OS is Full Windows Server' {
                Mock -CommandName Get-ItemProperty -MockWith {
                    [PSCustomObject]@{
                        InstallationType = 'Server'
                        PSPath           = 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\software\microsoft\windows nt\currentversion'
                        PSParentPath     = 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\software\microsoft\windows nt'
                        PSChildName      = 'currentversion'
                        PSDrive          = 'HKLM'
                        PSProvider       = 'Microsoft.PowerShell.Core\Registry'
                    }
                }

                $OSVersion = Get-OSEdition
                $OSVersion | Should -Be 'Server'
            }

            It 'Should run without exceptions' {
                Mock -CommandName Get-ItemProperty -MockWith {
                    [PSCustomObject]@{
                        InstallationType = 'Some other os'
                        PSPath           = 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\software\microsoft\windows nt\currentversion'
                        PSParentPath     = 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\software\microsoft\windows nt'
                        PSChildName      = 'currentversion'
                        PSDrive          = 'HKLM'
                        PSProvider       = 'Microsoft.PowerShell.Core\Registry'
                    }
                }
                {Get-OSEdition} | Should -Not -Throw
            }
        }
    }
}
finally
{
}

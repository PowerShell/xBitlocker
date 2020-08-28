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

        Describe 'xBitlockerCommon\Test-BitlockerEnabled' {

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
                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'TPMProtector' -RecoveryPasswordProtector $true | Should -Be $false
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
                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'TPMProtector' -RecoveryPasswordProtector $true -verbose | Should -Be $true
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
                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'TPMProtector' -RecoveryPasswordProtector $true | Should -Be $false
                }
            }

            Context 'When Test-BitlockerEnabled is called and Get-BitlockerVolume returns null' {
                It 'Should return False' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable

                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'TpmProtector' | Should -Be $false
                }
            }

            Context 'When Test-BitlockerEnabled is called and Get-BitlockerVolume returns a volume with no key protectors' {
                It 'Should return False' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith {
                        return @{
                            KeyProtector = $null
                        }
                    }

                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'TpmProtector' | Should -Be $false
                }
            }

            Context 'When Test-BitlockerEnabled is called, AutoUnlock is requested on a non-OS disk, and AutoUnlock is not enabled' {
                It 'Should return False' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith {
                        return @{
                            AutoUnlockEnabled = $false
                            VolumeType        = 'Data'
                            KeyProtector      = @('Protector1')
                        }
                    }

                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'TpmProtector' -AutoUnlock $true | Should -Be $false
                }
            }

            $defaultBLV = @(
                @{
                    KeyProtector = @('Protector1')
                }
            )

            $fakePin = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'fakepin', (New-Object -TypeName System.Security.SecureString)

            Context 'When Test-BitlockerEnabled is called, a AdAccountOrGroupProtector protector is requested, and does not exist on the disk' {
                It 'Should return False' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $defaultBLV }
                    Mock -CommandName Test-CollectionContainsKeyProtector -Verifiable -MockWith { return $false }

                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'TpmProtector' -AdAccountOrGroupProtector $true | Should -Be $false
                }
            }

            Context 'When Test-BitlockerEnabled is called, a PasswordProtector protector is requested, and does not exist on the disk' {
                It 'Should return False' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $defaultBLV }
                    Mock -CommandName Test-CollectionContainsKeyProtector -Verifiable -MockWith { return $false }

                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'TpmProtector' -PasswordProtector $true | Should -Be $false
                }
            }

            Context 'When Test-BitlockerEnabled is called, a Pin protector is requested, and does not exist on the disk' {
                It 'Should return False' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $defaultBLV }
                    Mock -CommandName Test-CollectionContainsKeyProtector -Verifiable -MockWith { return $false }

                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'TpmProtector' -Pin $fakePin | Should -Be $false
                }
            }

            Context 'When Test-BitlockerEnabled is called, a RecoveryKeyProtector protector is requested, and does not exist on the disk' {
                It 'Should return False' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $defaultBLV }
                    Mock -CommandName Test-CollectionContainsKeyProtector -Verifiable -MockWith { return $false }

                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'TpmProtector' -RecoveryKeyProtector $true | Should -Be $false
                }
            }

            Context 'When Test-BitlockerEnabled is called, a RecoveryPasswordProtector protector is requested, and does not exist on the disk' {
                It 'Should return False' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $defaultBLV }
                    Mock -CommandName Test-CollectionContainsKeyProtector -Verifiable -MockWith { return $false }

                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'TpmProtector' -RecoveryPasswordProtector $true | Should -Be $false
                }
            }

            Context 'When Test-BitlockerEnabled is called, a StartupKeyProtector protector is requested without a primary TPM protector, and does not exist on the disk' {
                It 'Should return False' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $defaultBLV }
                    Mock -CommandName Test-CollectionContainsKeyProtector -Verifiable -MockWith { return $false }

                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'StartupKeyProtector' -StartupKeyProtector $true | Should -Be $false
                }
            }

            Context 'When Test-BitlockerEnabled is called, a StartupKeyProtector protector is requested with a primary TPM protector, and does not exist on the disk' {
                It 'Should return False' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $defaultBLV }
                    Mock -CommandName Test-CollectionContainsKeyProtector -Verifiable -MockWith { return $false }

                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'TpmProtector' -StartupKeyProtector $true | Should -Be $false
                }
            }

            Context 'When Test-BitlockerEnabled is called, a TpmProtector protector is requested, and does not exist on the disk' {
                It 'Should return False' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $defaultBLV }
                    Mock -CommandName Test-CollectionContainsKeyProtector -Verifiable -MockWith { return $false }

                    Test-BitlockerEnabled -MountPoint 'C:' -PrimaryProtector 'TpmProtector' -TpmProtector $true | Should -Be $false
                }
            }
        }

        Describe 'xBitlockerCommon\Assert-HasPrereqsForBitlocker' {
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
                    Assert-HasPrereqsForBitlocker
                    Assert-MockCalled -Command Write-Error -Exactly -Times 0 -Scope It
                }

                It 'Should run the Assert-HasPrereqsForBitlocker function without exceptions' {
                    {Assert-HasPrereqsForBitlocker} | Should -Not -Throw
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
                    Assert-HasPrereqsForBitlocker
                    Assert-MockCalled -Command Write-Error -Exactly -Times 0 -Scope It
                }

                It 'Should run the Assert-HasPrereqsForBitlocker function without exceptions' {
                    {Assert-HasPrereqsForBitlocker} | Should -Not -Throw
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
                    {Assert-HasPrereqsForBitlocker} | Should -Throw
                    Assert-MockCalled -Command Write-Error -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Message -eq 'The Bitlocker feature needs to be installed before the xBitlocker module can be used'
                    }
                }

                It 'Should give an error that RSAT-Feature-Tools-BitLocker Windows Feature needs to be installed' {
                    {Assert-HasPrereqsForBitlocker} | Should -Throw
                    Assert-MockCalled -Command Write-Error -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Message -eq 'The RSAT-Feature-Tools-BitLocker feature needs to be installed before the xBitlocker module can be used'
                    }
                }

                It 'Should give an error that RSAT-Feature-Tools-BitLocker-RemoteAdminTool Windows Feature needs to be installed' {
                    {Assert-HasPrereqsForBitlocker} | Should -Throw
                    Assert-MockCalled -Command Write-Error -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Message -eq 'The RSAT-Feature-Tools-BitLocker-RemoteAdminTool feature needs to be installed before the xBitlocker module can be used'
                    }
                }

                It 'The Assert-HasPrereqsForBitlocker function should throw an exceptions about missing required Windows Features' {
                    {Assert-HasPrereqsForBitlocker} | Should -Throw 'Required Bitlocker features need to be installed before xBitlocker can be used'
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
                    {Assert-HasPrereqsForBitlocker} | Should -Throw
                    Assert-MockCalled -Command Write-Error -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Message -eq 'The Bitlocker feature needs to be installed before the xBitlocker module can be used'
                    }
                }

                It 'Should give an error that RSAT-Feature-Tools-BitLocker Windows Feature needs to be installed' {
                    {Assert-HasPrereqsForBitlocker} | Should -Throw
                    Assert-MockCalled -Command Write-Error -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Message -eq 'The RSAT-Feature-Tools-BitLocker feature needs to be installed before the xBitlocker module can be used'
                    }
                }

                It 'Should not give an error that RSAT-Feature-Tools-BitLocker-RemoteAdminTool Windows Feature needs to be installed as this Windows Features is not available on Server Core.' {
                    {Assert-HasPrereqsForBitlocker} | Should -Throw
                    Assert-MockCalled -Command Write-Error -Exactly -Times 0 -Scope It -ParameterFilter {
                        $Message -eq 'The RSAT-Feature-Tools-BitLocker-RemoteAdminTool feature needs to be installed before the xBitlocker module can be used'
                    }
                }

                It 'The Assert-HasPrereqsForBitlocker function should throw an exceptions about missing required Windows Features' {
                    {Assert-HasPrereqsForBitlocker} | Should -Throw 'Required Bitlocker features need to be installed before xBitlocker can be used'
                }
            }
        }

        Describe 'xBitLockerCommon\Get-OSEdition' {
            It 'Should return "Server Core" if the OS is Windows Server Core' {
                Mock -CommandName Get-ItemProperty -MockWith {
                    [PSCustomObject] @{
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
                    [PSCustomObject] @{
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
                    [PSCustomObject] @{
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

        Describe 'xBitLockerCommon\Enable-BitlockerInternal' -Tag 'Helper' {
            # Override Bitlocker cmdlets
            function Enable-Bitlocker {}
            function Enable-BitlockerAutoUnlock {}

            AfterEach {
                Assert-VerifiableMock
            }

            $fakePin = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'fakepin', (New-Object -TypeName System.Security.SecureString)
            $mountPoint = 'C:'
            $encryptedBLV = @{
                VolumeStatus = 'FullyEncrypted'
            }
            $encryptedOSBLV = @{
                VolumeStatus = 'FullyEncrypted'
                VolumeType   = 'OperatingSystem'
            }
            $decryptedOSBLV = @{
                VolumeStatus = 'FullyDecrypted'
                VolumeType   = 'OperatingSystem'
            }

            Context 'When Enable-BitlockerInternal is called Get-BitlockerVolume returns null' {
                It 'Should throw an exception' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable

                    { Enable-BitlockerInternal -MountPoint 'C:' -Pin $fakePin -PrimaryProtector 'PasswordProtector' } | Should -Throw -ExpectedMessage 'Unable to find Bitlocker Volume associated with Mount Point'
                }
            }

            Context 'When Enable-BitlockerInternal is called with TpmProtector set to True and PrimaryProtector not set to TpmProtector' {
                $badPrimaryProtectorCases = @(
                    @{
                        PrimaryProtector = 'PasswordProtector'
                    }

                    @{
                        PrimaryProtector = 'RecoveryPasswordProtector'
                    }

                    @{
                        PrimaryProtector = 'StartupKeyProtector'
                    }
                )

                It 'Should throw an exception' -TestCases $badPrimaryProtectorCases {
                    param
                    (
                        [System.String]
                        $PrimaryProtector
                    )

                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $encryptedBLV }

                    { Enable-BitlockerInternal -MountPoint $mountPoint -TpmProtector $true -PrimaryProtector $PrimaryProtector } | Should -Throw -ExpectedMessage 'If TpmProtector is used, it must be the PrimaryProtector.'
                }
            }

            Context 'When Enable-BitlockerInternal is called with Pin specified and TpmProtector not specified' {
                It 'Should throw an exception' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $encryptedBLV }

                    { Enable-BitlockerInternal -MountPoint $mountPoint -Pin $fakePin -PrimaryProtector 'PasswordProtector' } | Should -Throw -ExpectedMessage 'A TpmProtector must be used if Pin is used.'
                }
            }

            Context 'When Enable-BitlockerInternal is called with Pin specified and TpmProtector not specified' {
                It 'Should throw an exception' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $encryptedBLV }

                    { Enable-BitlockerInternal -MountPoint $mountPoint -Pin $fakePin -PrimaryProtector 'PasswordProtector' } | Should -Throw -ExpectedMessage 'A TpmProtector must be used if Pin is used.'
                }
            }

            $defaultEnableParams = @{
                MountPoint           = $mountPoint
                Pin                  = $fakePin
                PrimaryProtector     = 'TpmProtector'
                TpmProtector         = $true
                EncryptionMethod     = 'Aes256'
                HardwareEncryption   = $true
                Service              = $true
                SkipHardwareTest     = $true
                UsedSpaceOnly        = $true
                AllowImmediateReboot = $true
                StartupKeyProtector  = $true
            }

            Context 'When Enable-BitlockerInternal is called and the volume is not yet encrypted' {
                It 'Should enable Bitlocker with the correct key protectors and parameters' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $decryptedOSBLV }
                    Mock -CommandName Enable-Bitlocker -Verifiable -MockWith { return $encryptedOSBLV }
                    Mock -CommandName Start-Sleep -Verifiable
                    Mock -CommandName Restart-Computer -Verifiable

                    Enable-BitlockerInternal @defaultEnableParams
                }
            }

            Context 'When Enable-BitlockerInternal is called, the volume is not yet encrypted, and Enable-Bitlocker does not return a result' {
                It 'Should throw an exception' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $decryptedOSBLV }
                    Mock -CommandName Enable-Bitlocker -Verifiable

                    { Enable-BitlockerInternal @defaultEnableParams } | Should -Throw -ExpectedMessage 'Failed to successfully enable Bitlocker on MountPoint'
                }
            }

            Context 'When Enable-BitlockerInternal is called, the volume is not yet encrypted and is not an OS drive, and AutoUnlock is specified' {
                It 'Should enable Bitlocker with the correct key protectors and parameters and enable AutoUnlock' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith {
                        return @{
                            VolumeStatus = 'FullyDecrypted'
                            VolumeType   = 'Data'
                        }
                    }
                    Mock -CommandName Enable-Bitlocker -Verifiable -MockWith { return $encryptedBLV }
                    Mock -CommandName Enable-BitlockerAutoUnlock -Verifiable

                    $defaultEnableParams.Add('AutoUnlock', $true)

                    Enable-BitlockerInternal @defaultEnableParams

                    $defaultEnableParams.Remove('AutoUnlock')
                }
            }

            Context 'When Enable-BitlockerInternal is called with TPM only and the volume is not yet encrypted' {
                It 'Should enable Bitlocker with the correct key protectors and parameters' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $decryptedOSBLV }
                    Mock -CommandName Enable-Bitlocker -Verifiable -MockWith { return $encryptedBLV }

                    $tpmOnlyEnableParams = @{
                        MountPoint       = $mountPoint
                        PrimaryProtector = 'TpmProtector'
                        TpmProtector     = $true
                    }

                    Enable-BitlockerInternal @tpmOnlyEnableParams
                }
            }

            Context 'When Enable-BitlockerInternal is called with TPM and pin only and the volume is not yet encrypted' {
                It 'Should enable Bitlocker with the correct key protectors and parameters' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $decryptedOSBLV }
                    Mock -CommandName Enable-Bitlocker -Verifiable -MockWith { return $encryptedBLV }

                    $tpmAndPinOnlyEnableParams = @{
                        MountPoint       = $mountPoint
                        PrimaryProtector = 'TpmProtector'
                        TpmProtector     = $true
                        Pin              = $fakePin
                    }

                    Enable-BitlockerInternal @tpmAndPinOnlyEnableParams
                }
            }

            Context 'When Enable-BitlockerInternal is called with TPM and pin only and the volume is not yet encrypted' {
                It 'Should enable Bitlocker with the correct key protectors and parameters' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $decryptedOSBLV }
                    Mock -CommandName Enable-Bitlocker -Verifiable -MockWith { return $encryptedBLV }

                    $tpmAndStartupOnlyEnableParams = @{
                        MountPoint          = $mountPoint
                        PrimaryProtector    = 'TpmProtector'
                        TpmProtector        = $true
                        StartupKeyProtector = $true
                        StartupKeyPath      = 'C:\'
                    }

                    Enable-BitlockerInternal @tpmAndStartupOnlyEnableParams
                }
            }

            Context 'When Enable-BitlockerInternal is called with a Password Protector and the volume is not yet encrypted' {
                It 'Should enable Bitlocker with the correct key protectors and parameters' {
                    Mock -CommandName Get-BitLockerVolume -MockWith { return $decryptedOSBLV }
                    Mock -CommandName Enable-Bitlocker -MockWith { return $encryptedBLV }

                    $passwordEnableParams = @{
                        MountPoint        = $mountPoint
                        PrimaryProtector  = 'PasswordProtector'
                        PasswordProtector = $true
                        Password          = $fakePin
                    }

                    Enable-BitlockerInternal @passwordEnableParams
                }
            }

            Context 'When Enable-BitlockerInternal is called with a Recovery Password Protector and the volume is not yet encrypted' {
                It 'Should enable Bitlocker with the correct key protectors and parameters' {
                    Mock -CommandName Get-BitLockerVolume -MockWith { return $decryptedOSBLV }
                    Mock -CommandName Enable-Bitlocker -MockWith { return $encryptedBLV }

                    $recoveryPasswordEnableParams = @{
                        MountPoint                = $mountPoint
                        PrimaryProtector          = 'RecoveryPasswordProtector'
                        RecoveryPasswordProtector = $true
                        Password                  = $fakePin
                    }

                    Enable-BitlockerInternal @recoveryPasswordEnableParams
                }
            }

            Context 'When Enable-BitlockerInternal is called with a StartupKey Protector and the volume is not yet encrypted' {
                It 'Should enable Bitlocker with the correct key protectors and parameters' {
                    Mock -CommandName Get-BitLockerVolume -MockWith { return $decryptedOSBLV }
                    Mock -CommandName Enable-Bitlocker -MockWith { return $encryptedBLV }

                    $startupKeyEnableParams = @{
                        MountPoint          = $mountPoint
                        PrimaryProtector    = 'StartupKeyProtector'
                        StartupKeyProtector = $true
                        StartupKeyPath      = 'C:\Path'
                    }

                    Enable-BitlockerInternal @startupKeyEnableParams
                }
            }
        }

        Describe 'xBitLockerCommon\Add-MissingBitLockerKeyProtector' -Tag 'Helper' {
            # Override Bitlocker cmdlets
            function Add-BitLockerKeyProtector {}

            # Suppress Write-Verbose output
            Mock -CommandName Write-Verbose

            AfterEach {
                Assert-VerifiableMock
            }

            $fakePin = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'fakepin', (New-Object -TypeName System.Security.SecureString)
            $mountPoint = 'C:'
            $encryptedBLV = @{
                VolumeStatus = 'FullyEncrypted'
            }

            Context 'When Add-MissingBitLockerKeyProtector is called, the AdAccountOrGroupProtector protector is requested but not yet present on the volume, and is not the PrimaryKeyProtector' {
                It 'Should add the AdAccountOrGroupProtector protector' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $encryptedBLV }
                    Mock -CommandName Test-CollectionContainsKeyProtector -Verifiable -MockWith { return $false}
                    Mock -CommandName Add-BitLockerKeyProtector -Verifiable -ParameterFilter {$MountPoint -eq 'AdAccountOrGroupProtector'}

                    Enable-BitlockerInternal -MountPoint 'AdAccountOrGroupProtector' -Pin $fakePin -PrimaryProtector 'TpmProtector' -TpmProtector $true -AdAccountOrGroupProtector $true
                }
            }

            Context 'When Add-MissingBitLockerKeyProtector is called, the PasswordProtector protector is requested but not yet present on the volume, and is not the PrimaryKeyProtector' {
                It 'Should add the PasswordProtector protector' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $encryptedBLV }
                    Mock -CommandName Test-CollectionContainsKeyProtector -Verifiable -MockWith { return $false}
                    Mock -CommandName Add-BitLockerKeyProtector -Verifiable -ParameterFilter {$MountPoint -eq 'PasswordProtector'}

                    Enable-BitlockerInternal -MountPoint 'PasswordProtector' -Pin $fakePin -PrimaryProtector 'TpmProtector' -TpmProtector $true -PasswordProtector $true
                }
            }

            Context 'When Add-MissingBitLockerKeyProtector is called, the RecoveryKeyProtector protector is requested but not yet present on the volume, and is not the PrimaryKeyProtector' {
                It 'Should add the RecoveryKeyProtector protector' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $encryptedBLV }
                    Mock -CommandName Test-CollectionContainsKeyProtector -Verifiable -MockWith { return $false}
                    Mock -CommandName Add-BitLockerKeyProtector -Verifiable -ParameterFilter {$MountPoint -eq 'RecoveryKeyProtector'}

                    Enable-BitlockerInternal -MountPoint 'RecoveryKeyProtector' -Pin $fakePin -PrimaryProtector 'TpmProtector' -TpmProtector $true -RecoveryKeyProtector $true
                }
            }

            Context 'When Add-MissingBitLockerKeyProtector is called, the RecoveryPasswordProtector protector is requested but not yet present on the volume, and is not the PrimaryKeyProtector' {
                It 'Should add the RecoveryPasswordProtector protector' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $encryptedBLV }
                    Mock -CommandName Test-CollectionContainsKeyProtector -Verifiable -MockWith { return $false}
                    Mock -CommandName Add-BitLockerKeyProtector -Verifiable -ParameterFilter {$MountPoint -eq 'RecoveryPasswordProtector'}

                    Enable-BitlockerInternal -MountPoint 'RecoveryPasswordProtector' -Pin $fakePin -PrimaryProtector 'TpmProtector' -TpmProtector $true -RecoveryPasswordProtector $true
                }
            }

            Context 'When Add-MissingBitLockerKeyProtector is called, the StartupKeyProtector protector is requested but not yet present on the volume, and is not the PrimaryKeyProtector' {
                It 'Should add the StartupKeyProtector protector' {
                    Mock -CommandName Get-BitLockerVolume -Verifiable -MockWith { return $encryptedBLV }
                    Mock -CommandName Test-CollectionContainsKeyProtector -Verifiable -MockWith { return $false}
                    Mock -CommandName Add-BitLockerKeyProtector -Verifiable -ParameterFilter {$MountPoint -eq 'StartupKeyProtector'}

                    Enable-BitlockerInternal -MountPoint 'StartupKeyProtector' -PrimaryProtector 'RecoveryPasswordProtector' -RecoveryPasswordProtector $true -StartupKeyProtector $true
                }
            }
        }

        Describe 'xBitLockerCommon\Test-CollectionContainsKeyProtector' -Tag 'Helper' {
            $testKeyProtectorCollection = @(
                @{
                    KeyProtectorType = 'RecoveryPassword'
                }

                @{
                    KeyProtectorType = 'AdAccountOrGroup'
                }

                @{
                    KeyProtectorType = 'StartupKeyProtector'
                }
            )

            Context 'When Test-CollectionContainsKeyProtector is called and the target KeyProtector exists in the collection' {
                It 'Should return True' {
                    Test-CollectionContainsKeyProtector -Type 'AdAccountOrGroup' -KeyProtectorCollection $testKeyProtectorCollection | Should -Be $true
                }
            }

            Context 'When Test-CollectionContainsKeyProtector is called and the target KeyProtector does not exist in the collection' {
                It 'Should return False' {
                    Test-CollectionContainsKeyProtector -Type 'AdAccountOrGroup2' -KeyProtectorCollection $testKeyProtectorCollection | Should -Be $false
                }
            }

            Context 'When Test-CollectionContainsKeyProtector is called with the StartsWith switch and the target KeyProtector exists in the collection' {
                It 'Should return True' {
                    Test-CollectionContainsKeyProtector -Type 'AdAccount' -KeyProtectorCollection $testKeyProtectorCollection -StartsWith $true | Should -Be $true
                }
            }

            Context 'When Test-CollectionContainsKeyProtector is called with the StartsWith switch and the target KeyProtector does not exist in the collection' {
                It 'Should return False' {
                    Test-CollectionContainsKeyProtector -Type 'Account' -KeyProtectorCollection $testKeyProtectorCollection -StartsWith $true | Should -Be $false
                }
            }

            Context 'When Test-CollectionContainsKeyProtector is called with the Contains switch and the target KeyProtector exists in the collection' {
                It 'Should return True' {
                    Test-CollectionContainsKeyProtector -Type 'Account' -KeyProtectorCollection $testKeyProtectorCollection -Contains $true | Should -Be $true
                }
            }

            Context 'When Test-CollectionContainsKeyProtector is called with the Contains switch and the target KeyProtector does not exist in the collection' {
                It 'Should return False' {
                    Test-CollectionContainsKeyProtector -Type 'NotInCollection' -KeyProtectorCollection $testKeyProtectorCollection -Contains $true | Should -Be $false
                }
            }
        }

        Describe 'xBitLockerCommon\Add-ToPSBoundParametersFromHashtable' -Tag 'Helper' {
            AfterEach {
                Assert-VerifiableMock
            }

            Context 'When Add-ToPSBoundParametersFromHashtable is called, a parameter is added, and a parameter is changed' {
                It 'Should add a new parameter and change the existing parameter' {
                    $param1    = 'abc'
                    $param2    = $null
                    $param2new = 'notnull'
                    $param3    = 'def'
                    $param4    = 'ghi'

                    $psBoundParametersIn = @{
                        Param1 = $param1
                        Param2 = $param2
                        Param3 = $param3
                    }

                    $paramsToAdd = @{
                        Param2 = $param2new
                        Param4 = $param4
                    }

                    Add-ToPSBoundParametersFromHashtable -PSBoundParametersIn $psBoundParametersIn -ParamsToAdd $paramsToAdd

                    $psBoundParametersIn.ContainsKey('Param1') -and $psBoundParametersIn['Param1'] -eq $param1 | Should -Be $true
                    $psBoundParametersIn.ContainsKey('Param2') -and $psBoundParametersIn['Param2'] -eq $param2new | Should -Be $true
                    $psBoundParametersIn.ContainsKey('Param3') -and $psBoundParametersIn['Param3'] -eq $param3 | Should -Be $true
                    $psBoundParametersIn.ContainsKey('Param4') -and $psBoundParametersIn['Param4'] -eq $param4 | Should -Be $true
                }
            }
        }

        Describe 'xBitLockerCommon\Remove-FromPSBoundParametersUsingHashtable' -Tag 'Helper' {
            AfterEach {
                Assert-VerifiableMock
            }

            Context 'When Remove-FromPSBoundParametersUsingHashtable is called and both ParamsToKeep and ParamsToRemove are specified' {
                It 'Should throw an exception' {
                    { Remove-FromPSBoundParametersUsingHashtable -PSBoundParametersIn @{} -ParamsToKeep @('Param1') -ParamsToRemove @('Param2') } | `
                        Should -Throw -ExpectedMessage 'Parameter set cannot be resolved using the specified named parameters.'
                }
            }

            Context 'When Remove-FromPSBoundParametersUsingHashtable is called with ParamsToKeep' {
                It 'Should remove any parameter not specified in ParamsToKeep' {
                    $psBoundParametersIn = @{
                        Param1 = 1
                        Param2 = 2
                        Param3 = 3
                    }

                    $paramsToKeep = @('Param1', 'Param2')

                    Remove-FromPSBoundParametersUsingHashtable -PSBoundParametersIn $psBoundParametersIn -ParamsToKeep $paramsToKeep

                    $psBoundParametersIn.ContainsKey('Param1') | Should -Be $true
                    $psBoundParametersIn.ContainsKey('Param2') | Should -Be $true
                    $psBoundParametersIn.ContainsKey('Param3') | Should -Be $false
                }
            }

            Context 'When Remove-FromPSBoundParametersUsingHashtable is called with ParamsToRemove' {
                It 'Should remove any parameter specified in ParamsToRemove' {
                    $psBoundParametersIn = @{
                        Param1 = 1
                        Param2 = 2
                        Param3 = 3
                    }

                    $paramsToRemove = @(
                        'Param1',
                        'param2'
                    )

                    Remove-FromPSBoundParametersUsingHashtable -PSBoundParametersIn $psBoundParametersIn -ParamsToRemove $paramsToRemove

                    $psBoundParametersIn.ContainsKey('Param1') | Should -Be $false
                    $psBoundParametersIn.ContainsKey('Param2') | Should -Be $false
                    $psBoundParametersIn.ContainsKey('Param3') | Should -Be $true
                }
            }
        }
    }
}
finally
{
}

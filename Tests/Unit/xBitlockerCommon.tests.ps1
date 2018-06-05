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

        function Write-Error
        {

        }

        Describe 'xBitlockerCommon\TestBitlocker' {

            Context 'When OS Volume is not Encrypted and No Key Protectors Assigned' {
                Mock `
                    -CommandName Get-BitlockerVolume `
                    -ModuleName 'xBitlockerCommon' `
                    -MockWith {
                            # Decrypted with no Key Protectors
                            return @{
                            VolumeType = 'OperatingSystem'
                            MountPoint = $MountPoint
                            CapacityGB = 500
                            VolumeStatus = 'FullyDecrypted'
                            EncryptionPercentage = 0
                            KeyProtector = @()
                            AutoUnlockEnabled = $null
                            ProtectionStatus = 'Off'
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
                            VolumeType = 'OperatingSystem'
                            MountPoint = $MountPoint
                            CapacityGB = 500
                            VolumeStatus = 'FullyEncrypted'
                            EncryptionPercentage = 100
                            KeyProtector = @(
                                @{
                                    KeyProtectorType = 'Tpm'
                                },
                                @{
                                    KeyProtectorType = 'RecoveryPassword'
                                }
                            )
                            AutoUnlockEnabled = $null
                            ProtectionStatus = 'On'
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
                            VolumeType = 'OperatingSystem'
                            MountPoint = $MountPoint
                            CapacityGB = 500
                            VolumeStatus = 'FullyDecrypted'
                            EncryptionPercentage = 0
                            KeyProtector = @(
                                @{
                                    KeyProtectorType = 'Tpm'
                                },
                                @{
                                    KeyProtectorType = 'RecoveryPassword'
                                }
                            )
                            AutoUnlockEnabled = $null
                            ProtectionStatus = 'Off'
                        }
                    }

                It 'Should Fail The Test (TPM and RecoveryPassword Protectors)' {
                    TestBitlocker -MountPoint 'C:' -PrimaryProtector 'TPMProtector' -RecoveryPasswordProtector $true | Should -Be $false
                }
            }

            Context 'When OS is Windows Server Core and all required features are installed' {
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

                It 'Should run the CheckForPreReqs function without exceptions' {
                    {CheckForPreReqs} | Should -Not -Throw
                }
            }

            Context 'When OS is Full Server without the required features (RSAT-Feature-Tools-BitLocker-RemoteAdminTool) installed' {
                Mock -CommandName Get-OSEdition -MockWith {
                    return 'Server'
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
                            InstallState = 'Installed'
                        }
                    }
                }
                It 'The CheckForPreReqs function should throw an exceptions about missing Windows Feature' {
                    Mock -CommandName Write-Error -MockWith {
                        Throw 'Required Bitlocker features need to be installed before xBitlocker can be used'
                    }

                    {CheckForPreReqs} | Should -Throw 'Required Bitlocker features need to be installed before xBitlocker can be used'
                    Assert-MockCalled -Command Write-Error -Exactly -Time 1 -Scope It
                }
            }
        }
    }
}
finally
{
}

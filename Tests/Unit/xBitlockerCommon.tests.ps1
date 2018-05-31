$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Misc' -ChildPath 'xBitlockerCommon.psm1')) -Force

# Begin Testing
try
{
    InModuleScope "xBitlockerCommon" {

        function Get-BitlockerVolume {
            param
            (
                [Parameter()]
                [System.String]
                $MountPoint
            )
        }

        Describe "xBitlockerCommon\TestBitlocker" {

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
        }
    }
}
finally
{
}

#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xBitlocker' `
    -DSCResourceName 'MSFT_xBLAutoBitlocker' `
    -TestType Unit

#endregion HEADER

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment


}

# Begin Testing
try
{
    InModuleScope 'MSFT_xBLAutoBitlocker' {

        function Get-BitLockerVolume {
            param
            (
                [Parameter()]
                [System.String[]]
                $MountPoint
            )
        }

        # Get-BitlockerVolume is used to obtain list of volumes in the system and their current encryption status
        Mock `
            -CommandName Get-BitlockerVolume `
            -ModuleName 'MSFT_xBLAutoBitlocker' `
            -MockWith {
                # Returns a collection of OS/Fixed/Removable disks with correct/incorrect removable status
                return @(
                    @{
                        # C: is OS drive
                        VolumeType = 'OperatingSystem'
                        MountPoint = 'C:'
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
                    },
                    @{
                        # D: is Fixed drive, incorrectly reporting as Removable to Bitlocker
                        VolumeType = 'Data'
                        MountPoint = 'D:'
                        CapacityGB = 500
                        VolumeStatus = 'FullyDecrypted'
                        EncryptionPercentage = 0
                        KeyProtector = @(
                        )
                        AutoUnlockEnabled = $null
                        ProtectionStatus = 'Off'
                    },
                    @{
                        # E: is Fixed drive, correctly reporting as Fixed to Bitlocker
                        VolumeType = 'Data'
                        MountPoint = 'E:'
                        CapacityGB = 500
                        VolumeStatus = 'FullyDecrypted'
                        EncryptionPercentage = 0
                        KeyProtector = @(
                        )
                        AutoUnlockEnabled = $null
                        ProtectionStatus = 'Off'
                    }
                    @{
                        # F: is a Removable drive thumb drive, correctly reporting as Removable to Bitlocker
                        VolumeType = 'Data'
                        MountPoint = 'F:'
                        CapacityGB = 500
                        VolumeStatus = 'FullyDecrypted'
                        EncryptionPercentage = 0
                        KeyProtector = @(
                        )
                        AutoUnlockEnabled = $null
                        ProtectionStatus = 'Off'
                    },

                    @{
                        # 1 is Fixed drive, incorrectly reporting as Removable to Bitlocker
                        VolumeType = 'Data'
                        MountPoint = '\\?\Volume{00000000-0000-0000-0000-000000000001}\'
                        CapacityGB = 500
                        VolumeStatus = 'FullyDecrypted'
                        EncryptionPercentage = 0
                        KeyProtector = @(
                        )
                        AutoUnlockEnabled = $null
                        ProtectionStatus = 'Off'
                    },
                    @{
                        # 2 is Fixed drive, correctly reporting as Fixed to Bitlocker
                        VolumeType = 'Data'
                        MountPoint = '\\?\Volume{00000000-0000-0000-0000-000000000002}\'
                        CapacityGB = 500
                        VolumeStatus = 'FullyDecrypted'
                        EncryptionPercentage = 0
                        KeyProtector = @(
                        )
                        AutoUnlockEnabled = $null
                        ProtectionStatus = 'Off'
                    }
                    @{
                        # 3 is a Removable drive thumb drive, correctly reporting as Removable to Bitlocker
                        VolumeType = 'Data'
                        MountPoint = '\\?\Volume{00000000-0000-0000-0000-000000000003}\'
                        CapacityGB = 500
                        VolumeStatus = 'FullyDecrypted'
                        EncryptionPercentage = 0
                        KeyProtector = @(
                        )
                        AutoUnlockEnabled = $null
                        ProtectionStatus = 'Off'
                    }
                )
            }

            # Get-Volume evaluates volume removable status correctly
            # This was used in broken version of the module, replaced in Issue #11 by Win32_EncryptableVolume class
            Mock `
            -CommandName Get-Volume `
            -ModuleName 'MSFT_xBLAutoBitlocker' `
            -MockWith {
                # Returns a collection of OS/Fixed/Removable disks with correct/incorrect removable status

                switch ($Path)
                {
                    '\\?\Volume{00000000-0000-0000-0000-000000000001}\' {
                        return @{
                            # D: is Fixed drive, incorrectly reporting as Removable to Bitlocker
                            DriveLetter = ''
                            Path = '\\?\Volume{00000000-0000-0000-0000-000000000001}\'
                            DriveType = 'Fixed'
                        }
                    }
                    '\\?\Volume{00000000-0000-0000-0000-000000000002}\' {
                        return @{
                            # 2 is Fixed drive, correctly reporting as Fixed to Bitlocker
                            DriveLetter = ''
                            Path = '\\?\Volume{00000000-0000-0000-0000-000000000002}\'
                            DriveType = 'Fixed'
                        }
                    }
                    '\\?\Volume{00000000-0000-0000-0000-000000000003}\' {
                        return @{
                            # 3 is a Removable drive, correctly reporting as Fixed to Bitlocker
                            DriveLetter = ''
                            Path = '\\?\Volume{00000000-0000-0000-0000-000000000003}\'
                            DriveType = 'Removable'
                        }
                    }
                    default {
                        return $null
                    }
                }
            }

            Mock `
            -CommandName Get-CimInstance `
            -ModuleName 'MSFT_xBLAutoBitlocker' `
            -MockWith {
                # Returns a collection of OS/Fixed/Removable disks with correct/incorrect removable status
                return @(
                    @{
                        # C: is OS drive
                        DriveLetter = 'C:'
                        VolumeType=0
                        DeviceID='\\?\Volume{00000000-0000-0000-0000-000000000000}\'

                    },
                    @{
                        # D: is Fixed drive, incorrectly reporting as Removable to Bitlocker
                        DriveLetter = 'D:'
                        VolumeType=2
                        DeviceID='\\?\Volume{00000000-0000-0000-0000-000000000004}\'

                    },
                    @{
                        # E: is Fixed drive, correctly reporting as Fixed to Bitlocker
                        DriveLetter = 'E:'
                        VolumeType=1
                        DeviceID='\\?\Volume{00000000-0000-0000-0000-000000000005}\'

                    },
                    @{
                        # F: is a Removable drive, correctly reporting as Fixed to Bitlocker
                        DriveLetter = 'F:'
                        VolumeType=2
                        DeviceID='\\?\Volume{00000000-0000-0000-0000-000000000006}\'
                    },
                    @{
                        # 1 is Fixed drive, incorrectly reporting as Removable to Bitlocker
                        DriveLetter = ''
                        VolumeType=2
                        DeviceID='\\?\Volume{00000000-0000-0000-0000-000000000001}\'
                    },
                    @{
                        # 2 is Fixed drive, correctly reporting as Fixed to Bitlocker
                        DriveLetter = ''
                        VolumeType=1
                        DeviceID='\\?\Volume{00000000-0000-0000-0000-000000000002}\'
                    },
                    @{
                        # 3 is a Removable drive, correctly reporting as Fixed to Bitlocker
                        DriveLetter = ''
                        VolumeType=2
                        DeviceID='\\?\Volume{00000000-0000-0000-0000-000000000003}\'
                    }

                )
            }

        Describe 'MSFT_xBLAutoBitlocker\GetAutoBitlockerStatus' {

            Context 'When Volume C: Reports as OS Volume' {

                It 'Should Not Be In The List of Eligible Fixed Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Fixed" -PrimaryProtector TpmProtector|Select-Object -ExpandProperty Keys)|Should -Not -Contain 'C:'
                }

                It 'Should Not Be In The List of Eligible Removable Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Removable" -PrimaryProtector TpmProtector|Select-Object -ExpandProperty Keys)|Should -Not -Contain 'C:'
                }
            }

            Context 'When Volume D: Reports Fixed to OS, but Removable to Bitlocker' {

                It 'Should Not Be In The List of Eligible Fixed Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Fixed" -PrimaryProtector RecoveryPasswordProtector|Select-Object -ExpandProperty Keys)|Should -Not -Contain 'D:'
                }

                It 'Should Be In The List of Eligible Removable Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Removable" -PrimaryProtector RecoveryPasswordProtector|Select-Object -ExpandProperty Keys)|Should -Contain 'D:'
                }
            }

            Context 'When Volume E: Reports Fixed to OS and Bitlocker' {

                It 'Should Be In The List of Eligible Fixed Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Fixed" -PrimaryProtector RecoveryPasswordProtector|Select-Object -ExpandProperty Keys)|Should -Contain 'E:'
                }

                It 'Should Not Be In The List of Eligible Removable Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Removable" -PrimaryProtector RecoveryPasswordProtector|Select-Object -ExpandProperty Keys)|Should -Not -Contain 'E:'
                }
            }

            Context 'When Volume F: Reports as Removable to OS and Bitlocker' {

                It 'Should Not Be In The List of Eligible Fixed Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Fixed" -PrimaryProtector RecoveryPasswordProtector|Select-Object -ExpandProperty Keys)|Should -Not -Contain 'F:'
                }

                It 'Should Be In The List of Eligible Removable Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Removable" -PrimaryProtector RecoveryPasswordProtector|Select-Object -ExpandProperty Keys)|Should -Contain 'F:'
                }
            }

            Context 'When Volume \\?\Volume{00000000-0000-0000-0000-000000000001}\ Reports Fixed to OS, but Removable to Bitlocker' {

                It 'Should Not Be In The List of Eligible Fixed Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Fixed" -PrimaryProtector RecoveryPasswordProtector|Select-Object -ExpandProperty Keys)|Should -Not -Contain '\\?\Volume{00000000-0000-0000-0000-000000000001}\'
                }

                It 'Should Be In The List of Eligible Removable Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Removable" -PrimaryProtector RecoveryPasswordProtector|Select-Object -ExpandProperty Keys)|Should -Contain '\\?\Volume{00000000-0000-0000-0000-000000000001}\'
                }
            }

            Context 'When Volume \\?\Volume{00000000-0000-0000-0000-000000000002}\ Reports Fixed to OS and Bitlocker' {

                It 'Should Be In The List of Eligible Fixed Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Fixed" -PrimaryProtector RecoveryPasswordProtector|Select-Object -ExpandProperty Keys)|Should -Contain '\\?\Volume{00000000-0000-0000-0000-000000000002}\'
                }

                It 'Should Not Be In The List of Eligible Removable Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Removable" -PrimaryProtector RecoveryPasswordProtector|Select-Object -ExpandProperty Keys)|Should -Not -Contain '\\?\Volume{00000000-0000-0000-0000-000000000002}\'
                }
            }

            Context 'When Volume \\?\Volume{00000000-0000-0000-0000-000000000003}\ Reports as Removable to OS and Bitlocker' {

                It 'Should Not Be In The List of Eligible Fixed Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Fixed" -PrimaryProtector RecoveryPasswordProtector|Select-Object -ExpandProperty Keys)|Should -Not -Contain '\\?\Volume{00000000-0000-0000-0000-000000000003}\'
                }

                It 'Should Be In The List of Eligible Removable Volumes' {
                    (GetAutoBitlockerStatus -DriveType "Removable" -PrimaryProtector RecoveryPasswordProtector|Select-Object -ExpandProperty Keys)|Should -Contain '\\?\Volume{00000000-0000-0000-0000-000000000003}\'
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}

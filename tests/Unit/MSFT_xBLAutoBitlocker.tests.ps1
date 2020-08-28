#region HEADER
$script:dscModuleName = 'xBitlocker'
$script:dscResourceName = 'MSFT_xBLAutoBitlocker'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        # Override Bitlocker functions
        function Get-BitLockerVolume
        {
            param
            (
                [Parameter()]
                [System.String[]]
                $MountPoint
            )
        }

        # Override Helper functions
        function Assert-HasPrereqsForBitlocker {}
        function Remove-FromPSBoundParametersUsingHashtable {}
        function Add-ToPSBoundParametersFromHashtable {}
        function Test-BitlockerEnabled {}
        function Enable-BitlockerInternal {}

        Describe 'MSFT_xBLAutoBitlocker\Get-TargetResource' -Tag 'Get' {
            AfterEach {
                Assert-VerifiableMock
            }

            $testDriveType = 'Fixed'
            $testPrimaryProtector = 'TpmProtector'

            Mock -CommandName Import-Module -Verifiable
            Mock -CommandName Assert-HasPrereqsForBitlocker -Verifiable

            Context 'When Get-TargetResource is called and Assert-HasPrereqsForBitlocker succeeds' {
                It 'Should return a Hashtable with the input resource DriveType' {
                    $getResult = Get-TargetResource -DriveType $testDriveType -PrimaryProtector $testPrimaryProtector
                    $getResult | Should -Be -Not $null
                    $getResult.DriveType | Should -Be $testDriveType
                }
            }
        }

        Describe 'MSFT_xBLAutoBitlocker\Set-TargetResource' -Tag 'Set' {
            AfterEach {
                Assert-VerifiableMock
            }

            $testDriveType = 'Fixed'
            $testPrimaryProtector = 'TpmProtector'

            Mock -CommandName Import-Module -Verifiable
            Mock -CommandName Assert-HasPrereqsForBitlocker -Verifiable

            Context 'When Set-TargetResource is called, Assert-HasPrereqsForBitlocker succeeds, and Get-AutoBitlockerStatus returns null' {
                Mock -CommandName Get-AutoBitlockerStatus -Verifiable

                It 'Should throw an exception' {
                    { Set-TargetResource -DriveType $testDriveType -PrimaryProtector $testPrimaryProtector } | Should -Throw -ExpectedMessage 'No Auto Bitlocker volumes were found'
                }
            }

            Context 'When Set-TargetResource is called, Assert-HasPrereqsForBitlocker succeeds, Get-AutoBitlockerStatus returns a valid hashtable, and Test-BitlockerEnabled returns False' {
                Mock -CommandName Get-AutoBitlockerStatus -Verifiable -MockWith {
                    return @{
                        Keys = @('Volume1')
                    }
                }
                Mock -CommandName Remove-FromPSBoundParametersUsingHashtable -Verifiable
                Mock -CommandName Add-ToPSBoundParametersFromHashtable -Verifiable
                Mock -CommandName Test-BitlockerEnabled -Verifiable -MockWith { return $false }
                Mock -CommandName Enable-BitlockerInternal -Verifiable

                It 'Should enable Bitlocker' {
                    Set-TargetResource -DriveType $testDriveType -PrimaryProtector $testPrimaryProtector
                }
            }

            Context 'When Set-TargetResource is called, Assert-HasPrereqsForBitlocker succeeds, Get-AutoBitlockerStatus returns a valid hashtable, and Test-BitlockerEnabled returns True' {
                Mock -CommandName Get-AutoBitlockerStatus -Verifiable -MockWith {
                    return @{
                        Keys = @('Volume1')
                    }
                }
                Mock -CommandName Remove-FromPSBoundParametersUsingHashtable -Verifiable
                Mock -CommandName Add-ToPSBoundParametersFromHashtable -Verifiable
                Mock -CommandName Test-BitlockerEnabled -Verifiable -MockWith { return $true }
                Mock -CommandName Enable-BitlockerInternal

                It 'Should not enable Bitlocker' {
                    Set-TargetResource -DriveType $testDriveType -PrimaryProtector $testPrimaryProtector

                    Assert-MockCalled -CommandName Enable-BitlockerInternal -Times 0
                }
            }
        }

        Describe 'MSFT_xBLAutoBitlocker\Test-TargetResource' -Tag 'Test' {
            AfterEach {
                Assert-VerifiableMock
            }

            $testDriveType = 'Fixed'
            $testPrimaryProtector = 'TpmProtector'

            Mock -CommandName Import-Module -Verifiable
            Mock -CommandName Assert-HasPrereqsForBitlocker -Verifiable

            Context 'When Test-TargetResource is called, Assert-HasPrereqsForBitlocker succeeds, and Get-AutoBitlockerStatus returns null' {
                Mock -CommandName Get-AutoBitlockerStatus -Verifiable
                Mock -CommandName Write-Error -Verifiable

                It 'Should write an error and return false' {
                    Test-TargetResource -DriveType $testDriveType -PrimaryProtector $testPrimaryProtector | Should -Be $false
                }
            }

            Context 'When Test-TargetResource is called, Assert-HasPrereqsForBitlocker succeeds, Get-AutoBitlockerStatus returns a valid hashtable, and Test-BitlockerEnabled returns False' {
                Mock -CommandName Get-AutoBitlockerStatus -Verifiable -MockWith {
                    return @{
                        Keys = @('Volume1')
                    }
                }
                Mock -CommandName Remove-FromPSBoundParametersUsingHashtable -Verifiable
                Mock -CommandName Add-ToPSBoundParametersFromHashtable -Verifiable
                Mock -CommandName Test-BitlockerEnabled -Verifiable -MockWith { return $false }

                It 'Should return False' {
                    Test-TargetResource -DriveType $testDriveType -PrimaryProtector $testPrimaryProtector | Should -Be $false
                }
            }

            Context 'When Test-TargetResource is called, Assert-HasPrereqsForBitlocker succeeds, Get-AutoBitlockerStatus returns a valid hashtable, and Test-BitlockerEnabled returns True' {
                Mock -CommandName Get-AutoBitlockerStatus -Verifiable -MockWith {
                    return @{
                        Keys = @('Volume1')
                    }
                }
                Mock -CommandName Remove-FromPSBoundParametersUsingHashtable -Verifiable
                Mock -CommandName Add-ToPSBoundParametersFromHashtable -Verifiable
                Mock -CommandName Test-BitlockerEnabled -Verifiable -MockWith { return $true }

                It 'Should return True' {
                    Test-TargetResource -DriveType $testDriveType -PrimaryProtector $testPrimaryProtector | Should -Be $true
                }
            }
        }

        Describe 'MSFT_xBLAutoBitlocker\Get-AutoBitlockerStatus' {
        # Get-BitlockerVolume is used to obtain list of volumes in the system and their current encryption status
            Mock `
                -CommandName Get-BitlockerVolume `
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
                            CapacityGB = 50
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
                            CapacityGB = 50
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
                -MockWith {
                    # Returns a collection of OS/Fixed/Removable disks with correct/incorrect removable status

                    switch ($Path)
                    {
                        '\\?\Volume{00000000-0000-0000-0000-000000000001}\'
                        {
                            return @{
                                # D: is Fixed drive, incorrectly reporting as Removable to Bitlocker
                                DriveLetter = ''
                                Path = '\\?\Volume{00000000-0000-0000-0000-000000000001}\'
                                DriveType = 'Fixed'
                            }
                        }
                        '\\?\Volume{00000000-0000-0000-0000-000000000002}\'
                        {
                            return @{
                                # 2 is Fixed drive, correctly reporting as Fixed to Bitlocker
                                DriveLetter = ''
                                Path = '\\?\Volume{00000000-0000-0000-0000-000000000002}\'
                                DriveType = 'Fixed'
                            }
                        }
                        '\\?\Volume{00000000-0000-0000-0000-000000000003}\'
                        {
                            return @{
                                # 3 is a Removable drive, correctly reporting as Fixed to Bitlocker
                                DriveLetter = ''
                                Path = '\\?\Volume{00000000-0000-0000-0000-000000000003}\'
                                DriveType = 'Removable'
                            }
                        }
                        default
                        {
                            throw "No MSFT_Volume objects found with property 'Path' equal to '$Path'.  Verify the value of the property and retry."
                        }
                    }
                }

            Mock `
                -CommandName Get-CimInstance `
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

            Context 'When Volume C: Reports as OS Volume' {

                It 'Should Not Be In The List of Eligible Fixed Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Fixed' -PrimaryProtector TpmProtector).Keys | Should -Not -Contain 'C:'
                }

                It 'Should Not Be In The List of Eligible Removable Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Removable' -PrimaryProtector TpmProtector).Keys  | Should -Not -Contain 'C:'
                }
            }

            Context 'When Volume D: Reports Fixed to OS, but Removable to Bitlocker' {

                It 'Should Not Be In The List of Eligible Fixed Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Fixed' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Not -Contain 'D:'
                }

                It 'Should Be In The List of Eligible Removable Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Removable' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Contain 'D:'
                }
            }

            Context 'When Volume E: Reports Fixed to OS and Bitlocker' {

                It 'Should Be In The List of Eligible Fixed Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Fixed' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Contain 'E:'
                }

                It 'Should Not Be In The List of Eligible Removable Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Removable' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Not -Contain 'E:'
                }
            }

            Context 'When Volume F: Reports as Removable to OS and Bitlocker' {

                It 'Should Not Be In The List of Eligible Fixed Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Fixed' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Not -Contain 'F:'
                }

                It 'Should Be In The List of Eligible Removable Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Removable' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Contain 'F:'
                }
            }

            Context 'When Volume \\?\Volume{00000000-0000-0000-0000-000000000001}\ Reports Fixed to OS, but Removable to Bitlocker' {

                It 'Should Not Be In The List of Eligible Fixed Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Fixed' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Not -Contain '\\?\Volume{00000000-0000-0000-0000-000000000001}\'
                }

                It 'Should Be In The List of Eligible Removable Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Removable' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Contain '\\?\Volume{00000000-0000-0000-0000-000000000001}\'
                }
            }

            Context 'When Volume \\?\Volume{00000000-0000-0000-0000-000000000002}\ Reports Fixed to OS and Bitlocker' {

                It 'Should Be In The List of Eligible Fixed Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Fixed' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Contain '\\?\Volume{00000000-0000-0000-0000-000000000002}\'
                }

                It 'Should Not Be In The List of Eligible Removable Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Removable' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Not -Contain '\\?\Volume{00000000-0000-0000-0000-000000000002}\'
                }
            }

            Context 'When Volume \\?\Volume{00000000-0000-0000-0000-000000000003}\ Reports as Removable to OS and Bitlocker' {

                It 'Should Not Be In The List of Eligible Fixed Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Fixed' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Not -Contain '\\?\Volume{00000000-0000-0000-0000-000000000003}\'
                }

                It 'Should Be In The List of Eligible Removable Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Removable' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Contain '\\?\Volume{00000000-0000-0000-0000-000000000003}\'
                }
            }

            Context 'When MinDiskCapacity Parameter is Defined at 100 GB for Fixed Disks' {

                It 'Should Exclude E: from The List of Eligible Fixed Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Fixed' -PrimaryProtector RecoveryPasswordProtector -MinDiskCapacityGB 100).Keys  | Should -Not -Contain 'E:'
                }

                It 'Should Include Volume \\?\Volume{00000000-0000-0000-0000-000000000002}\ In The List of Eligible Removable Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Fixed' -PrimaryProtector RecoveryPasswordProtector -MinDiskCapacityGB 100).Keys  | Should -Contain '\\?\Volume{00000000-0000-0000-0000-000000000002}\'
                }
            }

            Context 'When MinDiskCapacity Parameter is Not Defined for Fixed Disks' {

                It 'Should Include E: In The List of Eligible Fixed Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Fixed' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Contain 'E:'
                }

                It 'Should Include Volume \\?\Volume{00000000-0000-0000-0000-000000000002}\ In The List of Eligible Removable Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Fixed' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Contain '\\?\Volume{00000000-0000-0000-0000-000000000002}\'
                }
            }

            Context 'When MinDiskCapacity Parameter is Defined at 100 GB for Removable Disks' {

                It 'Should Exclude \\?\Volume{00000000-0000-0000-0000-000000000003}\ from The List of Eligible Fixed Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Removable' -PrimaryProtector RecoveryPasswordProtector -MinDiskCapacityGB 100).Keys  | Should -Not -Contain '\\?\Volume{00000000-0000-0000-0000-000000000003}\'
                }

                It 'Should Include F: In The List of Eligible Removable Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Removable' -PrimaryProtector RecoveryPasswordProtector -MinDiskCapacityGB 100).Keys  | Should -Contain 'F:'
                }
            }

            Context 'When MinDiskCapacity Parameter is Not Defined for Fixed Disks' {

                It 'Should Include \\?\Volume{00000000-0000-0000-0000-000000000003}\ In The List of Eligible Fixed Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Removable' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Contain '\\?\Volume{00000000-0000-0000-0000-000000000003}\'
                }

                It 'Should Include F: In The List of Eligible Removable Volumes' {
                    (Get-AutoBitlockerStatus -DriveType 'Removable' -PrimaryProtector RecoveryPasswordProtector).Keys  | Should -Contain 'F:'
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}

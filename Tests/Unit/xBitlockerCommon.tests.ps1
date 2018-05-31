<#
    .SYNOPSIS
        Template for creating DSC Resource Unit Tests
    .DESCRIPTION
        To Use:
        1. Copy to \Tests\Unit\ folder and rename <ResourceName>.tests.ps1 (e.g. MSFT_xFirewall.tests.ps1)
        2. Customize TODO sections.
        3. Delete all template comments (TODOs, etc.)

    .NOTES
        There are multiple methods for writing unit tests. This template provides a few examples
        which you are welcome to follow but depending on your resource, you may want to
        design it differently. Read through our TestsGuidelines.md file for an intro on how to
        write unit tests for DSC resources: https://github.com/PowerShell/DscResources/blob/master/TestsGuidelines.md
#>

#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

# TODO: Insert the correct <ModuleName> and <ResourceName> for your resource
#$TestEnvironment = Initialize-TestEnvironment `
#    -DSCModuleName 'xBitlocker' `
#    -DSCResourceName 'xBitlockerCommon' `
#    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
    Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Misc' -ChildPath 'xBitlockerCommon.psm1')) -Force
}

function Invoke-TestCleanup {
#    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    # TODO: Other Optional Cleanup Code Goes Here...
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope "xBitlockerCommon" {

        function Get-BitlockerVolume {
        }
        # TODO: Optionally create any variables here for use by your tests

        # TODO: Complete the Describe blocks below and add more as needed.
        # The most common method for unit testing is to test by function. For more information
        # check out this introduction to writing unit tests in Pester:
        # https://www.simple-talk.com/sysadmin/powershell/practical-powershell-unit-testing-getting-started/#eleventh
        # You may also follow one of the patterns provided in the TestsGuidelines.md file:
        # https://github.com/PowerShell/DscResources/blob/master/TestsGuidelines.md

        Describe "xBitlockerCommon\TestBitlocker" {
            BeforeEach {
                # per-test-initialization
            }

            AfterEach {
                # per-test-cleanup
            }

            Context 'When OS Volume is not Encrypted and No Key Protectors Assigned' {
                Mock `
                    -CommandName Get-BitlockerVolume `
                    -ModuleName 'xBitlockerCommon' `
                    -MockWith {
                        param (
                            [string]
                            $MountPoint
                        )
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

                BeforeEach {
                    # per-test-initialization
                }

                AfterEach {
                    # per-test-cleanup
                }

                It 'Should Fail The Test (TPM and RecoveryPassword Protectors)' {
                    TestBitlocker -MountPoint 'C:' -PrimaryProtector 'TPMProtector' -RecoveryPasswordProtector $true | Should -Be $false
                }
            }

            Context 'When OS Volume is Encrypted using TPM and Recovery Password Protectors' {
                Mock -CommandName Get-BitlockerVolume -ModuleName 'xBitlockerCommon' -MockWith {
                            # Encrypted with TPM and Recovery Password Key Protectors
                            param (
                                [string]
                                $MountPoint
                            )
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
                            param (
                                [string]
                                $MountPoint
                            )
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
#    Invoke-TestCleanup
}

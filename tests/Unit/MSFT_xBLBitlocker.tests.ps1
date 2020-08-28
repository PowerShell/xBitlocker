#region HEADER
$script:dscModuleName = 'xBitlocker'
$script:dscResourceName = 'MSFT_xBLBitlocker'

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
        # Override helper functions
        function Assert-HasPrereqsForBitlocker {}

        # Setup common test variables
        $testMountPoint       = 'C:'
        $testPrimaryProtector = 'TpmProtector'

        # Setup common Mocks
        Mock -CommandName Assert-HasPrereqsForBitlocker -Verifiable

        Describe 'MSFT_xBLBitlocker\Get-TargetResource' -Tag 'Get' {
            AfterEach {
                Assert-VerifiableMock
            }

            Context 'When Get-TargetResource is called' {
                It 'Should return a Hashtable with the input MountPoint' {
                    $getResult = Get-TargetResource -MountPoint $testMountPoint -PrimaryProtector $testPrimaryProtector
                    $getResult | Should -Be -Not $null
                    $getResult.MountPoint | Should -Be $testMountPoint

                }
            }
        }

        Describe 'MSFT_xBLBitlocker\Set-TargetResource' -Tag 'Set' {
            AfterEach {
                Assert-VerifiableMock
            }

            Context 'When Set-TargetResource is called' {
                It 'Should call Enable-BitlockerInternal' {
                    Mock -CommandName Enable-BitlockerInternal -Verifiable

                    Set-TargetResource -MountPoint $testMountPoint -PrimaryProtector $testPrimaryProtector
                }
            }
        }

        Describe 'MSFT_xBLBitlocker\Test-TargetResource' -Tag 'Test' {
            AfterEach {
                Assert-VerifiableMock
            }

            Context 'When Test-BitlockerEnabled returns True' {
                It 'Should return True' {
                    Mock -CommandName Test-BitlockerEnabled -Verifiable -MockWith { return $true }

                    Test-TargetResource -MountPoint $testMountPoint -PrimaryProtector $testPrimaryProtector | Should -Be $true
                }
            }

            Context 'When Test-BitlockerEnabled returns False' {
                It 'Should return False' {
                    Mock -CommandName Test-BitlockerEnabled -Verifiable -MockWith { return $false }

                    Test-TargetResource -MountPoint $testMountPoint -PrimaryProtector $testPrimaryProtector | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}

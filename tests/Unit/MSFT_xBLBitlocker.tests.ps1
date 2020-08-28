#region HEADER
$script:DSCModuleName = 'xBitlocker'
$script:DSCResourceName = 'MSFT_xBLBitlocker'

# Unit Test Template Version: 1.2.4
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -ResourceType 'Mof' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{

}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
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

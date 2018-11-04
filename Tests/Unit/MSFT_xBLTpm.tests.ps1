#region HEADER
$script:DSCModuleName = 'xBitlocker'
$script:DSCResourceName = 'MSFT_xBLTpm'

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
        function CheckForPreReqs {}

        # Override Bitlocker functions
        function Get-Tpm {}
        function Initialize-Tpm {}

        $testTpmName = 'TPMName'

        Describe 'MSFT_xBLTpm\Get-TargetResource' -Tag 'Get' {
            AfterEach {
                Assert-VerifiableMock
            }

            Mock -CommandName Import-Module -Verifiable
            Mock -CommandName CheckForPreReqs -Verifiable

            Context 'When Get-TargetResource is called, CheckForPrereqs succeeds, and Get-Tpm returns a value' {
                Mock -CommandName Get-Tpm -Verifiable -MockWith { return 'NotNull' }

                It 'Should return a Hashtable with the input resource Identity' {
                    $getResult = Get-TargetResource -Identity $testTpmName
                    $getResult | Should -Be -Not $null
                    $getResult.Identity | Should -Be $testTpmName

                }
            }
        }

        Describe 'MSFT_xBLTpm\Set-TargetResource' -Tag 'Set' {
            AfterEach {
                Assert-VerifiableMock
            }

            Mock -CommandName Import-Module -Verifiable
            Mock -CommandName CheckForPreReqs -Verifiable

            Context 'When Set-TargetResource is called, CheckForPrereqs succeeds, and a restart is required' {
                Mock -CommandName Initialize-Tpm -Verifiable -MockWith {
                    return @{
                        RestartRequired = $true
                    }
                }
                Mock -CommandName Start-Sleep -Verifiable
                Mock -CommandName Restart-Computer -Verifiable

                It 'Should attempt to force a restart of the computer' {
                    Set-TargetResource -Identity $testTpmName -AllowImmediateReboot $true
                }
            }

            Context 'When Set-TargetResource is called and Initialize-Tpm returns null' {
                Mock -CommandName Initialize-Tpm -Verifiable

                It 'Should throw an exception' {
                    { Set-TargetResource -Identity $testTpmName } | Should -Throw -ExpectedMessage 'Failed to initialize TPM'
                }
            }
        }

        Describe 'MSFT_xBLTpm\Test-TargetResource' -Tag 'Test' {
            AfterEach {
                Assert-VerifiableMock
            }

            Mock -CommandName Import-Module -Verifiable
            Mock -CommandName CheckForPreReqs -Verifiable

            Context 'When Test-TargetResource is called, CheckForPrereqs succeeds, Get-Tpm returns a value, and TpmReady is True' {
                Mock -CommandName Get-Tpm -Verifiable -MockWith {
                    return @{
                        TpmReady = $true
                    }
                }

                It 'Should return True' {
                    Test-TargetResource -Identity $testTpmName | Should -Be $true
                }
            }

            Context 'When Test-TargetResource is called, CheckForPrereqs succeeds, Get-Tpm returns a value, and TpmReady is False' {
                Mock -CommandName Get-Tpm -Verifiable -MockWith {
                    return @{
                        TpmReady = $false
                    }
                }

                It 'Should return True' {
                    Test-TargetResource -Identity $testTpmName | Should -Be $False
                }
            }

            Context 'When Test-TargetResource is called, CheckForPrereqs succeeds, and Get-Tpm returns null' {
                Mock -CommandName Get-Tpm -Verifiable
                Mock -CommandName Write-Error -Verifiable

                It 'Should return False and write an error' {
                    Test-TargetResource -Identity $testTpmName | Should -Be $False
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
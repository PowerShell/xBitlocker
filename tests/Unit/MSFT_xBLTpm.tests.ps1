#region HEADER
$script:dscModuleName = 'xBitlocker'
$script:dscResourceName = 'MSFT_xBLTpm'

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

        # Override Bitlocker functions
        function Get-Tpm {}
        function Initialize-Tpm {}

        $testTpmName = 'TPMName'

        Describe 'MSFT_xBLTpm\Get-TargetResource' -Tag 'Get' {
            AfterEach {
                Assert-VerifiableMock
            }

            Mock -CommandName Import-Module -Verifiable
            Mock -CommandName Assert-HasPrereqsForBitlocker -Verifiable

            Context 'When Get-TargetResource is called, Assert-HasPrereqsForBitlocker succeeds, and Get-Tpm returns a value' {
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
            Mock -CommandName Assert-HasPrereqsForBitlocker -Verifiable

            Context 'When Set-TargetResource is called, Assert-HasPrereqsForBitlocker succeeds, and a restart is required' {
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
            Mock -CommandName Assert-HasPrereqsForBitlocker -Verifiable

            Context 'When Test-TargetResource is called, Assert-HasPrereqsForBitlocker succeeds, Get-Tpm returns a value, and TpmReady is True' {
                Mock -CommandName Get-Tpm -Verifiable -MockWith {
                    return @{
                        TpmReady = $true
                    }
                }

                It 'Should return True' {
                    Test-TargetResource -Identity $testTpmName | Should -Be $true
                }
            }

            Context 'When Test-TargetResource is called, Assert-HasPrereqsForBitlocker succeeds, Get-Tpm returns a value, and TpmReady is False' {
                Mock -CommandName Get-Tpm -Verifiable -MockWith {
                    return @{
                        TpmReady = $false
                    }
                }

                It 'Should return True' {
                    Test-TargetResource -Identity $testTpmName | Should -Be $False
                }
            }

            Context 'When Test-TargetResource is called, Assert-HasPrereqsForBitlocker succeeds, and Get-Tpm returns null' {
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

$script:dscModuleName = 'xBitlocker'
$script:dscResourceFriendlyName = 'xBLBitlocker'
$script:dscResourceName = "MSFT_$($script:dscResourceFriendlyName)"

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
    -TestType 'Integration'

# Import xBitlocker Test Helper Module
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath (Join-Path -Path '..' -ChildPath (Join-Path -Path 'TestHelpers' -ChildPath 'xBitlockerTestHelper.psm1'))) -Force

# Make sure the TPM is present before running tests
if (!(Test-HasPresentTpm))
{
    return
}

# Make sure required features are installed before running tests
if (!(Test-RequiredFeaturesInstalled))
{
    return
}

# Using try/finally to always cleanup.
try
{
    #region Integration Tests
    $configurationFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configurationFile

    Describe "$($script:dscResourceName)_Integration" {
        $configurationNames = @(
            "$($script:dscResourceName)_BasicTPMEncryptionOnSysDrive_Config"
            "$($script:dscResourceName)_TPMEncryptionOnSysDriveWithFalseSwitchParams_Config"
        )

        foreach ($configurationName in $configurationNames)
        {
            Context ('When using configuration {0}' -f $configurationName) {
                BeforeAll {
                    Disable-BitLockerOnTestDrive -MountPoint $env:SystemDrive
                }

                It 'Should compile and apply the MOF without throwing' {
                    {
                        $configurationParameters = @{
                            OutputPath           = $TestDrive
                            ConfigurationData    = $ConfigurationData
                        }

                        & $configurationName @configurationParameters

                        $startDscConfigurationParameters = @{
                            Path         = $TestDrive
                            ComputerName = 'localhost'
                            Wait         = $true
                            Verbose      = $true
                            Force        = $true
                            ErrorAction  = 'Stop'
                        }

                        Start-DscConfiguration @startDscConfigurationParameters
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    {
                        $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    (Get-BitlockerVolume -MountPoint $env:SystemDrive).KeyProtector[0].KeyProtectorType | Should -Be 'Tpm'
                }

                It 'Should return $true when Test-DscConfiguration is run' {
                    Test-DscConfiguration -Verbose | Should -Be $true
                }
            }
        }
    }
    #endregion

}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}

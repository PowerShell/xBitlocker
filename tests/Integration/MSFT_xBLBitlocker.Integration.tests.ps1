$script:dscModuleName = 'xBitlocker'
$script:dscResourceFriendlyName = 'xBLBitlocker'
$script:dcsResourceName = "MSFT_$($script:dscResourceFriendlyName)"

#region HEADER
# Integration Test Template Version: 1.3.1
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dcsResourceName `
    -TestType Integration

# Import xBitlocker Test Helper Module
Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Tests' -ChildPath (Join-Path -Path 'TestHelpers' -ChildPath 'xBitlockerTestHelper.psm1'))) -Force
#endregion

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
    $configurationFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dcsResourceName).config.ps1"
    . $configurationFile

    Describe "$($script:dcsResourceName)_Integration" {
        $configurationNames = @(
            "$($script:dcsResourceName)_BasicTPMEncryptionOnSysDrive_Config"
            "$($script:dcsResourceName)_TPMEncryptionOnSysDriveWithFalseSwitchParams_Config"
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

#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName        = 'localhost'
            }
        )
    }
}

<#
    .SYNOPSIS
        Initializes a TPM chip on the test machine
#>
Configuration MSFT_xBLTpm_BasicTPMInitialization_Config
{
    Import-DscResource -ModuleName 'xBitlocker'

    Node $AllNodes.NodeName
    {
        xBLTpm Integration_Test
        {
            Identity = 'TPMTest'
        }
    }
}

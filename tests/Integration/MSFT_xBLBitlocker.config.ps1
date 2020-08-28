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
        Enables Bitlocker on the Operating System drive using a TpmProtector.
#>
Configuration MSFT_xBLBitlocker_BasicTPMEncryptionOnSysDrive_Config
{
    Import-DscResource -ModuleName 'xBitlocker'

    Node $AllNodes.NodeName
    {
        xBLBitlocker Integration_Test
        {
            MountPoint       = $env:SystemDrive
            PrimaryProtector = 'TpmProtector'
            UsedSpaceOnly    = $true
        }
    }
}

<#
    .SYNOPSIS
        Enables Bitlocker on the Operating System drive using a TpmProtector
        and passed multiple Switch parameters of Enable-Bitlocker with False
        values.
#>
Configuration MSFT_xBLBitlocker_TPMEncryptionOnSysDriveWithFalseSwitchParams_Config
{
    Import-DscResource -ModuleName 'xBitlocker'

    Node $AllNodes.NodeName
    {
        xBLBitlocker Integration_Test
        {
            MountPoint         = $env:SystemDrive
            PrimaryProtector   = 'TpmProtector'
            HardwareEncryption = $false
            UsedSpaceOnly      = $false
        }
    }
}

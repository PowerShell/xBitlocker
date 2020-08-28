[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

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
                NodeName                    = 'localhost'
                PsDscAllowPlainTextPassword = $true
            }
        )
    }
}

<#
    .SYNOPSIS
        Enables Bitlocker on Fixed drives using a PasswordProtector
#>
Configuration MSFT_xBLAutoBitlocker_EnablePasswordProtectorOnDataDrives_Config
{
    Import-DscResource -ModuleName 'xBitlocker'

    Node $AllNodes.NodeName
    {
        xBLAutoBitlocker Integration_Test
        {
            DriveType        = 'Fixed'
            PrimaryProtector = 'PasswordProtector'
            Password         = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'AutoBitlocker', (ConvertTo-SecureString 'Password1' -AsPlainText -Force)
            UsedSpaceOnly    = $true
        }
    }
}

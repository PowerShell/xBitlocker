<#
.SYNOPSIS
   Resource that waits for a drive to get encrypted before proceeding. Follows the Wait-For pattern.
.DESCRIPTION
.NOTES
#>

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $MountPoint,

        [Parameter()]
        [System.UInt32]
        $RetryIntervalSeconds = 60,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 30
    )

    # Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    $status = Get-BitLockerVolume -MountPoint $MountPoint

    if ($status -ne $null)
    {
        $returnValue = @{
            Write-Verbose "Status for drive available."
            Status = "$($MountPoint) drive ProtectionStatus is $($status.ProtectionStatus)."
        }
    }
    else
    {
        $returnValue = @{
            Write-Verbose "Status for drive unavailable."
            Status = "No information could be retrieved for specified drive."
        }
    }

    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $MountPoint,

        [Parameter()]
        [System.UInt32]
        $RetryIntervalSeconds = 60,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 30
    )

    # Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    $encrypted = Test-Status($MountPoint)

    if (-not $encrypted)
    {
        Write-Verbose "Not yet fully encrypted. About to start waiting loop."
        for($count = 0; $count -lt $RetryCount; $count++)
        {
            if (IsFully-Encrypted($MountPoint))
            {
                Write-Verbose "Drive encryption complete. Exiting."
                break
            }
            else
            {
                Write-Verbose "Still encrypting..."
                Start-Sleep $RetryIntervalSeconds
            }
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $MountPoint,

        [Parameter()]
        [System.UInt32]
        $RetryIntervalSeconds = 60,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 30
    )

    # Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    Write-Verbose "About to check the status for drive."
    return Test-Status($MountPoint)
}

function Test-Status([Parameter()][string] $unit)
{
    $encrypted = $true

    $status = Get-BitLockerVolume -MountPoint $unit

    if ($status.EncryptionPercentage -ne 100)
    {
        $encrypted = $false
    }
    elseif ($status -eq $null)
    {
        throw "Unit $($unit) is not a logical drive."
    }

    return $encrypted
}

function IsFully-Encrypted([Parameter()][string]$unit)
{
    $status = Get-BitLockerVolume -MountPoint $unit

    if ($status.EncryptionPercentage -eq 100)
    {
        return $true
    }

    return $false
}

Export-ModuleMember -Function *-TargetResource

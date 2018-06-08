function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $MountPoint,

        [System.UInt32]
        $RetryIntervalSeconds = 60,

        [System.UInt32]
        $RetryCount = 30
    )

    #Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    $status = Get-BitLockerVolume

    if ($status -ne $null)
    {
        $returnValue = @{
            Status = $status.ProtectionStatus
        }
    }

    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $MountPoint,

        [System.UInt32]
        $RetryIntervalSeconds = 60,

        [System.UInt32]
        $RetryCount = 30
    )

    #Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    #$PSBoundParameters.Remove("Identity") | Out-Null

    $encrypted = TestStatus($MountPoint)

    if (-not $encrypted)
    {
        for($count = 0; $count -lt $RetryCount; $count++)
        {
            if (IsFullyEncrypted($MountPoint))
            {
                break
            }
            else {
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
        [parameter(Mandatory = $true)]
        [System.String]
        $MountPoint,

        [System.UInt32]
        $RetryIntervalSeconds = 60,

        [System.UInt32]
        $RetryCount = 30
    )

    #Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    return TestStatus($MountPoint)
}

function TestStatus([string] $unit)
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

function IsFullyEncrypted([string]$unit)
{
    $status = Get-BitLockerVolume -MountPoint $unit

    if ($status.EncryptionPercentage -eq 100)
    {
        return $true
    }

    return $false
}

Export-ModuleMember -Function *-TargetResource
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Identity
    )

    #Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    $status = Get-BitLockerVolume

    if ($status -ne $null)
    {
        $returnValue = @{
            Identity = $Identity
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
        $Identity,

        [parameter(Mandatory = $true)]
        [System.String]
        $LogicalUnit,

        [System.UInt32]
        $RetryIntervalSec = 60,

        [System.UInt32]
        $RetryCount = 30
    )

    #Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    $PSBoundParameters.Remove("Identity") | Out-Null

    $encrypted = TestStatus($LogicalUnit)

    if (-not $encrypted)
    {
        for($count = 0; $count -lt $RetryCount; $count++)
        {
            if (IsFullyEncrypted($LogicalUnit))
            {
                break
            }
            else {
                Start-Sleep $RetryIntervalSec
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
        $Identity,

        [parameter(Mandatory = $true)]
        [System.String]
        $LogicalUnit
    )

    #Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    return TestStatus($LogicalUnit)
}

function TestStatus([string] $Unit)
{
    $encrypted = $true

    $status = Get-BitLockerVolume -MountPoint "$($Unit):"

    if (($status.ProtectionStatus -eq "On") -and ($status.EncryptionPercentage -ne 100))
    {
        $encrypted = $false
    }
    elseif ($status -eq $null)
    {
        throw "Unit $($Unit) is not a logical drive."
    }

    return $encrypted
}

function IsFullyEncrypted([string]$unit)
{
    $status = Get-BitLockerVolume -MountPoint "$($unit):"

    if ($status.EncryptionPercentage -eq 100)
    {
        return $true
    }

    return $false
}

Export-ModuleMember -Function *-TargetResource

function Get-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Identity
    )

    #Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    $tpm = Get-Tpm

    if ($null -ne $tpm)
    {
        $returnValue = @{
            Identity = $Identity
        }
    }

    $returnValue
}


function Set-TargetResource
{
    # Suppressing this rule because $global:DSCMachineStatus is used to trigger a reboot.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function', Target='DSCMachineStatus')]
    <#
        Suppressing this rule because $global:DSCMachineStatus is only set,
        never used (by design of Desired State Configuration).
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Scope='Function', Target='DSCMachineStatus')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [CmdletBinding()]
    param
    ([Parameter(
        [parameter(Mandatory = $true)]
        [System.String]
        $Identity,

        [System.Boolean]
        $AllowClear,

        [System.Boolean]
        $AllowPhysicalPresence,

        [System.Boolean]
        $AllowImmediateReboot = $false
    )

    #Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    $PSBoundParameters.Remove("Identity") | Out-Null
    $PSBoundParameters.Remove("AllowImmediateReboot") | Out-Null

    $tpm = Initialize-Tpm @PSBoundParameters

    if ($null -ne $tpm)
    {
        if ($tpm.RestartRequired -eq $true)
        {
            $global:DSCMachineStatus = 1

            if ($AllowImmediateReboot -eq $true)
            {
                Write-Verbose "Forcing an immediate reboot of the computer in 30 seconds"

                Start-Sleep -Seconds 30
                Restart-Computer -Force
            }
        }
    }
    else
    {
        throw "Failed to initialize TPM"
    }
}


function Test-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    para[Parameter(
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Identity,

        [System.Boolean]
        $AllowClear,

        [System.Boolean]
        $AllowPhysicalPresence,

        [System.Boolean]
        $AllowImmediateReboot = $false
    )

    #Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    $tpm = Get-Tpm

    if ($null -eq $tpm)
    {
        return $false
    }
    else
    {
        return $tpm.TpmReady
    }
}


Export-ModuleMember -Function *-TargetResource



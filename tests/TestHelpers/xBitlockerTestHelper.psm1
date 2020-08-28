<#
    .SYNOPSIS
        Checks whether the appropriate features are installed to be able to
        test Bitlocker.
#>
function Test-RequiredFeaturesInstalled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param()

    $featuresInstalled = $true

    if ((Get-WindowsFeature -Name 'BitLocker').InstallState -ne 'Installed' -or
        (Get-WindowsFeature -Name 'RSAT-Feature-Tools-BitLocker').InstallState -ne 'Installed' -or
        (Get-WindowsFeature -Name 'RSAT-Feature-Tools-BitLocker-RemoteAdminTool').InstallState -ne 'Installed')
    {
        Write-Warning -Message 'One or more of the following Windows Features are not installed: BitLocker, RSAT-Feature-Tools-BitLocker, RSAT-Feature-Tools-BitLocker-RemoteAdminTool. Skipping Integration tests.'
        $featuresInstalled = $false
    }

    return $featuresInstalled
}

<#
    .SYNOPSIS
        Checks whether the system has a TPM chip.
#>
function Test-HasPresentTpm
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param()

    $hasReadyTpm = $true

    if ($null -eq (Get-Command -Name Get-Tpm -ErrorAction SilentlyContinue) -or !((Get-Tpm).TpmPresent))
    {
        Write-Warning -Message 'No TPM is present on test machine. Skipping Integration tests.'
        $hasReadyTpm = $false
    }

    return $hasReadyTpm
}

<#
    .SYNOPSIS
        Disables BitLocker on a test drive, if Enabled

    .PARAMETER MountPoint
        The MountPoint to disable BitLocker on
#>
function Disable-BitLockerOnTestDrive
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.String]
        $MountPoint
    )

    $blv = Get-BitLockerVolume -MountPoint $MountPoint

    if ($blv.KeyProtector.Count -gt 0 -or $blv.ProtectionStatus -ne 'Off')
    {
        Disable-BitLocker -MountPoint $blv
    }
}

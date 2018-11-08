function Get-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Fixed","Removable")]
        [System.String]
        $DriveType,

        [Parameter()]
        [System.Int32]
        $MinDiskCapacityGB,

        [Parameter(Mandatory = $true)]
        [ValidateSet("PasswordProtector","RecoveryPasswordProtector","StartupKeyProtector","TpmProtector")]
        [System.String]
        $PrimaryProtector,

        [Parameter()]
        [System.String]
        $AdAccountOrGroup,

        [Parameter()]
        [System.Boolean]
        $AdAccountOrGroupProtector,

        [Parameter()]
        [System.Boolean]
        $AutoUnlock = $false,

        [Parameter()]
        [ValidateSet("Aes128","Aes256")]
        [System.String]
        $EncryptionMethod,

        [Parameter()]
        [System.Boolean]
        $HardwareEncryption,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Password,

        [Parameter()]
        [System.Boolean]
        $PasswordProtector,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Pin,

        [Parameter()]
        [System.String]
        $RecoveryKeyPath,

        [Parameter()]
        [System.Boolean]
        $RecoveryKeyProtector,

        [Parameter()]
        [System.Boolean]
        $RecoveryPasswordProtector,

        [Parameter()]
        [System.Boolean]
        $Service,

        [Parameter()]
        [System.Boolean]
        $SkipHardwareTest,

        [Parameter()]
        [System.String]
        $StartupKeyPath,

        [Parameter()]
        [System.Boolean]
        $StartupKeyProtector,

        [Parameter()]
        [System.Boolean]
        $TpmProtector,

        [Parameter()]
        [System.Boolean]
        $UsedSpaceOnly
    )

    #Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    $returnValue = @{
        DriveType = $DriveType
    }

    $returnValue
}

function Set-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Fixed","Removable")]
        [System.String]
        $DriveType,

        [Parameter()]
        [System.Int32]
        $MinDiskCapacityGB,

        [Parameter(Mandatory = $true)]
        [ValidateSet("PasswordProtector","RecoveryPasswordProtector","StartupKeyProtector","TpmProtector")]
        [System.String]
        $PrimaryProtector,

        [Parameter()]
        [System.String]
        $AdAccountOrGroup,

        [Parameter()]
        [System.Boolean]
        $AdAccountOrGroupProtector,

        [Parameter()]
        [System.Boolean]
        $AutoUnlock = $false,

        [Parameter()]
        [ValidateSet("Aes128","Aes256")]
        [System.String]
        $EncryptionMethod,

        [Parameter()]
        [System.Boolean]
        $HardwareEncryption,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Password,

        [Parameter()]
        [System.Boolean]
        $PasswordProtector,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Pin,

        [Parameter()]
        [System.String]
        $RecoveryKeyPath,

        [Parameter()]
        [System.Boolean]
        $RecoveryKeyProtector,

        [Parameter()]
        [System.Boolean]
        $RecoveryPasswordProtector,

        [Parameter()]
        [System.Boolean]
        $Service,

        [Parameter()]
        [System.Boolean]
        $SkipHardwareTest,

        [Parameter()]
        [System.String]
        $StartupKeyPath,

        [Parameter()]
        [System.Boolean]
        $StartupKeyProtector,

        [Parameter()]
        [System.Boolean]
        $TpmProtector,

        [Parameter()]
        [System.Boolean]
        $UsedSpaceOnly
    )

    #Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    $autoBlVols = GetAutoBitlockerStatus @PSBoundParameters

    if ($null -eq $autoBlVols)
    {
        throw 'No Auto Bitlocker volumes were found'
    }
    else
    {
        RemoveParameters -PSBoundParametersIn $PSBoundParameters -ParamsToRemove "DriveType","MinDiskCapacityGB"
        AddParameters -PSBoundParametersIn $PSBoundParameters -ParamsToAdd @{"MountPoint" = ""}

        #Loop through each potential AutoBitlocker volume, see whether they are enabled for Bitlocker, and if not, enable it
        foreach ($key in $autoBlVols.Keys)
        {
            $PSBoundParameters["MountPoint"] = $key

            $testResult = TestBitlocker @PSBoundParameters

            if ($testResult -eq $false)
            {
                EnableBitlocker @PSBoundParameters -VerbosePreference $VerbosePreference
            }
        }
    }
}

function Test-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Fixed","Removable")]
        [System.String]
        $DriveType,

        [Parameter()]
        [System.Int32]
        $MinDiskCapacityGB,

        [Parameter(Mandatory = $true)]
        [ValidateSet("PasswordProtector","RecoveryPasswordProtector","StartupKeyProtector","TpmProtector")]
        [System.String]
        $PrimaryProtector,

        [Parameter()]
        [System.String]
        $AdAccountOrGroup,

        [Parameter()]
        [System.Boolean]
        $AdAccountOrGroupProtector,

        [Parameter()]
        [System.Boolean]
        $AutoUnlock = $false,

        [Parameter()]
        [ValidateSet("Aes128","Aes256")]
        [System.String]
        $EncryptionMethod,

        [Parameter()]
        [System.Boolean]
        $HardwareEncryption,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Password,

        [Parameter()]
        [System.Boolean]
        $PasswordProtector,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Pin,

        [Parameter()]
        [System.String]
        $RecoveryKeyPath,

        [Parameter()]
        [System.Boolean]
        $RecoveryKeyProtector,

        [Parameter()]
        [System.Boolean]
        $RecoveryPasswordProtector,

        [Parameter()]
        [System.Boolean]
        $Service,

        [Parameter()]
        [System.Boolean]
        $SkipHardwareTest,

        [Parameter()]
        [System.String]
        $StartupKeyPath,

        [Parameter()]
        [System.Boolean]
        $StartupKeyProtector,

        [Parameter()]
        [System.Boolean]
        $TpmProtector,

        [Parameter()]
        [System.Boolean]
        $UsedSpaceOnly
    )

    #Load helper module
    Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\xBitlockerCommon.psm1" -Verbose:0

    CheckForPreReqs

    $autoBlVols = GetAutoBitlockerStatus @PSBoundParameters

    $allEnabled = $true

    if ($null -eq $autoBlVols)
    {
        Write-Error -Message 'Failed to retrieve Bitlocker status'

        $allEnabled = $false
    }
    else
    {
        RemoveParameters -PSBoundParametersIn $PSBoundParameters -ParamsToRemove "DriveType","MinDiskCapacityGB"
        AddParameters -PSBoundParametersIn $PSBoundParameters -ParamsToAdd @{"MountPoint" = ""}

        #Check whether any potential AutoBitlocker volume is not currently enabled for Bitlocker, or doesn't have the correct settings
        foreach ($key in $autoBlVols.Keys)
        {
            $PSBoundParameters["MountPoint"] = $key

            $testResult = TestBitlocker @PSBoundParameters -VerbosePreference $VerbosePreference

            if ($testResult -eq $false)
            {
                Write-Verbose -Message "Volume with Key '$key' is not yet enabled for Bitlocker"

                $allEnabled = $false
            }
        }
    }

    return $allEnabled
}

function GetAutoBitlockerStatus
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Fixed","Removable")]
        [System.String]
        $DriveType,

        [Parameter()]
        [System.Int32]
        $MinDiskCapacityGB,

        [Parameter(Mandatory = $true)]
        [ValidateSet("PasswordProtector","RecoveryPasswordProtector","StartupKeyProtector","TpmProtector")]
        [System.String]
        $PrimaryProtector,

        [Parameter()]
        [System.String]
        $AdAccountOrGroup,

        [Parameter()]
        [System.Boolean]
        $AdAccountOrGroupProtector,

        [Parameter()]
        [System.Boolean]
        $AutoUnlock = $false,

        [Parameter()]
        [ValidateSet("Aes128","Aes256")]
        [System.String]
        $EncryptionMethod,

        [Parameter()]
        [System.Boolean]
        $HardwareEncryption,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Password,

        [Parameter()]
        [System.Boolean]
        $PasswordProtector,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Pin,

        [Parameter()]
        [System.String]
        $RecoveryKeyPath,

        [Parameter()]
        [System.Boolean]
        $RecoveryKeyProtector,

        [Parameter()]
        [System.Boolean]
        $RecoveryPasswordProtector,

        [Parameter()]
        [System.Boolean]
        $Service,

        [Parameter()]
        [System.Boolean]
        $SkipHardwareTest,

        [Parameter()]
        [System.String]
        $StartupKeyPath,

        [Parameter()]
        [System.Boolean]
        $StartupKeyProtector,

        [Parameter()]
        [System.Boolean]
        $TpmProtector,

        [Parameter()]
        [System.Boolean]
        $UsedSpaceOnly
    )

    #First get all Bitlocker Volumes of type Data
    $allBlvs = Get-BitLockerVolume | Where-Object -FilterScript {$_.VolumeType -eq 'Data'}

    #Filter on size if it was specified
    if ($PSBoundParameters.ContainsKey("MinDiskCapacityGB"))
    {
        $allBlvs = $allBlvs | Where-Object -FilterScript {$_.CapacityGB -ge $MinDiskCapacityGB}
    }

    #Now find disks of the appropriate drive type, and add them to the collection
    if ($null -ne $allBlvs)
    {
        [Hashtable]$returnValue = @{}

        # Convert DriveType into values returned by Win32_EncryptableVolume.VolumeType
        switch ($DriveType)
        {
            'Fixed'
            {
                $driveTypeValue = 1
            }
            'Removable'
            {
                $driveTypeValue = 2
            }
        }

        foreach ($blv in $allBlvs)
        {
            $vol = $null

            $encryptableVolumes = Get-CimInstance -Namespace 'root\cimv2\security\microsoftvolumeencryption' -Class Win32_Encryptablevolume -ErrorAction SilentlyContinue

            if (Split-Path -Path $blv.MountPoint -IsAbsolute)
            {
                # MountPoint is a Drive Letter
                $vol = $encryptableVolumes | Where-Object {($_.DriveLetter -eq $blv.Mountpoint) -and ($_.VolumeType -eq $driveTypeValue)}
            }
            else
            {
                # MountPoint is a path
                $vol = $encryptableVolumes | Where-Object {($_.DeviceID -eq $blv.Mountpoint) -and ($_.VolumeType -eq $driveTypeValue)}
            }

            if ($null -ne $vol)
            {
                [Hashtable]$props = @{
                    VolumeStatus = $blv.VolumeStatus
                    KeyProtectors = $blv.KeyProtector
                    EncryptionMethod = $blv.EncryptionMethod
                }

                $returnValue.Add($blv.MountPoint, $props)
            }
        }
    }

    $returnValue
}

Export-ModuleMember -Function *-TargetResource

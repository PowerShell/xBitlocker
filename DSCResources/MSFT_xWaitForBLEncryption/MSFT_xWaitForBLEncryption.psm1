[DscResource()]
class WaitForBLEncryption {

    [DscProperty(Key, Mandatory)]
    [string] $LogicalUnit

    [UInt64]$RetryIntervalSec = 60

    [UInt32]$RetryCount = 30

    [DscProperty(NotConfigurable)]
    [string] $LogicalUnitState

    <#
        This method is equivalent of the Set-TargetResource script function.
        It sets the resource to the desired state.
    #>
    [void] Set()
    {
        $encrypted = $this.TestStatus($this.LogicalUnit)

        if (-not $encrypted)
        {
            for($count = 0; $count -lt $this.RetryCount; $count++)
            {
                if ($this.IsFullyEncrypted($this.LogicalUnit))
                {
                    break
                }
                else {
                    Start-Sleep $this.RetryIntervalSec
                }
            }
        }
    }

    [bool] Test()
    {
        return $this.TestStatus($this.LogicalUnit)
    }

    [WaitForBLEncryption] Get()
    {
        $present = $this.TestStatus($this.LogicalUnit)

        if ($present)
        {
            $this.LogicalUnitState = "FullyEncrypted"
        }
        else
        {
            $this.LogicalUnitState = "Encrypting"
        }

        return $this
    }

    <#
        Helper method to check if the file exists and it is file
    #>
    [bool] TestStatus([string] $Unit)
    {
        $encrypted = $true

        $status = Get-BitLockerVolume -MountPoint "$($Unit):"

        if (($status.PSProvider.ProtectionStatus -eq "On") -and ($status.PSProvider.EncryptionPercentage -ne 100))
        {
            $encrypted = $false
        }
        elseif ($status -eq $null)
        {
            throw "Unit $($Unit) is not a logical drive."
        }

        return $encrypted
    }

    [bool] IsFullyEncrypted([string]$unit)
    {
        $status = Get-BitLockerVolume -MountPoint "$($unit):"

        if ($status.PSProvider.EncryptionPercentage -eq 100)
        {
            return $true
        }

        return $false
    }

}

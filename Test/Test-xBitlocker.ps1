[CmdletBinding()]
param()

$showVerbose = $true
$showValidSettings -eq $true

if ($null -eq $pin)
{
    $pin = Get-Credential -Message "Enter the Bitlocker Pin in the password field"
}

#Define the parameters that can be passed into individual tests
$blParams1 = @{
    MountPoint = "C:"
    PrimaryProtector = "RecoveryPasswordProtector"
    StartupKeyProtector = $true
    StartupKeyPath = "A:"
    RecoveryPasswordProtector = $true
    UsedSpaceOnly = $true
}

$blParams2 = @{
    MountPoint = "C:"
    PrimaryProtector = "StartupKeyProtector"
    StartupKeyProtector = $true
    StartupKeyPath = "A:"
    RecoveryPasswordProtector = $true
    UsedSpaceOnly = $true
}

$blParams7 = @{
    MountPoint                = 'C:'
    PrimaryProtector          = 'StartupKeyProtector'
    AdAccountOrGroupProtector = $true
    AdAccountOrGroup          = "mikelab.local\ucctest"
    StartupKeyProtector       = $true
    StartupKeyPath            = 'A:'
    RecoveryPasswordProtector = $true
    UsedSpaceOnly             = $true
}

$blParams8 = @{
    MountPoint                = 'C:'
    PrimaryProtector          = 'RecoveryPasswordProtector'
    AdAccountOrGroupProtector = $true
    AdAccountOrGroup          = "mikelab.local\ucctest"
    StartupKeyProtector       = $true
    StartupKeyPath            = 'A:'
    RecoveryPasswordProtector = $true
    UsedSpaceOnly             = $true
}

$blParams9 = @{
    MountPoint                = 'C:'
    PrimaryProtector          = 'PasswordProtector'
    StartupKeyProtector       = $true
    StartupKeyPath            = 'A:'
    PasswordProtector         = $true
    Password                  = $pin
    RecoveryPasswordProtector = $true
    UsedSpaceOnly             = $true
}

$autoBlParams1 = @{
    DriveType = "Fixed"
    MinDiskCapacityGB = 20
    PrimaryProtector = "RecoveryPasswordProtector"
    RecoveryPasswordProtector = $true
    UsedSpaceOnly = $true
}

function DisableBitlocker
{
    $blv = Get-BitLockerVolume

    foreach ($v in $blv)
    {
        if ($null -ne $v.KeyProtector -and $v.KeyProtector.Count -gt 0)
        {
            $v | Disable-BitLocker | Out-Null
        }
    }
}

#Compares two values and reports whether they are the same or not
function CheckSetting($testName, $expectedValue, $actualValue)
{
    if ($expectedValue -ne $actualValue)
    {
        Write-Error -Message "Test: '$($testName)'. Result: Fail. Expected value: '$($expectedValue)'. Actual value: '$($actualValue)'."
    }
    else
    {
        if ($showValidSettings -eq $true)
        {
            Write-Verbose -Message "Test: '$($testName)'. Result: Pass. Value: '$($expectedValue)'."
        }
    }
}

#Actually runs the specified test
function RunTest
{
    param([string]$TestName, [string[]]$ModulesToImport, [Hashtable]$Parameters)

    #Load Required Modules
    foreach ($module in $ModulesToImport)
    {
        $modulePath = "..\DSCResources\$($module)\$($module).psm1"
        Import-Module $modulePath
    }

    DisableBitlocker

    Write-Verbose "Beginning test '$($TestName)'"

    if ($showVerbose -eq $true)
    {
        Set-TargetResource @Parameters -Verbose

        $getResult = Get-TargetResource @Parameters -Verbose
        checkSetting -testName "$($TestName): Get" -expectedValue $true -actualValue ($null -ne $getResult)

        $testResult = Test-TargetResource @Parameters -Verbose
        checkSetting -testName "$($TestName): Test" -expectedValue $true -actualValue $testResult
    }
    else
    {
        Set-TargetResource @Parameters

        $getResult = Get-TargetResource @Parameters
        checkSetting -testName "$($TestName): Get" -expectedValue $true -actualValue ($null -ne $getResult)

        $testResult = Test-TargetResource @Parameters
        checkSetting -testName "$($TestName): Test" -expectedValue $true -actualValue $testResult
    }

    #Unload Required Modules
    foreach ($module in $ModulesToImport)
    {
        Remove-Module $module
    }
}

#Runs any tests that match the filter
function RunTests
{
    param([string]$Filter)

    if ("TestBitlocker" -like $Filter)
    {
        RunTest -TestName "TestBitlocker1" -ModulesToImport "MSFT_xBLBitlocker" -Parameters $blParams1
        RunTest -TestName "TestBitlocker2" -ModulesToImport "MSFT_xBLBitlocker" -Parameters $blParams2
        RunTest -TestName "TestBitlocker7" -ModulesToImport "MSFT_xBLBitlocker" -Parameters $blParams7
        RunTest -TestName "TestBitlocker8" -ModulesToImport "MSFT_xBLBitlocker" -Parameters $blParams8
        RunTest -TestName "TestBitlocker9" -ModulesToImport "MSFT_xBLBitlocker" -Parameters $blParams9
    }

    if ("TestAutoBitlocker" -like $Filter)
    {
        RunTest -TestName "TestAutoBitlocker1" -ModulesToImport "MSFT_xBLAutoBitlocker" -Parameters $autoBlParams1
    }
}

RunTests -Filter "TestBitlocker*"

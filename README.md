# xBitlocker

[![Build Status](https://dev.azure.com/dsccommunity/xBitlocker/_apis/build/status/dsccommunity.xBitlocker?branchName=master)](https://dev.azure.com/dsccommunity/xBitlocker/_build/latest?definitionId={definitionId}&branchName=master)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/xBitlocker/{definitionId}/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/xBitlocker/{definitionId}/master)](https://dsccommunity.visualstudio.com/xBitlocker/_test/analytics?definitionId={definitionId}&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/xBitlocker?label=xBitlocker%20Preview)](https://www.powershellgallery.com/packages/xBitlocker/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/xBitlocker?label=xBitlocker)](https://www.powershellgallery.com/packages/xBitlocker/)

This DSC module allows you to configure Bitlocker on a single disk, configure a
TPM chip, or automatically enable Bitlocker on multiple disks.

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Requirements

This module requires that both the **Bitlocker** and
**RSAT-Feature-Tools-Bitlocker** features are installed.
It also requires the latest version of PowerShell (v4.0, which ships in Windows
8.1 or Windows Server 2012R2).
For more information on using PowerShell 4.0 on older operating systems,
[Install WMF 4.0](https://social.technet.microsoft.com/wiki/contents/articles/21016.how-to-install-windows-powershell-4-0.aspx).

## Description

The **xBitlocker** module contains the **xBLAutoBitlocker, xBLBitlocker,
xBLTpm** DSC Resources.
This DSC Module allows you to configure Bitlocker on a single disk, configure a
TPM chip, or automatically enable Bitlocker on multiple disks.

## Resources

**xBLAutoBitlocker** is used to automatically enable Bitlocker on drives of
type Fixed or Removable.
It does not work on Operating System drives.
**xBLAutoBitlocker** has the following properties.
Where no description is listed, properties correspond directly to
[Enable-Bitlocker](https://docs.microsoft.com/en-us/powershell/module/bitlocker/enable-bitlocker)
parameters.

* DriveType: The type of volume to auto apply Bitlocker to. Valid values are
  "Fixed" or "Removable"
* PrimaryProtector: The primary protector type to be used for AutoBitlocker.
  Valid values are: "AdAccountOrGroupProtector", "PasswordProtector", "Pin",
  "RecoveryKeyProtector", "RecoveryPasswordProtector", "StartupKeyProtector",
  or "TpmProtector"
* MinDiskCapacityGB: If specified, only disks this size or greater will auto
  apply Bitlocker
* AutoUnlock: Whether volumes should be enabled for auto unlock using
  Enable-BitlockerAutoUnlock
* AdAccountOrGroup
* AdAccountOrGroupProtector
* EncryptionMethod
* HardwareEncryption
* Password
* PasswordProtector
* Pin
* RecoveryKeyPath
* RecoveryKeyProtector
* RecoveryPasswordProtector
* Service
* SkipHardwareTest
* StartupKeyPath
* StartupKeyProtector
* TpmProtector
* UsedSpaceOnly

**xBLBitlocker** has the following properties.
Where no description is listed, properties correspond directly to
[Enable-Bitlocker](https://docs.microsoft.com/en-us/powershell/module/bitlocker/enable-bitlocker)
parameters.

* MountPoint: The MountPoint name as reported in Get-BitLockerVolume
* PrimaryProtector: The primary protector type to be used for AutoBitlocker.
  Valid values are: "AdAccountOrGroupProtector", "PasswordProtector", "Pin",
  "RecoveryKeyProtector", "RecoveryPasswordProtector", "StartupKeyProtector",
  or "TpmProtector"
* AutoUnlock: Whether volumes should be enabled for auto unlock using
  Enable-BitlockerAutoUnlock
* AllowImmediateReboot: Whether the computer can be immediately rebooted after
  enabling Bitlocker on an OS drive.
  Defaults to false.

* AdAccountOrGroup
* AdAccountOrGroupProtector
* EncryptionMethod
* HardwareEncryption
* Password
* PasswordProtector
* Pin
* RecoveryKeyPath
* RecoveryKeyProtector
* RecoveryPasswordProtector
* Service
* SkipHardwareTest
* StartupKeyPath
* StartupKeyProtector
* TpmProtector
* UsedSpaceOnly

**xBLTpm** is used to initialize a TPM chip using [Initialize-TPM](https://docs.microsoft.com/en-us/powershell/module/trustedplatformmodule/initialize-tpm).
**xBLTpm** has the following properties.

* Identity: A required string value which is used as a Key for the resource.
  The value does not matter, as long as its not empty.
* AllowClear: Indicates that the provisioning process clears the TPM, if
  necessary, to move the TPM closer to complying with Windows Server 2012
  standards.
* AllowPhysicalPresence: Indicates that the provisioning process may send
  physical presence commands that require a user to be present in order to
  continue.
* AllowImmediateReboot: Whether the computer can rebooted immediately after
  initializing the TPM.

## Examples

### [ConfigureBitlockerOnOSDrive](source/Examples/ConfigureBitlockerOnOSDrive)

This example enables Bitlocker on an Operating System drive.
The example code for ConfigureBitlockerOnOSDrive is located in
[`ConfigureBitlockerOnOSDrive.ps1`](source/Examples/ConfigureBitlockerOnOSDrive/ConfigureBitlockerOnOSDrive.ps1).

### [ConfigureBitlockerAndAutoBitlocker](source/Examples/ConfigureBitlockerAndAutoBitlocker)

Enables Bitlocker on an Operating System drive, and automatically enables
Bitlocker on all drives of type 'Fixed'. The example code for
ConfigureBitlockerAndAutoBitlocker is located in
[`ConfigureBitlockerAndAutoBitlocker.ps1`](source/Examples/ConfigureBitlockerAndAutoBitlocker/ConfigureBitlockerAndAutoBitlocker.ps1).

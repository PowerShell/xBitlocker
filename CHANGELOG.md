# Change log for xBitlocker

## Unreleased

Win10_Fix_Working_Branch
- Fixed issue causing Assert-HasPrereqsForBitlocker to fail on Windows 10.
  Credit: https://github.com/goldfinger2
  ([issue #47](https://github.com/PowerShell/xBitlocker/issues/47))
=======
- Fix hashtables according to the style guideline.
dev

## 1.4.0.0

- Change double quoted string literals to single quotes
- Add spaces between array members
- Add spaces between variable types and variable names
- Add spaces between comment hashtag and comments
- Explicitly removed extra hidden files from release package

## 1.3.0.0

- Update appveyor.yml to use the default template.
- Added default template files .gitattributes, and .vscode settings.
- Fixes most PSScriptAnalyzer issues.
- Fix issue where AutoUnlock is not set if requested, if the disk was
  originally encrypted and AutoUnlock was not used.
- Add remaining Unit Tests for xBitlockerCommon.
- Add Unit tests for MSFT_xBLTpm
- Add remaining Unit Tests for xBLAutoBitlocker
- Add Unit tests for MSFT_xBLBitlocker
- Moved change log to CHANGELOG.md file
- Fixed Markdown validation warnings in README.md
- Added .MetaTestOptIn.json file to root of module
- Add Integration Tests for module resources
- Rename functions with improper Verb-Noun constructs
- Add comment based help to any functions without it
- Update Schema.mof Description fields
- Fixes issue where Switch parameters are passed to Enable-Bitlocker even if
  the corresponding DSC resource parameter was set to False (Issue #12)

## 1.2.0.0

- Converted appveyor.yml to install Pester from PSGallery instead of from
  Chocolatey.
- Added Codecov support.
- Updated appveyor.yml to use the one in template.
- Added folders for future unit and integration tests.
- Added Visual Studio Code formatting settings.
- Added .gitignore file.
- Added markdown lint rules.
- Fixed encoding on README.md.
- Added `PowerShellVersion = '4.0'`, and updated copyright information, in the
  module manifest.
- Fixed issue which caused Test to incorrectly succeed on fully decrypted
  volumes when correct Key Protectors were present
  ([issue #13](https://github.com/PowerShell/xBitlocker/issues/13))
- Fixed issue which caused xBLAutoBitlocker to incorrectly detect Fixed vs
  Removable volumes.
  ([issue #11](https://github.com/PowerShell/xBitlocker/issues/11))
- Fixed issue which made xBLAutoBitlocker unable to encrypt volumes with drive
  letters assigned.
  ([issue #10](https://github.com/PowerShell/xBitlocker/issues/10))
- Fixed an issue in CheckForPreReqs function where on Server Core the
  installation of the non existing Windows Feature
  'RSAT-Feature-Tools-BitLocker-RemoteAdminTool' was erroneously checked.
  ([issue #8](https://github.com/PowerShell/xBitlocker/issues/8))

## 1.1.0.0

- Versioning updates

## 1.0.1.1

- Reduced the number of acceptable values for PrimaryProtector in
  xBLAutoBitlocker and xBLBitlocker.
- Changed the properties that are returned by Get-TargetResource in
  xBLAutoBitlocker, xBLBitlocker, and xBLTpm.
- Fixed issue which caused protectors to be continually re-added.

## 1.0.0.0

- Initial release with the following resources
  - xBLAutoBitlocker
  - xBLBitlocker
  - xBLTpm

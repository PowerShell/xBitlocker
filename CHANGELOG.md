# Change log for xBitlocker

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Updated to a new CI/CD pipeline ([issue #54)](https://github.com/dsccommunity/xBitlocker/issues/54).

### Fixed

- Fix hashtables according to the style guideline.

## [1.4.0.0] - 2019-01-09

### Changed

- Change double quoted string literals to single quotes
- Add spaces between array members
- Add spaces between variable types and variable names
- Add spaces between comment hashtag and comments
- Explicitly removed extra hidden files from release package

## [1.3.0.0] - 2018-11-28

### Changed

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

## [1.2.0.0] - 2018-06-13

### Changed

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
  ([issue #13](https://github.com/dsccommunity/xBitlocker/issues/13))
- Fixed issue which caused xBLAutoBitlocker to incorrectly detect Fixed vs
  Removable volumes.
  ([issue #11](https://github.com/dsccommunity/xBitlocker/issues/11))
- Fixed issue which made xBLAutoBitlocker unable to encrypt volumes with drive
  letters assigned.
  ([issue #10](https://github.com/dsccommunity/xBitlocker/issues/10))
- Fixed an issue in CheckForPreReqs function where on Server Core the
  installation of the non existing Windows Feature
  'RSAT-Feature-Tools-BitLocker-RemoteAdminTool' was erroneously checked.
  ([issue #8](https://github.com/dsccommunity/xBitlocker/issues/8))

## [1.1.0.0] - 2016-02-02

### Changed

- Versioning updates

## [1.0.1.1] - 2015-04-23

### Changed

- Reduced the number of acceptable values for PrimaryProtector in
  xBLAutoBitlocker and xBLBitlocker.
- Changed the properties that are returned by Get-TargetResource in
  xBLAutoBitlocker, xBLBitlocker, and xBLTpm.
- Fixed issue which caused protectors to be continually re-added.

## [1.0.0.0] - 2015-04-15

### Changed

- Initial release with the following resources
  - xBLAutoBitlocker
  - xBLBitlocker
  - xBLTpm

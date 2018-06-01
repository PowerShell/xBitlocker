$moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Import-Module (Join-Path -Path $moduleRoot -ChildPath '\Misc\xBitlockerCommon.psm1')

InModuleScope 'xBitlockerCommon' {
    Describe 'xBitlockerCommon' {
        #Empty function so we can mock Get-WindowsFeature Cmdlet
        function Get-WindowsFeature
        {

        }

        function Get-OSEdition
        {

        }

        Context "When OS is Windows Server Core and all required features are installed" {
            Mock -CommandName Get-OSEdition -MockWith {
                'Server Core'
            }

            Mock -CommandName Get-WindowsFeature -MockWith {
                param
                (
                    [string]
                    $FeatureName
                )

                if ($FeatureName -eq 'RSAT-Feature-Tools-BitLocker-RemoteAdminTool')
                {
                    return $null
                }
                else
                {
                    return @{
                        DisplayName  = $FeatureName
                        Name         = $FeatureName
                        InstallState = 'Installed'
                    }
                }
            }

            It "Should run the CheckForPreReqs function without exceptions" {
                {CheckForPreReqs} | Should -Not -Throw
            }
        }

        Context "When OS is Full Server and all required features are installed" {
            Mock -CommandName Get-OSEdition -MockWith {
                return 'Server'
            }

            Mock -CommandName Get-WindowsFeature -MockWith {
                param
                (
                    [string]
                    $FeatureName
                )

                return @{
                    DisplayName  = $FeatureName
                    Name         = $FeatureName
                    InstallState = 'Installed'
                }
            }

            It "Should run the CheckForPreReqs function without exceptions" {
                {CheckForPreReqs} | Should -Not -Throw
            }
        }

        Context "When OS is Full Server without the required features ('RSAT-Feature-Tools-BitLocker-RemoteAdminTool') installed" {
            Mock -CommandName Get-OSEdition -MockWith {
                return 'Server'
            }

            Mock -CommandName Get-WindowsFeature -MockWith {
                param
                (
                    [string]
                    $FeatureName
                )

                if ($FeatureName -eq 'RSAT-Feature-Tools-BitLocker-RemoteAdminTool')
                {
                    return $null
                }
                else
                {

                    return @{
                        DisplayName  = $FeatureName
                        Name         = $FeatureName
                        InstallState = 'Installed'
                    }
                }
            }
            It "The CheckForPreReqs function should throw an exceptions about missing Windows Feature" {
                {CheckForPreReqs} | Should -Throw "Required Bitlocker features need to be installed before xBitlocker can be used"
            }
        }
    }
}



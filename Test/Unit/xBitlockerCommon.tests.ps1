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

        Context "Verifing PreReqs on Windows Server Core with all required features" {
            Mock -CommandName Get-OSEdition -MockWith {
                "Server Core"
            }

            Mock -CommandName Get-WindowsFeature -MockWith {
                param
                (
                    [string]
                    $FeatureName
                )
                
                if($FeatureName -eq 'RSAT-Feature-Tools-BitLocker-RemoteAdminTool')
                {
                    return $null
                }
                else {
                    return @{
                        DisplayName = $FeatureName
                        Name = $FeatureName
                        InstallState = 'Installed'
                    }
                }
            }

            It "Should run the CheckForPreReqs function without exceptions" {
                CheckForPreReqs
            }
        }

        Context "Verifing PreReqs on Full Server with all required features" {
            Mock -CommandName Get-OSEdition -MockWith {
                return "Server"
            }

            Mock -CommandName Get-WindowsFeature -MockWith {
                param
                (
                    [string]
                    $FeatureName
                )
    
                return @{
                    DisplayName = $FeatureName
                    Name = $FeatureName
                    InstallState = 'Installed'
                }
            }
            It "Should run the CheckForPreReqs function without exceptions" {
                CheckForPreReqs
            }
        }

        Context "Verifing PreReqs on Full Server without the required features 'RSAT-Feature-Tools-BitLocker-RemoteAdminTool'" {
            Mock -CommandName Get-OSEdition -MockWith {
                return "Server"
            }

            Mock -CommandName Get-WindowsFeature -MockWith {
                param
                (
                    [string]
                    $FeatureName
                )
                
                if($FeatureName -eq 'RSAT-Feature-Tools-BitLocker-RemoteAdminTool')
                {
                    return $null
                }
                else {
                    return @{
                        DisplayName = $FeatureName
                        Name = $FeatureName
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



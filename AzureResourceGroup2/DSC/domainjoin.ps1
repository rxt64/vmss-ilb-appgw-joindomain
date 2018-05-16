Configuration Main {

    # Import the module that contains the resources we're using.
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    # Configure the DSC to only enforce the configuration once, rebooting as needed
    # (https://msdn.microsoft.com/en-us/powershell/dsc/metaconfig)
    LocalConfigurationManager {
        ConfigurationMode = "ApplyOnly"
        RebootNodeIfNeeded = $True
    }

    WindowsFeature ActiveDirectory {
        Name = "RSAT-AD-PowerShell"
    }

    Script DomainJoin {
        DependsOn = "[WindowsFeature]ActiveDirectory"
        GetScript = {return @{"Result" =""}}
        TestScript = {
            return (wmic computersystem get domain) -match "phx\.gbl"
        }
        SetScript = {
            # Get accountnames
            $accountName = "vmss@patitos.local"
            $accountPassword = "Rolo2010"
            $OUPath = "OU=Azure Servers,DC=patitos,DC=local"
            $domain = "patitos.local"
            
            # Join Domain
            $password = $accountPassword | ConvertTo-SecureString -asPlainText -Force
            $username = "$domain\$accountName"
            $credential = New-Object System.Management.Automation.PSCredential($username, $password)
            Add-Computer -DomainName $domain -Credential $credential -OUPath $ouPath

            # reboot
            $global:DSCMachineStatus = 1
        }
    }

    Script UpdateAdmins {
        DependsOn = "[Script]DomainJoin"
        GetScript = {return @{"Result" = ""}}
        TestScript = {
            # TODO once migrated to Windows Server 2016 to leverage better cmdlets
            Return $True
        }
        SetScript = {
            $adminGroup = ""
            # TODO use powershell (instead of cmd) with proper group
            net localgroup administrators /add $adminGroup
       }
    }

}
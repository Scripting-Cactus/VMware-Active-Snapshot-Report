#requires -version 2
<#
.SYNOPSIS
    This script is designed to return a list of all active snapshots
  
.DESCRIPTION
    This script is designed to return a list of all active snapshots
  
.PARAMETER $Vcenter_Array
    Creates an array of the vcenter servers you want to run this script against

.PARAMETER $Credential_User
    Specifiy the user to connect to the vCenter servers 
	as
.INPUTS
    Credential XML files need to be stored in folder relative to the script in \CredentialStore
    Credential files need to be named 
  
.OUTPUTS
    Log file stored in folder relative to the script in \Output\Vmware_Active_Snapshots_Report.log
  
.NOTES
    Version:        1.1.0
    Author:         Scripting-Cactus
    Creation Date:  10/11/2016
    Purpose/Change: Changed script to use standard template
                    Removed reliance for stored credentials in a file
  
.EXAMPLE
    $Vcenter_Array = @("vCenter-1", "vCenter-2", "etc")
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$Project_Author = "Scripting-Cactus"
$Project_Name = "VMware-Active-Snapshot-Report"
$Local_Version = "Version 1.1.0"

#Path Decloration
$Invocation = (Get-Variable MyInvocation).Value
$Directory_Path = Split-Path $Invocation.MyCommand.Path

#Log File Info
$Log_Path = $Directory_Path + "\Output"
$Log_Name = $Project_Name + ".log"
$Log_File = Join-Path -Path $Log_Path -ChildPath $Log_Name
$Output_Name = "Active_Snapshots.csv"
$Output_File = Join-Path -Path $Log_Path -ChildPath $Output_Name

#Array of vCenter servers to connect to
$Vcenter_Array = @("vCenter-1")

# Set user to run script as
$Credentials_User = "username"

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

# Start Logging
Add-content $Log_File -value "$Project_Name"
Add-content $Log_File -value "$(Get-Date) : Initialising Script"
write-host "Initialising Script"

#Add VMware PowerCLI Snap-Ins
try{
	Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop
}
catch{
	write-host "VMware Snapin could not be loaded. Is VMware PowerCli installed?"
	Add-content $Log_File -value "$Log_Date : $_"
	break
}
Finally{
	Add-content $Log_File -value  "$(Get-Date) : VMware Snapin successfully loaded"
	write-host "VMware Snapin successfully loaded"
}

# Set Error Preferences
$WarningActionPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

# Create snapshot csv file and header
try{
	New-Item -path $Output_File -type file -force
	Add-content $Output_File -value '"snapVC", "snapEventVM", "snapEventInfo", "snapEventDate", "snapEventUser"'
	$snapshot = "" | select-object snapVC, snapEventVM, snapEventInfo, snapEventDate, snapEventUser
	write-host "CSV file created"
	Add-content $Log_File -value "$(Get-Date) : CSV file created at $$Output_File"
}
catch{
	write-host "CSV file could not be created. Are the permissions set correctly?"
	Add-content $Log_File -value "$(Get-Date) : $_"
	break
}

#-----------------------------------------------------------[Functions]------------------------------------------------------------

#Function to connect to vCenters
Function Connect-VMwareServer{
    Param([Parameter(Mandatory=$true)][string]$Vcenter_Server)
    Begin{
            Add-content $Log_File -value "$(Get-Date) : Attempting to connect to $Vcenter_Server"
    }
    Process{
            Try{
				$Credentials = Get-VICredentialStoreItem -Host $Vcenter_Server | where {$_.User -eq $Credentials_User}
				Connect-VIServer $Vcenter_Server -User $Credentials.User -Password $Credentials.Password
            }
            Catch{
				Add-content $Log_File -value "$(Get-Date) : $_"
				write-host "Error connecting to vCenter $Vcenter_Server. See log file $Log_File for details."
				$Connected = "False"
				$Errors_Encounterd = "True"
                return
            }
    }
    End{
            If($Connected -eq "True"){
                Add-content $Log_File -value  "$(Get-Date) : Successfully connected to $Vcenter_Server"
                write-host "Successfully connected to $Vcenter_Server"
            }
    }
}

#Function to connect to vCenters
Function Disconnect-VMwareServer{
    Param([Parameter(Mandatory=$true)][string]$Vcenter_Server)
    Begin{
            Add-content $Log_File -value "$(Get-Date) : Attempting to Disconnect from $Vcenter_Server"
    }
    Process{
		$Connection_State = $defaultviserver | foreach {$_.IsConnected}
        if($Connection_State -eq "True"){
            disconnect-VIServer -server $Vcenter_Server -confirm:$false
            $Disconnected = "True"
        }
        else{
            Add-content $Log_File -value  "$(Get-Date) : Cannot disconnect from $Vcenter_Server as it is not connected"
            write-host "Cannot disconnect from $Vcenter_Server as it is not connected"
			$Errors_Encounterd = "True"
            return
        }
    }
    End{
        If($Disconnected -eq "True"){
            Add-content $Log_File -value  "$(Get-Date) : Successfully disconnected from $Vcenter_Server"
            write-host "Successfully disconnected from $Vcenter_Server"
        }
    }
}

# Function to list active snapshots
Function List-Active_Sanpshots{
	Add-content $Log_File -value  "$(Get-Date) : Retrieving list of active snapshots"
    write-host "Retrieving list of active snapshots"
	try{
		Get-VM | Get-Snapshot |%{
				$snap = $_
				$snapevent = Get-VIEvent -Entity $snap.VM -Types Info -Finish $snap.Created -MaxSamples 1 | Where-Object {$_.FullFormattedMessage -imatch 'Task: Create virtual machine snapshot'}
				$snapshot.snapVC = $vCenter
				if ($snapevent -ne $null)
					{ 
						$snapshot.snapEventVM = $snap.VM
						$snapshot.snapEventInfo = $snap
						$snapshot.snapEventDate = $snap.Created.DateTime
						$snapshot.snapEventUser = $snapevent.UserName
					}
				else 
					{
						$snapshot.snapEventVM = $snap.VM
						$snapshot.snapEventInfo = $snap
						$snapshot.snapEventDate = ("Unknown")
						$snapshot.snapEventUser = ("This event is not in vCenter events database")
					}
				$snapshot
			} | Export-Csv -Path $Output_File -NoTypeInformation -UseCulture -Force -Append
	}
	catch{
		Add-content $Log_File -value "$(Get-Date) : $_"
		write-host "Error retrieving running snapshots for $vCenter. See log file $Log_File for details."
		$Errors_Encounterd = "True"
		return
	}
	finally{
        If($Errors_Encounterd -ne "True"){
			Add-content $Log_File -value  "$(Get-Date) : Successfully retrieved list of active snapshots"
			write-host "Successfully retrieved list of active snapshots"
		}	
	}
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

foreach($vCenter in $vCenter_Array)
	{
        Connect-VMwareServer -Vcenter_Server $Vcenter
        List-Active_Sanpshots
        Disconnect-VMwareServer $Vcenter
    }

#-----------------------------------------------------------[Finalisation]---------------------------------------------------------

if($Errors_Encounterd = "True")
	{
		Add-content $Log_File -value "$(Get-Date) : Script has completed with errors"
		write-host "Script has completed with errors. Please review the log file located at $Log_File"
	}
else
	{
		Add-content $Log_File -value "$(Get-Date) : Script has been successfully completed"
		write-host "Script has been successfully completed"
	}

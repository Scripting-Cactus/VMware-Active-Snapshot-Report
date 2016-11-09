######################################################################################################
# Author: Scripting-Cactus
# Date : 09/11/2016
# Version: 1.0.0
######################################################################################################
# Only edit items in this section otherwise the script may not work. Read the readme.md for more info.
#
$vcenters = @("vCenter-1", "vCenter-2", "etc")
#
######################################################################################################
try
    {
        Add-PSSnapin VMware.VimAutomation.Core1 -ErrorAction Stop
    }
catch
    {
        write-host "VMware Snapin could not be loaded. Is VMware powercli installed?"
        break
    }
$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path 
New-Item $directorypath + "\Output\Active_Snapshots.csv" -type file -force
$snapshot = "" | Select-Object snapVC, snapEventVM, snapEventInfo, snapEventDate, snapEventUser
foreach($vCenter in $vCenters)
	{
		$vCenterCreds = $directorypath + "\CredentialStore\"+$vcenter +"_Credentials.xml"
        $Creds = Get-VICredentialStoreItem -Host $vcenter -File $vCenterCreds
        Connect-VIServer $vcenter -User $Creds.User -Password $Creds.Password
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
		} | Export-Csv -Path  $directorypath + "\Output\Active_Snapshots.csv" -NoTypeInformation -UseCulture -Force -Append
        Disconnect-VIServer -Server $vcenter -confirm:$false
    }
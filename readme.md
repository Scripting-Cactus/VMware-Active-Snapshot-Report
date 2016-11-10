# VMware Active Snapshot Report
This script is designed to run against multiple VMware vCenter servers and return a list of all active snapshots.
The are exmaples of the log file and the output in the output folder.

## Prerequistes

### Software
For this script to be able to run it is required that VMware Powercli is installed so that Powershell can talk to the vCenters and run the required commands.

### Stored Credentials
This script is based on the VICredentialStoreItem method of authentication. You will need to create some credentials using New-VICredentialStoreItem See https://www.vmware.com/support/developer/windowstoolkit/wintk40u1/html/New-VICredentialStoreItem.html for an example on how to create your credentials.

## Configuring the Script
To get this script running all you need to do is replace the data in the $Venters_Array with the FQDN or IP address of your vCenter Servers. this will work with a single vcenter in the array or multiple.

# VMware Active Snapshot Report
This script is designed to run against multiple VMware vCenter servers and return a list of all active snapshots.

## Prerequistes

### Software
For this script to be able to run it is required that VMware powercli is installed so that powershell can talk to the vCenters and run the required commands.

### Stored Credentials
This script is based on the VICredentialStoreItem xml file method of authentication. You will need ot create an xml file and store it in the \CredentailStore folder for the script to work. See https://www.vmware.com/support/developer/windowstoolkit/wintk40u1/html/New-VICredentialStoreItem.html for an example on how to creat your file. There is a file included in the \CredentialStore folder to give you an idea of what the xml file output will look like. This will need to be done for every vCenter you want to connect to and requires a seperate xml file for each.
The xml files will need to be located in the \CredentialStore folder and named in the following way: vCenterName_Credentials.xml e.g. vCenter-1.local_Credentials.xml

## Configuring the Script
To get this script running all you need to do is replace the data in the vCenters array with the FQDN or IP address of your vCenter Servers. Make sure that teh names you place in the array match the start of the credentials xml file name otherwise it will not be able to connect.

# azure-jenkins-devtest-env
A private &amp; secure Jenkins dev/test environment running in Azure. 

This project will feature some Azure ARM templates that deploy a private dev/test environment in Azure.  It will feature the following:
1) A virtual network
2) Two subnets -> 1) Jumpbox DMZ & 2) DevTest 
3) A Jenkins Master server on the private DevTest subnet
4) A Windows Server 2016 VM configured as a "jumpbox" with RDP access.
5) Azure plugin for Jenkins to enable Jenkins to create/delete Azure Agent VMs
6) Azure plugin for Jenkins to read/write artifacts from Azure Storage.
7) Instructions for how to use & configure all of the pieces.

Please see the file named Azure-Jenkins-DevTest-Environment.docx file for instructions on how to set up an Azure Jenkins dev test environment.

#SB

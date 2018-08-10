These scripts are intended for demo only, and should probably never be run in a production environment. Either script can do serious damage when run improperly. 

Make-Machines.ps1
This script was written to create a group of virtual machines. It is intended to show clone performance in lab testing scenarios. 
This script connects to vCenter and creates as many virtual machines as specified in the script. The default is 250. 

When creating a large number of VMs, it is critical to ensure your resources (CPU, Memory and Storage) are sufficient to handle the created load. 
Your ESXi enviroment may become unstable if you over commit your resources.

Remove-Machines.ps1
This script removes the VMs created above, but if not handled correctly, it could delete VMs you didn't intend to delete. 
By default, this script deletes any VM starting with "TestVM". This script deletes them from the disk. 
If you accidently put in the wrong string, you can remove machines you didn't intend to delete. 

If you review this code, and you are unsure of what it does, you probably shouldn't be running it. 

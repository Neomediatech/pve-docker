> [!WARNING]
> **Maybe something is not working, use this image with caution, bad things can happens. YHBW**  

# Proxmox VE on a Docker container
Proxmox Virtual Environment on a Docker container  

## Known limits
* **Postfix is not working**
* (and maybe many other things)  

## How to run
`./run.sh` ;-)  
What does [run.sh](run.sh) do:
* set docker ENV vars if they are set in the script or in the `.envs` file
* set shell script vars if they are set in the script or in the `.shell-vars` file (see [example](#environment-variables))
* check if datastore exists; if not, it exit prior tu run the container (maybe in future i'll make it more smart, see [To DO](#to-do) section)
* run the container
  
or  
`docker run -d --name pve neomediatech/pve`

## Environment Variables
| Name                | Description                                                     | Default         |
| ------------------- | --------------------------------------------------------------- | --------------- |
| ADMIN_PASSWORD      | Password to access PVE web interface (mandatory)                | (none)          |
| RELAY_HOST          | Hostname to use to relay email from Postfix (NOT WORKING!)      |                 |
| PVE_ENTERPRISE      | If set to "yes", enterprise repository will be retained         | no              |

Set vars in `run.sh` script and/or set them in `.envs` file.  
Example `.envs` file:
```
ADMIN_PASSWORD=myrealsecretpassword
RELAY_HOST=10.40.50.4
```
## run.sh script shell vars
| Name                | Description                                                     | Default         
| ------------------- | --------------------------------------------------------------- | --------------- 
| INTERACTIVE         | Run the container in "interactive mode" (run it in foreground)  <br /> CTRL+C will end the container | no 
| NAME                | Proxmox VE name | pve
| BASE_PATH           | Path where to store PVE configurations, users, etc... | /srv/pve
  
`.shell-vars` example file:
```
NAME="myserver-pve"
BASE_PATH="/srv/pve"
INTERACTIVE="no"
```
## Mountpoints/volumes
Put your docker bindmount in the script [run.sh](run.sh) or in the `.volumes` file  
`.volumes` example file:
```
${BASE_PATH}/data/logs:/var/log
${BASE_PATH}/data/pve_cluster:/var/lib/pve-cluster
${BASE_PATH}/data/pve_manager:/var/lib/pve-manager
${BASE_PATH}/data/bin:/srv/bin
```  
  
## To DO
- [ ] Make Postfix working, to send emails


this [this](https://medium.com/@numb95/setup-nexus-repository-manager-with-nginx-reverse-proxy-and-lets-encrypt-ssl-certificate-on-docker-1c1b05988ce3?sk=9025078deda34020ca7312d110b79673) article for info or `./init.sh` to run.

# Update

**Table of contents**  
- [Prerequisites](#prerequisitess)
- [Installation](#installation)
- [Note](#note)

## Prerequisites 
- Installed [docker(ubuntu for example)](https://docs.docker.com/engine/install/ubuntu/)
- `sudo usermod -aG docker $USER` for user which will run docker commands from [Post-installation steps for Linux](https://docs.docker.com/engine/install/linux-postinstall/)
- Installed [docker-compose](https://docs.docker.com/compose/install/)
- Installed **git** (`sudo apt-get update && sudo apt-get install git-all -y`)
- Registered domain for SSL purposes with both YOUR_DOMAIN.com and **www**.YOUR_DOMAIN.com *A-records* pointed to ip address of your server.

## Installation  
You may want to choose&create some directory for Nexus repository, it's tested in user's $HOME directory somewhere.
- Clone this repository and navigate to clonned repo:
```bash
git clone https://github.com/Vladkarok/nexus-nginx-letsencrypt-docker.git && cd nexus-nginx-letsencrypt-docker
```
- Fix permissions for `init.sh` to give this script executable permissions
```bash
chmod +x init.sh
```
- Run this script
```bash
./init.sh
```
- Enter your:
  - **domain name**
  - **email-address**
  - **Script mode** (1 for testing if all works, 0 - for actual certificate issue) 
  > **Note!** Let's Encrypt has [limits](https://letsencrypt.org/docs/rate-limits/), so don't overlimit them.  
  - Existing data found for YOUR_DOMAIN. Continue and replace existing certificate? (y/N)

Then check again your input, if all data are correct - press **y** and let the script do all the work.  
After successful finish you can visit (https://YOUR_DOMAIN.COM) for futher Nexus installation
## Note
1) We exposed on Nginx container additional `5000` and `8082` ports with **SSL** enabled for future usage, for example **docker-hosted** or **docker-proxy** repositories so you don't have to rebuild containers.
2) If you want to change your domains after script execution (for example in case of some mistake or other reason) - replace parts with your previous domain name in [conf/nginx/nginx.conf](https://github.com/Vladkarok/nexus-nginx-letsencrypt-docker/blob/master/confs/nginx/nginx.conf) on lines 9, 10 and 17 with `DOMAINNAME` string if you want the script to replace this values **or** you can edit it manually.
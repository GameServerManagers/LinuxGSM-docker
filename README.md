# note: This Repo is now retired and replaced with a new Docker container  https://github.com/GameServerManagers/docker-gameserver
<h1 align="center">
  <br>
  <a href="https://linuxgsm.com"><img src="https://i.imgur.com/Eoh1jsi.jpg" alt="LinuxGSM"></a>
  LinuxGSM Docker Container
</h1>

[LinuxGSM](https://linuxgsm.com) is the command-line tool for quick, simple deployment and management of Linux dedicated game servers.

> This docker container is under development is subject to significant change and not considered stable.

A dockerised version of LinuxGSM https://linuxgsm.com

Dockerhub https://hub.docker.com/r/gameservermanagers/linuxgsm-docker/
# Usage

## docker-compose
Below is an example `docker-compose` for csgoserver. Ports will vary depending upon server.
  ```
version: '3.4'
services:
  linuxgsm:
    image: "ghcr.io/gameservermanagers/linuxgsm-docker:latest"
    container_name: csgoserver
    environment:
      - GAMESERVER=csgoserver
      - LGSM_GITHUBUSER=GameServerManagers
      - LGSM_GITHUBREPO=LinuxGSM
      - LGSM_GITHUBBRANCH=master
    volumes:
      - /path/to/serverfiles:/home/linuxgsm/serverfiles
      - /path/to/log:/home/linuxgsm/log
      - /path/to/config-lgsm:/home/linuxgsm/lgsm/config-lgsm
    ports:
      - "27015:27015/tcp"
      - "27015:27015/udp"
      - "27020:27020/udp"
      - "27005:27005/udp"
    restart: unless-stopped
```
# First Run
Edit the `docker-compose.yml` file changing `GAMESERVER=` to the game server of choice.
On first run linuxgsm will install your selected server and will start running. Once completed the game server details will be output.
## Game Server Ports
Each game server has its own port requirements. Becuase of this you will need to configure the correct ports in your `docker-compose` after first run. The required ports are output once installation is completed and everytime the docker container is started.
## Volumes
volumes are required to save persistant data for your game server. The example above covers a basic csgoserver however some game servers save files in other places. Please check all the correct locations are mounted to remove the risk of loosing save data.
# Run LinuxGSM commands

Commands can be run just like standard LinuxGSM using the docker exec command.

```

docker exec -it csgoserver ./csgoserver details

```
#

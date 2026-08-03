# Server Init

## Prerequisites

`hcloud cli`
```sh
brew install hcloud
```
or
```sh
scoop install main/hcloud
```
and
```sh
# .env.local
HCLOUD_TOKEN="RW_TOKEN_HERE"
```

## Creation

```sh
export $(xargs < .env.local) && hcloud server create \
  --name whatphilipruns \
  --image ubuntu-26.04 \
  --type cx23 \
  --location fsn1 \
  --ssh-key "gerdes.philip@gmail.com" \
  --user-data-from-file .init/cloudconf.yaml
```

## Rebuild

```sh
export $(xargs < .env.local) && hcloud server rebuild whatphilipruns \
  --image ubuntu-26.04 \
  --user-data-from-file .init/cloudconf.yaml
```


## Setup

`Setup`
```sh
sudo bash setup.sh
```

`Terminal`
```sh
sudo cp -r /home/philip/.terminfo/* /usr/share/terminfo/
```

## Troubleshooting

### sudo user

`WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`<br>
This has to be run after each rebuild
```sh
ssh-keygen -R "[<server-ip>]:2222"
```
---
`'xterm-ghostty': unknown terminal type.`<br>
Some terminal emulations like Ghostty cache into which SSH connections they already injected their definitions. After a rebuild run this:
```sh
ghostty +ssh-cache --remove="philip@<server-ip>"
```
Afterwards rerun this on the server
```sh
sudo cp -r /home/philip/.terminfo/* /usr/share/terminfo/
```
---
`root access`
```sh
sudo -i
```

`switch user` (default access)
```sh
sudo su - <username>
```

### podman user

`switch user` (full access)
```sh
sudo machinectl shell podman@
```

`podman status overview`
```sh
  systemctl --user list-units --type=service --state=active
```

`podman status detail`
```sh
  systemctl --user status <name>.service
```
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
  --user-data-from-file ./cloudconf.yaml
```

## Rebuild

```sh
export $(xargs < .env.local) && hcloud server rebuild whatphilipruns \
  --image ubuntu-26.04 \
  --user-data-from-file ./cloudconf.yaml
```

`WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`<br>
This has to be run after every rebuild
```sh
ssh-keygen -R "[<server-ip>]:2222"
```

## Setup

`Setup`
```sh
git clone https://github.com/whatphilipcodes/whatphilipruns && bash whatphilipruns/setup.sh
```

## Local Dev

using `podman-compose` (run from repo root dir)

```sh
podman compose up -d
```
Inside the `/apps` dir, you can then use `Shift+Cmd+P` to run `Attach to Running Container` and select the adjacent container. Alternatively you can rebuild the container directly in vscode (running as submodule that is child to this repo).

## Troubleshooting

`'xterm-ghostty': unknown terminal type.`<br>
Some terminal emulations like Ghostty cache into which SSH connections they already injected their definitions. After a rebuild run this on your local dev machine:
```sh
ghostty +ssh-cache --remove="<username>@<server-ip>"
```

## Useful Commands

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
sudo machinectl shell <username>@
```

`podman status overview`
```sh
systemctl --user list-units --type=service --state=active
```

`podman status detail`
```sh
systemctl --user status <name>.service
```

`podman service log`
```sh
journalctl --user -u <name>.service
```

`start service`
```sh
systemctl --user start <name>.service
```

`stop service`
```sh
systemctl --user stop <name>.service
```
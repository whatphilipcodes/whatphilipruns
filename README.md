# Remote VPS Setup

### Setup / Rebuild
Make sure you created `secrets.nix` and `.env`, both populated with your data. You can find the required structures for both in `secrets.example.nix` and `.env.example`. Once that is set up, you can run the `init.sh` script to instantiate the VPS on Hetzner's infra:
```sh
bash init.sh
```

All of these commands assume the following ssh config setting:
```
Host wpr
    HostName xxxx:xxx:xxxx:xxxx::1
    Port 2222
```

### NixOS Rebuild (Soft)
Run this upon config changes to update the VPS instance:
```sh
sudo nixos-rebuild switch
```

### NixOS Test Build (Dry Run)

`dry-build`
Evaluate the config and list what would be built.
```sh
sudo nixos-rebuild build
```

`dry-activate`
Run the full build but not apply it yet.
```sh
sudo nixos-rebuild test
```

## Local Dev

1. Spin up the infrastructure locally using `podman-compose` (run from repo root dir).
    ```sh
    podman compose up -d
    ```
    If you want to manage the dev servers manually from inside the containers use the manual override:
    ```sh
    podman compose -f compose.yaml -f compose.manual.yaml up -d
    ```

2. Add this to your local .ssh config:
    ```
    Host time-dev inferno-dev
        HostName localhost
        User root
        PreferredAuthentications none
        UserKnownHostsFile ~/.ssh/known_devcontainers

    Host time-dev
        Port 2222

    Host inferno-dev
        Port 2223
    ```

3. Connect to the dev container via SSH.


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
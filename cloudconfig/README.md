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
NIX_SSHOPTS="-p 2222" nix run --inputs-from . nixpkgs#nixos-rebuild-ng -- switch --sudo \
   --flake "path:.#whatphilipruns" \
   --build-host philip@wpr \
   --target-host philip@wpr
```

### NixOS Test Build (Dry Run)

`dry-build`
Evaluate the config and list what would be built.
```sh
NIX_SSHOPTS="-p 2222" nix run --inputs-from . nixpkgs#nixos-rebuild-ng -- dry-build \
   --flake "path:.#whatphilipruns" \
   --build-host philip@wpr
```

`dry-activate`
Run the full build but not apply it yet.
```sh
NIX_SSHOPTS="-p 2222" nix run --inputs-from . nixpkgs#nixos-rebuild-ng -- dry-activate --sudo \
   --flake "path:.#whatphilipruns" \
   --build-host philip@wpr \
   --target-host philip@wpr
```
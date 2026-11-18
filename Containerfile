# Tooling image for init.sh. Built for linux/arm64 so that flake evaluation
# happens against an aarch64-linux system. Tool versions come from NIXPKGS_REF;
# the flake's own inputs are pinned separately by flake.lock.
ARG NIX_IMAGE=docker.io/nixos/nix:latest
FROM ${NIX_IMAGE}

ARG NIXPKGS_REF=nixos-26.05

RUN mkdir -p /etc/nix \
 && printf 'experimental-features = nix-command flakes\nsandbox = false\n' >> /etc/nix/nix.conf

# Own profile (the base image's default profile is managed by nix-env).
RUN nix profile install --profile /nix/var/nix/profiles/tools \
      github:NixOS/nixpkgs/${NIXPKGS_REF}#hcloud \
      github:NixOS/nixpkgs/${NIXPKGS_REF}#nixos-anywhere \
      github:NixOS/nixpkgs/${NIXPKGS_REF}#openssh \
      github:NixOS/nixpkgs/${NIXPKGS_REF}#bashInteractive \
      github:NixOS/nixpkgs/${NIXPKGS_REF}#git \
      github:NixOS/nixpkgs/${NIXPKGS_REF}#coreutils \
      github:NixOS/nixpkgs/${NIXPKGS_REF}#gnugrep \
      github:NixOS/nixpkgs/${NIXPKGS_REF}#gnused

ENV PATH=/nix/var/nix/profiles/tools/bin:${PATH}
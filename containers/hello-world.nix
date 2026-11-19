{ config, ... }:
{
  virtualisation.quadlet.containers.hello-world = {
    uid = config.users.users.podman.uid;
    containerConfig.Image = "docker.io/library/hello-world:latest";
  };
}

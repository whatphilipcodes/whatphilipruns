# Server Init

### Prerequisites

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
export HCLOUD_TOKEN=""
```

### Creation

```sh
hcloud server create \
  --name whatphilipruns \
  --image ubuntu-26.04 \
  --type cx23 \
  --location fsn1 \
  --ssh-key "gerdes.philip@gmail.com" \
  --user-data-from-file .init/create.yaml
```

### Rebuild

```sh
hcloud server rebuild whatphilipruns \
  --image ubuntu-26.04 \
  --user-data-from-file .init/rebuild.yaml
```


### Terminal

```sh
sudo cp -r /home/philip/.terminfo/* /usr/share/terminfo/
```
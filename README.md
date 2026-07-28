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
# .env
HCLOUD_TOKEN="RW_TOKEN_HERE"
```
```sh
export $(xargs < .env)
```

### Creation

```sh
hcloud server create \
  --name whatphilipruns \
  --image ubuntu-26.04 \
  --type cx23 \
  --location fsn1 \
  --ssh-key "gerdes.philip@gmail.com" \
  --user-data-from-file .init/cloudconf.yaml
```

### Rebuild

```sh
hcloud server rebuild whatphilipruns \
  --image ubuntu-26.04 \
  --user-data-from-file .init/cloudconf.yaml
```


### Setup

`Terminal`
```sh
sudo cp -r /home/philip/.terminfo/* /usr/share/terminfo/
```

`Setup`
```sh

```

### Troubleshooting

`WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`
This has to be run after each rebuild
```sh
ssh-keygen -R "[<server-ip>]:2222"
```
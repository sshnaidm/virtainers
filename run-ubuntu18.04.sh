#!/bin/bash
cat <<EOF >/tmp/temp-user-data
#cloud-config
password: ${PASSWORD:-password}
chpasswd: { expire: False }
ssh_pwauth: True
hostname: localvm
ssh_authorized_keys:
  - $(cat ${SSH_KEY:-~/.ssh/id_rsa.pub})
EOF

docker run \
    --privileged \
    -v /tmp/temp-user-data:/tmp/user-data \
    --name ubuntu18.04 \
    -d -t docker.io/virtainers/ubuntu:18.04
docker inspect ubuntu18.04 -f "{{ .NetworkSettings.IPAddress }}"

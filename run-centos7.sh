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
    --name centos7 \
    -d -t docker.io/virtainers/centos:7
docker inspect centos7 -f "{{ .NetworkSettings.IPAddress }}"

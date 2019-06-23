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
    --name fedora30 \
    -d -t docker.io/sshnaidm/virtainers:fedora30
docker inspect fedora30 -f "{{ .NetworkSettings.IPAddress }}"

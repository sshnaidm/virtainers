#!/bin/bash
IMAGE_URL=${IMAGE_URL:-https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2}
IMAGE=${IMAGE:-CentOS-7-x86_64-GenericCloud.qcow2}
if ! [[ -e $IMAGE ]]; then
    curl -o $IMAGE $IMAGE_URL
fi
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
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    --privileged \
    --cap-add SYS_ADMIN \
    -v $(realpath $IMAGE):/image \
    -v /tmp/temp-user-data:/tmp/user-data \
    --name virtainer \
    -d -t docker.io/sshnaidm/virtainers:stable
docker inspect virtainer -f "{{ .NetworkSettings.IPAddress }}"

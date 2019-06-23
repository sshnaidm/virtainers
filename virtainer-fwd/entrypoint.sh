#!/bin/sh
dbus-daemon --system --print-address
virtlogd -d
libvirtd -d

if [[ -e /tmp/cloud_init.iso ]]; then
  cp /tmp/cloud_init.iso /cloud_init.iso
elif [[ -e /tmp/user-data -a -e /tmp/meta-data ]]; then
  genisoimage -output /cloud_init.iso -volid cidata -joliet -rock /tmp/user-data /tmp/meta-data
elif [[ -e /tmp/user-data ]]; then
  { echo instance-id: localimage-01; echo local-hostname: cloudimage; } > /tmp/meta-data
  genisoimage -output /cloud_init.iso -volid cidata -joliet -rock /tmp/user-data /tmp/meta-data
elif [[ -e /tmp/id_rsa.pub ]]; then
  cat <<EOF >/tmp/user-data
#cloud-config
ssh_authorized_keys:
  - $(cat /tmp/id_rsa.pub)
EOF
  { echo instance-id: localimage-01; echo local-hostname: cloudimage; } > /tmp/meta-data
  genisoimage -output /cloud_init.iso -volid cidata -joliet -rock /tmp/user-data /tmp/meta-data
else
  cat <<EOF >/tmp/user-data
#cloud-config
password: password
chpasswd: { expire: False }
ssh_pwauth: True
hostname: localvm
EOF
  { echo instance-id: localimage-01; echo local-hostname: cloudimage; } > /tmp/meta-data
  genisoimage -output /cloud_init.iso -volid cidata -joliet -rock /tmp/user-data /tmp/meta-data
fi

if [[ -e /image.xz ]]; then
  unxz /image.xz
fi

IMAGE_DIR=${IMAGE_DIR:-/mounted}
mkdir -p $IMAGE_DIR
if [[ ! -e ${IMAGE_DIR}/local_image.qcow2 ]]; then
  qemu-img create -f qcow2 -o backing_file=/image ${IMAGE_DIR}/local_image.qcow2 ${DISK_SIZE:-40G}
fi
old=$(virsh net-dumpxml default | grep range|sed "s/^ *//g")
virsh net-update default delete ip-dhcp-range "$old" --live
virsh net-update default add ip-dhcp-range "<range start='192.168.122.100' end='192.168.122.100'/>" --live
iface=$(ip r | grep default | sed "s/.*dev \(.*\)/\1/g")
ipadd=$(ip a sh $iface | grep -Eo "inet [^ ]*" | sed "s/inet //g" | sed "s@/.*@@g")
iptables -I FORWARD 1 -o virbr0 -m state -d 192.168.122.0/24 --state NEW,RELATED,ESTABLISHED -j ACCEPT
iptables -D FORWARD 2
iptables -t nat -A PREROUTING -d $ipadd -p tcp --dport 1:65535 -j DNAT --to-destination 192.168.122.100:1-65535

virt-install --hvm \
	--connect qemu:///system \
	--network default \
	--name ${VM_NAME:-vm} \
	--ram=${RAM:-1024} \
	--vcpus=${CPU:-1} \
	--os-type=linux \
	--os-variant=${OS_VARIANT:-rhel7} \
	--disk path=${IMAGE_DIR}/local_image.qcow2 \
	--disk ${CLOUD_INIT_DISK:-/cloud_init.iso},device=cdrom \
	--graphics none \
	--cpu host \
	--import

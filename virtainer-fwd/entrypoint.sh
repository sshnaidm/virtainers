#!/bin/sh
dbus-daemon --system --print-address
virtlogd -d
libvirtd -d

echo "+++++++++++ Creating user-data..."
if [[ -e /tmp/cloud_init.iso ]]; then
  cp /tmp/cloud_init.iso /cloud_init.iso
elif [[ -e /tmp/user-data && -e /tmp/meta-data ]]; then
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
  echo "+++++++++++ Decompressing OS image..."
  unxz /image.xz
fi
echo "+++++++++++ Preparing networking..."


IMAGE_DIR=${IMAGE_DIR:-/mounted}
mkdir -p $IMAGE_DIR
if [[ ! -e ${IMAGE_DIR}/local_image.qcow2 ]]; then
  echo "+++++++++++ Creating a disk ${IMAGE_DIR}/local_image.qcow2 for virtual machine..."
  qemu-img create -f qcow2 -o backing_file=/image ${IMAGE_DIR}/local_image.qcow2 ${DISK_SIZE:-40G}
else
  echo "+++++++++++ Using existing disk in ${IMAGE_DIR}/local_image.qcow2 for virtual machine"
fi
echo "+++++++++++ Starting networking..."
#old=$(virsh net-dumpxml default | grep range|sed "s/^ *//g")
#virsh net-update default delete ip-dhcp-range "$old" --live
#virsh net-update default add ip-dhcp-range "<range start='192.168.122.100' end='192.168.122.100'/>" --live
CIDR=${CIDR:-192.168.100}
cat <<EOF >/tmp/network
<network>
  <name>virtualnet</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr1' stp='on' delay='0'/>
  <ip address='${CIDR}.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='${CIDR}.100' end='${CIDR}.100'/>
    </dhcp>
  </ip>
</network>
EOF

virsh net-define /tmp/network
virsh net-autostart virtualnet
virsh net-start virtualnet

iface=$(ip r | grep default | sed "s/.*dev \(.*\)/\1/g")
ipadd=$(ip a sh $iface | grep -Eo "inet [^ ]*" | sed "s/inet //g" | sed "s@/.*@@g")
/sbin/iptables -t nat -I PREROUTING -d $ipadd -j DNAT --to ${CIDR}.100
/sbin/iptables -t nat -I POSTROUTING -s ${CIDR}.100 -j SNAT --to $ipadd
/sbin/iptables -t filter -I FORWARD -d ${CIDR}.100 -j ACCEPT
/sbin/iptables -t filter -I FORWARD -s ${CIDR}.100 -j ACCEPT
iptables-save > /etc/iptables-rules

virt-install --hvm \
	--connect qemu:///system \
	--network network=virtualnet \
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
sleep 365d

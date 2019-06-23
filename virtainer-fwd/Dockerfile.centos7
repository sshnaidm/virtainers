FROM alpine:3.9

# URL for XZ compressed image
ARG image_url=https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2.xz
RUN apk update &&\
	apk add --no-cache cdrkit alpine-conf qemu-system-x86_64 libvirt libvirt-daemon dbus polkit qemu-img openrc virt-install xz openssh bash xz py-libxml2 py-libvirt &&\
	rc-update add libvirtd &&\
	rc-update add dbus
RUN wget $image_url -O /image.xz

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

FROM alpine:3.9

# URL for XZ compressed image
ARG image_url=https://cloud-images.ubuntu.com/minimal/releases/bionic/release/ubuntu-18.04-minimal-cloudimg-amd64.img
RUN apk update &&\
	apk add --no-cache cdrkit alpine-conf qemu-system-x86_64 libvirt libvirt-daemon dbus polkit qemu-img openrc virt-install xz openssh bash xz py-libxml2 py-libvirt &&\
	rc-update add libvirtd &&\
	rc-update add dbus
RUN wget $image_url -O /image

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

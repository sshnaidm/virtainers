FROM alpine:3.9

RUN apk update &&\
	apk add --no-cache cdrkit alpine-conf qemu-system-x86_64 libvirt libvirt-daemon dbus polkit qemu-img openrc virt-install xz openssh bash py-libxml2 py-libvirt &&\
	rc-update add libvirtd &&\
	rc-update add dbus

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

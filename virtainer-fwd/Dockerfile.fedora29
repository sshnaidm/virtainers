FROM alpine:3.9

# URL for XZ compressed image
ARG image_url=https://ewr.edge.kernel.org/fedora-buffet/fedora/linux/releases/29/Cloud/x86_64/images/Fedora-Cloud-Base-29-1.2.x86_64.raw.xz
RUN apk update &&\
	apk add --no-cache cdrkit alpine-conf qemu-system-x86_64 libvirt libvirt-daemon dbus polkit qemu-img openrc virt-install xz openssh bash wget py-libxml2 py-libvirt &&\
	rc-update add libvirtd &&\
	rc-update add dbus
RUN wget $image_url -O /image.xz

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

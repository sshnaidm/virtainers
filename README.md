# Virtainers

Virtual machines within containers
----------------------------------

TL;DR - run Fedora 29 virtual machine as a container
```bash
docker run --privileged -v ~/.ssh/id_rsa.pub:/tmp/id_rsa.pub:ro --name fedora29 -d -t docker.io/virtainers/fedora:29
IP=$(docker inspect fedora29 -f "{{ .NetworkSettings.IPAddress }}")
docker logs fedora29 # use to see when virtual machine is up, usually about a minute
ssh fedora@$IP
# PROFIT! you're inside a virtual machine
```

# Table of Contents
- [Virtainers](#Virtainers)
  - [Virtual machines within containers](#Virtual-machines-within-containers)
- [Table of Contents](#Table-of-Contents)
  - [Intro to virtainers](#Intro-to-virtainers)
    - [Why and how](#Why-and-how)
    - [Which containers engines are supported - docker and podman](#Which-containers-engines-are-supported---docker-and-podman)
    - [Which virtual machines are provided?](#Which-virtual-machines-are-provided)
  - [Running VM inside a container locally](#Running-VM-inside-a-container-locally)
    - [Options to inject user data](#Options-to-inject-user-data)
    - [Tweaking and customizing virtual machine parameters](#Tweaking-and-customizing-virtual-machine-parameters)
    - [Console connection](#Console-connection)
    - [Prepared virtainers of specific distro](#Prepared-virtainers-of-specific-distro)
    - [Generic virtainer](#Generic-virtainer)
    - [Persistent data](#Persistent-data)
    - [Connections between virtainers on the same host](#Connections-between-virtainers-on-the-same-host)
    - [Note for running docker inside a virtainer](#Note-for-running-docker-inside-a-virtainer)
  - [How to run virtainer with IP from external network](#How-to-run-virtainer-with-IP-from-external-network)
    - [Bridges and macvlan networks](#Bridges-and-macvlan-networks)
  - [Use cases](#Use-cases)
  - [What's next?](#Whats-next)


## Intro to virtainers
We have two main isolation ways - it's virtualization and containerization. But what we don't have, it's simplicity,
easy distribution and orchestration of containers with possibilities to deploy different operation systems of
virtualization.

Virtainers are coming to solve this problem and provide easy deployment of isolated environment - virtual machine inside
a container, which allows to run any OS and enjoy of all containerization advantages and tools.

### Why and how
For example you have a bare Jenkins slave, which runs Ubuntu 12.04 and you need to test your application or deployment
scripts on Fedora, and your deployment scripts includes starting a Docker service via systemd, running there containers
and restarting services.

There are systemd enabled containers, but when it comes to deal with restarts of Docker service inside and running
containers it turns to total mess with bunch of hacks and non obvious solutions. And what if we want to test something
network related? This complicates things even more.

That's why the solution could be running a "virtainer".

Actually virtainer requires from host the same what can require a libvirt service - enabled virtualization option. But
you don't need to deal with any virtualization framework, tools, service like Vagrant, VirtualBox, VMWare or
libvirt/KVM, just a container - docker or podman installed. It will allow you to run VM in one simple command without
dealing with any dependencies, additional packages, repositories, etc etc. It also allows you to provide a configured VM
to any of your team members or even to publish it. You can publish your changes to virtual machine and everyone who
use them with virtainer will have the exactly same VM as you. It's only matter of publishing one file, which includes
all changes you made for the VM from its start.

### Which containers engines are supported - docker and podman
We support two containers engines - it's docker and podman. Podman is supported with "sudo" - not rootless containers.
Usually the difference comes when we set up a special networking for virtainers, podman doesn't have network related
command options, so it's done differently. When running just virtainer on the host connected to internal network, you
can easily replace "docker" by "sudo podman" and have the same experience.

### Which virtual machines are provided?
Currently we provide one generic virtainer that can pick up any cloud image you set for it and ready virtainers
that already include the image inside:
- Fedora 29
- Fedora 30
- CentOS 7
- Ubuntu 18.04

Others could be added easily.

## Running VM inside a container locally
We need to run docker in privileged mode: ``--priveleged``, nothing more special is required. Also you need to add
``-t`` option to add a terminal, so you can see logs of VM starting.
So if we run a virtual machine, we most likely would like to inject a specific data there, either SSH keys or some
more advanced pre-configuration of the host. We use cloud images for virtainers to run VM from, so it supports
[cloud-init](https://cloud-init.io/). You can pass any preconfigured cloud-init file and virtainer will inject it to VM.

### Options to inject user data
The options are as following:
1. If you map your SSH key to ``/tmp/id_rsa.pub key`` like ``-v ~/.ssh/id_rsa.pub:/tmp/id_rsa.pub:ro`` then virtainer
will inject your SSH key into virtual machine and you can SSH to it with a default image user. Usually it's:
- ``fedora`` - for all Fedora VMs
- ``centos`` - for all CentOS VMs
- ``cloud-user`` - for all RHEL VMs
- ``ubuntu`` - for all Ubuntu VMs
Please find out username of your cloud image if you use a generic virtainer.
2. If you have your user-data in [cloud-config](https://cloudinit.readthedocs.io/en/latest/topics/examples.html) format,
then mount it to ``/tmp/user-data`` inside the container, like ``-v /path/to/my/user-data:/tmp/user-data``, and
virtainer will pick it up.
3. If you have your own meta-data file, you can mount it to ``/tmp/meta-data`` file inside a container, like
``-v /path/to/my/meta-data:/tmp/meta-data`` and virtainer will pick it up. Otherwise it will be generated for you
automatically using parameteres ``instance-id: localimage-01`` and ``local-hostname: cloudimage``.
4. If you have your own prepared cloud-init.iso file with required user-data and meta-data inside, just mount it to
``/tmp/cloud_init.iso`` inside the container as ``-v /path/to/my/cloud_init.iso:/tmp/cloud_init.iso``.
5. And finally, if you don't specify anything, container will run with password ``password``, you can enter it by SSH or
console. (**Try not to use this option because of security risks!**)

### Tweaking and customizing virtual machine parameters
Currently there are parameters which could be customized via environment variables:
- RAM of virtual machine in MB - $RAM (default: 1024)
- Virtual machine name - $VM_NAME (default: "vm")
- Number of CPUs - $CPU (default: 1)
- OS variant - $OS_VARIANT (default: "rhel7")
- Internal path for diff image (see [Persistent data](#persistent-data) section) - $IMAGE_DIR (default: "/mounted")
- Internal path for cloud-init ISO disk - $CLOUD_INIT_DISK (default: "/cloud_init.iso")

For running virtainer with 4GB RAM and 2 CPUs run as:
```bash
RAM=4096 CPU=2 docker run --privileged -v ~/.ssh/id_rsa.pub:/tmp/id_rsa.pub:ro --name fedora29 -d -t docker.io/virtainers/fedora:29
```

### Console connection
Virtual machine is running using libvirt/KVM, so you can also enter the console:
``docker exec -it virtainer_name virsh console --force vm``.

### Prepared virtainers of specific distro
For your convinience there are scripts in root dir of repo to run virtainers:
- [run-centos7.sh](https://github.com/sshnaidm/virtainers/blob/master/run-centos7.sh)
- [run-fedora29.sh](https://github.com/sshnaidm/virtainers/blob/master/run-fedora29.sh)
- [run-fedora30.sh](https://github.com/sshnaidm/virtainers/blob/master/run-fedora30.sh)
- [run-generic.sh](https://github.com/sshnaidm/virtainers/blob/master/run-generic.sh)
- [run-ubuntu18.04.sh](https://github.com/sshnaidm/virtainers/blob/master/run-ubuntu18.04.sh)

When each one starts the virtual machine according to its name.

### Generic virtainer
``run-generic.sh`` script will run a virtual machine with your image, just export IMAGE_URL (url of cloud image) or
IMAGE (path to image): ``IMAGE=/path/to/image  ./run-generic.sh`` or ``IMAGE_URL=http://url/to/image ./run-generic.sh``.

### Persistent data
Virtainers use backing image as base image for running OS and all diff will be written to different file
(``$IMAGE_DIR`` which is by default ``/mounted``). By mounting ``$IMAGE_DIR`` to a local path on your host you'll get
``local_image.qcow2`` file with diff that you can use later to restore virtual machine state.

For example:
```bash
docker run --privileged -v ~/.ssh/id_rsa.pub:/tmp/id_rsa.pub:ro -v /tmp/data_folder:/mounted -d -t --name fedora29 docker.io/virtainers/fedora:29
IP=$(docker inspect fedora29 -f "{{ .NetworkSettings.IPAddress }}")
ssh fedora@$IP
# now let's install some additional package for example
sudo dnf install -y vim
# when package is installed, exit
exit
# remove the containers completely
docker rm -f fedora29
# Let's check we have diff image in our host
ls /tmp/data_folder
# Now let's run a new container
docker run --privileged -v ~/.ssh/id_rsa.pub:/tmp/id_rsa.pub:ro -v /tmp/data_folder:/mounted -d -t --name new-fedora29 docker.io/virtainers/fedora:29
IP=$(docker inspect new-fedora29 -f "{{ .NetworkSettings.IPAddress }}")
ssh fedora@$IP
# Check that packge is installed
rpm -qa | grep vim
```
Local diff image will contain everything you did on virtual machine and is ready to be picked up when you run a new
virtainer. It could be easily distributed, relocated, etc. But important: it will work only if you have the same version
of backing image!

### Connections between virtainers on the same host
Nothing special is required. Virtainers can connect each to other as usual:
```
ssh fedora@172.17.0.3
ping 172.17.0.2

PING 172.17.0.2 (172.17.0.2) 56(84) bytes of data.
64 bytes from 172.17.0.2: icmp_seq=1 ttl=62 time=1.43 ms
64 bytes from 172.17.0.2: icmp_seq=2 ttl=62 time=0.301 ms
64 bytes from 172.17.0.2: icmp_seq=3 ttl=62 time=0.903 ms

```

### Note for running docker inside a virtainer
In case you want to run a docker inside a virtual machine of virtainer, you'll need to use a different network. The
problem appears when docker installs its default ``docker0`` interface with ``172.17.0.1/16``. While outer network of
virtainer is also from this subnet, if you run it by default. Packets to outer world won't go from virtual machine and
network connectivity will break. To prevent this, if you plan to run docker inside a virtainer, create a different
network for virtainers:
```bash
docker network create -d bridge --subnet=172.28.100.0/24 --ip-range=172.28.100.0/24 --gateway=172.28.100.1 virtual
docker run --privileged --name fedora29 -d -t --network=virtual docker.io/virtainers/fedora:29
```
That way you don't need to care about overlapping of docker networks inside and outside of virtainer. To discover an IP
of container just run ``docker inspect fedora29 -f "{{ .NetworkSettings.Networks.virtual.IPAddress }}"`` where
``virtual`` is your network name from previous step.
You also can play with IP ranges, for example if creating network like that:
```bash
docker network create -d bridge --subnet=172.28.100.0/24 --ip-range=172.28.100.2/32 --gateway=172.28.100.1 feels_alone
```
You will have only one posible IP which is 172.28.100.2, so you don't even need to inspect container for finding an IP.

Another way to run a container with well known IP is just to set it in command line:
```bash
docker run --privileged -v ~/.ssh/id_rsa.pub:/tmp/id_rsa.pub:ro --name fefora -d -t --ip 172.28.100.10 --network=virtual docker.io/virtainers/fedora:29
```
Pay attention that specifying IP address works for your custom networks only, not for default one (``172.17.0.0/16``)

**Using a custom network is strongly recommended while using virtainers to prevent possible clashes and networks overlaps.**

## How to run virtainer with IP from external network
TBD

### Bridges and macvlan networks
TBD

## Use cases
1. Installation of virtual machine with virtainer won't require anything to be installed on the host, except docker or
podman, it significantly simplifies workflow and make them lighter and shorter.
2. Continuous integration could be easier when using quick to setup and remove virtual machines, also it can use current
containers plugin or orchestration tools. Virtainers could be managed by any usual for you container management tool.
3. Orchestration of virtual machines can use now advanced practices from containers world, like Kubernetes for example.

Tell us about another ideas and use cases it can be helpful for you.

## What's next?
What is the roadmap:
1. Create Linux containers with X window, running VNC on startup.
2. Create a python script that will manage all command options.
3. Create an API.
4. Create a CNI networking scripts for podman networking.
...

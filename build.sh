#!/bin/bash

set -ex

SUITE=jessie
MIRROR=http://ftp.us.debian.org/debian/
ARCH=armhf

function setup {
for i in "$@"; do
  case $i in
  	-i)
  	  echo "i386 selected"
  	  ARCH=i386
  	  shift
  	  ;;
  	-a)
  	  echo "armhf selected"
  	  ARCH=armhf
  	  shift
  	  ;;
  	*)
  	  echo "Invalid selection: -$OPTARG" >&2
  	  exit 1
  	  ;;
  esac
done
}

function build_debootstrap {
  echo "=> Bulding base Debian rootfs..."
  sudo qemu-debootstrap --no-check-gpg --arch=$ARCH ${SUITE} rootfs.debootstrap/ ${MIRROR}

}

function cross_setup {
  sudo cp /usr/bin/qemu-arm-static rootfs/usr/bin/
  sudo cp /etc/resolv.conf rootfs/etc/

  sudo touch rootfs/usr/sbin/policy-rc.d
  sudo chmod a+w rootfs/usr/sbin/policy-rc.d
  echo >rootfs/usr/sbin/policy-rc.d <<EOF
echo "************************************" >&2
echo "All rc.d operations denied by policy" >&2
echo "************************************" >&2
exit 101
EOF
  sudo chmod 0755 rootfs/usr/sbin/policy-rc.d


  # mount proc, sys and dev
  sudo mount -t proc     chproc  rootfs/proc
  sudo mount -t sysfs    chsys   rootfs/sys

  sudo chroot rootfs /bin/bash <<EOF
set -x
echo -e "\
\n\
deb http://emdebian.org/tools/debian/ jessie main\
" >> /etc/apt/sources.list

  wget -qO - http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | apt-key add -
  
  dpkg --add-architecture armhf
  apt-get update
  apt-get install crossbuild-essential-armhf

}

function post_strap {
  for a in $(mount |grep $PWD|awk '{print $3}'); do sudo umount $a; done
  sudo rm -rf rootfs
  sudo mkdir rootfs
  sudo cp -a rootfs.debootstrap/* rootfs

  sudo tar -zvcf rootfs.tar.gz rootfs
}

setup || exit $?
build_debootstrap || exit $?

if [[ $ARCH = i386 ]]; then
  cross_setup || exit $?
fi

post_strap || exit $?

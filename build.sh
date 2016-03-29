#!/bin/bash

set -ex

SUITE=jessie
MIRROR=http://ftp.us.debian.org/debian/
ARCH=armhf

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



function build_debootstrap {
  if [[ ! -d rootfs.debootstrap ]]; then
	  echo "=> Bulding base Debian rootfs..."
	  sudo qemu-debootstrap --no-check-gpg --arch=$ARCH ${SUITE} rootfs.debootstrap/ ${MIRROR}
  else
	  echo "=> Recycling existing base Debian rootfs..."
  fi

  for a in $(mount |grep $PWD|awk '{print $3}'); do sudo umount $a; done
  sudo rm -rf rootfs
  sudo mkdir rootfs
  sudo cp -a rootfs.debootstrap/* rootfs

  sudo tar -zvcf rootfs.tar.gz rootfs
}

build_debootstrap || exit $?


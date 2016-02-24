#!/bin/bash

set -x

SUITE=jessie
MIRROR=http://ftp.us.debian.org/debian/

function build_debootstrap {
  if [[ ! -d rootfs.debootstrap ]]; then
	  echo "=> Bulding base Debian rootfs..."
	  #sudo qemu-debootstrap --variant=minbase --no-check-gpg --arch=armhf ${SUITE} rootfs.debootstrap/ ${MIRROR}
	  sudo qemu-debootstrap --no-check-gpg --arch=armhf ${SUITE} rootfs.debootstrap/ ${MIRROR}
  else
	  echo "=> Recycling existing base Debian rootfs..."
  fi

  for a in $(mount |grep $PWD|awk '{print $3}'); do sudo umount $a; done
  sudo rm -rf rootfs
  sudo mkdir rootfs
  sudo cp -a rootfs.debootstrap/* rootfs

  sudo chown -R $USER:$USER *

  sudo rm -rf rootfs/dev/*
  sudo rm -rf rootfs/run/*
  sudo tar -zcf rootfs.tar.gz rootfs
}

build_debootstrap || exit $?


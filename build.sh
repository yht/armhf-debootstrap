#!/bin/bash

set -x

SUITE=jessie
MIRROR=http://ftp.us.debian.org/debian/
ARCH=armhf

for a in $(mount |grep $PWD|awk '{print $3}'); do sudo umount $a; done
sudo rm -rf rootfs*
sudo rm -rf *rootfs

for var in "$@"; do
  case $var in
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
  echo "=> Bulding base Debian rootfs..."
  sudo qemu-debootstrap --no-check-gpg --arch=$ARCH ${SUITE} rootfs.debootstrap/ ${MIRROR}

}

function cross_setup {
  sudo cp /etc/resolv.conf rootfs.debootstrap/etc/

  sudo touch rootfs.debootstrap/usr/sbin/policy-rc.d
  sudo chmod a+w rootfs.debootstrap/usr/sbin/policy-rc.d
  echo >rootfs.debootstrap/usr/sbin/policy-rc.d <<EOF
echo "************************************" >&2
echo "All rc.d operations denied by policy" >&2
echo "************************************" >&2
exit 101
EOF
  sudo chmod 0755 rootfs.debootstrap/usr/sbin/policy-rc.d


  # mount proc, sys and dev
  sudo mount -t proc     chproc  rootfs.debootstrap/proc
  sudo mount -t sysfs    chsys   rootfs.debootstrap/sys

  sudo chroot rootfs.debootstrap /bin/bash <<EOF
set -x
echo -e "\
deb http://ftp.us.debian.org/debian/ jessie main\
\n\
deb http://emdebian.org/tools/debian/ jessie main\
" > /etc/apt/sources.list

  cat /etc/apt/sources.list

  wget -qO - http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | apt-key add -
  
  dpkg --add-architecture armhf
  apt-get update
  apt-get install -y crossbuild-essential-armhf
EOF
}

function post_strap {
  for a in $(mount |grep $PWD|awk '{print $3}'); do sudo umount $a; done


  if [[ $ARCH = armhf ]]; then
    mkdir rootfs
    sudo cp -a rootfs.debootstrap/* rootfs
    sudo tar -zcf rootfs.tar.gz rootfs
  else
    mkdir i386.rootfs
    sudo cp -a rootfs.debootstrap/* i386.rootfs
    sudo tar -zcf i386.rootfs.tar.gz i386.rootfs
  fi
}

build_debootstrap || exit $?

if [[ $ARCH = i386 ]]; then
  cross_setup || exit $?
fi

post_strap

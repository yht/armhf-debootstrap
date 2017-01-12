sudo apt-get update
sudo apt-get install -y qemu-user-static debootstrap wget tar

wget http://kaplan2539.gitlab.io/baumeister/qemu-arm-static.tar.gz
tar -xf qemu-arm-static.tar.gz usr/bin/qemu-arm-static
sudo mv usr/bin/qemu-arm-static /usr/bin/qemu-arm-static

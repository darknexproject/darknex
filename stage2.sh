#!/bin/sh

# i'm not good in bash, so read this with eyes closed please :D

MUSL_VER=1.2.2
HOST=x86_64-linux-musl

if [[ $(id -u) -ne 0 ]]; then
  echo "please run script as root"
  exit 1
fi

if [ -z $DESTDIR ]; then
  echo "you need to set \$DESTDIR first"
  exit 1
fi

if [ -z $MKJOBS ]; then
  echo "you need to set \$MKJOBS first"
  exit 1
fi

mkdir -p $DESTDIR/etc

cat > $DESTDIR/etc/os-release << "EOF"
NAME="Nemesis Linux"
VERSION="git"
ID=nemesis
PRETTY_NAME="Nemesis Linux git"
VERSION_CODENAME="git"
EOF

cat > $DESTDIR/etc/profile << "EOF"
export PATH=/toolchain/bin:$PATH
export DESTDIR=/
EOF

cat > $DESTDIR/etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

cat > $DESTDIR/etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF

echo "patching filesystem..."

mkdir -p $DESTDIR/usr/share $DESTDIR/proc $DESTDIR/sys $DESTDIR/dev $DESTDIR/tmp $DESTDIR/var $DESTDIR/root $DESTDIR/tmp

mount --bind /tmp $DESTDIR/tmp
mount --bind /dev $DESTDIR/dev
mount --bind /dev/shm $DESTDIR/dev/shm
mount --bind /proc $DESTDIR/proc
mount --bind /sys $DESTDIR/sys

cp /etc/resolv.conf $DESTDIR/etc/resolv.conf

if [ ! -z $ONLY_CHROOT ]; then
  chroot $DESTDIR /bin/sh
  
  umount $DESTDIR/dev/shm
  umount $DESTDIR/proc
  umount $DESTDIR/sys
  umount $DESTDIR/dev
  
  rm $DESTDIR/etc/resolv.conf

  exit 0
fi

echo "building musl..."

cat << EOF | chroot $DESTDIR /bin/sh
cd /tmp
curl -OL "http://musl.libc.org/releases/musl-$MUSL_VER.tar.gz"
tar xvpf "musl-$MUSL_VER.tar.gz"
cd "musl-$MUSL_VER"
mkdir build
cd build
source /etc/profile
../configure --prefix=/usr --host=$HOST
make -j$MKJOBS
make install
EOF

echo "patching toolchain..."

cd $DESTDIR/toolchain/bin
ln -s gcc cc

chroot $DESTDIR /bin/sh

umount $DESTDIR/dev/shm
umount $DESTDIR/proc
umount $DESTDIR/sys
umount $DESTDIR/dev
umount $DESTDIR/tmp

rm $DESTDIR/etc/resolv.conf

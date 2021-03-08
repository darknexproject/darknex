#!/bin/sh

# i'm not good in bash, so read this with eyes closed please :D

TOOLCHAIN_URL=https://musl.cc/x86_64-linux-musl-cross.tgz
# MKSH_VER=R59c
GLIBC_VER=2.33
CURL_VER=7.75.0
MAKE_VER=4.3

if [[ $(id -u) -ne 0 ]]; then
  echo "please run script as root"
  exit 1
fi

if [ -z $MKJOBS ]; then
  echo "you need to set \$MKJOBS first"
  exit 1
fi

if [ -z $DESTDIR ]; then
  echo "you need to set \$DESTDIR first"
  exit 1
fi

if [ -z $WORKDIR ]; then
  echo "you need to set \$WORKDIR first"
  exit 1
fi

if [[ "$WORKDIR" != /* ]]; then
  echo "\$WORKDIR must be absolute path"
  exit 1
fi

if [[ "$DESTDIR" != /* ]]; then
  echo "\$DESTDIR must be absolute path"
  exit 1
fi

echo "setting filesystem up..."

rm -rf $DESTDIR
mkdir -p $DESTDIR
mkdir -p $DESTDIR/usr $DESTDIR/bin $DESTDIR/lib

cd $DESTDIR
ln -s bin sbin

cd usr
ln -s ../bin
ln -s ../lib
ln -s ../bin sbin

rm -rf $WORKDIR
mkdir -p $WORKDIR

setup_toolchain() {
  echo "installing busybox..."

  curl "https://busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-x86_64" --output "$DESTDIR/bin/busybox"
  chmod +x "$DESTDIR/bin/busybox"

  cd "$DESTDIR/bin"

  ./busybox --install .

  # echo "installing mksh..."

  # cd $WORKDIR

  # curl "https://github.com/MirBSD/mksh/archive/mksh-$MKSH_VER.tar.gz" -OL
  # tar xvpf "mksh-$MKSH_VER.tar.gz"
  # cd "mksh-mksh-$MKSH_VER"
  # CFLAGS="-static" sh Build.sh -r
  # install mksh "$DESTDIR/bin/mksh"

  echo "installing static gcc toolchain..."

  cd $WORKDIR

  curl $TOOLCHAIN_URL -OL
  tar xvpf x86_64-linux-musl-cross.tgz
  mv x86_64-linux-musl-cross "$DESTDIR/toolchain"

  echo "installing static curl..."

  curl "https://github.com/moparisthebest/static-curl/releases/download/v$CURL_VER/curl-amd64" --output $DESTDIR/bin/curl -L
  chmod +x $DESTDIR/bin/curl

  echo "installing make..."

  cd $WORKDIR

  curl "https://ftp.gnu.org/gnu/make/make-$MAKE_VER.tar.gz" -OL
  tar xvpf "make-$MAKE_VER.tar.gz"
  cd "make-$MAKE_VER"
  mkdir build
  cd build
  CFLAGS="-static" ../configure \
    --prefix=/usr \
    --without-guile
  make -j$MKJOBS
  make DESTDIR=$DESTDIR install
}

echo "setting toolchain up..."
setup_toolchain

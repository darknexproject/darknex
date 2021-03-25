#!/bin/sh

# i'm not good in bash, so read this with eyes closed please :D

TOOLCHAIN_URL=https://musl.cc/x86_64-linux-musl-cross.tgz
# MKSH_VER=R59c
CURL_VER=7.75.0
MAKE_VER=4.3
ZSH_VER=5.8-6
TARGET=x86_64-linux-musl

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
  echo "installing static gcc toolchain..."
  
  cd $WORKDIR

  curl $TOOLCHAIN_URL -OL
  tar xvpf $TARGET-cross.tgz
  mv $TARGET-cross "$DESTDIR/toolchain"

  echo "installing toybox..."

  curl "http://landley.net/toybox/bin/toybox-x86_64" --output "$DESTDIR/toolchain/bin/toybox"
  chmod +x "$DESTDIR/toolchain/bin/toybox"

  cd "$DESTDIR/toolchain/bin"

  for x in $(./toybox); do
    ln -sv ./toybox $x
  done

  # echo "installing mksh..."

  # cd $WORKDIR

  # curl "https://github.com/MirBSD/mksh/archive/mksh-$MKSH_VER.tar.gz" -OL
  # tar xvpf "mksh-$MKSH_VER.tar.gz"
  # cd "mksh-mksh-$MKSH_VER"
  # CFLAGS="-static" sh Build.sh -r
  # install mksh "$DESTDIR/bin/mksh"

  echo "installing static curl..."

  curl "https://github.com/moparisthebest/static-curl/releases/download/v$CURL_VER/curl-amd64" --output $DESTDIR/toolchain/bin/curl -L
  chmod +x $DESTDIR/toolchain/bin/curl

  echo "installing make..."

  cd $WORKDIR

  curl "https://ftp.gnu.org/gnu/make/make-$MAKE_VER.tar.gz" -OL
  tar xvpf "make-$MAKE_VER.tar.gz"
  cd "make-$MAKE_VER"
  mkdir build
  cd build
  export PATH=$DESTDIR/toolchain/bin:$PATH
  CFLAGS="-static" ../configure \
    --host=$TARGET \
    --prefix=/toolchain \
    --without-guile
  make -j$MKJOBS
  make DESTDIR=$DESTDIR install

  echo "installing zsh..."

  cd $WORKDIR

  curl -OL http://ftp.us.debian.org/debian/pool/main/z/zsh/zsh-static_${ZSH_VER}_amd64.deb
  $TARGET-ar x zsh-static_${ZSH_VER}_amd64.deb
  tar xvpf "data.tar.xz"
  mv ./bin/zsh-static $DESTDIR/toolchain/bin/zsh
  cd $DESTDIR/bin
  ln -sv ../toolchain/bin/zsh sh
  ln -sv ../toolchain/bin/env env
}

echo "setting toolchain up..."
setup_toolchain

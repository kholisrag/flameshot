#!/bin/bash

set -e
set -x

umask 022

brew install qt@5 llvm
brew link --force qt@5

mkdir -pv $HOME/.local/bin
echo "$HOME/.local/bin" >> $GITHUB_PATH
export PATH="$HOME/.local/bin:$PATH"

# build `makeuniversal` tools from local qt installation first
cd $RUNNER_TEMP
git clone https://github.com/nedrysoft/makeuniversal.git
cd makeuniversal
qmake
make

chmod +x ./makeuniversal
mv ./makeuniversal $HOME/.local/bin/makeuniversal
cd ..
rm -rf makeuniversal

which makeuniversal
brew unlink qt@5

# Ref: https://gitlab.kitware.com/cmake/cmake/-/blob/master/Utilities/Release/macos/qt-5.15.2-macosx10.13-x86_64-arm64.bash
# Download, verify, and extract sources.
cd $RUNNER_TEMP
curl -sOL https://download.qt.io/archive/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz
shasum -a 256 qt-everywhere-src-5.15.2.tar.xz | grep -q 3a530d1b243b5dec00bc54937455471aaa3e56849d2593edb8ded07228202240
tar xjf qt-everywhere-src-5.15.2.tar.xz
patch -p0 < ${GITHUB_WORKSPACE}/packaging/macos/build.patch

# Build the arm64 variant.
mkdir -pv $RUNNER_TEMP/qt-5.15.2-arm64
cd $RUNNER_TEMP/qt-5.15.2-arm64
cp -R $RUNNER_TEMP/qt-everywhere-src-5.15.2/ $RUNNER_TEMP/qt-5.15.2-arm64/
./configure \
  --prefix=/ \
  -platform macx-clang \
  -device-option QMAKE_APPLE_DEVICE_ARCHS=arm64 \
  -device-option QMAKE_MACOSX_DEPLOYMENT_TARGET=11.3 \
  -release \
  -opensource -confirm-license \
  -gui \
  -widgets \
  -no-openssl \
  -securetransport \
  -no-gif \
  -no-icu \
  -no-pch \
  -no-angle \
  -no-opengl \
  -no-dbus \
  -no-harfbuzz \
  -skip declarative \
  -skip multimedia \
  -skip qtcanvas3d \
  -skip qtcharts \
  -skip qtconnectivity \
  -skip qtdeclarative \
  -skip qtgamepad \
  -skip qtlocation \
  -skip qtmultimedia \
  -skip qtnetworkauth \
  -skip qtpurchasing \
  -skip qtremoteobjects \
  -skip qtscript \
  -skip qtsensors \
  -skip qtserialbus \
  -skip qtserialport \
  -skip qtsvg \
  -skip qtwebchannel \
  -skip qtwebengine \
  -skip qtwebsockets \
  -skip qtxmlpatterns \
  -nomake examples \
  -nomake tests \
  -nomake tools
make -s -j$(sysctl -n hw.ncpu) -k
cd $HOME

# Build the x86_64 variant.
mkdir -pv $RUNNER_TEMP/qt-5.15.2-x86_64
cd $RUNNER_TEMP/qt-5.15.2-x86_64
cp -R $RUNNER_TEMP/qt-everywhere-src-5.15.2/ $RUNNER_TEMP/qt-5.15.2-x86_64/
./configure \
  --prefix=/ \
  -platform macx-clang \
  -device-option QMAKE_APPLE_DEVICE_ARCHS=x86_64 \
  -device-option QMAKE_MACOSX_DEPLOYMENT_TARGET=10.15 \
  -release \
  -opensource -confirm-license \
  -gui \
  -widgets \
  -no-openssl \
  -securetransport \
  -no-gif \
  -no-icu \
  -no-pch \
  -no-angle \
  -no-opengl \
  -no-dbus \
  -no-harfbuzz \
  -skip declarative \
  -skip multimedia \
  -skip qtcanvas3d \
  -skip qtcharts \
  -skip qtconnectivity \
  -skip qtdeclarative \
  -skip qtgamepad \
  -skip qtlocation \
  -skip qtmultimedia \
  -skip qtnetworkauth \
  -skip qtpurchasing \
  -skip qtremoteobjects \
  -skip qtscript \
  -skip qtsensors \
  -skip qtserialbus \
  -skip qtserialport \
  -skip qtsvg \
  -skip qtwebchannel \
  -skip qtwebengine \
  -skip qtwebsockets \
  -skip qtxmlpatterns \
  -nomake examples \
  -nomake tests \
  -nomake tools
make -s -j$(sysctl -n hw.ncpu) -k
cd $HOME

# Combine the two builds into universal binaries.
mkdir -pv $HOME/.local/bin/qt-5.15.2-univ
makeuniversal "$HOME/.local/bin/qt-5.15.2-univ" "$RUNNER_TEMP/qt-5.15.2-x86_64" "$RUNNER_TEMP/qt-5.15.2-arm64"
cd $HOME/.local/bin/qt-5.15.2-univ
make install -j$(sysctl -n hw.ncpu) INSTALL_ROOT=$HOME/.local/bin
export PATH="$HOME/.local/bin/qt-5.15.2-univ/bin/bin:$PATH"
which qmake

cd $HOME
curl -sOL https://github.com/Kitware/CMake/releases/download/v3.21.4/cmake-3.21.4-macos-universal.tar.gz
shasum cmake-3.21.4-macos-universal.tar.gz | grep -q f818a10fe625b215e31d0c29c19a6563fb5f51ed7cc7727e5011626c11ea321a
tar xzf cmake-3.21.4-macos-universal.tar.gz

cd cmake-3.21.4-macos-universal/CMake.app/Contents/bin
mv ./ccmake $HOME/.local/bin/ccmake
mv ./cmake $HOME/.local/bin/cmake
mv ./cpack $HOME/.local/bin/cpack
mv ./ctest $HOME/.local/bin/ctest

cd $HOME
rm -rf cmake-3.21.4-macos-universal

echo "$HOME/.local/bin/qt-5.15.2-univ/bin/bin" >> $GITHUB_PATH

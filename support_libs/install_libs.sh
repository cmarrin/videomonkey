#!/bin/sh

#
# faac - From http://www.audiocoding.com/faac.html (be sure to get the bootstrapped version)
#
tar xzf faac-1.28.tar.gz
cd faac-1.28
./configure --disable-shared
make
sudo make install
cd ..
rm -rf faac-1.28

#
# lame - From http://lame.sourceforge.net/download.php
#
tar xzf lame-3.98.4.tar.gz
cd lame-3.98.4
./configure --disable-shared
make
sudo make install
cd ..
rm -rf lame-3.98.4

#
# x264 - From http://www.videolan.org/developers/x264.html
#
bunzip2 -k x264-snapshot-20110309-2245-stable.tar.bz2
tar xf x264-snapshot-20110309-2245-stable.tar
cd x264-snapshot-20110309-2245-stable
./configure
make
sudo make install
cd ..
rm -rf x264-snapshot-20110309-2245-stable x264-snapshot-20110309-2245-stable.tar

#
# ogg - From http://xiph.org/downloads/
#
tar xzf libogg-1.2.2.tar.gz
cd libogg-1.2.2
./configure --disable-shared
make
sudo make install
cd ..
rm -rf libogg-1.2.2

#
# vorbis - From http://xiph.org/downloads/
#
tar xzf libvorbis-1.3.2.tar.gz
cd libvorbis-1.3.2
./configure --disable-shared
make
sudo make install
cd ..
rm -rf libvorbis-1.3.2

#
# theora - From http://xiph.org/downloads/
#
bunzip2 -k libtheora-1.1.1.tar.bz2
tar xf libtheora-1.1.1.tar
cd libtheora-1.1.1
./configure --disable-shared
make
sudo make install
cd ..
rm -rf libtheora-1.1.1 libtheora-1.1.1.tar

#
# yasm - From http://www.tortall.net/projects/yasm/wiki/Download
#
tar xzf yasm-1.1.0.tar.gz
cd yasm-1.1.0
./configure
make
sudo make install
cd ..
rm -rf yasm-1.1.0

#
# xvid - From http://www.xvid.org/Downloads.43.0.html
#
tar xzf xvidcore-1.3.0.tar.gz
cd xvidcore/build/generic
./configure --disable-shared --disable-assembly
make
sudo make install
cd ..
rm -rf xvidcore

#
# ffmpeg - Build from git repository at git://git.ffmpeg.org/ffmpeg.git
#
if [ -d ffmpeg ]; then
    echo "Updating ffmpeg..."
    cd ffmpeg
    git pull
else
    echo "Getting ffmpeg..."
    git clone git://git.ffmpeg.org/ffmpeg.git
fi

#!/bin/sh
cd /tmp

curl -O http://voxel.dl.sourceforge.net/sourceforge/faac/faac-1.26.zip
unzip faac-1.26.zip
cd faac
sh bootstrap
./configure --disable-shared
make
sudo make install
rm -rf faac-1.26.zip faac

curl -O http://internap.dl.sourceforge.net/sourceforge/faac/faad2-2.6.1.zip
unzip faad2-2.6.1.zip
cd faad2
sh bootstrap
./configure --disable-shared
make
sudo make install
rm -rf faad2-2.6.1.zip faad2

curl -O http://superb-east.dl.sourceforge.net/sourceforge/lame/lame-398-2.tar.gz
tar xzvf lame-398-2.tar.gz
cd lame-398-2
./configure --disable-shared
make
sudo make install
rm -rf lame-398-2.tar.gz lame-398-2

curl -O ftp://ftp.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-20081119-2245.tar.bz2
bunzip2 x264-snapshot-20081119-2245.tar.bz2
tar xvf x264-snapshot-20081119-2245.tar
cd x264-snapshot-20081119-2245
./configure
make
sudo make install
rm -rf x264-snapshot-20081119-2245.tar.bz2 x264-snapshot-20081119-2245.tar x264-snapshot-20081119-2245

curl -O http://downloads.xiph.org/releases/ogg/libogg-1.1.3.tar.gz
tar xzvf libogg-1.1.3.tar.gz
cd libogg-1.1.3
./configure --disable-shared
make
sudo make install
rm -rf xzvf libogg-1.1.3.tar.gz libogg-1.1.3

curl -O http://downloads.xiph.org/releases/vorbis/libvorbis-1.2.0.tar.gz
tar xzvf libvorbis-1.2.0.tar.gz
cd libvorbis-1.2.0
./configure --disable-shared
make
sudo make install
rm -rf xzvf libvorbis-1.2.0.tar.gz libvorbis-1.2.0

curl -O http://downloads.xiph.org/releases/theora/libtheora-1.0.zip
unzip libtheora-1.0.zip
cd libtheora-1.0
./configure --disable-shared
make
sudo make install
rm -rf xzvf libtheora-1.0.zip libtheora-1.0

curl -O http://downloads.xvid.org/downloads/xvidcore-1.1.3.tar.gz
tar xzvf xvidcore-1.1.3.tar.gz
cd xvidcore-1.1.3/build/generic
./configure --enable-macosx_module --disable-shared
curl -O http://rob.opendot.cl/wp-content/files/platform.inc
make
sudo make install
rm -rf xzvf xvidcore-1.1.3.tar.gz xvidcore-1.1.3





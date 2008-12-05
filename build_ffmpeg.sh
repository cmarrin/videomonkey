#!/bin/sh
bunzip2 -kv ffmpeg.tar.bz2
tar xvf ffmpeg.tar
rm ffmpeg.tar
cd ffmpeg
./configure --disable-ffmpeg --disable-ffplay --disable-ffserver --enable-gpl --enable-postproc --enable-swscale --enable-avfilter --enable-avfilter-lavf --disable-vhook --enable-libfaac --enable-libfaad --enable-libmp3lame --enable-libvorbis --enable-libtheora --enable-libx264 --enable-libxvid
make
sudo make install


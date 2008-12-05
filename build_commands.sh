#!/bin/sh

bunzip2 -kv ffmpeg.tar.bz2
tar xvf ffmpeg.tar
rm ffmpeg.tar
cd ffmpeg
./configure --disable-ffplay --disable-ffserver --enable-gpl --enable-postproc --enable-swscale --enable-avfilter --enable-avfilter-lavf --disable-vhook --enable-libfaac --enable-libfaad --enable-libmp3lame --enable-libvorbis --enable-libtheora --enable-libx264 --enable-libxvid
make
sudo make install
cp ffmpeg ../bin/

cd ..
rm -rf ffmpeg

gcc -O3 -I/usr/local/include -I/usr/local/include/mjpegtools -lavcodec -lavformat -lavutil -lmjpegutils -lswscale -lmp3lame -lz -ltheora -logg -lvorbis -lx264 -lxvidcore -lfaac -lfaad -lvorbisenc -lbz2 toyuv.c -o toyuv
cp toyuv bin/

gcc -O3 -L/usr/local/lib -I/usr/local/include/mjpegtools -lmjpegutils yuvadjust.c -o yuvadjust
cp yuvadjust bin/

#!/bin/sh

bunzip2 -kv ffmpeg.tar.bz2
tar xvf ffmpeg.tar
rm ffmpeg.tar
cp ffmpeg.c ffmpeg-0.5.1
cd ffmpeg-0.5.1
./configure --disable-ffplay --disable-ffserver --enable-gpl --enable-libxvid --enable-libmp3lame --enable-libvorbis --enable-libfaac --enable-libfaad --enable-nonfree --enable-pthreads --enable-swscale --enable-avfilter --enable-avfilter-lavf --enable-libtheora --enable-libx264 --enable-postproc 

make
sudo make install
cp ffmpeg ../bin/

cd ..
rm -rf ffmpeg-0.5.1

gcc -O3 -I/usr/local/include -I/usr/local/include/mjpegtools -lavcodec -lavformat -lavutil -lmjpegutils -lswscale -lmp3lame -lz -ltheora -logg -lvorbis -lx264 -lxvidcore -lfaac -lfaad -lvorbisenc -lbz2 toyuv.c -o toyuv
cp toyuv bin/

gcc -O3 -L/usr/local/lib -I/usr/local/include/mjpegtools -lmjpegutils yuvadjust.c -o yuvadjust
cp yuvadjust bin/

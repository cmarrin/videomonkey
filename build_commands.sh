#!/bin/sh

bunzip2 -kv ffmpeg.tar.bz2
tar xvf ffmpeg.tar
rm ffmpeg.tar
cp ffmpeg.c ffmpeg-0.5.1
cd ffmpeg-0.5.1
./configure --disable-ffplay --disable-ffserver --enable-gpl --enable-pthreads --enable-version3 \
--enable-libmp3lame --enable-libx264 --enable-avfilter --enable-libxvid \
--enable-libfaac --enable-nonfree --enable-swscale \
--enable-postproc \
--enable-libtheora --enable-libvorbis --enable-filters --enable-runtime-cpudetect --arch=x86 \
--disable-doc --enable-static --disable-shared


--enable-libspeex --enable-libvpx --disable-decoder=libvpx --enable-libtheora --enable-libvorbis 
--enable-filters --enable-runtime-cpudetect

--arch=x86

--enable-libopencore_amrwb 


--enable-gpl --enable-pthreads --enable-version3 --enable-libspeex --enable-libvpx --disable-decoder=libvpx \
--enable-libmp3lame --enable-libtheora --enable-libvorbis --enable-libx264 --enable-avfilter \
--enable-libopencore_amrnb --enable-filters --arch=x86 --enable-runtime-cpudetect



make
sudo make install
cp ffmpeg ../bin/

cd ..
rm -rf ffmpeg-0.5.1

gcc -O3 -I/usr/local/include -I/usr/local/include/mjpegtools -lavcodec -lavformat -lavutil -lmjpegutils -lswscale -lmp3lame -lz -ltheora -logg -lvorbis -lx264 -lxvidcore -lfaac -lfaad -lvorbisenc -lbz2 toyuv.c -o toyuv
cp toyuv bin/

gcc -O3 -L/usr/local/lib -I/usr/local/include/mjpegtools -lmjpegutils yuvadjust.c -o yuvadjust
cp yuvadjust bin/

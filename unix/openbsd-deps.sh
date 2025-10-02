#!/bin/sh -e

pkg_add -u

pkg_add cmake ninja bison gawk gsed wget \
	libiconv libogg libvorbis flac libsndfile \
	opus mpg123 pulseaudio libusb1-1.0.27 lxrandr\
	unzip-6.0p18-iconv
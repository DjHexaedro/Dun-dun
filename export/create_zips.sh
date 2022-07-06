#!/bin/sh

cd /home/djhexaedro/proyectos/tetractys/export

cd linux
if [ -z "$1" ]
    then
        rm ../dundun_linux.zip 2> /dev/null
        zip ../dundun_linux.zip dundun.x86_64 dundun.pck
else
    rm ../dundun_linux_stable.zip 2> /dev/null
    zip ../dundun_linux_stable.zip dundun.x86_64 dundun.pck
fi


cd ../windows
if [ -z "$1" ]
    then
        rm ../dundun_windows.zip 2> /dev/null
        zip ../dundun_windows.zip dundun.exe dundun.pck
else
    rm ../dundun_windows_stable.zip 2> /dev/null
    zip ../dundun_windows_stable.zip dundun.exe dundun.pck
fi


cd ../mac
if [ -z "$1" ]
    then
        rm ../dundun_osx.zip 2> /dev/null
        cp dundun.x86_64.zip ../dundun_osx.zip
else
    rm ../dundun_osx_stable.zip 2> /dev/null
    cp dundun.x86_64.zip ../dundun_osx_stable.zip
fi


cd ../html5
if [ -z "$1" ]
    then
        rm ../dundun_html.zip 2> /dev/null
        zip ../dundun_html.zip *
else
    rm ../dundun_html_stable.zip 2> /dev/null
    zip ../dundun_html_stable.zip *
fi


#!/usr/bin/env bash

builddir=`readlink -f .`
version=${1:?You must enter a MediaCenter version.}
release=`sed -nre "s/.*:([0-9]+)$/\1/gp" /etc/system-release-cpe`
variation=${version##*.}
mversion=${version%%.*}

bold=$(tput bold)
normal=$(tput sgr0)

echo "${bold}Checking for RPMFusion repos${normal}"

rpm --quiet --query rpmfusion-free-release || sudo dnf -y --nogpgcheck install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
rpm --quiet --query rpmfusion-nonfree-release || sudo dnf -y --nogpgcheck install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

echo "${bold}Checking for rpm-build${normal}"

if ! rpm -qa --nosignature | grep -qw "rpm-build-[0-9]"; then
    echo "${bold}Attempting to install rpm-build package...${normal}"
    sudo dnf install rpm-build -y
fi

echo "${bold}Checking for dpkg${normal}"

if ! rpm -qa --nosignature | grep -qw dpkg; then
    echo "${bold}Attempting to install dpkg...${normal}"
    sudo dnf install dpkg -y
fi

echo "${bold}Making build directories${normal}"
mkdir -p SOURCES SPECS

echo "${bold}Creating input files${normal}"

# Create SPEC file

echo 'Name:    MediaCenter' > SPECS/mediacenter.spec
echo 'Version: %{_tversion}' >> SPECS/mediacenter.spec
echo 'Release: %{?_variation:%{_variation}}%{?dist}' >> SPECS/mediacenter.spec
echo 'Summary: JRiver Media Center' >> SPECS/mediacenter.spec
echo 'Group:   Applications/Media' >> SPECS/mediacenter.spec
echo "Source0: http://files.jriver.com/mediacenter/channels/v${mversion}/latest/MediaCenter-%{_version}-amd64.deb" >> SPECS/mediacenter.spec
echo "Source1: mediacenter${mversion}.desktop" >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo 'BuildRequires: rpm >= 4.12.0' >> SPECS/mediacenter.spec
echo 'BuildRequires: dpkg' >> SPECS/mediacenter.spec
echo 'BuildArch: x86_64' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo 'AutoReq:  0' >> SPECS/mediacenter.spec
echo 'Requires: libnotify librtmp lame vorbis-tools alsa-lib' >> SPECS/mediacenter.spec
echo 'Requires: libX11 libX11-common libxcb libXau libXdmcp libuuid' >> SPECS/mediacenter.spec
echo 'Requires: gtk3 mesa-libGL gnutls lame libgomp webkit2gtk3' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo 'License: Copyright 1998-2013, JRiver, Inc.  All rights reserved.  Protected by U.S. patents #7076468 and #7062468' >> SPECS/mediacenter.spec
echo 'URL:     http://www.jriver.com/' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo '%description' >> SPECS/mediacenter.spec
echo 'Media Center is more than a world class player.' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo '%prep' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo '%build' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo '%install' >> SPECS/mediacenter.spec
echo 'dpkg -x %{S:0} %{buildroot}' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo '%post -p /sbin/ldconfig' >> SPECS/mediacenter.spec
echo '%postun -p /sbin/ldconfig' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo '%files' >> SPECS/mediacenter.spec
echo "%{_bindir}/mediacenter${mversion}" >> SPECS/mediacenter.spec
echo '"%{_libdir}/jriver"' >> SPECS/mediacenter.spec
echo '%{_datadir}' >> SPECS/mediacenter.spec

# Create .desktop file

echo '[Desktop Entry]' > SOURCES/mediacenter${mversion}.desktop
echo 'Name=Media Center' >> SOURCES/mediacenter${mversion}.desktop
echo 'GenericName=Music Player' >> SOURCES/mediacenter${mversion}.desktop
echo "X-GNOME-FullName=JRiver Media Center ${mversion}" >> SOURCES/mediacenter${mversion}.desktop
echo "Comment=JRiver Media Center ${mversion}" >> SOURCES/mediacenter${mversion}.desktop
echo 'Keywords=Audio;Song;MP3;CD;Podcast;MTP;iPod;Playlist;Last.fm;UPnP;DLNA;Radio;' >> SOURCES/mediacenter${mversion}.desktop
echo "Exec=mediacenter${mversion} %U" >> SOURCES/mediacenter${mversion}.desktop
echo 'Terminal=false' >> SOURCES/mediacenter${mversion}.desktop
echo 'Type=Application' >> SOURCES/mediacenter${mversion}.desktop
echo "Icon=/usr/lib/jriver/Media Center ${mversion}/Data/Default Art/Application.ico" >> SOURCES/mediacenter${mversion}.desktop
echo 'Categories=GNOME;GTK;AudioVideo;' >> SOURCES/mediacenter${mversion}.desktop
echo 'MimeType=application/x-ogg;application/ogg;audio/x-vorbis+ogg;audio/x-scpls;audio/x-mp3;audio/x-mpeg;audio/mpeg;audio/ape;audio/x-ape;audio/mac;audio/x-mpegurl;audio/x-flac;x-scheme-handler/itms;' >> SOURCES/mediacenter${mversion}.desktop
echo 'StartupNotify=true' >> SOURCES/mediacenter${mversion}.desktop
echo 'X-GNOME-UsesNotifications=false' >> SOURCES/mediacenter${mversion}.desktop
echo "StartupWMClass=Media Center ${mversion}" >> SOURCES/mediacenter${mversion}.desktop
echo '' >> SOURCES/mediacenter${mversion}.desktop
echo "Name[en_US]=mediacenter${mversion}" >> SOURCES/mediacenter${mversion}.desktop

echo "${bold}Checking for source DEB..."

if [ ! -f $builddir/SOURCES/MediaCenter-${version}-amd64.deb ] ; then
    echo "${bold}Downloading source DEB...${normal}"
	wget -O $builddir/SOURCES/MediaCenter-${version}-amd64.deb http://files.jriver.com/mediacenter/channels/v${mversion}/latest/MediaCenter-${version}-amd64.deb
fi

echo "${bold}Found source DEB!${normal}"

cd ${builddir}/SPECS

echo "${bold}Converting DEB to RPM...${normal}"

rpmbuild --define="%_topdir $builddir" --define="%_variation $variation" --define="%_tversion ${mversion}" --define="%_version ${version}" --define="%_libdir /usr/lib" -bb mediacenter.spec > /dev/null 2>&1

if [ -f $builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.fc${release}.x86_64.rpm ] ; then
	echo "${bold}Attempting to install RPM...${normal}"
	sudo dnf install $builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.fc${release}.x86_64.rpm -y && echo "${bold}JRiver Media Center ${version} installed successfully!${normal}"
else
    echo "${bold}Conversion Failed!${normal}"
fi


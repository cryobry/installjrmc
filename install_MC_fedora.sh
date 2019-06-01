#!/usr/bin/env bash
shopt -s extglob

# Usage: ./install_MC_fedora.sh [-v|--version] [version] [-a|--auto] [-b|--build-only] [-i|--install-repo]
# e.g. ./install_MC_fedora.sh -v 25.0.41
# If no version number is specified (i.e. ./install_MC_fedora.sh or ./install_MC_fedora.sh --build-only), automatic mode will be attempted

# URL for latest MC for Linux board (for automatic version scraping)
boardurl="https://yabb.jriver.com/interact/index.php/board,62.0.html"

##########################
####### FUNCTIONS ########
##########################

parse_inp () {
    # clear user vars
    build_only_mode=false
    auto_mode=false
    install_mode=false

    # parse user input
    while (( "$#" )); do
        case "$1" in
            -i |--install-repo )
                echo "Installing repo file!"
                install_mode=true
                ;;
            -a |--auto )
                echo "Using auto mode!"
                auto_mode=true
                ;;
            -b |--build-only )
                echo "Using build-only mode!"
                build_only_mode=true
                ;;
            -v |--version )
                echo "Using manual mode!"
                shift
                version="$1"
                ;;
            +([0-9]).[0-9].+([0-9]) )
                echo "Using manual mode!"
                version="$1"
        esac
        shift
    done

    # if no version number specified, enter auto_mode
    [ -z $version ] && [ $auto_mode == false ] %% [ $install_mode == false ] && echo "Using auto mode!" && auto_mode=true
}


find_os () {

    if [ $build_only_mode == false ]; then
        if [ -e /etc/os-release ]; then
            source /etc/os-release
            if [ $ID = "centos" ] && [ "$VERSION_ID" -ge "8" ]; then
                ID="el"
                SID="el"
                PM="yum"
            elif [ $ID = "fedora" ]; then
                ID="fedora"
                SID="fc"
                PM="dnf"
            elif [ $install_mode == false ]; then
                echo "You are not running Fedora or CentOS >=8, falling back to build-only mode..."
                build_only_mode=true
            fi
        elif [ $install_mode == false ]; then
            echo "You are not running Fedora or CentOS >=8, falling back to build-only mode..."
            build_only_mode=true
        fi
    fi
}


get_source_deb () {

    # Skip if in install mode
    [ $install_mode == true ] && return

    # Get version number from user input or scrape Interact
    if [ $auto_mode == true ]; then
        version=$(curl -s "${boardurl}" | grep -o "2[0-9]\.[0-9]\.[0-9]\+" | head -n 1)
        while [ -z ${version} ]; do
            read -p "Version number cannot be scraped, re-enter it now manually, otherwise Ctrl-C to exit: " version
        done
    fi

    # parse version number
    variation=${version##*.}
    mversion=${version%%.*}

    # in automatic mode and build only mode, skip building/reinstalling the same version
    if [ $auto_mode == true ]; then
        if [ $build_only_mode == true ]; then
            if [ -f $builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.x86_64.rpm ]; then
                echo "$builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.x86_64.rpm already exists!"
                exit 0
            fi
        else
            installed_ver="$(rpm --quiet --query MediaCenter)"
            to_be_installed_ver="MediaCenter-${mversion}-${variation}.${SID}${VERSION_ID}.x86_64"
            if [ "${installed_ver}" == "${to_be_installed_ver}" ]; then
                echo "MediaCenter-${mversion}-${variation}.${SID}${VERSION_ID}.x86_64 is already installed!"
                exit 0
            fi
        fi
    fi

    # Acquire DEB if missing
    if [ -f $builddir/SOURCES/MediaCenter-${version}-amd64.deb ]; then
        echo "Using local DEB file: $builddir/SOURCES/MediaCenter-${version}-amd64.deb"
    else
        echo "Downloading source DEB..."
        wget -O $builddir/SOURCES/MediaCenter-${version}-amd64.deb http://files.jriver.com/mediacenter/channels/v${mversion}/latest/MediaCenter-${version}-amd64.deb
        if [ $? -ne 0 ]; then
            echo "Specified Media Center version not found! Retrying the test repo..."
            wget -O $builddir/SOURCES/MediaCenter-${version}-amd64.deb http://files.jriver.com/mediacenter/test/MediaCenter-${version}-amd64.deb
            while [ $? -ne 0 ]; do
                read -p "Not found in test repo, if beta version, enter beta password to retry, otherwise Ctrl-C to exit: " betapwd
                wget -O $builddir/SOURCES/MediaCenter-${version}-amd64.deb http://files.jriver.com/mediacenter/channels/v${mversion}/beta/${betapwd}/MediaCenter-${version}-amd64.deb
            done
        fi
    fi
}


install_dependencies () {

    # Skip if in install mode
    [ $install_mode == true ] && return

    if [ $build_only_mode == false ]; then
        if ! rpm --quiet --query rpmfusion-free-release; then echo "Installing rpmfusion-free-release repo..."; \
            sudo ${PM} -y --nogpgcheck install https://download1.rpmfusion.org/free/${ID}/rpmfusion-free-release-${VERSION_ID}.noarch.rpm; fi
        if ! rpm --quiet --query rpm-build; then echo "Installing rpm-build..."; sudo ${PM} install rpm-build -y; fi
        if ! rpm --quiet --query dpkg; then echo "Installing dpkg..."; sudo ${PM} install dpkg -y; fi
    else
        command -v rpmbuild >/dev/null 2>&1 || { echo "Please install rpmbuild, cannot continue, aborting..." >&2; exit 1; }
        command -v dpkg >/dev/null 2>&1 || { echo "Please install dpkg, cannot continue, aborting..." >&2; exit 1; }
    fi
}


build_rpm () {

    # Skip if in install mode
    [ $install_mode == true ] && return

    # If necessary, make build directories
    [ -d SOURCES ] || mkdir -p SOURCES
    [ -d SPECS ] || mkdir -p SPECS

    # Create spec file
    echo 'Name:    MediaCenter' > SPECS/mediacenter.spec
    echo 'Version: %{_tversion}' >> SPECS/mediacenter.spec
    echo 'Release: %{?_variation:%{_variation}}%{?dist}' >> SPECS/mediacenter.spec
    echo 'Summary: JRiver Media Center' >> SPECS/mediacenter.spec
    echo 'Group:   Applications/Media' >> SPECS/mediacenter.spec
    echo "Source0: http://files.jriver.com/mediacenter/channels/v${mversion}/latest/MediaCenter-%{_version}-amd64.deb" >> SPECS/mediacenter.spec
    echo '' >> SPECS/mediacenter.spec
    if [ $build_only_mode == false ]; then
        echo 'BuildRequires: rpm >= 4.11.0' >> SPECS/mediacenter.spec
        echo 'BuildRequires: dpkg' >> SPECS/mediacenter.spec
    fi
    echo 'BuildArch: x86_64' >> SPECS/mediacenter.spec
    echo '' >> SPECS/mediacenter.spec
    echo 'AutoReq:  0' >> SPECS/mediacenter.spec
    echo 'Requires: libnotify librtmp lame vorbis-tools alsa-lib' >> SPECS/mediacenter.spec
    echo 'Requires: libX11 libX11-common libxcb libXau libXdmcp libuuid' >> SPECS/mediacenter.spec
    echo 'Requires: gtk3 mesa-libGL gnutls lame libgomp webkit2gtk3 ca-certificates' >> SPECS/mediacenter.spec
    echo 'Requires: gstreamer1 gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-ugly gstreamer1-libav' >> SPECS/mediacenter.spec
    echo '' >> SPECS/mediacenter.spec
    echo 'License: Copyright 1998-2019, JRiver, Inc.  All rights reserved.  Protected by U.S. patents #7076468 and #7062468' >> SPECS/mediacenter.spec
    echo 'URL:     http://www.jriver.com/' >> SPECS/mediacenter.spec
    echo '' >> SPECS/mediacenter.spec
    echo '%description' >> SPECS/mediacenter.spec
    echo 'Media Center is more than a world class player.' >> SPECS/mediacenter.spec
    echo '' >> SPECS/mediacenter.spec
    echo '%global __os_install_post %{nil}' >> SPECS/mediacenter.spec
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
    echo '%{_libdir}/jriver' >> SPECS/mediacenter.spec
    echo '%{_datadir}' >> SPECS/mediacenter.spec
    echo '/etc/security/limits.d/*' >> SPECS/mediacenter.spec

    # Run rpmbuild
    cd ${builddir}/SPECS
    rpmbuild --quiet --define="%_topdir $builddir" --define="%_variation $variation" --define="%_tversion ${mversion}" \
             --define="%_version ${version}" --define="%_libdir /usr/lib" -bb mediacenter.spec
}


install_rpm () {

    # Install mode
    if [ $install_mode == true ]; then

        echo "Attempting to install repo file"
        sudo bash -c 'cat << EOF > /etc/yum.repos.d/jriver.repo
[jriver]
name=JRiver Media Center repo by BryanC
baseurl=https://repos.bryanroessler.com/jriver
gpgcheck=0
EOF'
        echo "Attempting to install JRiver Media Center version ${version} from repo..."
        sudo ${PM} update && sudo ${PM} install MediaCenter -y

    elif [ -f $builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.${SID}${VERSION_ID}.x86_64.rpm ]; then
        echo "Attempting to install version ${version}..."
        sudo ${PM} install $builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.${SID}${VERSION_ID}.x86_64.rpm -y && echo "JRiver Media Center ${version} installed successfully!"
    else
        echo "$builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.${SID}${VERSION_ID}.x86_64.rpm is missing!"
        echo "Installation Failed!"
        exit 1
    fi

    # Symlink certificates
    if [ ! -e /etc/ssl/certs/ca-certificates.crt ] && [ -e /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem ]; then
        echo "Symlinking ca-certificates for license registration..."
        sudo ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/ssl/certs/ca-certificates.crt
    fi
}



##########################
######## EXECUTE #########
##########################

# set build directory to current path
builddir="$(pwd)"
parse_inp "${@}"
find_os
get_source_deb
install_dependencies
echo "Building version ${version}, please wait..."
build_rpm
[ $build_only_mode == false ] && install_rpm

exit 0

#!/bin/bash

REFRESH=false
DIR="./certs"
DONE=false

function download {
    url=$1
    folder=$2

    if [ -x "$(which wget)" ] ; then
        wget -q $url -P $folder
    else
        echo "Could not find wget, please install one." >&2
    fi
}

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
fi

OS=${OS,,}

####################################################################
# Get arguments
####################################################################

while getopts 'r' flag; do
  case "${flag}" in
    r) REFRESH=true ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

####################################################################
# Chech if certificates should be downloaded
####################################################################

if [[ ! -d "$DIR" ]] || [[ -z `ls -A "$DIR"` ]]; then
     read -p "Do you want to download certificates? [Y/n] " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
          REFRESH=true
      fi
else
    echo "Certificates already downloaded"
fi

####################################################################
# Download certificates 
####################################################################

if [ "$REFRESH" = true ] ; then
  rm -r $DIR; mkdir $DIR;


  if ! [ -x "$(which jq)" ] ; then
        echo "Could not find jq, please install one." >&2
        exit 1
    fi

  # copy(Array.from(document.querySelectorAll('.roots tr a')).map(a => a.href).filter(a => a.includes('/DigiCert')).filter(a => a.endsWith('.pem')))
  cat ./certs.json | jq -r '.[]' | while read object; do
      download $object ./certs
  done
fi

####################################################################
# Chech if the system is Ubuntu, if yes symlink mozilla certs
####################################################################

if [ "$OS" == "ubuntu" ]; then
  read -p "Are you running Ubuntu? [Y/n] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
      sudo ln -s /usr/share/ca-certificates/mozilla/* /opt/Citrix/ICAClient/keystore/cacert
      DONE=true
      exit 
  fi
fi

####################################################################
# Chech if the system is Fedora
####################################################################

if [ "$OS" == "fedora" ]; then
  read -p "Are you running Fedora? [Y/n] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
      DONE=true
  fi
fi


if [ "$DONE" = false ] ; then
  echo "Looks like your distro '$OS' is not suported/tested at the moment. Or something went wrong."
  echo "Contact marko@weareneopix.com"
fi

####################################################################
# On Fedora and other distros copy the certs folder
####################################################################

if [ "$DONE" = true ] ; then
  sudo cp ./certs/* /opt/Citrix/ICAClient/keystore/cacerts/
fi
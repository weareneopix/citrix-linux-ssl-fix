#!/bin/bash

REFRESH=false
DIR="./certs"
DONE=false
DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)

function download {
    url=$1
    folder=$2

    if [ -x "$(which wget)" ] ; then
        wget -q $url -P $folder
    else
        echo "Could not find wget, please install one." >&2
    fi
}

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

if [ "$DISTRO" == "Ubuntu" ]; then
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

if [ "$DISTRO" == "Fedora" ]; then
  read -p "Are you running Fedora? [Y/n] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
      DONE=true
  fi
fi


if [ "$DONE" = false ] ; then
  echo "Looks like your distro '$DISTRO' is not suported/tested at the moment. Or something went wrong."
  echo "Contact marko@weareneopix.com"
fi

####################################################################
# On Fedora and other distros copy the certs folder
####################################################################

if [ "$DONE" = true ] ; then
  sudo cp ./certs/* /opt/Citrix/ICAClient/keystore/cacerts/
fi
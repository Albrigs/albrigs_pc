#!/bin/bash

ppa_exists() #remove trecho de loop se ppa já estiver instalado
{
	apt policy | grep $1
	if [ $? != 0 ]; then continue ; fi
}


# Tirando travas do apt
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock
sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com 241FE6973B765FAE

#Repositórios não nativos
PPAS=("webupd8team/atom")

for e in ${PPAS[@]} 
do 
ppa_exists $e
sudo add-apt-repository ppa:${e}

done 


#arquitetura 32 bits
sudo dpkg --add-architecture i386
sudo apt update
sudo apt upgrade
sudo apt --fix-broken install

is_online=$(ping -c 1 -q 8.8.8.8 >&/dev/null; echo $?)

if [ $is_online != 0 ]
then
	echo "You are offline, this script will not work."
	exit
fi

#PACOTES
APT_PKGS=( "snapd" "flathub" "python3.8" "default-jdk" "openjdk-8-jdk" "python3-pip" "npm" "lua" "jupyter-notebook" "love" "ffmpeg" "okular" "audacity" "transmission" "firefox" "apt-transport-https" "preload" "putty" "telegram-desktop" "discord" "xclip" "nano" "dia" "krita" "inkskape" "scribus" "git" "ppa-purge" "gufw" "xz-utils" "clamav" "font-manager" "libreoffice" "retroarch" "wget" "unzip" "bash" "atom" "featherpad")

)

PIP_PKGS=( "pyinstaller" "virtualenv" "jupyterthemes" )

SNAP_PKGS=( "hugo" "insomnia" )

#TODO Selecionar pacotes
ATOM_PKGS=( )

for e in ${SNAP_PKGS[@]}; do if ! dpkg -l | grep -q $e; then sudo apt -f -y install $e; fi; done
for e in ${PIP_PKGS[@]}; do sudo pip3 install $e; done
for e in ${PIP_PKGS[@]}; do sudo snap install $e; done
for e in ${ATOM_PKGS[@]}; do apm install $e; done


flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.github.libresprite.LibreSprite

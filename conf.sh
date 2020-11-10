#!/bin/bash

#Script só inicia se estiver conectado a internet
is_online=$(ping -c 1 -q 8.8.8.8 >&/dev/null; echo $?)
if [ $is_online != 0 ]
then
	echo "You are offline, this script will not work."
	exit
fi


PPA_EXISTS() #remove trecho de loop se ppa já estiver instalado
{
	apt policy | grep $1
	wait $!
	if [ $? != 0 ]; then continue ; fi
}


# Tirando travas do apt
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock
sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com 241FE6973B765FAE


#Repositórios não nativos
PPAS=("webupd8team/atom")
for e in ${PPAS[@]}; do clear;  PPA_EXISTS $e; sudo sudo add-apt-repository ppa:${e}; done 

apt policy | grep dart
if [ $? != 0 ]; then
	sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
	sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
fi

apt policy | grep spotify
if [ $? != 0 ]; then
	curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | sudo apt-key add - 
	echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
fi

#arquitetura 32 bits
sudo dpkg --add-architecture i386
sudo apt update; sudo apt upgrade
sudo apt --fix-broken install
clear

APT_INSTALL()
{
	clear;  if ! dpkg -l | grep -q $1; then sudo apt -f -y install $1; fi
}

#PACOTES
APT_PKGS=( "snapd" "flathub" "python3.8" "default-jdk" "openjdk-8-jdk" "python3-pip" "python" "python-pip" "npm" "lua" "jupyter-notebook" "love" "ffmpeg" "okular" "audacity" "transmission" "firefox" "apt-transport-https" "preload" "putty" "telegram-desktop" "discord" "xclip" "nano" "dia" "krita" "git" "ppa-purge" "gufw" "xz-utils" "clamav" "font-manager" "retroarch" "wget" "unzip" "bash" "featherpad", "spotify-client" "dart" "steam")
PIP_PKGS=( "pyinstaller" "virtualenv" "jupyterthemes" )
SNAP_PKGS=( "hugo" "insomnia" )
NPM_PKGS=( "npx" "nextron" )
FLATHUB_PKGS=( 
"com.github.libresprite.LibreSprite"
)

for e in ${APT_PKGS[@]}; APT_INSTALL $e; done
for e in ${PIP_PKGS[@]}; do clear; sudo pip3 install $e; done
for e in ${SNAP_PKGS[@]}; do clear; sudo snap install $e; done
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; clear
for e in ${FLATHUB_PKGS[@]}; do clear; flatpak install -y flathub $e; done
for e in ${NPM_PKGS[@]}; do clear; sudo npm i -g $e; done; clear

sudo curl -fsSL https://deno.land/x/install/install.sh | sh; clear


#Adicionando shells que serão carregados no login.
#TODO Adicionar
SH_URLS=(
 "https://raw.githubusercontent.com/Albrigs/albrigs_pc/main/login_files/custom_path.sh"
)
if [ -d /etc/profile.d ]
then
	for e in ${SH_URLS[@]};do clear; sudo wget -P /etc/profile.d $e; done
fi


#escolhendo versões padrão quando há alternativas
ALTS=( "java" "python" "pip" )
for e in ${ALTS[@]}; do clear; sudo update-alternatives --config $e; done

#Meu GYT
if [ -f master.zip ]; then rm master.zip ; fi
wget https://github.com/Albrigs/gyt/archive/master.zip
unzip master.zip; rm master.zip
sudo pip3 install e gyt-master
sudo rm -r gyt-master

#Text Editor

ROOT_SIZE=$(df | grep "/$" | cut -d " " -f 3)
ROOT_SIZE=$(echo $(($ROOT_SIZE/1000000)))

if [ $ROOT_SIZE -lt 100 ]; then
	# Se meu root for menor que 100 gb vai instalar sublime
	HAS_SUBLIME=$(apt search sublime-text)
	wait $!
	echo $HAS_SUBLIME | grep sublime-text

	if [ $? != 0 ] then 
		sudo snap install sublime-text --classic
	else
		APT_INSTALL sublime-text
	fi
else
	# Se meu root for maior vai instalar atom
	APT_INSTALL atom
	
	ATOM_PKGS=( "emmet" "ask-stack" "git-time-machine" "highlight-selected" "advanced-open-file" "file-icons" "pigments" "color-picker" "python-snippets" "python-jedi" "language-babel" "react-es6-snippets" "react-es7-snippets" "autocomplete-modules" "data-atom" "love-ide" )
	for e in ${ATOM_PKGS[@]}; do clear; apm install $e; done
	
	#libre-office apenas quando tem mais espaço
	APT_INSTALL libreoffice
fi
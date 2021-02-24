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

APT_INSTALL()
{
	clear;  if ! dpkg -l | grep -q $1; then sudo apt -f -y install $1; fi
}

PKG_IN_APT()
{
	HAS =$(apt search $1)
	wait $!
	grep -w $1 $HAS
	echo $?
	return	
}

GDEBI_INSTALL()
{
	which $1
	if [ $? != 1 ]; then
		DEB_PATH= "~/${1}.deb"
		wget -O  $DEB_PATH $2
		sudo gdebi -n $DEB_PATH 
		sudo rm -r $DEB_PATH
	fi

}


# Tirando travas do apt
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock
sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com 241FE6973B765FAE


#Repositórios não nativos
PPAS=("webupd8team/atom" "lutris-team/lutris" "oguzhaninan/stacer")
for e in ${PPAS[@]}; do clear;  PPA_EXISTS $e; sudo sudo add-apt-repository ppa:${e}; done 

#Spotfy
if [ "$(PKG_IN_APT spotify)" != 0 ]; then
	curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | sudo apt-key add - 
	echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
fi

#Sublime Text
if [ "$(PKG_IN_APT sublime-text)" != 0 ] then
	wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
	echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
fi 

#Insomnia
if [ "$(PKG_IN_APT insomnia)" != 0 ] then
	echo "deb https://dl.bintray.com/getinsomnia/Insomnia /" | sudo tee -a /etc/apt/sources.list.d/insomnia.list
	wget --quiet -O - https://insomnia.rest/keys/debian-public.key.asc | sudo apt-key add -

fi 

##
#if [ "$(PKG_IN_APT )" != 0 ] then
#fi

#arquitetura 32 bits
sudo dpkg --add-architecture i386
sudo apt update; sudo apt upgrade
sudo apt --fix-broken install
clear

#Necessidades no GalliumOS
uname -or | grep galliu
if [ $? != 0 ]; then
	PKGS_SMOL=( "lightdm" "xfwm4" )
	PKGS_REMOVE=( "lxdm" "appgrid" "audaciou*" "atri*" )
	
	for e in ${PKGS_SMOL[@]}; do APT_INSTALL $e; done
	for e in ${PKGS_REMOVE[@]}; do sudo apt remove -y $e; done
# bspwm herbstluftwm

fi


#PACOTES
APT_PKGS=( "gdebi" "insomnia" "sublime-text" "sqlitebrowser" "wmctrl" "xdotool" "flathub" "nodejs" "python3.8" "default-jdk" "openjdk-8-jdk" "python3-pip" "python" "python-pip" "npm" "lua" "jupyter-notebook" "love" "ffmpeg" "okular" "audacity" "transmission" "firefox" "apt-transport-https" "preload" "putty" "telegram-desktop" "discord" "xclip" "nano" "dia" "krita" "git" "ppa-purge" "gufw" "xz-utils" "clamav" "font-manager" "retroarch" "wget" "unzip" "bash" "featherpad", "spotify-client" "dart" "sed" "stacer" )
PIP_PKGS=( "pyinstaller" "virtualenv" "jupyterthemes" )
NPM_PKGS=( "npx" "nextron" )
FLATHUB_PKGS=( 
"com.github.libresprite.LibreSprite"
"com.github.marktext.marktext"
)


for e in ${APT_PKGS[@]}; APT_INSTALL $e; done
for e in ${PIP_PKGS[@]}; do clear; sudo pip3 install $e; done
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; clear
for e in ${FLATHUB_PKGS[@]}; do clear; flatpak install -y flathub $e; done
for e in ${NPM_PKGS[@]}; do clear; sudo npm i -g $e; done; clear

#Discord
wget -O ~/discord.deb "https://discordapp.com/api/download?platform=linux&format=deb"
sudo gdebi -n ~/discord.deb 
sudo rm -r ~/discord.deb



#navegador min
wget -O ~/min.deb "https://github.com/minbrowser/min/releases/download/v1.17.1/min_1.17.1_amd64.deb"
sudo gdebi -n -i ~/min.deb
sudo rm -r ~/min.deb

#DENO
sudo curl -fsSL https://deno.land/x/install/install.sh | sh; clear




#Adicionando shells que serão carregados no login.
#TODO Adicionar
SH_URLS=(
 "https://raw.githubusercontent.com/Albrigs/albrigs_pc/main/login_files/custom_path.sh"
)
if [ -d /etc/profile.d ]; then
	for e in ${SH_URLS[@]};do clear; sudo wget -P /etc/profile.d $e; done
fi


SH_COMMANDS=(
	"https://raw.githubusercontent.com/Albrigs/albrigs_pc/main/command_files/update_all"
	"https://raw.githubusercontent.com/Albrigs/albrigs_pc/main/command_files/clear_all"
)
if [ -d /usr/bin ]; then
	for e in ${SH_COMMANDS[@]};do
		clear
		sudo wget -P /usr/bin $e;
		FILE_NAME=$(echo $e | cut -d "/" -f 8)
		sudo chmod -x "/usr/bin/$FILE_NAME"
	done
fi

#Alterar tema jupyter
jt -t chesterish

#escolhendo versões padrão quando há alternativas
ALTS=( "java" "python" "pip" "x-www-browser" )
for e in ${ALTS[@]}; do clear; sudo update-alternatives --config $e; done


#Visualizador de DBS
wget https://dbvis.com/product_download/dbvis-11.0.5/media/dbvis_linux_11_0_5.sh -O dbvis.sh
chmod a+x dbvis.sh
./dbvis.sh
rm dbvis.sh


#Meu GYT
if [ -f master.zip ]; then rm master.zip ; fi
wget https://github.com/Albrigs/gyt/archive/master.zip
unzip master.zip; rm master.zip
sudo pip3 install e gyt-master
sudo rm -r gyt-master


#Heavy thins
ROOT_SIZE=$(df | grep "/$" | cut -d " " -f 3)
ROOT_SIZE=$(echo $(($ROOT_SIZE/1000000)))

if [ $ROOT_SIZE -gt 100 ]; then
	# Se meu root for maior vai instalar pacotes pesados
	wget -nc https://dl.winehq.org/wine-builds/winehq.key
	sudo apt-key add winehq.key
	VERSION=$( cat /etc/os-release | grep VERSION_CODENAME | cut -d "=" -f 2 )
	sudo add-apt-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ ${VERSION} main"
	clear; sudo apt update -y; clear
	sudo apt install -y --install-recommends winehq-stable

	HEAVY_PKGS=( "libreoffice" "lutris" "steam" )
	for e in ${HEAVY_PKGS}; do APT_INSTALL $e; done
fi

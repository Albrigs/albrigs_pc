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
PPAS=("webupd8team/atom" "lutris-team/lutris" "oguzhaninan/stacer")
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


#Necessidades no GalliumOS
uname -or | grep galliu
if [ $? != 0 ]; then
	PKGS_SMOL=( "lightdm" "xfwm4" )
	PKGS_REMOVE=( "lxdm" "chromiu*" "appgrid" "audaciou*" "atri*" )
	
	for e in ${PKGS_SMOL[@]}; do APT_INSTALL $e; done
	for e in ${PKGS_REMOVE[@]}; do sudo apt remove -y $e; done
# bspwm herbstluftwm

fi


#PACOTES
APT_PKGS=( "snapd" "flathub" "python3.8" "default-jdk" "openjdk-8-jdk" "python3-pip" "python" "python-pip" "npm" "lua" "jupyter-notebook" "love" "ffmpeg" "okular" "audacity" "transmission" "firefox" "apt-transport-https" "preload" "putty" "telegram-desktop" "discord" "xclip" "nano" "dia" "krita" "git" "ppa-purge" "gufw" "xz-utils" "clamav" "font-manager" "retroarch" "wget" "unzip" "bash" "featherpad", "spotify-client" "dart" "sed" "stacer" )
PIP_PKGS=( "pyinstaller" "virtualenv" "jupyterthemes" )
SNAP_PKGS=( "hugo" "insomnia" )
NPM_PKGS=( "npx" "nextron" )
FLATHUB_PKGS=( 
"com.github.libresprite.LibreSprite"
"flathub com.github.marktext.marktext"
)


for e in ${APT_PKGS[@]}; APT_INSTALL $e; done
for e in ${PIP_PKGS[@]}; do clear; sudo pip3 install $e; done
for e in ${SNAP_PKGS[@]}; do clear; sudo snap install $e; done
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; clear
for e in ${FLATHUB_PKGS[@]}; do clear; flatpak install -y flathub $e; done
for e in ${NPM_PKGS[@]}; do clear; sudo npm i -g $e; done; clear


sudo curl -fsSL https://deno.land/x/install/install.sh | sh; clear


#navegador min
wget https://github.com/minbrowser/min/releases/download/v1.17.1/min_1.17.1_amd64.deb
sudo dpkg -i min_1.17.1_amd64.deb
sudo rm -r min_1.17.1_amd64.deb


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

	SUBLIME_FOLDER="~/.config/sublime-text-3/Packages/"
	SUBL_PACKAGES=(
		"https://github.com/braver/ColorHints/archive/master.zip"
		"https://github.com/braver/FileIcons/archive/master.zip"
		"https://github.com/Wramberg/TerminalView/archive/master.zip"
		"https://github.com/kiteco/KiteSublime/archive/master.zip"
		"https://github.com/sergeche/emmet-sublime/archive/master.zip"
		"https://github.com/jugyo/SublimeColorSchemeSelector/archive/master.zip"
		"https://github.com/titoBouzout/SideBarEnhancements/archive/st3.zip"
		"https://github.com/skuroda/Sublime-AdvancedNewFile/archive/master.zip"
	)


	for e in ${SUBL_PACKAGES[@]}; do wget -P $SUBLIME_FOLDER $e; done
	unzip "${SUBLIME_FOLDER}/*.zip" 
	sudo rm -r "${SUBLIME_FOLDER}/*.zip"


else
	# Se meu root for maior vai instalar pacotes pesados
	wget -nc https://dl.winehq.org/wine-builds/winehq.key
	sudo apt-key add winehq.key
	VERSION=$( cat /etc/os-release | grep VERSION_CODENAME | cut -d "=" -f 2 )
	sudo add-apt-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ ${VERSION} main"
	clear; sudo apt update; clear
	sudo apt install --install-recommends winehq-stable


	HEAVY_PKGS=( "atom" "libreoffice" "lutris" "steam" )
	for e in ${HEAVY_PKGS}; do APT_INSTALL $e; done


	ATOM_PKGS=( "emmet" "ask-stack" "git-time-machine" "highlight-selected" "advanced-open-file" "file-icons" "pigments" "color-picker" "python-snippets" "python-jedi" "language-babel" "react-es6-snippets" "react-es7-snippets" "autocomplete-modules" "data-atom" "love-ide" )
	for e in ${ATOM_PKGS[@]}; do clear; apm install $e; done

fi

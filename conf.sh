#!/bin/bash

#Script só inicia se estiver conectado a internet
is_online=$(ping -c 1 -q 8.8.8.8 >&/dev/null; echo $?)


if [ $is_online != 0 ]
then
	echo "You are offline, this script will not work."
	exit
fi


PPA_EXISTS()
{
	#Remove trecho de loop se ppa já estiver instalado
	#$1 : ppa
	apt policy | grep $1
	wait $!
	if [ $? != 0 ]; then continue ; fi
}

APT_INSTALL()
{
	#Instala um pacote via APT caso ele ainda nao tenha sido instalado
	#$1 : nome do pacote
	clear;  if ! dpkg -l | grep -q $1; then sudo apt -f -y -qq install $1; fi
}

#pacotes fundamentias
APT_INSTALL jq
APT_INSTALL sed

PKG_IN_APT()
{
	#Verifica se um pacote esta presente na busca do apt.
	#$1 : nome do pacote
	HAS =$(apt search $1)
	wait $!
	grep -w $1 $HAS
	echo $?
	return	
}

GDEBI_INSTALL()
{
	#Instala um pacote via gdebi caso ainda nao tenha sido instalado
	#$1 : nome do pacote
	which $1
	if [ $? != 1 ]; then
		DEB_PATH= "~/${1}.deb"
		wget -O  $DEB_PATH $2
		sudo gdebi -n $DEB_PATH 
		sudo rm -r $DEB_PATH
	fi

}

#URLs importantes
PROJECT_URL="https://raw.githubusercontent.com/Albrigs/albrigs_pc/main/"
PACKAGES_URL="${PROJECT_URL}pkgs.json"

#Pegando json com listas de pacotes a serem instalados
PACKAGES=$(curl -sS $PACKAGES_URL)
wait $!


GET_PACKAGES()
{
	#Filtra json e retorna uma lista compativel com bash
	#$1 : .nome_do_gerenciador_de_pacotes
	echo $PACKAGES | jq $1 | jq '.[]' | sed 's/"//g'
	return
}

ADD_APT_PKG()
{
	#Adiciona pacote a lista de pacotes do apt
	#1 : nome do pacote
	#2 : URL da chave
	#3 : URL do .deb
	curl -sS $2 | sudo tee "/etc/apt/sources.list.d/${1}.list"
	echo "deb ${3}" | sudo apt-key add - 
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
	ADD_APT_PKG 'spotify' 'https://download.spotify.com/debian/pubkey_0D811D58.gpg' 'http://repository.spotify.com stable non-free'
fi

#Sublime Text
if [ "$(PKG_IN_APT sublime-text)" != 0 ] then
	ADD_APT_PKG 'sublime-text' 'https://download.sublimetext.com/sublimehq-pub.gpg' 'https://download.sublimetext.com/ apt/stable/'
fi 

#Insomnia
if [ "$(PKG_IN_APT insomnia)" != 0 ] then
	ADD_APT_PKG 'insomnia' 'https://insomnia.rest/keys/debian-public.key.asc' 'https://dl.bintray.com/getinsomnia/Insomnia /'
fi 


##
#if [ "$(PKG_IN_APT )" != 0 ] then
#fi

#arquitetura 32 bits
sudo dpkg --add-architecture i386
sudo apt update -y -qq; sudo apt upgrade -y -qq
sudo apt --fix-broken install -qq
clear


#PACOTES
APT_PKGS=$( GET_PACKAGES '.apt')
PIP_PKGS=$(GET_PACKAGES '.pip')
NPM_PKGS=$(GET_PACKAGES '.npm')
FLATHUB_PKGS=$(GET_PACKAGES '.flathub')


for e in ${APT_PKGS[@]}; APT_INSTALL $e; done
for e in ${PIP_PKGS[@]}; do clear; sudo pip3 install $e; done
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; clear
for e in ${FLATHUB_PKGS[@]}; do clear; flatpak install -y flathub $e; done
for e in ${NPM_PKGS[@]}; do clear; sudo npm i -g $e; done; clear

#Discord
GDEBI_INSTALL "discord" "https://discordapp.com/api/download?platform=linux&format=deb"

#navegador min
GDEBI_INSTALL "min" "https://github.com/minbrowser/min/releases/download/v1.17.1/min_1.17.1_amd64.deb"

#DENO
sudo curl -fsSL https://deno.land/x/install/install.sh | sh; clear

#Node version manager
sudo curl -sS https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash



#Adicionando scripts que serão carregados no login.
SH_LOGIN=(
 "${PROJECT_URL}login_files/custom_path.sh"
)
if [ -d /etc/profile.d ]; then
	for e in ${SH_LOGIN[@]};do clear; sudo wget -P /etc/profile.d $e; done
fi

#Adicionando scripts que executam comandos no terminal
COMMAND_URL="${PROJECT_URL}command_files/"
SH_COMMANDS=(
	"${COMMAND_URL}update_all"
	"${COMMAND_URL}clear_all"
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
	WINE_PPA="deb https://dl.winehq.org/wine-builds/ubuntu/ ${VERSION} main"
	ADD_APT_PKG 'winehq' "https://dl.winehq.org/wine-builds/winehq.key" $WINE_PPA
	sudo apt update -y -qq;
	sudo apt install -y -qq --install-recommends winehq-stable

	HEAVY_PKGS=$(GET_PACKAGES '.heavy')
	for e in ${HEAVY_PKGS}; do APT_INSTALL $e; done
fi

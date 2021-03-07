#!/bin/bash

#Script só inicia se estiver conectado a internet
is_online=$(ping -c 1 -q 8.8.8.8 >&/dev/null; echo $?)
if [ $is_online != 0 ]; then echo "You are offline, this script will not work."; exit; fi

#Variaveis do Script
#URLs Base
PROJECT_URL="https://raw.githubusercontent.com/Albrigs/albrigs_pc/main/"
CONFIG_URL="${PROJECT_URL}base.yaml"
LOGINS_URL="${PROJECT_URL}login_files/"
COMMAND_URL="${PROJECT_URL}command_files/"

#Infos basicas do sistema
ROOT_SIZE=$(df | grep "/$" | cut -d " " -f 3)
ROOT_SIZE=$(echo $(($ROOT_SIZE/1000000)))

curl -sS $CONFIG_URL > base.yaml


PPA_EXISTS()
{
	#Remove trecho de loop se ppa já estiver instalado
	#$1 : ppa
	apt policy | grep $1; wait $!
	if [ $? != 0 ]; then continue ; fi
}


APT_INSTALL()
{
	#Instala um pacote via APT caso ele ainda nao tenha sido instalado
	#$1 : nome do pacote
	clear;  if ! dpkg -l | grep -q $1; then apt -f -y -qq install $1; fi
}


PKG_IN_APT()
{
	#Verifica se um pacote esta presente na busca do apt.
	#$1 : nome do pacote
	HAS=$(apt search $1); wait $!
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
		wget -O  $DEB_PATH $2; wait $!
		gdebi -n $DEB_PATH
		rm -r $DEB_PATH
	fi

}


GET_CONFIG(){
	TMP=$(yq r base.yaml "${1}")
	echo $TMP
	return
}


GET_CONFIG_LENGTH(){
	TMP=$(yq r base.yaml "${1}" -l)
	echo $TMP
	return
}


ADD_APT_PKG()
{
	#Adiciona pacote a lista de pacotes do apt
	#1 : nome do pacote
	#2 : URL da chave
	#3 : URL do .deb
	wget -qO $2 | tee "/etc/apt/sources.list.d/${1}.list"
	echo "deb ${3}" | apt-key add -

}


SH_INSTALL()
{
	#Instala pacote atraves de um SH online
	#1 : url do script
	curl -sS $1 | bash
}


# Tirando travas do apt
rm /var/lib/dpkg/lock-frontend; rm /var/cache/apt/archives/lock
apt-key adv --recv-key --keyserver keyserver.ubuntu.com 241FE6973B765FAE
# Repositórios não nativos
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64
# Arquitetura 32 bits
dpkg --add-architecture i386
apt update -y -qq; apt upgrade -y -qq
apt --fix-broken install -qq
clear

#pacotes fundamentias
APT_INSTALL yq


PPAS=$(GET_CONFIG ppa);


for e in ${PPAS[@]}; do clear;  PPA_EXISTS $e; add-apt-repository -y ppa:${e}; done


NUM_EXT_REPOS=$(GET_CONFIG_LENGTH external_repos)
for i in $(seq 1 $NUM_EXT_REPOS); do

	i=$(expr $i - 1)

	TMP_NAME=$(GET_CONFIG external_repos[$i].name)
	TMP_KEY=$(GET_CONFIG external_repos[$i].key)
	TMP_URL=$(GET_CONFIG external_repos[$i].url)

	ADD_APT_PKG "${TMP_NAME}" "${TMP_KEY}" "${TMP_URL}"

done


#PACOTES
APT_PKGS=$(GET_CONFIG 'apt')
PIP_PKGS=$(GET_CONFIG 'pip')
NPM_PKGS=$(GET_CONFIG 'npm')
FLATHUB_PKGS=$(GET_CONFIG 'flathub')
NUM_GDEBI_REPOS=$(GET_CONFIG_LENGTH gdebi_software)
SH_INSTALL_URL=$(GET_CONFIG sh_install)


for e in ${APT_PKGS[@]}; do echo $e; APT_INSTALL $e; done
for e in ${PIP_PKGS[@]}; do clear; pip3 install $e; done
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; clear
for e in ${FLATHUB_PKGS[@]}; do clear; flatpak install -y flathub $e; done
for e in ${NPM_PKGS[@]}; do clear; npm i -g $e; done; clear

for i in $(seq 1 $NUM_GDEBI_REPOS); do
	i=$(expr $i - 1)
	TMP_NAME=$(GET_CONFIG gdebi_software[$i].name)
	TMP_URL=$(GET_CONFIG gdebi_software[$i].url)

	GDEBI_INSTALL $TMP_NAME $TMP_URL
done

for e in ${SH_INSTALL_URL[@]}; do echo 1; SH_INSTALL $e; done


#Adicionando scripts que serão carregados no login.
SH_LOGIN=$(GET_CONFIG sh_login)
if [ -d /etc/profile.d ]; then
	for e in ${SH_LOGIN[@]};do clear; wget -P /etc/profile.d "${LOGINS_URL}${e}"; done
fi

#Adicionando scripts que executam comandos no terminal
SH_COMMANDS=$(GET_CONFIG sh_commands)
if [ -d /usr/bin ]; then
	for e in ${SH_COMMANDS[@]};do
		clear; wget -P /usr/bin "${COMMAND_URL}${e}"; chmod -x "/usr/bin/${e}"
	done
fi


#Meu GYT
if [ -f master.zip ]; then rm master.zip ; fi
wget https://github.com/Albrigs/gyt/archive/master.zip
unzip master.zip; rm master.zip
pip3 install e gyt-master/
rm -r gyt-master


#Heavy thins
if [ $ROOT_SIZE -gt 100 ]; then
	#Alterar tema jupyter
	jt -t chesterish

	# Se meu root for maior vai instalar pacotes pesados
	WINE_PPA="deb https://dl.winehq.org/wine-builds/ubuntu/ ${VERSION} main"
	ADD_APT_PKG 'winehq' "https://dl.winehq.org/wine-builds/winehq.key" $WINE_PPA
	apt update -y -qq;
	apt install -y -qq --install-recommends winehq-stable

	HEAVY_PKGS=$(GET_CONFIG 'heavy')
	for e in ${HEAVY_PKGS}; do APT_INSTALL $e; done
fi

# Ajustaodn quantidade de watches
echo fs.inotify.max_user_watches=524288 | tee -a /etc/sysctl.conf && sysctl -p

rm -r base.yaml

#escolhendo versões padrão quando há alternativas
ALTS=$(GET_CONFIG alternatives)
for e in ${ALTS[@]}; do clear; update-alternatives --config $e; done

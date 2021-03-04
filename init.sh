set -e
#!/bin/bash

#Script só inicia se estiver conectado a internet
is_online=$(ping -c 1 -q 8.8.8.8 >&/dev/null; echo $?)
if [ $is_online != 0 ]; then echo "You are offline, this script will not work."; exit; fi

#Variaveis do Script
#URLs Base
PROJECT_URL="https://raw.githubusercontent.com/Albrigs/albrigs_pc/main/"
PACKAGES_URL="${PROJECT_URL}pkgs.yaml"
CONFIG_URL="${PROJECT_URL}base.yaml"
LOGINS_URL="${PROJECT_URL}login_files/"
COMMAND_URL="${PROJECT_URL}command_files/"

#Infos basicas do sistema
ROOT_SIZE=$(df | grep "/$" | cut -d " " -f 3)
ROOT_SIZE=$(echo $(($ROOT_SIZE/1000000)))

#Pegando infos base
PACKAGES=$(curl -sS $PACKAGES_URL); wait $!
CONFIG=$(curl -sS $CONFIG_URL); wait $!




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
	clear;  if ! dpkg -l | grep -q $1; then sudo apt -f -y -qq install $1; fi
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
		sudo gdebi -n $DEB_PATH
		sudo rm -r $DEB_PATH
	fi

}


GET_PACKAGES()
{
	#Filtra yml e retorna uma lista compativel com bash
	#$1 : atributo
	echo $PACKAGES | yq r - "${1}"
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


SH_INSTALL()
{
	#Instala pacote atraves de um SH online
	#1 : url do script
	sudo curl -sS $1 | bash
}


# Tirando travas do apt
sudo rm /var/lib/dpkg/lock-frontend; sudo rm /var/cache/apt/archives/lock
sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com 241FE6973B765FAE
# Repositórios não nativos
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64
# Arquitetura 32 bits
sudo dpkg --add-architecture i386
sudo apt update -y -qq; sudo apt upgrade -y -qq
sudo apt --fix-broken install -qq
clear

#pacotes fundamentias
APT_INSTALL yq


PPAS=$(echo $CONFIG | yq r - ppa); wait $!;

echo $PPAS
exit

for e in ${PPAS[@]}; do clear;  PPA_EXISTS $e; sudo sudo add-apt-repository ppa:${e}; done


NUM_EXT_REPOS=$(echo $CONFIG | yq r - external_repos -l)
for i in $(seq 1 $NUM_EXT_REPOS); do
	TMP_NAME=$(echo $CONFIG | yq r - external_repos[$i].name)
	TMP_KEY=$(echo $CONFIG | yq r - external_repos[$i].key)
	TMP_URL=$(echo $CONFIG | yq r - external_repos[$i].url)

	if [ "$(PKG_IN_APT "${TMP_NAME}")" != 0 ]; then
		ADD_APT_PKG "${TMP_NAME}" "${TMP_KEY}" "${TMP_URL}"
	fi
done


#PACOTES
APT_PKGS=$(GET_PACKAGES 'apt')
PIP_PKGS=$(GET_PACKAGES 'pip')
NPM_PKGS=$(GET_PACKAGES 'npm')
FLATHUB_PKGS=$(GET_PACKAGES 'flathub')
NUM_GDEBI_REPOS=$(echo $CONFIG | yq r - gdebi_software -l)
SH_INSTALL_URL=$(echo $CONFIG | yq r - sh_install)


for e in ${APT_PKGS[@]}; do echo $e; APT_INSTALL $e; done
for e in ${PIP_PKGS[@]}; do clear; sudo pip3 install $e; done
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; clear
for e in ${FLATHUB_PKGS[@]}; do clear; flatpak install -y flathub $e; done
for e in ${NPM_PKGS[@]}; do clear; sudo npm i -g $e; done; clear

for i in $(seq 1 $NUM_GDEBI_REPOS); do
	TMP_NAME=$(echo $CONFIG | yq r - gdebi_software[$i].name)
	TMP_URL=$(echo $CONFIG | yq r - gdebi_software[$i].url)

	GDEBI_INSTALL $TMP_NAME $TMP_URL
done

for e in ${SH_INSTALL_URL[@]}; do echo 1; SH_INSTALL $e; done


#Adicionando scripts que serão carregados no login.
SH_LOGIN=$(echo $CONFIG | yq r - sh_login)
if [ -d /etc/profile.d ]; then
	for e in ${SH_LOGIN[@]};do clear; sudo wget -P /etc/profile.d "${LOGINS_URL}${e}"; done
fi

#Adicionando scripts que executam comandos no terminal
SH_COMMANDS=$(echo $CONFIG | yq r - sh_commands)
if [ -d /usr/bin ]; then
	for e in ${SH_COMMANDS[@]};do
		clear; sudo wget -P /usr/bin "${COMMAND_URL}${e}"; sudo chmod -x "/usr/bin/${e}"
	done
fi


#Meu GYT
if [ -f master.zip ]; then rm master.zip ; fi
wget https://github.com/Albrigs/gyt/archive/master.zip
unzip master.zip; rm master.zip
sudo pip3 install e gyt-master/
sudo rm -r gyt-master


#Heavy thins
if [ $ROOT_SIZE -gt 100 ]; then
	#Alterar tema jupyter
	jt -t chesterish

	# Se meu root for maior vai instalar pacotes pesados
	WINE_PPA="deb https://dl.winehq.org/wine-builds/ubuntu/ ${VERSION} main"
	ADD_APT_PKG 'winehq' "https://dl.winehq.org/wine-builds/winehq.key" $WINE_PPA
	sudo apt update -y -qq;
	sudo apt install -y -qq --install-recommends winehq-stable

	HEAVY_PKGS=$(GET_PACKAGES 'heavy')
	for e in ${HEAVY_PKGS}; do APT_INSTALL $e; done
fi

# Ajustaodn quantidade de watches
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p


#escolhendo versões padrão quando há alternativas
ALTS=$(echo $CONFIG | yq r - alternatives)
for e in ${ALTS[@]}; do clear; sudo update-alternatives --config $e; done

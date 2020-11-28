$MYIP="$(dig +short myip.opendns.com @resolver1.opendns.com)"

WIFI_STATE=$(iwconfig | grep ESSID | cut -d ":" -f 2| cut -d "/" -f 1); clear
if [ $WIFI_STATE != "off" ]; then
	WIFI_FREQUENCY=$(iwconfig | grep "Frequency:" | cut -d ":" -f 3 | cut -d " " -f 1 | cut -d "." -f 1)
	WIFI_SPEED=$(iwconfig | grep "Bit Rate" | cut -d "=" -f 2 | cut -d "T" -f 1)
	clear
	echo "VERIFICANDO CONEXAO DE WIFI"
	echo "IPV4: ${MYPI}"
	echo "Teto de velocidade do computador: ${WIFI_SPEED}"
	echo "Rede: ${WIFI_FREQUENCY} GHZ"
fi
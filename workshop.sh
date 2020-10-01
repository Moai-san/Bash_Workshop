#!/bin/bash
#LEONARDO GONZALEZ 
case "$1" in 
	-ps)
		maxPid=$(cat /proc/sys/kernel/pid_max)
		printf "\033[1mUID\t\tPID\tPPID\tStatus\tCMD\033[0m\n"
		for((i=0;i<$maxPid;i=$((i+1))))
			do
				if [ -n "$i" -a -e /proc/$i ]; then
					echo -n $USER
					cat /proc/"$i"/stat | awk '{printf"\t%d\t%d\t%c\t%s\n",$1,$4,$3,$2}'
				fi
			done	
	;;
	-psBlocked)
		printf '\033[1m%s\t%-15s\t%s\033[0m\n' "PID" "NOMBRE PROCESO" "TIPO" #cabecera
		lines=$(cat /proc/locks | wc -l) #cuentalineas
		for ((i=1;i<=$lines;i=$((i+1)))) #imprimo Tipo FLOCK
			do
				Type=$(head -"$i" /proc/locks | tail -1)
				PID=$(echo $Type | awk '{ print $5 }')
				Type=$(echo $Type | awk '{ print $2 }')
				if [[ $Type == "FLOCK" ]]; then
					PName=$(cat /proc/$PID/status | head -1)
					PName=$(echo $PName | cut -c 7- /dev/stdin)
					printf '%s\t%-15s\t%s\n' $PID $PName $Type
				fi
			done
		for ((i=1;i<=$lines;i=$((i+1)))) #imprimo Tipo POSIX
			do
				Type=$(head -"$i" /proc/locks | tail -1)
				PID=$(echo $Type | awk '{ print $5 }')
				Type=$(echo $Type | awk '{ print $2 }')
				if [ $Type == "POSIX" ]; then
					PName=$(cat /proc/$PID/status | head -1)
					PName=$(echo $PName | cut -c 7- /dev/stdin)
					printf '%s\t%-15s\t%s\n' $PID $PName $Type
				fi
			done
	;;
	-m)
		printf "\033[1mTotal\t\tAvailable\033[0m\n"
		cat /proc/meminfo |grep "MemTotal" | awk '{v1 = 1048576;printf"%.1f\t\t",$2/v1}'
		cat /proc/meminfo |grep "MemAvailable" | awk '{v1 = 1048576;printf"%.1f\n",$2/v1}'
	;;
	-tcp)
		lines=$(cat /proc/net/tcp | wc -l) #cuentalineas
		printf '\033[1m%-15s:%-5s\t%-15s:%-5s\t%s\033[0m\n' Source Port Destination Port Status #cabecera
		for((i=2;i<=$lines;i=$((i+1))))
			do
				
				localIp=$(head -"$i" /proc/net/tcp | tail -1) #extraigo la linea numero i(indice del for)
				localIp=$(echo $localIp | awk '{ print $2 }') #saco solo la ip+puerto
				localPort=$(echo $localIp | cut -c 10-14 /dev/stdin) #dejo el puerto solo para convertirlo
				localIp=$(echo $localIp | cut -c 1-8 /dev/stdin) #dejo la ip sola para convertirla
				localIp=$(printf '%d.%d.%d.%d\n' $(echo $localIp | sed 's/../0x& /g' | tr ' ' '\n' | tac)) #convierto la ip en hex a decimal punteado
				localPort=$(echo "obase=10; ibase=16; $localPort" | bc) #convierto puerto en hex, a decimal


				printf '%-15s:%-5s\t' $localIp $localPort #printeo Source:Port

				
				outIp=$(head -"$i" /proc/net/tcp | tail -1) #extraigo la linea numero i(indice del for)
				outIp=$(echo $outIp | awk '{ print $3 }') #saco solo la ip+puerto
				outPort=$(echo $outIp | cut -c 10-14 /dev/stdin) #dejo el puerto solo para convertirlo
				outIp=$(echo $outIp | cut -c 1-8 /dev/stdin) #dejo la ip sola para convertirla
				outIp=$(printf '%d.%d.%d.%d\n' $(echo $outIp | sed 's/../0x& /g' | tr ' ' '\n' | tac)) #convierto la ip en hex a decimal punteado
				outPort=$(echo "obase=10; ibase=16; $outPort" | bc) #convierto puerto en hex, a decimal


				printf '%-15s:%-5s' $outIp $outPort #printeo Destination:Port


				status=$(head -"$i" /proc/net/tcp | tail -1) #extraigo la linea numero i(indice del for)
				status=$(echo $status | awk '{ print $4 }') #saco solo el parametro status ($4)
				case $status in #printeo segun status con switch
					01)
						printf "\tTCP_ESTABLISHED\n"
					;;
					02)
						printf "\tTCP_SYN_SENT\n"
					;;
					03)
						printf "\tTCP_SYN_RECV\n"
					;;
					04)
						printf "\tTCP_FIN_WAIT1\n"
					;;
					05)
						printf "\tTCP_FIN_WAIT2\n"
					;;
					06)
						printf "\tTCP_TIME_WAIT\n"
					;;
					07)
						printf "\tTCP_CLOSE\n"
					;;
					08)
						printf "\tTCP_CLOSE_WAIT\n"
					;;
					09)
						printf "\tTCP_LAST_ACK\n"
					;;
					0A)
						printf "\tTCP_LISTEN\n"
					;;
					0B)
						printf "\tTCP_CLOSING\n"
					;;
					0C)
						printf "\tTCP_NEW_SYN_RECV\n"
					;;
				esac
			done

	;;
	-tcpStatus)
		printf '\033[1m%-15s:%-5s\t%-15s:%-5s\t%s\033[0m\n' Source Port Destination Port Status #cabecera
		bash workshop.sh -tcp > file.txt #para no programar innecesariamente, llamamos a la funcion tcp y generamos un txt con la salida de esta
		sed -i "1d" file.txt #eliminamos su cabecera, ya que esta quedaría al final del archivo una vez hecho el sort
		sort -k 5n file.txt #aplicamos la funcion sort que viene incluida en el shell de unix, la cual con el parametro -k ordena el archivo segun la cantidad de bits en la columna especificada (5)
		#por lo que quedaran ordenadas por estado.
		unlink file.txt #eliminamos el archivo una vez usado
	;;
	-help)
		printf "Al ejecutar \033[95msin parametros\033[0m, se muestra informacion general del computador (\033[92mProcesador\033[0m, \033[92mVersion de Kernel\033[0m, \033[92mMemoria Ram Instalada (En KiloBytes)\033[0m y \033[92muptime (tiempo encendido de la maquina)\033[0m.)\n"
		printf "Al ejecutar con el parametro \033[95m-ps\033[0m, se muestra informacion de los procesos en ejecucion (\033[92mUID\033[0m,\033[92mPID\033[0m,\033[92mPPID\033[0m,\033[92mSTATUS\033[0m y \033[92mCMD\033[0m)\n"
		printf "Al ejecutar con el parametro \033[95m-psBlocked\033[0m, se muestra los procesos bloqueados, \033[92magrupados por tipo de bloqueo\033[0m\n"
		printf "Al ejecutar con el parametro \033[95m-m\033[0m, se muestra la cantidad de memoria \033[92mRAM Instalada\033[0m, y la cantidad de memoria \033[92mRAM disponible\033[0m\n"
		printf "Al ejecutar con el parametro \033[95m-tcp\033[0m, se muestra informacion respecto a las conexiones TCP (\033[92mIp de Salida\033[0m + \033[92mPuerto\033[0m, \033[92mIp de Entrada\033[0m + \033[92mPuerto\033[0m ,\033[92mStatus de la Conexion\033[0m).\n"
		printf "Al ejecutar con el parametro \033[95m-tcpStatus\033[0m, se muestran las conexiones TCP, agrupada por Estado\n"
		printf "Al ejecutar con el parametro \033[95m-help\033[0m, se muestra informacion respecto a como usar el Script.\n"
	;;
		*) 	
		cat /proc/cpuinfo | grep "model name" | head -1| awk '{print "\033[1mModelName: \033[0m" $4,$5,$6,$7,$9}'
		cat /proc/version | awk '{print "\033[1mKernelVersion: \033[0m" $3}'
		cat /proc/meminfo | grep "MemTotal" | awk '{print "\033[1mMemory (kB): \033[0m" $2,$3}'
		cat /proc/uptime | awk '{v1=86400;printf"\033[1mUptime (Days): \033[0m%.3f\n",$1/v1}'
	;;
esac


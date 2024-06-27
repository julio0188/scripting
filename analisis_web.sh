#!/bin/bash

#Se hacen validaciones de aplicaciones, si no existen solicitara instalacion
#------------------------Inicio---------------------------------------------
# Array de programas a verificar
programas=("jq" "curl" "nmap" "wafw00f")

# Función para verificar si un programa está instalado
programa_instalado() {
    if command -v "$1" &> /dev/null
    then
        echo "true"
    else
        echo "false"
    fi
}

# Función para verificar si todos los programas están instalados
todos_programas_instalados() {
    for programa in "${programas[@]}"
    do
        if [ $(programa_instalado "$programa") == "false" ]; then
            return 1
        fi
    done
    return 0
}

# Bucle hasta que todos los programas estén instalados
while true
do
    # Verificar si todos los programas están instalados
    if todos_programas_instalados; then
        echo "Todos los programas están instalados."
        break
    fi

    # Recorrer el array de programas
    for programa in "${programas[@]}"
    do
        if [ $(programa_instalado "$programa") == "true" ]; then
            echo "$programa ya está instalado."
        else
            read -p "$programa no está instalado. ¿Desea instalarlo? (s/n): " respuesta
            if [ "$respuesta" == "s" ] || [ "$respuesta" == "S" ]; then
                sudo apt-get update
                sudo apt-get install -y "$programa"
            else
                echo "No se instalará $programa."
            fi
        fi
    done

    echo "Revisando nuevamente..."
done

#---------------FIN de validacion de aplicaciones-------------------------
#==========================================================================


# Define tu clave de API de URLScan.io aquí
API_KEY="TU_CLAVE_API"

# Definir las variables para cada sitio web en un arreglo
sitios=("irsi.education" "n")

# Declarar un arreglo asociativo para almacenar los UUIDs de URLScan.io asociados a cada sitio
declare -A uuid_por_sitio

# Función para mostrar los sitios web
mostrar_sitios() {
    for sitio in "${sitios[@]}"; do
        echo "Sitio web: $sitio"
    done
}

# Función para analizar los sitios web con wafw00f
analizar_con_wafw00f() {
    for sitio in "${sitios[@]}"; do
        echo "Analizando $sitio con wafw00f..."
        wafw00f $sitio
    done
}

# Función para analizar puertos abiertos con nmap
analizar_con_nmap() {
    for sitio in "${sitios[@]}"; do
        echo "Analizando puertos abiertos en $sitio con nmap..."
        nmap -Pn $sitio
    done
}

# Función para enviar URLs a URLScan.io
enviar_a_urlscan() {
    for sitio in "${sitios[@]}"; do
        echo "Enviando $sitio a URLScan.io..."
        response=$(curl -s --request POST --url 'https://urlscan.io/api/v1/scan/' \
        --header "Content-Type: application/json" \
        --header "API-Key: $API_KEY" \
        --data "{\"url\": \"$sitio\", \"customagent\": \"US\"}")
        uuid=$(echo $response | jq -r '.uuid')
        if [ "$uuid" != "null" ]; then
            echo "UUID de URLScan.io para $sitio: $uuid"
            uuid_por_sitio["$sitio"]=$uuid
        else
            echo "Error al enviar $sitio a URLScan.io. Respuesta: $response"
        fi
    done
}

# Función para obtener resultados de URLScan.io
obtener_resultados_urlscan() {
    for sitio in "${!uuid_por_sitio[@]}"; do
        uuid=${uuid_por_sitio[$sitio]}
        echo "Obteniendo resultados de URLScan.io para $sitio (UUID: $uuid)..."
        response=$(curl -s --request GET --url "https://urlscan.io/api/v1/result/$uuid/" \
        --header "API-Key: $API_KEY")
        echo "Resultado de URLScan.io para $sitio (UUID: $uuid): $response"
    done
}

# Mostrar todos los sitios web
echo "Mostrando todos los sitios web"
mostrar_sitios
read -p "Presiona Enter para continuar"
clear

# Usar bucle for para analizar los sitios web con wafw00f
echo "Usando el ciclo for para analizar con wafw00f"
analizar_con_wafw00f
read -p "Presiona Enter para continuar"
clear

# Usar bucle for para analizar puertos abiertos con nmap
echo "Usando el ciclo for para analizar puertos con nmap"
analizar_con_nmap
read -p "Presiona Enter para continuar"
clear

# Enviar URLs a URLScan.io
echo "Enviando URLs a URLScan.io"
enviar_a_urlscan
read -p "Presiona Enter para continuar"
clear

# Obtener resultados de URLScan.io
echo "Obteniendo resultados de URLScan.io"
obtener_resultados_urlscan
read -p "Presiona Enter para finalizar"
clear

echo "Script finalizado."

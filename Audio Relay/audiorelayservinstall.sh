#!/bin/bash
#Ruta origen del script y archivos
ORIGEN="$(dirname "$0")"
# Ruta del archivo prefs.xml para asignar el audio relay sink como salida predeterminada para el servidor Audio Relay
ARCHPREFS="/home/deck/.java/.userPrefs/com/azefsw/audioconnect/prefs.xml"
# Cadena de texto a buscar para evitar duplicados
BUSQUEDA='key="device_capture_id" value="AudioRelay"'
# Destino bin Audio Relay para comprobación
DESTINOBIN="/home/deck/Apps/audiorelay"
DESTINOSERV="/home/deck/.config/systemd/user/audiorelay.service"
echo "                                                  "
echo "=================================================="
echo "            INICIANDO CHEQUEO PREVIO              "
echo "=================================================="
echo "                                                  "
echo "1. Desactivando servicio Audio Relay... si existe"
if [ -f "$DESTINOSERV" ]; then
    systemctl --user stop audiorelay.service
    systemctl --user disable audiorelay.service
    sudo rm "$DESTINOSERV"
    echo "  [OK] Servicio detenido correctamente..."
fi
echo "                                                  "
echo "2. Comprobando archivos de Audio Relay en la ruta /home/deck/Apps/audiorelay/"
if [ -d "$DESTINOBIN" ]; then
    echo "  [ERROR] YA se encuentra la carpeta audiorelay... Borrando porque yo mando aquí..."
    sudo rm -rf "$DESTINOBIN"
fi


echo "                                                  "
echo "=================================================="
echo "  INICIANDO INSTALACION AUTOMÁTICA DE AUDIO WIFI  "
echo "=================================================="
echo "                                                  "
echo "1. Copiando archivos de Audio Relay a la ruta /home/deck/Apps/audiorelay/"
if [ -d "$ORIGEN/audiorelay" ]; then
    sudo cp -r "$ORIGEN/audiorelay/" /home/deck/Apps/
    echo "  [OK] Archivos copiados correctamente."
else
    echo "  [ERROR] No se encontró la carpeta audiorelay en la carpeta del script."
    exit 0
fi

# 2. Copiando archivo de servicio a la ruta de servicios de usuario
echo "                                                  "
echo "2. Copiando archivo de servicio a la ruta de servicios de usuario..."
if [ -f "$ORIGEN/audiorelay.service" ]; then
    sudo cp "$ORIGEN/audiorelay.service" /home/deck/.config/systemd/user/
    echo "  [OK] Archivo de servicio copiado correctamente."
else
    echo "  [ERROR] No se encontró audiorelay.service en la carpeta del script."
    exit 0
fi

# Copia de archivo prefs.xml o edición de uno existente
echo "                                                  "
echo "3. Copiando archivo prefs.xml a la ruta de usuario para Audio Relay..."
if [ ! -f "$ARCHPREFS" ]; then
    echo "  [AVISO] El archivo prefs.xml no existe en la ruta destino. Se creará con datos básicos necesarios."
    #Si el archivo no existe en el destino se verifica si el archivo origen existe en la carpeta del script
    if [ -f "$ORIGEN/prefs.xml" ]; then
        sudo cp "$ORIGEN/prefs.xml" /home/deck/.java/.userPrefs/com/azefsw/audioconnect/
        echo "  [OK] Archivo prefs.xml copiado correctamente."
    else
        echo "  [ERROR] No se encontró prefs.xml en la carpeta del script."
        exit 0
    fi
else
    # Si el archivo ya existe en el destino se verifica si ya contiene la cadena necesaria
    echo "  [AVISO] El archivo prefs.xml ya existe en la ruta destino. Se agregará la cadena necesaria."
    if ! grep -q "$BUSQUEDA" "$ARCHPREFS"; then
        # Usa sed para buscar la línea </map> e insertar (i) el contenido antes de ella
        sed -i '/<\/map>/i \
    <entry key="device_capture_id" value="AudioRelay"/>\
    <entry key="device_name" value="SteamDeck"/>' "$ARCHPREFS"
        echo "  [OK] Configuración agregada exitosamente."
    else
        echo "  [OK] La configuración ya existe. No se hicieron cambios."
    fi
fi
echo "                                                  "
echo "4. Habilitando servicio audiorelay.service para el arranque automático..."
systemctl --user enable audiorelay.service
echo "5. Reiniciando servicio PipeWire para arranque de Audio Relay..."
systemctl --user restart pipewire
echo "6. Arrancando manualmente audiorelay.service..."
systemctl --user start audiorelay.service

echo "                                                  "
echo "--------------------------------------------------"
echo "          ¡PROCESO FINALIZADO CON ÉXITO!          "
echo "               Servicio instalado.                "
echo "  Seleccionar salida Audio Relay para audio Wifi. "
echo "=================================================="

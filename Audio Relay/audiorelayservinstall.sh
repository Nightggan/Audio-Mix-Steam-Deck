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
DESTINOTIMER="/home/deck/.config/systemd/user/audiorelayservice.timer"

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
echo "2. Desactivando timer para servicio Audio Relay... si existe"
if [ -f "$DESTINOTIMER" ]; then
    sudo runuser -l deck -c "XDG_RUNTIME_DIR=/run/user/1000 systemctl --user stop --now audiorelayservice.timer"
    sudo runuser -l deck -c "XDG_RUNTIME_DIR=/run/user/1000 systemctl --user disable --now audiorelayservice.timer"
    sudo rm "$DESTINOTIMER"
    echo "  [OK] Timer detenido correctamente..."
fi
echo "                                                  "
echo "3. Comprobando archivos de Audio Relay en la ruta /home/deck/Apps/audiorelay/"
if [ -d "$DESTINOBIN" ]; then
    echo "  [ERROR] YA se encuentra la carpeta audiorelay... Borrando porque yo mando aquí..."
    sudo rm -rf "$DESTINOBIN"
fi
echo "                                                  "
echo "4. Desbloqueando sistema de archivos de SteamOS..."
sudo steamos-readonly disable

echo "                                                  "
echo "=================================================="
echo "  INICIANDO INSTALACION AUTOMÁTICA DE AUDIO WIFI  "
echo "=================================================="
echo "                                                  "
echo "1. Copiando archivos de Audio Relay a la ruta /home/deck/Apps/audiorelay/"
if [ -d "$ORIGEN/audiorelay" ]; then
    sudo cp -r "$ORIGEN/audiorelay/" /home/deck/Apps/
    sudo chmod -R 777 /home/deck/Apps/audiorelay
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
echo "5. Instalando servicio de mantenimiento para reinicio automático de Audio Relay..."
if [ -f "$ORIGEN/audiorelay-health.service" ]; then
    mkdir -p /home/deck/.config/systemd/user/
    cp "$ORIGEN/audiorelay-health.service" /home/deck/.config/systemd/user/
    echo "  [OK] Servicio de mantenimiento instalado correctmente."
else
    echo "  [ERROR] No se encontró audiorelay-health.service en la carpeta."
    exit 0
fi
if [ -f "$ORIGEN/audiorelayservice.timer" ]; then
    mkdir -p /home/deck/.config/systemd/user/
    cp "$ORIGEN/audiorelayservice.timer" /home/deck/.config/systemd/user/
    echo "  [OK] Timer para servicio de mantenimiento restaurado."
else
    echo "  [ERROR] No se encontró audiorelayservice.timer en la carpeta."
    exit 0
fi
if [ -f "$ORIGEN/audiorelay-restart.sh" ]; then
    sudo cp "$ORIGEN/audiorelay-restart.sh" /usr/local/bin/
    sudo chmod +x /usr/local/bin/audiorelay-restart.sh
    echo "  [OK] Script de servicio de mantenimiento instalado correctamente."
else
    echo "  [ERROR] No se encontró audiorelay-restart.sh en la carpeta del script."
    exit 0
fi
echo "                                                  "
echo "6. Aplicando cambios y recargando daemons..."

# A. Primero el sistema global y forzar el disparo de hardware como "add"
echo "  [INFO] Recargando daemons del sistema global."
sudo systemctl daemon-reload
echo "  [INFO] Reiniciando servicio PipeWire..."
systemctl --user restart pipewire
systemctl --user restart wireplumber
# B. SEGUNDO: Recarga limpia de la memoria de Systemd del usuario deck
echo "  [INFO] Habilitando timer a nivel de usuario para el servicio."
sudo runuser -l deck -c "XDG_RUNTIME_DIR=/run/user/1000 systemctl --user daemon-reload"
sudo runuser -l deck -c "XDG_RUNTIME_DIR=/run/user/1000 systemctl --user enable --now audiorelayservice.timer"


# 5. Volver a activar el modo solo lectura para proteger SteamOS
echo "                                                  "
echo "8. Bloqueando sistema de archivos de SteamOS (Seguridad)..."
sudo steamos-readonly enable


echo "                                                  "
echo "--------------------------------------------------"
echo "          ¡PROCESO FINALIZADO CON ÉXITO!          "
echo "               Servicio instalado.                "
echo "  Seleccionar salida Audio Relay para audio Wifi. "
echo "=================================================="

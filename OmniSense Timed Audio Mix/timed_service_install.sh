#!/bin/bash

ORIGEN="$(dirname "$0")"
DESTINOSERV="/home/deck/.config/systemd/user/omni-audio-mixer.service"
DESTINOTIMER="/home/deck/.config/systemd/user/omni-audio-mixer.timer"

echo "                                                  "
echo "=================================================="
echo "            INICIANDO CHEQUEO PREVIO              "
echo "=================================================="
echo "                                                  "
echo "1. Desactivando servicio ... si existe"
if [ -f "$DESTINOSERV" ]; then
    systemctl --user stop omni-audio-mixer.service
    systemctl --user disable omni-audio-mixer.service
    sudo rm "$DESTINOSERV"
    echo "  [OK] Servicio detenido correctamente..."
else
    echo "  [INFO] No se encontró el servicio. Continuando..."
fi
if [ -f "$DESTINOTIMER" ]; then
    systemctl --user stop omni-audio-mixer.timer
    systemctl --user disable omni-audio-mixer.timer
    sudo rm "$DESTINOTIMER"
    echo "  [OK] Timer detenido correctamente..."
else
    echo "  [INFO] No se encontró el Timer de servicio. Continuando..."
fi

echo "                                                  "
echo "=================================================="
echo "  INICIANDO RESTAURACIÓN AUTOMÁTICA DE AUDIO USB  "
echo "                 TIMED EDITION                    "
echo "=================================================="
echo "                                                  "
# 1. Cambiar perfil de audio a Pro-Audio
echo "1. Cambiando perfil de audio del Dongle a Pro-Audio..."

pactl set-card-profile alsa_card.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller-00 pro-audio

# 2. Asignar un nombre fijo al Dongle para Wireplumber
echo "                                                  "
echo "2. Asignando un nombre fijo al Dongle para Wireplumber..."
if [ -f "$ORIGEN/51-ds5dongle.conf" ]; then
    sudo mkdir -p ~/.config/wireplumber/wireplumber.conf.d
    sudo cp "$ORIGEN/51-ds5dongle.conf" /home/deck/.config/wireplumber/wireplumber.conf.d/
    systemctl --user restart wireplumber
    echo "  [OK] Nombre fijo asignado y servicio reiniciado."
else
    echo "  [ERROR] No se encontró 51-ds5dongle.conf en la carpeta."
fi

# 3. Desactivar temporalmente el modo de solo lectura de SteamOS
echo "                                                  "
echo "3. Desbloqueando sistema de archivos de SteamOS..."
sudo steamos-readonly disable
echo "                                                  "
echo "4. Copiando archivos a sus rutas originales..."

# 3.1 Restaurar Servicio Mezclador (Usuario)
if [ -f "$ORIGEN/omni-audio-mixer.service" ]; then
    mkdir -p /home/deck/.config/systemd/user/
    cp "$ORIGEN/omni-audio-mixer.service" /home/deck/.config/systemd/user/
    echo "  [OK] Servicio Mezclador restaurado."
else
    echo "  [ERROR] No se encontró omni-audio-mixer.service en la carpeta."
fi

# 3.2 Restaurar Timer Mezclador (Usuario)
if [ -f "$ORIGEN/omni-audio-mixer.timer" ]; then
    mkdir -p /home/deck/.config/systemd/user/
    cp "$ORIGEN/omni-audio-mixer.timer" /home/deck/.config/systemd/user/
    echo "  [OK] Timer para servicio restaurado."
else
    echo "  [ERROR] No se encontró omni-audio-mixer.timer en la carpeta."
fi

# 3.3 Restaurar Script Mezclador de PipeWire y dar permisos
if [ -f "$ORIGEN/usb-audio-mixer.sh" ]; then
    sudo cp "$ORIGEN/usb-audio-mixer.sh" /usr/local/bin/
    sudo chmod +x /usr/local/bin/usb-audio-mixer.sh
    echo "  [OK] Script de PipeWire restaurado y con permisos de ejecución."
else
    echo "  [ERROR] No se encontró usb-audio-mixer.sh en la carpeta."
fi

# 4. Recargar configuraciones del sistema para aplicar cambios en caliente
echo "                                                  "
echo "5. Aplicando cambios y recargando daemons..."

# A. Primero el sistema global y forzar el disparo de hardware como "add"
echo "  [INFO] Recargando daemons del sistema global."
sudo systemctl daemon-reload

# B. SEGUNDO: Recarga limpia de la memoria de Systemd del usuario deck
echo "  [INFO] Habilitando timer a nivel de usuario para el servicio."
sudo runuser -l deck -c "XDG_RUNTIME_DIR=/run/user/1000 systemctl --user daemon-reload"
sudo runuser -l deck -c "XDG_RUNTIME_DIR=/run/user/1000 systemctl --user enable --now omni-audio-mixer.timer"

# 5. Volver a activar el modo solo lectura para proteger SteamOS
echo "                                                  "
echo "6. Bloqueando sistema de archivos de SteamOS (Seguridad)..."
sudo steamos-readonly enable
echo "                                                  "
echo "--------------------------------------------------"
echo "         ¡PROCESO FINALIZADO CON ÉXITO!           "
echo "=================================================="

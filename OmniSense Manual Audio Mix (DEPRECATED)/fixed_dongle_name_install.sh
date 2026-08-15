#!/bin/bash

ORIGEN="$(dirname "$0")"
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

echo "                                                  "
echo "--------------------------------------------------"
echo "         ¡PROCESO FINALIZADO CON ÉXITO!           "
echo "=================================================="

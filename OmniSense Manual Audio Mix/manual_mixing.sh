#!/bin/bash
DESTINO_ACTIVO="ds5_dongle_sink"
ORIGEN="$(dirname "$0")"
echo "                                                   "
echo "==================================================="
echo " INICIANDO REDIRECCION DE AUDIO MANUAL A OMNISENSE "
echo "==================================================="

echo "                                                   "
# 1. Asignar un nombre fijo al Dongle para Wireplumber
echo "1. Asignando un nombre fijo al Dongle para Wireplumber..."
if [ -f "$ORIGEN/51-ds5dongle.conf" ]; then
    sudo mkdir -p ~/.config/wireplumber/wireplumber.conf.d
    sudo cp "$ORIGEN/51-ds5dongle.conf" /home/deck/.config/wireplumber/wireplumber.conf.d/
    systemctl --user restart wireplumber
    echo "   Nombre fijo asignado como ds5_dongle_sink y servicio reiniciado."
else
    echo "   [ERROR] No se encontró 51-ds5dongle.conf en la carpeta."
    exit 0
fi
echo "                                                   "
echo "2. Verificando conexión del dongle..."
echo "                                                   "
# Control de salud del hardware: Si da error porque desconectaste el dongle físicamente, cerramos el servicio limpio
if ! pw-link -i | grep -q "$DESTINO_ACTIVO"; then
    echo "   [ERROR] El destino $DESTINO_ACTIVO ya no responde en PipeWire. Se cancela el proceso"
    exit 0
fi

echo "3. Usando OmniSense Dongle como destino para duplicación de audio..."
echo "                                                   "
echo "   [INFO] Intentando enlazar con parlantes incorporados..."
# A. Intentar enlace del Speaker de la Steam Deck
if pw-link -o | grep -q "alsa_output.pci-0000_04_00.5-platform-acp5x_mach.0.HiFi__Speaker__sink"; then
    salida_error=$(pw-link alsa_output.pci-0000_04_00.5-platform-acp5x_mach.0.HiFi__Speaker__sink "$DESTINO_ACTIVO" 2>&1)
    codigo_salida=$?

    if [ $codigo_salida -ne 0 ] && ! echo "$salida_error" | grep -qi "existe"; then
        errores=$((errores + 1))
        echo "   [INFO] No se encuentra la salida."
    else
        echo "   [OK] Se duplica con éxito la salida."
    fi

fi

echo "                                                   "
echo "   [INFO] Intentando enlazar con Soundcore VR P10..."
# B. Intentar enlace de los Audífonos VR
if pw-link -o | grep -q "alsa_output.usb-Telink_VR_P10_Dongle-00.analog-stereo"; then
    salida_error=$(pw-link alsa_output.usb-Telink_VR_P10_Dongle-00.analog-stereo "$DESTINO_ACTIVO" 2>&1)
    codigo_salida=$?

    if [ $codigo_salida -ne 0 ] && ! echo "$salida_error" | grep -qi "existe"; then
        errores=$((errores + 1))
        echo "   [INFO] No se encuentra la salida."
    else
        echo "   [OK] Se duplica con éxito la salida."
    fi
fi

echo "                                                   "
echo "   [INFO] Intentando enlazar con salida de audio por HDMI..."
# C. Intentar enlace de la salida HDMI (TV / Monitor)
if pw-link -o | grep -q "alsa_output.pci-0000_04_00.1.hdmi-stereo-extra2"; then
    salida_error=$(pw-link alsa_output.pci-0000_04_00.1.hdmi-stereo-extra2 "$DESTINO_ACTIVO" 2>&1)
    codigo_salida=$?

    if [ $codigo_salida -ne 0 ] && ! echo "$salida_error" | grep -qi "existe"; then
        errores=$((errores + 1))
        echo "   [INFO] No se encuentra la salida."
    else
        echo "   [OK] Se duplica con éxito la salida."
    fi
fi

echo "                                                   "
echo "--------------------------------------------------"
echo "        ¡PROCESO FINALIZADO CON ÉXITO!            "
echo "   Mando avanzado y redirección de audio listos.  "
echo "=================================================="

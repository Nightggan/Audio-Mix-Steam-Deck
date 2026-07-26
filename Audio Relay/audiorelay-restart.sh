#!/usr/bin/env bash

# Define the user service name (do not use sudo for user services)
SERVICE_NAME="audiorelay.service"

# Check if the user service is active
if systemctl --user is-active --quiet "$SERVICE_NAME"; then
    echo "[INFO] $SERVICE_NAME esta corriendo... Se revisará en 10 segundos."
else
    echo "[INFO] $SERVICE_NAME está inactivo. Intentando reiniciar el servicio..."
    SALIDA=$(pactl get-default-sink)
    # Try to restart the user service
    
    systemctl --user restart $SERVICE_NAME
    echo "[INFO] Salida de audio previa: $SALIDA"

    # Double check if the restart was successful
    if systemctl --user is-active --quiet "$SERVICE_NAME"; then
        echo "[OK] $SERVICE_NAME se reinició correctamente."
        echo "[INFO] Devolviendo salida de audio a la salida previa: $SALIDA"
    pactl get-default-sink $SALIDA
    else
        echo "[ERROR] Error al reiniciar $SERVICE_NAME. Se reintentará en 10 segundos..."
    fi    
fi



#!/usr/bin/env bash

# Asegurar entorno de PipeWire y rutas básicas para el usuario deck
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export XDG_RUNTIME_DIR="/run/user/1000"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"

DESTINO_ACTIVO="ds5_dongle_sink"

echo "[INFO] Usando la OmniSense Dongle como destino."

# Esperar de forma segura a que el dongle sea indexado por PipeWire
echo "[INFO] Comprobando que $DESTINO_ACTIVO esté disponible..."
echo "                                                " 
if pw-link -i | grep -q "$DESTINO_ACTIVO"; then
    echo "  [OK] $DESTINO_ACTIVO disponible!"
else
    echo "  [INFO] $DESTINO_ACTIVO no disponible. Esperando 5 segundos para reintentar..."
    exit 0
fi
sleep 1
SALIDA=$(pactl get-default-sink)
echo "[INFO] Intentando conectar $DESTINO_ACTIVO con la salida de audio actual: $SALIDA"
echo "                                                " 

if [ -z "$SALIDA" ]; then
    echo "[INFO] No hay salida por defecto."
    exit 0
fi

if [ "$SALIDA" = "$DESTINO_ACTIVO" ]; then
    echo "[INFO] Origen y destino son el mismo ($SALIDA). Se omite pw-link."
    exit 0
fi

if ! pw-link -o | grep -q "$SALIDA"; then
    echo "[INFO] La salida actual no está disponible aún en PipeWire."
    exit 0
fi

if pw-link -l | awk -v s="$SALIDA" -v d="$DESTINO_ACTIVO" 'index($0, s) && index($0, d) { found=1 } END { exit(found ? 0 : 1) }'; then
    echo "[INFO] El enlace $SALIDA -> $DESTINO_ACTIVO ya existe."
    exit 0
fi

pw-link "$SALIDA" "$DESTINO_ACTIVO"
# Guardar el código de salida inmediatamente
RESULTADO=$?

if [ $RESULTADO -eq 0 ]; then
    echo "[INFO] Se conectó correctamente $SALIDA con $DESTINO_ACTIVO."
else
    echo "[ERROR] No se pudo conectar. Código de error: $RESULTADO"
fi

#!/bin/bash
echo "                                                  "
echo "=================================================="
echo "      INICIANDO DESINSTALACIÓN DE AUDIO USB       "
echo "=================================================="
echo "                                                  "
# 1. Detener y deshabilitar los servicios activos primero
echo "1. Deteniendo y deshabilitando servicios..."

# Servicio de usuario (Deck)
XDG_RUNTIME_DIR=/run/user/1000 systemctl --user stop omni-audio-mixer.timer 2>/dev/null
XDG_RUNTIME_DIR=/run/user/1000 systemctl --user disable omni-audio-mixer.timer 2>/dev/null
XDG_RUNTIME_DIR=/run/user/1000 systemctl --user stop omni-audio-mixer.service 2>/dev/null
XDG_RUNTIME_DIR=/run/user/1000 systemctl --user disable omni-audio-mixer.service 2>/dev/null

# 2. Desactivar temporalmente el modo de solo lectura
echo "                                                  "
echo "2. Desbloqueando sistema de archivos de SteamOS..."
sudo steamos-readonly disable

echo "                                                  "
echo "3. Eliminando archivos del sistema y de usuario..."

# 3. Eliminar Servicio Mezclador (Usuario)
if [ -f "/home/deck/.config/systemd/user/omni-audio-mixer.service" ]; then
    rm /home/deck/.config/systemd/user/omni-audio-mixer.service
    echo "  [OK] Servicio Mixer (Usuario) eliminado."
fi

# 4. Eliminar Timer de Servicio (Usuario)
if [ -f "/home/deck/.config/systemd/user/omni-audio-mixer.timer" ]; then
    rm /home/deck/.config/systemd/user/omni-audio-mixer.timer
    echo "  [OK] Timer de servicio Mezclador (Usuario) eliminado."
fi

# 5. Eliminar Script Mezclador de PipeWire
if [ -f "/usr/local/bin/usb-audio-mixer.sh" ]; then
    sudo rm /usr/local/bin/usb-audio-mixer.sh
    echo "  [OK] Script de PipeWire eliminado."
fi

# 6. Recargar configuraciones del sistema para limpiar la memoria
echo "                                                  "
echo "4. Aplicando cambios y recargando daemons a su estado original..."

# Limpiar caché de Systemd (Sistema y Usuario)
sudo systemctl daemon-reload
XDG_RUNTIME_DIR=/run/user/1000 systemctl --user daemon-reload

# Reiniciar WirePlumber para que olvide el nombre fijo y recupere su política por defecto
XDG_RUNTIME_DIR=/run/user/1000 systemctl --user restart wireplumber

# 7. Volver a activar el modo solo lectura
echo "                                                  "
echo "5. Bloqueando sistema de archivos de SteamOS (Seguridad)..."
sudo steamos-readonly enable

echo "                                                     "
echo "-----------------------------------------------------"
echo "         ¡DESINSTALACIÓN FINALIZADA CON ÉXITO!       "
echo " Se quita servicio de Mezcla de Audio para OmniSense "
echo "====================================================="

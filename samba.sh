#!/bin/bash

# =========================================================================
# Función para pausar y esperar al usuario
# =========================================================================
pause_script() {
    echo ""
    read -p "[-] Presiona [Enter] para continuar..."
}

# =========================================================================
# 1. Instalación de Dependencias
# =========================================================================
install_dependencies() {
    clear
cat << "EOF"
   ___                           _                 _         
  / _ \                         | |               (_)        
 / /_\ \_ __  _ __  ___   _   _ | |__  _   _ _ __  _ ___  ___
 |  _  | '_ \| '_ \/ __| | | | || '_ \| | | | '_ \| / __|/ __|
 | | | | |_) | | | \__ \ | |_| || |_) | |_| | | | | \__ \\__ \
 \_| |_/ .__/|_| |_|___/  \__,_||_.__/ \__,_|_| |_|_|___/|___/
       | |                                                   
       |_|                                                   
EOF

    echo "[-] INICIANDO INSTALACIÓN DE DEPENDENCIAS..."
    echo ""
    
    echo "[*] Actualizando repositorios y el sistema..."
    sudo apt update && sudo apt upgrade -y

    echo "[*] Instalando Samba y SMBClient..."
    sudo apt install samba smbclient -y

    echo "[*] Instalando sensores y utilidades de red..."
    sudo apt install lm-sensors -y
    sudo sensors-detect --auto
    sudo apt install net-tools vnstat iputils-ping -y

    echo "[*] Instalando y configurando Fail2Ban..."
    sudo apt install fail2ban -y
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

    echo ""
    echo "[+] ¡Dependencias instaladas correctamente!"
    pause_script
}

# =========================================================================
# 2. Configuración e Instalación del Servidor Samba
# =========================================================================
start_installation() {
    clear
cat << "EOF"
  _____             _           _____             __ _       
 /  ___|           | |         /  __ \           / _(_)      
 \ `--.  __ _ _ __ | |__   __ _| /  \/ ___  _ __| |_ _  __ _ 
  `--. \/ _` | '_ \| '_ \ / _` | |    / _ \| '_ \  _| |/ _` |
 /\__/ / (_| | |_) | |_) | (_| | \__/\ (_) | | | | | | (_| |
 \____/ \__,_| .__/|_.__/ \__,_|\____/\___/|_| |_|_| |_|\__, |
             | |                                         __/ |
             |_|                                        |___/ 
EOF

    echo "[-] CONFIGURANDO SERVIDOR SAMBA..."
    echo ""
    
    # 1. Crear directorio
    echo "[*] Creando directorio compartido en /srv/samba/compartido..."
    sudo mkdir -p /srv/samba/compartido

    # 2. Crear grupo
    echo "[*] Creando grupo 'smbgroup'..."
    sudo addgroup smbgroup > /dev/null 2>&1

    # 3. Asignar usuario
    echo ""
    read -p "[-] Ingresa el nombre de tu usuario de Linux para añadirlo a Samba: " smb_user
    sudo usermod -aG smbgroup $smb_user

    # 4. Permisos
    echo "[*] Ajustando permisos y propietarios del directorio..."
    sudo chown -R root:smbgroup /srv/samba/compartido
    sudo chmod -R 2770 /srv/samba/compartido

    # 5. Configurar smb.conf
    echo "[*] Realizando respaldo de smb.conf..."
    sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

    echo "[*] Añadiendo configuración al archivo smb.conf..."
    # Se utiliza 'tee -a' para inyectar la configuración de forma automatizada
sudo tee -a /etc/samba/smb.conf > /dev/null << EOF

# --- Configuración añadida por script de automatización ---
[Compartido]
   comment = Servidor de Archivos Local
   path = /srv/samba/compartido
   valid users = @smbgroup
   guest ok = no
   writable = yes
   browsable = yes
   create mask = 0660
   directory mask = 0770
EOF

    # 6. Contraseña de Samba
    echo ""
    echo "[-] Es necesario asignar una contraseña de Samba para el usuario '$smb_user':"
    sudo smbpasswd -a $smb_user

    # 7. Reiniciar servicios
    echo ""
    echo "[*] Reiniciando y habilitando servicios smbd y nmbd..."
    sudo systemctl restart smbd nmbd
    sudo systemctl enable smbd nmbd

    echo ""
    echo "[+] ¡Instalación y configuración completadas con éxito!"
    pause_script
}

# =========================================================================
# Bucle del Menú Principal
# =========================================================================
while true; do
    clear

cat << "EOF"
  _____  ___  ___  _______  ___   ___  _   _ _____ _____ ___  _      _      _____ ______ 
 /  ___|/ _ \ |  \/  || ___ \/ _ \ |_   _| \ | /  ___|_   _/ _ \| |    | |    |_   _| ___ \
 \ `--./ /_\ \| .  . || |_/ / /_\ \  | | |  \| \ `--.  | |/ /_\ \ |    | |      | | | |_/ /
  `--. \  _  || |\/| || ___ \  _  |  | | | . ` |`--. \ | ||  _  | |    | |      | | |    / 
 /\__/ / | | || |  | || |_/ / | | | _| |_| |\  /\__/ / | || | | | |____| |____ _| |_| |\ \ 
 \____/\_| |_/\_|  |_/\____/\_| |_/ \___/\_| \_/\____/ \_/\_| |_/\_____/\_____/\___/\_| \_|

EOF

    echo -e "\033[33m                    ¡Bienvenido al Instalador de Samba!\033[0m"
    echo ""
    echo "[-] Creado para:             |         Automatización en Debian"
    echo "[-] Basado en script de:     |         N0kyapi"
    echo ""

    echo "[1] Instalar dependencias requeridas"
    echo "[2] Iniciar instalación y configuración de Samba"
    echo "[3] Salir"
    echo ""
    read -p "[-] Selecciona una opción [1-3]: " option

    case $option in
        1) install_dependencies ;;
        2) start_installation ;;
        3) echo "[-] Saliendo del instalador. ¡Hasta pronto!"; exit 0 ;;
        *) echo "[-] Opción inválida. Por favor, intenta de nuevo."; sleep 2 ;;
    esac
done
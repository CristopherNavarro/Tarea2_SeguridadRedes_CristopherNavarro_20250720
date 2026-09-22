#!/bin/sh
# ==============================================================================
# Script de Aprovisionamiento y Servicios de Hosts - Tarea #2 Seguridad de Redes
# Estudiante: Cristopher Navarro | Matrícula: 2025-0720
# Docente: Jonathan Esteban Rondón Corniel
# Institución: Instituto Tecnológico de Las Américas (ITLA)
# ==============================================================================

echo "=== Configuración de Servicios para Entorno de Laboratorio GNS3 ==="

# ------------------------------------------------------------------------------
# 1. SERVIDOR DE BASE DE DATOS (DB-Server - VLAN 20: 10.25.72.131/28)
# ------------------------------------------------------------------------------
setup_db_server() {
    echo "[*] Configurando DB-Server (MySQL en puerto 3306)..."
    ip addr add 10.25.72.131/28 dev eth0 2>/dev/null
    ip link set eth0 up
    ip route add default via 10.25.72.129 2>/dev/null

    cat << 'EOF' > /tmp/mysql_handler.sh
#!/bin/sh
echo "5.7.35-MySQL Community Server (GPL)"
EOF
    chmod +x /tmp/mysql_handler.sh

    killall nc 2>/dev/null
    nc -lk -p 3306 -e /tmp/mysql_handler.sh &
    echo "[+] DB-Server iniciado y escuchando en el puerto 3306 (MySQL)."
}

# ------------------------------------------------------------------------------
# 2. SERVIDOR WEB (Web-Server - VLAN 20: 10.25.72.130/28)
# ------------------------------------------------------------------------------
setup_web_server() {
    echo "[*] Configurando Web-Server (HTTP:80 y HTTPS:443)..."
    ip addr add 10.25.72.130/28 dev eth0 2>/dev/null
    ip link set eth0 up
    ip route add default via 10.25.72.129 2>/dev/null

    # Creación del binario simulado .exe para prueba de File-Filter
    mkdir -p /var/www
    printf 'MZ-DUMMY-EXE-PAYLOAD' > /var/www/test.exe

    # Script manejador HTTP/HTTPS con drenaje de encabezados y Content-Length
    cat << 'EOF' > /tmp/http_handler.sh
#!/bin/sh
read req
while read -r line; do
  clean=$(echo "$line" | tr -d '\r')
  [ -z "$clean" ] && break
done

case "$req" in
  *test.exe*)
    printf 'HTTP/1.1 200 OK\r\nContent-Type: application/x-msdownload\r\nContent-Length: 20\r\nConnection: close\r\n\r\nMZ-DUMMY-EXE-PAYLOAD'
    ;;
  *)
    HTML='<html><body><h1>Servidor Web Seguro - Tarea 2 Cristopher Navarro (2025-0720)</h1></body></html>'
    printf 'HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 87\r\nConnection: close\r\n\r\n%s' "$HTML"
    ;;
esac
EOF
    chmod +x /tmp/http_handler.sh

    killall nc 2>/dev/null
    nc -lk -p 80 -e /tmp/http_handler.sh &
    nc -lk -p 443 -e /tmp/http_handler.sh &
    echo "[+] Web-Server iniciado y escuchando en los puertos 80 y 443."
}

# ------------------------------------------------------------------------------
# 3. CLIENTE DE USUARIO (PC1-Usuario - VLAN 10: Asignación Dinámica DHCP)
# ------------------------------------------------------------------------------
setup_client_pc1() {
    echo "[*] Configurando PC1-Usuario (Adquisición de DHCP)..."
    ip link set eth0 up
    udhcpc -i eth0
    echo "[+] PC1-Usuario configurado con IP dinámica desde el FortiGate."
}

echo "Ejecute la función correspondiente según el nodo en el que se encuentre:"
echo " - setup_db_server"
echo " - setup_web_server"
echo " - setup_client_pc1"

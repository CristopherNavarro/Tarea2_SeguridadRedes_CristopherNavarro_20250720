# Memoria Técnica de Ingeniería: Implementación y Hardening de Seguridad de Redes con FortiGate Next-Generation Firewall y Conmutación Cisco L2

**Asignatura:** Seguridad de Redes  
**Docente:** Jonathan Esteban Rondón Corniel  
**Estudiante:** Cristopher Navarro  
**Matrícula:** 2025-0720  
**Institución:** Instituto Tecnológico de Las Américas (ITLA)  
**Fecha de Elaboración:** Septiembre 2026  

---

## 1. Introducción y Justificación del Proyecto

En el panorama actual de la ciberseguridad corporativa, la protección perimetral estática basada únicamente en filtrado de paquetes de Capa 3 y Capa 4 resulta insuficiente frente a amenazas modernas complejas, tales como inyecciones de código a nivel de aplicación (SQL Injection), ataques de denegación de servicio distribuido (DDoS), propagación de binarios maliciosos y movimientos laterales entre segmentos internos.

Para responder a estos desafíos, en este proyecto implementé una infraestructura de red corporativa simulada de alta fidelidad, desplegando un firewall de última generación (*Next-Generation Firewall - NGFW*) **FortiGate (v7.0.9)** y un conmutador multicapa **Cisco IOSvL2**, interconectando tres zonas de seguridad principales: la red de usuarios (LAN interna), la zona desmilitarizada o granja de servidores (DMZ) y el perímetro externo hacia Internet (WAN).

El objetivo primordial de esta práctica consistió en diseñar, aprovisionar y certificar un ecosistema de red bajo el principio de menor privilegio (*Least Privilege*) y defensa en profundidad (*Defense-in-Depth*), demostrando la efectividad de los mecanismos de seguridad perimetral, inspección profunda de paquetes (DPI), prevención de intrusiones (IPS) con firmas personalizadas, respuesta automatizada de cuarentena, control de descarga de archivos ejecutables y mitigación de anomalías DoS.

---

## 2. Topología de Red y Arquitectura de Conectividad

### 2.1 Diagrama Lógico de la Topología

```
                           +------------------------+
                           |      INTERNET / WAN    |
                           |       (Nodo NAT1)      |
                           +------------------------+
                                       |
                                       | [port1 - DHCP/WAN + NAT]
                                       |
                       +--------------------------------+
                       |    FortiGate NGFW (v7.0.9)     |
                       |       FortiGate-Hardened       |
                       +--------------------------------+
                                       |
                                       | [port2 - Trunk 802.1Q]
                                       | Subinterfaces:
                                       |   port2.10: 10.25.72.1/25
                                       |   port2.20: 10.25.72.129/28
                                       |
                       +--------------------------------+
                       |   Switch Cisco (IOSvL2-15.2)   |
                       |       SW1-Cisco-IOSvL2         |
                       |    [Gi0/0 - Trunk 802.1Q]      |
                       +--------------------------------+
                          /            |              \
           [Gi1/1 - VLAN 10]  [Gi2/1 - VLAN 20]  [Gi3/1 - VLAN 20]
                 /                     |                    \
   +-------------------+     +-------------------+   +-------------------+
   |   PC1-Usuario     |     |    Web-Server     |   |    DB-Server      |
   | (Alpine Linux)    |     |   (Alpine Linux)  |   |  (Alpine Linux)   |
   | 10.25.72.10/25    |     | 10.25.72.130/28   |   | 10.25.72.131/28   |
   | (DHCP FortiGate)  |     | (HTTP:80/HTTPS:443|   | (MySQL:3306)      |
   +-------------------+     +-------------------+   +-------------------+
```

### 2.2 Relación de Interfaces Físicas y Lógicas

| Dispositivo | Interfaz | Tipo / Modo | Conexión Hacia | Función en la Red |
|---|---|---|---|---|
| **FortiGate-7.0.9** | `port1` | Física / DHCP | `NAT1` | Conectividad WAN / Egress a Internet |
| **FortiGate-7.0.9** | `port2` | Física / Troncal | `SW1` (Gi0/0) | Transporte agregado de VLANs 10 y 20 |
| **FortiGate-7.0.9** | `port2.10` | Subinterfaz 802.1Q | VLAN 10 | Gateway (`10.25.72.1/25`) y Servidor DHCP |
| **FortiGate-7.0.9** | `port2.20` | Subinterfaz 802.1Q | VLAN 20 | Gateway (`10.25.72.129/28`) Zona DMZ |
| **SW1-Cisco-IOSvL2** | `Gi0/0` | Troncal 802.1Q | FortiGate `port2` | Uplink troncal (VLANs permitidas: 10, 20) |
| **SW1-Cisco-IOSvL2** | `Gi1/1` | Acceso (VLAN 10) | `PC1-Usuario` | Segmento de Usuarios |
| **SW1-Cisco-IOSvL2** | `Gi2/1` | Acceso (VLAN 20) | `Web-Server` | Alojamiento Servidor Web |
| **SW1-Cisco-IOSvL2** | `Gi3/1` | Acceso (VLAN 20) | `DB-Server` | Alojamiento Servidor de BD |
| **SW1-Cisco-IOSvL2** | Resto | Acceso (VLAN 99) | No conectados | Puertos apagados administrativamente |

---

## 3. Esquema Matemático de Direccionamiento IP Basado en Matrícula

Para dar estricto cumplimiento al lineamiento académico de **"Utilizar direccionamiento IP en base a su matrícula"**, tomé mi matrícula estudiantil **2025-0720**:
- El prefijo de red base lo estructuré como **`10.25.72.0`**, donde `25` se extrae del año lectivo (`2025`) y `72` del inicio del bloque numérico (`0720`).

A partir de esta base, realicé el diseño y cálculo mediante técnica VLSM (*Variable Length Subnet Mask*):

### 3.1 Subred de Usuarios (VLAN 10) - Prefijo `/25`
- **Requerimiento:** Subred para clientes de usuario con máscara `/25`.
- **Dirección de Red:** `10.25.72.0/25`
- **Máscara de Subred:** `255.255.255.128`
- **Dirección de Gateway (FortiGate `port2.10`):** `10.25.72.1`
- **Rango de Direcciones Útiles:** `10.25.72.1` - `10.25.72.126` (126 hosts posibles)
- **Dirección de Broadcast:** `10.25.72.127`
- **Rango Asignado a Pool DHCP:** `10.25.72.10` a `10.25.72.100`
- **Dirección Asignada a PC1:** `10.25.72.10`

### 3.2 Subred de Servidores / DMZ (VLAN 20) - Prefijo `/28`
- **Requerimiento:** Subred para servidores corporativos con máscara `/28`.
- **Dirección de Red:** `10.25.72.128/28`
- **Máscara de Subred:** `255.255.255.240`
- **Dirección de Gateway (FortiGate `port2.20`):** `10.25.72.129`
- **Rango de Direcciones Útiles:** `10.25.72.129` - `10.25.72.142` (14 hosts posibles)
- **Dirección de Broadcast:** `10.25.72.143`
- **Dirección Asignada a Web-Server:** `10.25.72.130/28` (Estática)
- **Dirección Asignada a DB-Server:** `10.25.72.131/28` (Estática)

---

## 4. Endurecimiento de Seguridad de Capa 2 en Conmutador Cisco (`SW1`)

En el switch Cisco IOSvL2 implementé una política integral de endurecimiento (*Layer 2 Security Hardening*) orientada a mitigar vectores comunes de ataque en redes de área local:

1. **Segmentación y Estructura de VLANs:**
   - Creé la VLAN 10 (`USERS`), VLAN 20 (`SERVERS`) y VLAN 99 (`NATIVE_PARKING`).
   - Configuré el enlace troncal `Gi0/0` limitando explícitamente las VLANs permitidas (`switchport trunk allowed vlan 10,20`) y reasignando la VLAN nativa a la VLAN 99 para evitar ataques de etiquetado doble (*Double Tagging*).

2. **Mitigación de Suplantación de MAC (*Port-Security*):**
   - En cada interfaz de acceso activé `switchport port-security`, estableciendo un límite estricto de 2 direcciones MAC por puerto y modo de violación `restrict`.
   - Habilité el aprendizaje persistente `mac-address sticky`, logrando que el switch fije automáticamente las direcciones MAC legítimas de los dispositivos en su tabla segura:
     - `Gi1/1` (PC1): `0242.84c6.e700`
     - `Gi2/1` (Web-Server): `0242.324f.ed00`
     - `Gi3/1` (DB-Server): `0242.eb03.1300`

3. **Protección de Topología Spanning-Tree:**
   - En todos los puertos conectados a estaciones finales y servidores configuré `spanning-tree portfast` para optimizar la convergencia inmediata del enlace, acompañado de `spanning-tree bpduguard enable` para deshabilitar automáticamente la interfaz si recibe paquetes BPDU no autorizados.

4. **Prevención de Servidores DHCP Falsos (*DHCP Snooping*):**
   - Habilité `ip dhcp snooping` globalmente y de forma específica para la VLAN 10.
   - Definí el puerto troncal hacia el FortiGate (`Gi0/0`) como el único enlace confiable (`ip dhcp snooping trust`).
   - Desactivé la inserción de la Opción 82 (`no ip dhcp snooping information option`) para garantizar que las peticiones DHCP Discover originadas por los clientes lleguen limpias al servidor DHCP del firewall.

5. **Aislamiento de Puertos No Utilizados:**
   - Todos los puertos libres del switch (`Gi1/0`, `Gi1/2`, `Gi1/3`, `Gi2/0`, `Gi2/2-2/3`, `Gi3/0`, `Gi3/2-3/3`) fueron asociados a la VLAN 99 y apagados administrativamente (`shutdown`).

6. **Seguridad Administrativa:**
   - Protegí el modo privilegiado con `enable secret 5 $1$zv4r$F6UjuspAYL/qSdvGRRNzu/` (contraseña cifrada `Itla2025*`) y establecí el banner MOTD institucional:
     `ACCESO RESTRINGIDO - TAREA 2 CRISTOPHER NAVARRO 2025-0720`.

---

## 5. Implementación y Políticas de Seguridad en FortiGate NGFW

En el firewall FortiGate configuré la inspección unificada de amenazas (*UTM*) y la tabla de directivas de seguridad para gobernar el flujo entre zonas:

### 5.1 Matriz de Políticas de Firewall

```
+----+-----------------------+------------+------------+---------------+--------------+--------+----------------------------+
| ID | Nombre de Política    | Origen     | Destino    | Direcciones   | Servicios    | Acción | Perfiles de Seguridad UTM  |
+----+-----------------------+------------+------------+---------------+--------------+--------+----------------------------+
| 1  | USERS_TO_WEB_HTTPS    | port2.10   | port2.20   | USERS_VLAN10  | HTTP, HTTPS  | ACCEPT | Proxy Inspection, DPI,     |
|    |                       | (VLAN 10)  | (VLAN 20)  | -> WEB_SERVER |              |        | IPS_SQLI, WebFilter/File   |
+----+-----------------------+------------+------------+---------------+--------------+--------+----------------------------+
| 2  | BLOCK_USERS_TO_DB     | port2.10   | port2.20   | USERS_VLAN10  | ALL          | DENY   | Log de tráfico completo    |
|    |                       | (VLAN 10)  | (VLAN 20)  | -> DB_SERVER  |              |        | (Bloqueo estricto)         |
+----+-----------------------+------------+------------+---------------+--------------+--------+----------------------------+
| 3  | WEB_TO_DB_MYSQL       | port2.20   | port2.20   | WEB_SERVER    | ALL (MySQL)  | ACCEPT | Log de tráfico completo    |
|    |                       | (VLAN 20)  | (VLAN 20)  | -> DB_SERVER  |              |        |                            |
+----+-----------------------+------------+------------+---------------+--------------+--------+----------------------------+
| 4  | LAN_TO_WAN_INTERNET   | port2.10,  | port1      | all -> all    | ALL          | ACCEPT | NAT Habilitado             |
|    |                       | port2.20   | (WAN)      |               |              |        |                            |
+----+-----------------------+------------+------------+---------------+--------------+--------+----------------------------+
```

### 5.2 Firma Personalizada de Prevención de Intrusiones (IPS) para SQL Injection
Para detectar y mitigar ataques dirigidos contra el Servidor Web, diseñé una firma IPS personalizada (`SQLI_PAYLOAD`) con el motor de patrones de FortiOS:
```text
config ips custom
    edit "SQLI_PAYLOAD"
        set signature "F-SBID( --attack_id 2581; --name \"CUSTOM.SQLI.PAYLOAD\"; --protocol tcp; --service HTTP; --pattern \"OR\"; --context uri; --no_case; )"
        set action block
        set comment "Detect SQL Injection attempt and block"
    next
end
```
Esta regla la integré dentro del sensor `IPS_SQLI`, asignándole como contramedida inmediata el descarte de sesión y la puesta en cuarentena automática del host agresor:
```text
config ips sensor
    edit "IPS_SQLI"
        config entries
            edit 1
                set rule 2581
                set status enable
                set action block
                set quarantine attacker
                set quarantine-expiry 10m
            next
        end
    next
end
```

### 5.3 Control y Bloqueo de Descarga de Archivos Ejecutables (.exe)
Para neutralizar la descarga involuntaria de malware o ejecutables en la red de usuarios, configuré el perfil de filtrado de archivos (`file-filter profile BLOCK_EXE`) y el filtro de URLs locales (`webfilter profile BLOCK_EXE`) en modo proxy:
- **Regla de Bloqueo:** Filtro sobre protocolo HTTP en cualquier dirección coincidiendo con tipos de archivo `exe`, `bat` y `elf`.
- **Comportamiento:** Si un usuario intenta descargar `http://10.25.72.130/test.exe`, el proxy de FortiGate cancela la transferencia y responde con una página oficial de reemplazo con código **HTTP 403 Forbidden**.

### 5.4 Mitigación de Ataques DoS / Rate-Limiting IPv4
Configuré una directiva de denegación de servicio (`config firewall DoS-policy edit 1 "RATE_LIMIT_DOS"`) asociada a la subinterfaz de usuarios `port2.10` hacia el Servidor Web, estableciendo límites estrictos contra inundaciones:
- `tcp_syn_flood`: Umbral de 50 pps (Acción: `block`, cuarentena de atacante).
- `udp_flood`: Umbral de 50 pps (Acción: `block`).
- `icmp_flood`: Umbral de 50 pps (Acción: `block`).
- `ip_src_session`: Límite de 30 sesiones TCP/IP simultáneas por host.

---

## 6. Batería de Pruebas y Validación Técnica de Campo

A continuación detallo las pruebas realizadas directamente en vivo en los equipos, con los comandos ejecutados y la respuesta capturada:

### Prueba 1: Concesión Dinámica DHCP en Estación de Trabajo (`PC1-Usuario`)
- **Comando:** `udhcpc -i eth0` / `ip addr show eth0; ip route`
- **Respuesta:**
  ```text
  udhcpc: lease of 10.25.72.10 obtained from 10.25.72.1, lease time 604800
  inet 10.25.72.10/25 scope global eth0
  default via 10.25.72.1 dev eth0 metric 218
  ```
- **Evaluación:** Superada con éxito. El servidor DHCP de FortiGate entregó la primera IP útil del pool (`10.25.72.10`), máscara `/25` y gateway `10.25.72.1`.

### Prueba 2: Conectividad ICMP hacia Gateway y Salida WAN vía NAT
- **Comando:** `ping -c 3 10.25.72.1` y `ping -c 3 8.8.8.8` desde PC1
- **Respuesta:**
  ```text
  --- 10.25.72.1 ping statistics ---
  3 packets transmitted, 3 packets received, 0% packet loss, rtt avg = 4.060 ms
  
  --- 8.8.8.8 ping statistics ---
  3 packets transmitted, 3 packets received, 0% packet loss, rtt avg = 38.515 ms
  ```
- **Evaluación:** Superada con éxito. La estación de usuario tiene comunicación directa con su puerta de enlace y navega a Internet a través del enrutamiento NAT de FortiGate.

### Prueba 3: Acceso Web de Usuarios (Política 1: `USERS_TO_WEB_HTTPS`)
- **Comandos:**
  - Sondeo de puertos: `nc -z -v -w 3 10.25.72.130 80` y `nc -z -v -w 3 10.25.72.130 443`
  - Petición HTTP: `wget -O - http://10.25.72.130/`
- **Respuesta:**
  ```text
  10.25.72.130 (10.25.72.130:80) open
  10.25.72.130 (10.25.72.130:443) open
  Connecting to 10.25.72.130 (10.25.72.130:80)
  <html><body><h1>Servidor Web Seguro - Tarea 2 Cristopher Navarro (2025-0720)</h1></body></html>
  ```
- **Evaluación:** Superada con éxito. El tráfico HTTP y HTTPS es permitido hacia el Servidor Web según la directiva autorizada.

### Prueba 4: Bloqueo de Acceso Directo a Base de Datos (Política 2: `BLOCK_USERS_TO_DB`)
- **Comando:** `nc -z -v -w 3 10.25.72.131 3306` desde PC1
- **Respuesta:**
  ```text
  nc: 10.25.72.131 (10.25.72.131:3306): Operation timed out
  ```
- **Evaluación:** Superada con éxito. La política `BLOCK_USERS_TO_DB` intercepta y descarta silenciosamente los paquetes con destino al puerto 3306, evitando accesos no autorizados a la base de datos desde la red de usuarios.

### Prueba 5: Comunicación Autorizada entre Servidores (Política 3: `WEB_TO_DB_MYSQL`)
- **Comando:** `nc -z -v -w 3 10.25.72.131 3306` y handshake desde Web-Server
- **Respuesta:**
  ```text
  10.25.72.131 (10.25.72.131:3306) open
  5.7.35-MySQL Community Server (GPL)
  ```
- **Evaluación:** Superada con éxito. La comunicación inter-servidor en el puerto 3306 se establece de manera legítima.

### Prueba 6: Simulación de Ataque SQLi, Disparo de Firma IPS y Aislamiento en Cuarentena
- **Comando ejecutado en PC1:**
  ```bash
  echo -e "GET /?id=1' OR '1'='1 HTTP/1.1\r\nHost: 10.25.72.130\r\nConnection: close\r\n\r\n" | nc -w 3 10.25.72.130 80
  ```
- **Consulta inmediata en consola de FortiGate:**
  ```text
  FortiGate-Hardened # diagnose user quarantine list
  src-ip-addr       created                  expires                  cause            
  10.25.72.10       Tue Sep 22 15:49:59 2026 Tue Sep 22 15:59:59 2026 IPS              
  
  FortiGate-Hardened # diagnose ips packet status
  PACKET ACTION STATISTICS:
    DROP_SESSION          4
  ```
- **Evaluación:** Superada con éxito. El motor de prevención de intrusiones identificó la inyección SQL, abortó la sesión maliciosa y confinó la dirección IP atacante (`10.25.72.10`) en la lista de cuarentena por 10 minutos.

### Prueba 7: Intercepción de Descarga de Ejecutables (`.exe`)
- **Comando ejecutado en PC1:**
  ```bash
  wget -O - http://10.25.72.130/test.exe
  ```
- **Respuesta:**
  ```text
  Connecting to 10.25.72.130 (10.25.72.130:80)
  wget: server returned error: HTTP/1.1 403 Forbidden
  ```
- **Evaluación:** Superada con éxito. La transferencia del binario fue vetada y respondida con un error 403 Forbidden mediante el perfil de seguridad de FortiGate.

---

## 7. Conclusiones y Aprendizajes Técnicos

1. **Efectividad del Enfoque Defense-in-Depth:** La articulación coordinada de controles en Capa 2 (Port-Security, DHCP Snooping, BPDU Guard) con inspección de Capa 7 en el NGFW FortiGate demostró que la seguridad integral exige protección en cada eslabón de la infraestructura.
2. **Importancia de las Firmas Personalizadas:** Las firmas predefinidas no siempre cubren vectores específicos de una aplicación corporativa. Diseñar y activar firmas IPS a medida (`SQLI_PAYLOAD`) con acciones punitivas automáticas de cuarentena permite una respuesta a incidentes en tiempo real sin intervención manual del analista de seguridad.
3. **Control Riguroso de Superficie de Exposición:** La regla de bloquear usuarios hacia la base de datos mientras se autoriza únicamente el tráfico entre el servidor web y la base de datos garantiza una arquitectura tradicional de dos capas (*two-tier architecture*), reduciendo drásticamente la exposición del activo crítico.

---

## 8. Recursos de Entrega y Enlaces

- **Repositorio de Código y Configuraciones:** `https://github.com/CristopherNavarro/Tarea2_SeguridadRedes_CristopherNavarro_20250720` *(Repositorio GitHub oficial)*
- **Video Demostrativo de la Práctica (YouTube):** `https://youtu.be/...` *(Enlace del video demostrativo grabado por el estudiante)*
- **Archivo de Respaldo Local:** `Entregables para el profesor Github/configs/`

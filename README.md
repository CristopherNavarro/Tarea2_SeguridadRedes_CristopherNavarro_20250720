# Tarea #2 (Práctica 1) - Infraestructura y Hardening de Seguridad de Redes

[![FortiOS 7.0.9](https://img.shields.io/badge/FortiOS-7.0.9-red.svg)](https://www.fortinet.com/)
[![Cisco IOSvL2](https://img.shields.io/badge/Cisco_IOS-15.2-blue.svg)](https://www.cisco.com/)
[![GNS3](https://img.shields.io/badge/Simulator-GNS3_2.2.61-green.svg)](https://www.gns3.com/)
[![Status](https://img.shields.io/badge/Estado-100%25_Completado-brightgreen.svg)]()

> **Asignatura:** Seguridad de Redes  
> **Docente:** Jonathan Esteban Rondón Corniel  
> **Estudiante:** Cristopher Navarro  
> **Matrícula:** 2025-0720  
> **Institución:** Instituto Tecnológico de Las Américas (ITLA)  

---

## Enlace al Video Demostrativo

- **Video Explicativo en YouTube:** [Ver Demostración en YouTube](https://youtu.be/PENDIENTE_GRABACION)  
*(Grabación técnica de máximo 10 minutos cumpliendo con todos los lineamientos: presentación de rostro, voz, fecha y hora en tiempo real, recorrido de topología y validación en vivo de cada comando).*

---

## 1. Descripción del Proyecto

En este repositorio presento la implementación, configuración y endurecimiento (*hardening*) de una topología de seguridad de redes simulada en **GNS3** con backend en **VMware Workstation Pro 17**. 

El diseño incorpora un firewall de última generación **FortiGate (v7.0.9)** como nodo perimetral de enrutamiento e inspección de amenazas (NGFW), un switch multicapa **Cisco IOSvL2** para segmentación de Capa 2 y tres zonas de red bien diferenciadas: red de usuarios (LAN), zona de servidores (DMZ) y salida a Internet (WAN).

---

## 2. Topología de Red y Arquitectura

```
                           +------------------------+
                           |      INTERNET / WAN    |
                           |       (Nodo NAT1)      |
                           +------------------------+
                                       |
                                       | [port1 - WAN/DHCP + NAT]
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
   | 10.25.72.10/25    |     | 10.25.72.130/28   |   | 10.25.72.131/28   |
   | (DHCP FortiGate)  |     | (HTTP:80/HTTPS:443|   | (MySQL:3306)      |
   +-------------------+     +-------------------+   +-------------------+
```

---

## 3. Direccionamiento IP Basado en Matrícula (2025-0720)

Para dar estricto cumplimiento a la pauta de direccionamiento en base a matrícula, utilicé la base privada **`10.25.72.0`**:

| Zona / Segmento | VLAN | Red / Prefijo | Gateway | Rango Útil | Dirección Asignada | Método |
|---|:---:|---|---|---|---|:---:|
| **Usuarios (LAN)** | 10 | `10.25.72.0/25` | `10.25.72.1` | `10.25.72.1` - `10.25.72.126` | `10.25.72.10` (PC1) | DHCP FortiGate |
| **Servidores (DMZ)** | 20 | `10.25.72.128/28` | `10.25.72.129` | `10.25.72.129` - `10.25.72.142` | `10.25.72.130` (Web)<br>`10.25.72.131` (DB) | Estático |
| **Salida WAN** | - | `192.168.122.0/24` | Dinámico | Segmento NAT GNS3 | Asignación DHCP WAN | DHCP / NAT |

---

## 4. Resumen de Hardening Implementado

### 4.1 En Switch Cisco IOSvL2 (`SW1`)
- **Segmentación:** VLANs 10 (USERS), 20 (SERVERS) y 99 (NATIVE_PARKING).
- **Enlace Troncal:** `Gi0/0` en 802.1Q con `native vlan 99` y filtrado `switchport trunk allowed vlan 10,20`.
- **Port-Security:** Modo `restrict`, límite de 2 MACs por puerto, aprendizaje de MACs en hardware vía `mac-address sticky`.
- **Spanning-Tree:** `PortFast` y `BPDU Guard` habilitados en todas las interfaces de acceso (`P2p Edge`).
- **DHCP Snooping:** Activo en VLAN 10; enlace `Gi0/0` configurado como `trusted`. Inserción de opción 82 desactivada para compatibilidad directa.
- **Aislamiento de Puertos:** Interfaces sin uso asignadas a VLAN 99 y apagadas (`shutdown`).
- **Autenticación:** Contraseña de modo privilegiado cifrada con algoritmo tipo 5 (`enable secret`) y banner MOTD institucional.

### 4.2 En Firewall FortiGate (`FortiGate-7.0.9`)
- **Subinterfaces:** `port2.10` (`10.25.72.1/25`) y `port2.20` (`10.25.72.129/28`) sobre enlace troncal `port2`.
- **Servidor DHCP:** Pool `10.25.72.10 - 10.25.72.100` en VLAN 10 entregando gateway y DNS.
- **Enrutamiento y NAT:** Ruta por defecto `0.0.0.0/0` hacia WAN (`port1`), con traducción NAT para navegación a Internet.
- **Directivas de Tráfico:**
  - **Política 1:** Usuarios -> Servidor Web (HTTP/HTTPS) permitido con inspección UTM y proxy.
  - **Política 2:** Usuarios -> Servidor de Base de Datos (puerto 3306) **bloqueado terminantemente**.
  - **Política 3:** Servidor Web -> Servidor de Base de Datos (MySQL 3306) **permitido exclusivamente**.
  - **Política 4:** Tráfico LAN -> WAN (Internet) con NAT habilitado.
- **Inspección Profunda e IPS:** Firma personalizada #2581 (`SQLI_PAYLOAD`) para detectar inyecciones SQL en el URI, cancelando la sesión y enviando al atacante a **cuarentena automática durante 10 minutos**.
- **Filtrado de Archivos:** Perfil `file-filter` y filtro URL bloqueando descargas de archivos ejecutables (`.exe`, `.bat`, `.elf`), respondiendo con código **HTTP 403 Forbidden**.
- **Mitigación DoS:** Política DoS IPv4 activa limitando inundaciones TCP SYN, UDP, ICMP y número de sesiones simultáneas.

---

## 5. Matriz de Pruebas y Resultados de Validación

| # | Prueba / Requisito Evaluado | Comando Ejecutado | Resultado Obtenido | Estado |
|---|---|---|---|:---:|
| **1** | **DHCP en VLAN 10** | `udhcpc -i eth0` en PC1 | IP `10.25.72.10/25`, Gateway `10.25.72.1`. Ping 0% pérdida. | **Aprobado** |
| **2** | **Acceso Web Seguro** | `wget -O - http://10.25.72.130/` | HTTP 200 OK, página entregada con banner web legítimo. Puertos 80 y 443 abiertos. | **Aprobado** |
| **3** | **Bloqueo Acceso a BD** | `nc -z -v -w 3 10.25.72.131 3306` | `Operation timed out`. Tráfico bloqueado estrictamente por Política 2. | **Aprobado** |
| **4** | **Acceso Web a BD** | `nc -z -v -w 3 10.25.72.131 3306` | Conexión establecida (`open`). Handshake de MySQL recibido exitosamente. | **Aprobado** |
| **5** | **Detección Ataque SQLi** | `GET /?id=1' OR '1'='1` desde PC1 | Firma IPS 2581 activada, paquete descartado (`DROP_SESSION`). | **Aprobado** |
| **6** | **Cuarentena Automática** | `diagnose user quarantine list` | Host `10.25.72.10` en cuarentena inmediata por causa `IPS` con vencimiento a 10 min. | **Aprobado** |
| **7** | **Bloqueo Ejecutables (.exe)** | `wget -O - http://10.25.72.130/test.exe` | Intercepción inmediata de FortiGate: `HTTP/1.1 403 Forbidden`. | **Aprobado** |
| **8** | **Mitigación DoS / Rate-Limit** | `show firewall DoS-policy 1` | Regla `RATE_LIMIT_DOS` activa con umbrales configurados para SYN, UDP, ICMP y sesiones. | **Aprobado** |
| **9** | **Hardening L2 en Switch** | `show port-security`, `show ip dhcp snooping` | Modo `Restrict` activo, MACs sticky aprendidas, DHCP snooping y BPDU guard operativos. | **Aprobado** |

---

## 6. Estructura de Archivos del Repositorio

```text
├── README.md                                                  <- Portada oficial y resumen del proyecto
├── Memoria_Tecnica_Seguridad_Redes_CristopherNavarro_20250720.md <- Documento técnico académico completo
├── CristopherNavarro_20250720_P1.txt                          <- Archivo de entrega oficial para plataforma
├── topologia/
│   ├── Tarea2_SeguridadRedes_CristopherNavarro_20250720.gns3  <- Archivo de topología nativo para GNS3
│   └── INSTRUCCIONES_IMPORTACION_TOPOLOGIA.md                 <- Guía de importación para el profesor
└── configs/
    ├── SW1_Cisco_running_config.txt                           <- Respaldo de configuración activa de Cisco SW1
    ├── FortiGate_config_backup.conf                           <- Respaldo de configuración completa de FortiOS
    └── hosts_services_config.sh                               <- Scripts de arranque de servicios de servidores
```

---

## 7. Autor y Créditos Académicos

* **Estudiante:** Cristopher Navarro  
* **Matrícula:** 2025-0720  
* **Carrera:** Redes y Seguridad Informática  
* **Docente:** Jonathan Esteban Rondón Corniel  
* **Institución:** Instituto Tecnológico de Las Américas (ITLA)  

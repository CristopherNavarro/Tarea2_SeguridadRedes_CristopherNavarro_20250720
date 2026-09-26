# Instrucciones de Importación de Topología GNS3

**Asignatura:** Seguridad de Redes  
**Docente:** Jonathan Esteban Rondón Corniel  
**Estudiante:** Cristopher Navarro  
**Matrícula:** 2025-0720  
**Proyecto:** Tarea #2 (Práctica 1)  

---

## 1. Archivo de Topología Incluido

En este directorio se incluye el archivo de topología maestro en formato nativo de GNS3:
- **`Tarea2_SeguridadRedes_CristopherNavarro_20250720.gns3`**: Archivo JSON de definición completa de nodos, interfaces, coordenadas y enlaces de la simulación.

---

## 2. Requisitos Previos para la Apertura

Para abrir y ejecutar esta topología se requiere:
1. **GNS3 2.2.x** (probado y certificado en GNS3 versión 2.2.61).
2. **GNS3 VM** ejecutándose en VMware Workstation Pro / Player o VirtualBox.
3. **Imágenes / Appliances instalados en GNS3 VM:**
   - **FortiGate NGFW:** Imagen QEMU `FortiGate 7.0.9` (`fortios.qcow2`).
   - **Switch Cisco L2:** Imagen QEMU `Cisco IOSvL2` (`viosl2-adventerprisek9-m.ssa.high_iron_20200929`).
   - **Nodos Hosts:** Imagen Docker `Alpine Linux` con herramientas de red (`curl`, `wget`, `netcat`, `udhcpc`).
   - **Nodo NAT:** Conector estándar de salida a Internet de GNS3.

---

## 3. Procedimiento para Abrir el Proyecto en GNS3

1. Abra la interfaz gráfica de GNS3 y asegúrese de que el servidor local y la máquina virtual **GNS3 VM** se encuentren en verde.
2. Vaya al menú superior: `File` -> `Open Project...` (o presione `Ctrl + O`).
3. Navegue hasta la carpeta donde descargó o clonó este repositorio, ingrese a la carpeta `topologia/` y seleccione el archivo `Tarea2_SeguridadRedes_CristopherNavarro_20250720.gns3`.
4. GNS3 cargará la disposición completa de los nodos con sus enlaces y direccionamiento gráfico.
5. Para inicializar los dispositivos:
   - Haga clic en el botón verde **Start/Resume all nodes** en la barra superior.
   - Si desea aplicar o verificar las configuraciones limpias de fábrica, los archivos de respaldo se encuentran disponibles en la carpeta `configs/` de este mismo repositorio:
     - `configs/SW1_Cisco_running_config.txt`
     - `configs/FortiGate_config_backup.conf`
     - `configs/hosts_services_config.sh`

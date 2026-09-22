# Urbania

Sistema de gestión agrícola para huertos urbanos. Administra huertos, parcelas, cultivos, siembras, seguimientos, incidencias y cosechas, además de la bitácora de actividades y las estadísticas generales del sistema.

## Descripción

Esta versión es un **prototipo de estructura**: HTML5 puro, sin hojas de estilo, sin JavaScript y sin conexión a una base de datos. Cada módulo del menú es una sola página con datos de ejemplo, pensada para revisar la navegación y los campos de cada operación antes de construir la implementación funcional.

## Roles del sistema

Cada rol solo ve, al iniciar sesión, el menú con sus módulos permitidos.

| Rol | Alcance |
|---|---|
| Administrador | Control total del sistema: administra usuarios y accede a todos los módulos. |
| Encargado de Huerto | Operación diaria del huerto: huertos, parcelas, cultivos, siembras y su seguimiento. |
| Supervisor Agrícola | Supervisión agrícola: seguimientos, incidencias, cultivos, bitácora y estadísticas. |
| Responsable de Cosecha | Gestión de cosechas: consulta de siembras, registro de cosechas, bitácora y estadísticas. |

## Módulos

| Módulo | Descripción | Requisitos |
|---|---|---|
| Usuarios | Inicio/cierre de sesión, alta, consulta, actualización y baja de usuarios. | RF-01 a RF-06 |
| Huertos | Alta, consulta, actualización y baja de huertos. | RF-07 a RF-10 |
| Siembras | Alta y consulta de siembras, ficha en PDF, cálculo de totales y gráfica mensual. | RF-11 a RF-17 |
| Parcelas | Alta de parcelas asociadas a un huerto, consulta, actualización y baja. | RF-18 a RF-21 |
| Seguimientos | Seguimiento de cultivos, evidencias, historial en PDF, total y gráfica de actividades. | RF-22 a RF-29 |
| Cultivos | Alta, consulta, actualización y baja de cultivos. | RF-30 a RF-33 |
| Incidencias | Tipos de incidencia, registro, consulta, actualización, baja, evidencias, reporte y gráfica. | RF-34 a RF-45 |
| Cosechas | Alta, consulta, actualización, baja, evidencia, reporte, rendimiento y producción por cultivo. | RF-46 a RF-53 |
| Bitácora | Registro y consulta de las actividades realizadas por los usuarios. | RF-54 y RF-55 |
| Estadísticas | Consulta de las estadísticas y gráficas generales del sistema. | RF-56 y RF-57 |

## Cómo leer este prototipo

- Los formularios no envían información a ningún servidor: muestran los campos que tendría cada operación.
- Las secciones marcadas con una flecha ("Actualizar", "Eliminar" y similares) se pueden abrir y cerrar; están recogidas por defecto para que la operación principal de cada módulo (alta y consulta) quede primero.
- Como no hay JavaScript ni servidor, en **Iniciar sesión** el rol no se elige con una lista desplegable separada del botón: cada rol tiene su propio botón de inicio de sesión, y al pulsarlo se simula el resultado de haber entrado con ese rol y se abre el menú correspondiente, que solo enlaza los módulos permitidos para él.

## Estructura del proyecto

```
urbania/
├── index.html                 # Página de inicio
├── login.html                 # Inicio de sesión (accesos directos por rol)
├── registro.html               # Registro de usuarios
├── menu-administrador.html     # Menú del rol Administrador
├── menu-encargado.html         # Menú del rol Encargado de Huerto
├── menu-supervisor.html        # Menú del rol Supervisor Agrícola
├── menu-cosecha.html           # Menú del rol Responsable de Cosecha
├── usuarios.html
├── huertos.html
├── parcelas.html
├── cultivos.html
├── siembras.html
├── seguimientos.html
├── incidencias.html
├── cosechas.html
├── bitacora.html
├── estadisticas.html
└── logo.jpeg
```

## Cómo ejecutarlo

Al ser HTML puro sin dependencias, basta con abrir `index.html` en un navegador, o servirlo con un servidor estático simple (por ejemplo, la extensión Live Server de VS Code).

## Tecnologías

- HTML5 (sin hojas de estilo ni JavaScript en esta versión)

## Estado

Prototipo de estructura y navegación. Pendiente de estilos, lógica de cliente/servidor y persistencia de datos.

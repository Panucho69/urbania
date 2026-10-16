-- =====================================================================
--  URBANIA — Base de datos (MySQL 8 / MariaDB 10.5+)
--  Proyecto integrador · Programación Web · TecNM Villahermosa
--  Basada en el Diccionario de Datos CORREGIDO.
--
--  REGLAS DE NOMBRES
--  * Cada columna usa EXACTAMENTE una palabra del diccionario; el número
--    entre [ ] es su número en el diccionario actualizado.
--  * Cuando el diccionario tiene dos nombres para el MISMO dato
--    (ej. Correo_Login y Correo_Usuarios), la columna lleva el nombre BASE
--    y el otro se anota como "también se captura como".
--  * Los Id_ (llaves primarias) y las llaves foráneas NO están en el
--    diccionario, por regla; aquí sí aparecen porque la base las necesita.
--  * Los campos que "no se guardan" (Periodo_*, Filtro_Bitacora, gráficas,
--    estadísticas) se resuelven con VISTAS y CONSULTAS al final.
-- =====================================================================

DROP DATABASE IF EXISTS urbania;
CREATE DATABASE urbania CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;
USE urbania;

-- ---------------------------------------------------------------------
-- 1. USUARIOS  (Iniciar sesión, Registro, módulo Usuarios RF-03/05/06)
-- ---------------------------------------------------------------------
CREATE TABLE Usuarios (
  Id_Usuario        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,   -- ID (no va en el diccionario)
  Nombre_Login      VARCHAR(120) NOT NULL,                     -- [43] también se captura como Nombre_Usuario [45]
  Correo_Login      VARCHAR(120) NOT NULL UNIQUE,              -- [18] también se captura como Correo_Usuarios [19];
                                                               --      Usuario_Login [64] se compara contra este campo
  Contrasena_Login  VARCHAR(255) NOT NULL,                     -- [16] cifrada; también se captura como Contrasena_Usuario [17]
                                                               --      Confirmar_Contrasena_Login [14] solo valida, no se guarda
  Rol               ENUM('Administrador','Encargado de Huerto',    -- [57]
                         'Supervisor Agrícola','Responsable de Cosecha') NOT NULL,
  Estado_Usuario    ENUM('Activo','Inactivo') NOT NULL DEFAULT 'Activo',         -- [28] NUEVO: baja lógica RF-06
  INDEX idx_estado_usuario (Estado_Usuario)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. HUERTOS  (RF-07, RF-09, RF-10)
-- ---------------------------------------------------------------------
CREATE TABLE Huertos (
  Id_Huerto          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  Nombre_Huerto      VARCHAR(80)  NOT NULL,                    -- [41]
  Descripcion_Huerto TEXT         NOT NULL,                    -- [22] lo sustituye Descripcion_Registro_Huerto [24] al actualizar
  Ubicacion_Huerto   VARCHAR(150) NOT NULL,                    -- [62]
  Activo_Huerto      TINYINT(1)   NOT NULL DEFAULT 1,          -- [5]  NUEVO: eliminación lógica RF-10
  INDEX idx_activo_huerto (Activo_Huerto)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. PARCELAS  (RF-18, RF-20, RF-21)
-- ---------------------------------------------------------------------
CREATE TABLE Parcelas (
  Id_Parcela         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  Id_Huerto          INT UNSIGNED NOT NULL,                    -- FK -> Huertos
  Nombre_Parcela     VARCHAR(60)  NOT NULL,                    -- [44]
  Ubicacion_Parcela  VARCHAR(80)  NOT NULL,                    -- [63]
  Activo_Parcela     TINYINT(1)   NOT NULL DEFAULT 1,          -- [7]  NUEVO: eliminación lógica RF-21
  CONSTRAINT fk_parcela_huerto FOREIGN KEY (Id_Huerto) REFERENCES Huertos(Id_Huerto)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_activo_parcela (Activo_Parcela)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. CULTIVOS  (RF-30, RF-32, RF-33)
-- ---------------------------------------------------------------------
CREATE TABLE Cultivos (
  Id_Cultivo          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  Nombre_Cultivo      VARCHAR(60) NOT NULL UNIQUE,             -- [40] contra este se compara Cultivo_Seguimiento [20]
  Tipo_Cultivo        VARCHAR(60) NOT NULL,                    -- [61]
  Descripcion_Cultivo TEXT        NOT NULL,                    -- [21]
  Activo_Cultivo      TINYINT(1)  NOT NULL DEFAULT 1,          -- [4]  NUEVO: eliminación lógica RF-33
  INDEX idx_activo_cultivo (Activo_Cultivo)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. SIEMBRAS  (RF-11 a RF-17)
-- ---------------------------------------------------------------------
CREATE TABLE Siembras (
  Id_Siembra       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  Id_Cultivo       INT UNSIGNED NOT NULL,                      -- FK -> Cultivos
  Id_Parcela       INT UNSIGNED NOT NULL,                      -- FK -> Parcelas
  Fecha_Siembra    DATE         NOT NULL,                      -- [36]
  Cantidad_Siembra INT UNSIGNED NOT NULL CHECK (Cantidad_Siembra > 0), -- [12]
  Estado_Siembra   ENUM('En crecimiento','Disponible para cosecha','Cosechada') -- [27] NUEVO
                   NOT NULL DEFAULT 'En crecimiento',          --      lo consulta el Responsable de Cosecha
  Activo_Siembra   TINYINT(1)   NOT NULL DEFAULT 1,            -- [9]  NUEVO: eliminación lógica RF-14
  CONSTRAINT fk_siembra_cultivo FOREIGN KEY (Id_Cultivo) REFERENCES Cultivos(Id_Cultivo)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_siembra_parcela FOREIGN KEY (Id_Parcela) REFERENCES Parcelas(Id_Parcela)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_fecha_siembra (Fecha_Siembra),                     -- Periodo_Inicio_Siembra / Periodo_Fin_Siembra
  INDEX idx_activo_siembra (Activo_Siembra),
  INDEX idx_estado_siembra (Estado_Siembra)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. SEGUIMIENTOS  (RF-22 a RF-29)
-- ---------------------------------------------------------------------
CREATE TABLE Seguimientos (
  Id_Seguimiento         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  Id_Siembra             INT UNSIGNED NOT NULL,                -- FK -> Siembras
  Fecha_Seguimiento      DATE         NOT NULL,                -- [35]
  Actividad_Seguimiento  VARCHAR(60)  NOT NULL,                -- [2]
  Observacion_Siembra    TEXT         NOT NULL,                -- [47] (el diccionario la ubica en Seguimientos)
  Evidencia_Seguimiento  VARCHAR(255) NULL,                    -- [31] ruta de la imagen (RF-26)
  Activo_Seguimiento     TINYINT(1)   NOT NULL DEFAULT 1,      -- [8]  NUEVO: eliminación lógica RF-25
  CONSTRAINT fk_seguimiento_siembra FOREIGN KEY (Id_Siembra) REFERENCES Siembras(Id_Siembra)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_activo_seguimiento (Activo_Seguimiento)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. TIPOS_INCIDENCIA  (RF-34, RF-36, RF-37) — catálogo
-- ---------------------------------------------------------------------
CREATE TABLE Tipos_Incidencia (
  Id_Tipo_Incidencia      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  Nombre_Incidencias      VARCHAR(60) NOT NULL UNIQUE,         -- [42]
  Descripcion_Incidencias TEXT        NOT NULL,                -- [23]
  Activo_Tipo_Incidencia  TINYINT(1)  NOT NULL DEFAULT 1,      -- [10] NUEVO: no rompe las incidencias que ya usan el tipo
  INDEX idx_activo_tipo_incidencia (Activo_Tipo_Incidencia)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. INCIDENCIAS  (RF-38 a RF-45)
-- ---------------------------------------------------------------------
CREATE TABLE Incidencias (
  Id_Incidencia        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  Id_Tipo_Incidencia   INT UNSIGNED NOT NULL,                  -- FK -> Tipos_Incidencia
  Id_Cultivo           INT UNSIGNED NOT NULL,                  -- FK -> Cultivos (cultivo afectado)
  Fecha_Incidencia     DATE         NOT NULL,                  -- [34]
  Severidad_Incidencia ENUM('Baja','Media','Alta') NOT NULL DEFAULT 'Media',   -- [59]
  Estado_Incidencia    ENUM('Activa','Atendida')   NOT NULL DEFAULT 'Activa',  -- [26]
  Nueva_Incidencia     TEXT         NOT NULL,                  -- [46] lo sustituye Registro_Incidencia [56] al actualizar
  Evidencia_Incidencia VARCHAR(255) NULL,                      -- [30] ruta de la imagen (RF-42)
  Activo_Incidencia    TINYINT(1)   NOT NULL DEFAULT 1,        -- [6]  NUEVO: eliminación lógica RF-41
  CONSTRAINT fk_incidencia_tipo    FOREIGN KEY (Id_Tipo_Incidencia) REFERENCES Tipos_Incidencia(Id_Tipo_Incidencia)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_incidencia_cultivo FOREIGN KEY (Id_Cultivo)         REFERENCES Cultivos(Id_Cultivo)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_fecha_incidencia (Fecha_Incidencia),               -- Periodo_Incidencias
  INDEX idx_activo_incidencia (Activo_Incidencia)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. COSECHAS  (RF-46 a RF-53)
-- ---------------------------------------------------------------------
CREATE TABLE Cosechas (
  Id_Cosecha             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  Id_Siembra             INT UNSIGNED NOT NULL,                -- FK -> Siembras
  Fecha_Cosecha          DATE          NOT NULL,               -- [33]
  Cantidad_Kilos         DECIMAL(10,2) NOT NULL CHECK (Cantidad_Kilos > 0), -- [11]
  Observaciones_Cosechas TEXT          NOT NULL,               -- [48] lo sustituye Observaciones_Registro_Cosechas [49]
  Evidencia_Cosecha      VARCHAR(255)  NULL,                   -- [29] ruta de la imagen (RF-50)
  Activo_Cosecha         TINYINT(1)    NOT NULL DEFAULT 1,     -- [3]  NUEVO: eliminación lógica RF-49
  CONSTRAINT fk_cosecha_siembra FOREIGN KEY (Id_Siembra) REFERENCES Siembras(Id_Siembra)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_fecha_cosecha (Fecha_Cosecha),                     -- Periodo_Inicio_Cosechas / Periodo_Fin_Cosechas
  INDEX idx_activo_cosecha (Activo_Cosecha)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 10. BITACORA  (Filtrar bitácora)
-- ---------------------------------------------------------------------
CREATE TABLE Bitacora (
  Id_Bitacora      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  Id_Usuario       INT UNSIGNED NOT NULL,                      -- FK -> Usuarios (quién hizo la acción)
  Fecha_Bitacora   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP, -- [32] NUEVO (columna «Fecha y hora»)
  Accion_Bitacora  ENUM('Inicio de sesión','Alta','Baja','Modificación', -- [1] NUEVO: columna «Acción»
                        'Generación de reporte') NOT NULL,
  Detalle_Bitacora VARCHAR(255) NOT NULL,                      -- [25] NUEVO (columna «Detalle»)
  CONSTRAINT fk_bitacora_usuario FOREIGN KEY (Id_Usuario) REFERENCES Usuarios(Id_Usuario)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_fecha_bitacora (Fecha_Bitacora)                    -- Filtro_Bitacora
) ENGINE=InnoDB;

-- =====================================================================
--  DATOS DE EJEMPLO (los mismos del prototipo)
--  Contrasena_Login: hash de EJEMPLO (marcador). Al programar, genera el
--  real con password_hash($Contrasena_Login, PASSWORD_DEFAULT) en PHP.
-- =====================================================================
INSERT INTO Usuarios (Nombre_Login, Correo_Login, Contrasena_Login, Rol) VALUES
('Admin Urbania',             'admin@urbania.mx',     '$2y$10$EJEMPLOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'Administrador'),
('María Fernanda López Cruz', 'mlopez@urbania.mx',    '$2y$10$EJEMPLOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'Encargado de Huerto'),
('Jorge Iván Pérez Santos',   'jperez@urbania.mx',    '$2y$10$EJEMPLOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'Supervisor Agrícola'),
('Rosa Elena Martínez Díaz',  'rmartinez@urbania.mx', '$2y$10$EJEMPLOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'Responsable de Cosecha');

INSERT INTO Huertos (Nombre_Huerto, Descripcion_Huerto, Ubicacion_Huerto) VALUES
('Huerto Central', 'Huerto urbano principal, hortalizas de ciclo corto.', 'Av. Reforma 100, CDMX'),
('Huerto Norte',   'Huerto de apoyo para hierbas aromáticas.',            'Calle Pino 45, CDMX');

INSERT INTO Parcelas (Id_Huerto, Nombre_Parcela, Ubicacion_Parcela) VALUES
(1, 'Parcela A1', 'Sector norte'),
(1, 'Parcela A2', 'Sector sur'),
(2, 'Parcela B1', 'Sector poniente');

INSERT INTO Cultivos (Nombre_Cultivo, Tipo_Cultivo, Descripcion_Cultivo) VALUES
('Jitomate', 'Hortaliza',        'Cultivo de jitomate saladette.'),
('Lechuga',  'Hortaliza',        'Cultivo de lechuga orejona.'),
('Cilantro', 'Hierba aromática', 'Cultivo de ciclo corto para condimento.');

INSERT INTO Siembras (Id_Cultivo, Id_Parcela, Fecha_Siembra, Cantidad_Siembra, Estado_Siembra) VALUES
(1, 1, '2026-02-10', 150, 'Cosechada'),
(2, 2, '2026-02-15', 200, 'Cosechada'),
(3, 3, '2026-03-01',  80, 'Disponible para cosecha');

INSERT INTO Seguimientos (Id_Siembra, Fecha_Seguimiento, Actividad_Seguimiento, Observacion_Siembra) VALUES
(1, '2026-02-20', 'Riego',         'Riego por goteo, sin incidencias.'),
(1, '2026-03-05', 'Fertilización', 'Aplicación de fertilizante orgánico.'),
(2, '2026-02-25', 'Deshierbe',     'Deshierbe manual en toda la parcela.');

INSERT INTO Tipos_Incidencia (Nombre_Incidencias, Descripcion_Incidencias) VALUES
('Plaga',      'Presencia de insectos o plagas en el cultivo.'),
('Enfermedad', 'Síntomas de enfermedad fúngica o bacteriana.'),
('Clima',      'Daño por condiciones climáticas adversas.');

INSERT INTO Incidencias (Id_Tipo_Incidencia, Id_Cultivo, Fecha_Incidencia, Severidad_Incidencia, Estado_Incidencia, Nueva_Incidencia) VALUES
(1, 1, '2026-03-02', 'Media', 'Activa',   'Se detectó pulgón en hojas jóvenes.'),
(3, 2, '2026-03-10', 'Alta',  'Atendida', 'Granizada dañó hojas exteriores.');

INSERT INTO Cosechas (Id_Siembra, Fecha_Cosecha, Cantidad_Kilos, Observaciones_Cosechas) VALUES
(1, '2026-05-01', 120, 'Cosecha completa, buen estado.'),
(2, '2026-04-20', 180, 'Cosecha parcial por lluvias.');

INSERT INTO Bitacora (Id_Usuario, Fecha_Bitacora, Accion_Bitacora, Detalle_Bitacora) VALUES
(2, '2026-03-01 06:10:00', 'Alta',                  'Se registró la siembra de Cilantro en Parcela B1.'),
(3, '2026-03-01 07:45:00', 'Generación de reporte', 'Se generó el reporte PDF de incidencias del periodo 03/2026.'),
(3, '2026-03-10 08:00:00', 'Modificación',          'Se actualizó el estado de la incidencia #2 a Atendida.'),
(4, '2026-04-20 17:30:00', 'Alta',                  'Se registró la cosecha de Lechuga de la Siembra 2 (180 kg).'),
(1, '2026-09-14 09:15:00', 'Inicio de sesión',      'El usuario Admin Urbania inició sesión como Administrador.');

-- =====================================================================
--  CAMPOS QUE "NO SE GUARDAN": vistas y consultas
--  Cada vista lleva el nombre de la palabra del diccionario que resuelve.
-- =====================================================================

-- [60] Siembra_Mes — gráfica de siembras por mes (RF-17)
--      Desde = Periodo_Inicio_Siembra [54], Hasta = Periodo_Fin_Siembra [51]
CREATE VIEW Siembra_Mes AS
SELECT DATE_FORMAT(Fecha_Siembra, '%Y-%m') AS Mes,
       COUNT(*)              AS Siembras,
       SUM(Cantidad_Siembra) AS Cantidad
  FROM Siembras WHERE Activo_Siembra = 1
 GROUP BY DATE_FORMAT(Fecha_Siembra, '%Y-%m');

-- [58] Seguimiento_Actividad — gráfica de seguimientos por tipo de actividad (RF-29) NUEVO
CREATE VIEW Seguimiento_Actividad AS
SELECT Actividad_Seguimiento, COUNT(*) AS Total
  FROM Seguimientos WHERE Activo_Seguimiento = 1
 GROUP BY Actividad_Seguimiento;

-- [38] Incidencias_Tipo — gráfica de incidencias por tipo (RF-45)
CREATE VIEW Incidencias_Tipo AS
SELECT t.Nombre_Incidencias, i.Severidad_Incidencia, COUNT(i.Id_Incidencia) AS Total
  FROM Tipos_Incidencia t
  LEFT JOIN Incidencias i ON i.Id_Tipo_Incidencia = t.Id_Tipo_Incidencia AND i.Activo_Incidencia = 1
 WHERE t.Activo_Tipo_Incidencia = 1
 GROUP BY t.Id_Tipo_Incidencia, t.Nombre_Incidencias, i.Severidad_Incidencia;

-- [55] Produccion_Cultivo — suma de Cantidad_Kilos por Nombre_Cultivo (RF-53)
CREATE VIEW Produccion_Cultivo AS
SELECT cu.Nombre_Cultivo, COALESCE(SUM(co.Cantidad_Kilos), 0) AS Kilos
  FROM Cultivos cu
  LEFT JOIN Siembras s  ON s.Id_Cultivo  = cu.Id_Cultivo AND s.Activo_Siembra = 1
  LEFT JOIN Cosechas co ON co.Id_Siembra = s.Id_Siembra  AND co.Activo_Cosecha = 1
 WHERE cu.Activo_Cultivo = 1
 GROUP BY cu.Id_Cultivo, cu.Nombre_Cultivo;

-- [39] Indicador_Estadistica + [13] Cifra_Estadistica — estadísticas generales (RF-56)
--      La vista se abre con el botón Consulta_Estadistica [15]
CREATE VIEW Estadisticas_Generales AS
SELECT 'Total de siembras realizadas' AS Indicador_Estadistica,
       CAST(COUNT(*) AS CHAR) AS Cifra_Estadistica, 'RF-16' AS Requisito
  FROM Siembras WHERE Activo_Siembra = 1
UNION ALL
SELECT 'Total de seguimientos realizados', CAST(COUNT(*) AS CHAR), 'RF-28'
  FROM Seguimientos WHERE Activo_Seguimiento = 1
UNION ALL
SELECT 'Porcentaje de cultivos con incidencias',
       CONCAT(ROUND(100 * (SELECT COUNT(DISTINCT Id_Cultivo) FROM Incidencias WHERE Activo_Incidencia = 1)
                        / (SELECT COUNT(*) FROM Cultivos WHERE Activo_Cultivo = 1), 1), '%'), 'RF-44'
UNION ALL
SELECT 'Rendimiento total de las cosechas', CONCAT(COALESCE(SUM(Cantidad_Kilos), 0), ' kg'), 'RF-52'
  FROM Cosechas WHERE Activo_Cosecha = 1;

-- =====================================================================
--  TRIGGERS — automatizan la Bitácora (Alta / Baja / Modificación)
--
--  Contrato con la aplicación: antes de cada INSERT/UPDATE que haga un
--  usuario autenticado, el código debe fijar la sesión con:
--      SET @usuario_actual = <Id_Usuario del que está logueado>;
--  Si no se fija, los triggers usan como responsable al Id_Usuario=1
--  (Admin de ejemplo) para no romper la inserción en Bitacora, salvo en
--  Usuarios, donde el alta puede ser auto-registro (RF-01): ahí se usa el
--  propio Id_Usuario recién creado si no hay @usuario_actual.
-- =====================================================================
DELIMITER $$

-- ---- Usuarios ----
CREATE TRIGGER trg_usuarios_alta AFTER INSERT ON Usuarios
FOR EACH ROW
BEGIN
  INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
  VALUES (COALESCE(@usuario_actual, NEW.Id_Usuario), 'Alta',
          CONCAT('Se registró el usuario ', NEW.Nombre_Login, ' (', NEW.Rol, ').'));
END$$

CREATE TRIGGER trg_usuarios_update AFTER UPDATE ON Usuarios
FOR EACH ROW
BEGIN
  IF OLD.Estado_Usuario = 'Activo' AND NEW.Estado_Usuario = 'Inactivo' THEN
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (COALESCE(@usuario_actual, NEW.Id_Usuario), 'Baja',
            CONCAT('Se dio de baja al usuario ', NEW.Nombre_Login, '.'));
  ELSE
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (COALESCE(@usuario_actual, NEW.Id_Usuario), 'Modificación',
            CONCAT('Se actualizaron los datos del usuario ', NEW.Nombre_Login, '.'));
  END IF;
END$$

-- ---- Huertos ----
CREATE TRIGGER trg_huertos_alta AFTER INSERT ON Huertos
FOR EACH ROW
BEGIN
  INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
  VALUES (IFNULL(@usuario_actual, 1), 'Alta',
          CONCAT('Se registró el huerto ', NEW.Nombre_Huerto, '.'));
END$$

CREATE TRIGGER trg_huertos_update AFTER UPDATE ON Huertos
FOR EACH ROW
BEGIN
  IF OLD.Activo_Huerto = 1 AND NEW.Activo_Huerto = 0 THEN
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Baja',
            CONCAT('Se eliminó el huerto ', NEW.Nombre_Huerto, '.'));
  ELSE
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Modificación',
            CONCAT('Se actualizó el huerto ', NEW.Nombre_Huerto, '.'));
  END IF;
END$$

-- ---- Parcelas ----
CREATE TRIGGER trg_parcelas_alta AFTER INSERT ON Parcelas
FOR EACH ROW
BEGIN
  INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
  VALUES (IFNULL(@usuario_actual, 1), 'Alta',
          CONCAT('Se registró la parcela ', NEW.Nombre_Parcela, '.'));
END$$

CREATE TRIGGER trg_parcelas_update AFTER UPDATE ON Parcelas
FOR EACH ROW
BEGIN
  IF OLD.Activo_Parcela = 1 AND NEW.Activo_Parcela = 0 THEN
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Baja',
            CONCAT('Se eliminó la parcela ', NEW.Nombre_Parcela, '.'));
  ELSE
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Modificación',
            CONCAT('Se actualizó la parcela ', NEW.Nombre_Parcela, '.'));
  END IF;
END$$

-- ---- Cultivos ----
CREATE TRIGGER trg_cultivos_alta AFTER INSERT ON Cultivos
FOR EACH ROW
BEGIN
  INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
  VALUES (IFNULL(@usuario_actual, 1), 'Alta',
          CONCAT('Se registró el cultivo ', NEW.Nombre_Cultivo, '.'));
END$$

CREATE TRIGGER trg_cultivos_update AFTER UPDATE ON Cultivos
FOR EACH ROW
BEGIN
  IF OLD.Activo_Cultivo = 1 AND NEW.Activo_Cultivo = 0 THEN
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Baja',
            CONCAT('Se eliminó el cultivo ', NEW.Nombre_Cultivo, '.'));
  ELSE
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Modificación',
            CONCAT('Se actualizó el cultivo ', NEW.Nombre_Cultivo, '.'));
  END IF;
END$$

-- ---- Siembras ----
CREATE TRIGGER trg_siembras_alta AFTER INSERT ON Siembras
FOR EACH ROW
BEGIN
  INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
  VALUES (IFNULL(@usuario_actual, 1), 'Alta',
          CONCAT('Se registró la siembra #', NEW.Id_Siembra, ' (', NEW.Cantidad_Siembra, ' unidades).'));
END$$

CREATE TRIGGER trg_siembras_update AFTER UPDATE ON Siembras
FOR EACH ROW
BEGIN
  IF OLD.Activo_Siembra = 1 AND NEW.Activo_Siembra = 0 THEN
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Baja',
            CONCAT('Se eliminó la siembra #', NEW.Id_Siembra, '.'));
  ELSE
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Modificación',
            CONCAT('Se actualizó la siembra #', NEW.Id_Siembra, ' (estado: ', NEW.Estado_Siembra, ').'));
  END IF;
END$$

-- ---- Seguimientos ----
CREATE TRIGGER trg_seguimientos_alta AFTER INSERT ON Seguimientos
FOR EACH ROW
BEGIN
  INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
  VALUES (IFNULL(@usuario_actual, 1), 'Alta',
          CONCAT('Se registró el seguimiento "', NEW.Actividad_Seguimiento, '" de la siembra #', NEW.Id_Siembra, '.'));
END$$

CREATE TRIGGER trg_seguimientos_update AFTER UPDATE ON Seguimientos
FOR EACH ROW
BEGIN
  IF OLD.Activo_Seguimiento = 1 AND NEW.Activo_Seguimiento = 0 THEN
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Baja',
            CONCAT('Se eliminó el seguimiento #', NEW.Id_Seguimiento, '.'));
  ELSE
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Modificación',
            CONCAT('Se actualizó el seguimiento #', NEW.Id_Seguimiento, '.'));
  END IF;
END$$

-- ---- Tipos_Incidencia ----
CREATE TRIGGER trg_tipos_incidencia_alta AFTER INSERT ON Tipos_Incidencia
FOR EACH ROW
BEGIN
  INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
  VALUES (IFNULL(@usuario_actual, 1), 'Alta',
          CONCAT('Se registró el tipo de incidencia ', NEW.Nombre_Incidencias, '.'));
END$$

CREATE TRIGGER trg_tipos_incidencia_update AFTER UPDATE ON Tipos_Incidencia
FOR EACH ROW
BEGIN
  IF OLD.Activo_Tipo_Incidencia = 1 AND NEW.Activo_Tipo_Incidencia = 0 THEN
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Baja',
            CONCAT('Se eliminó el tipo de incidencia ', NEW.Nombre_Incidencias, '.'));
  ELSE
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Modificación',
            CONCAT('Se actualizó el tipo de incidencia ', NEW.Nombre_Incidencias, '.'));
  END IF;
END$$

-- ---- Incidencias ----
CREATE TRIGGER trg_incidencias_alta AFTER INSERT ON Incidencias
FOR EACH ROW
BEGIN
  INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
  VALUES (IFNULL(@usuario_actual, 1), 'Alta',
          CONCAT('Se registró una incidencia de severidad ', NEW.Severidad_Incidencia,
                 ' en el cultivo #', NEW.Id_Cultivo, '.'));
END$$

CREATE TRIGGER trg_incidencias_update AFTER UPDATE ON Incidencias
FOR EACH ROW
BEGIN
  IF OLD.Activo_Incidencia = 1 AND NEW.Activo_Incidencia = 0 THEN
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Baja',
            CONCAT('Se eliminó la incidencia #', NEW.Id_Incidencia, '.'));
  ELSE
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Modificación',
            CONCAT('Se actualizó la incidencia #', NEW.Id_Incidencia, ' a estado ', NEW.Estado_Incidencia, '.'));
  END IF;
END$$

-- ---- Cosechas ----
CREATE TRIGGER trg_cosechas_alta AFTER INSERT ON Cosechas
FOR EACH ROW
BEGIN
  INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
  VALUES (IFNULL(@usuario_actual, 1), 'Alta',
          CONCAT('Se registró la cosecha de la siembra #', NEW.Id_Siembra, ' (', NEW.Cantidad_Kilos, ' kg).'));
END$$

CREATE TRIGGER trg_cosechas_update AFTER UPDATE ON Cosechas
FOR EACH ROW
BEGIN
  IF OLD.Activo_Cosecha = 1 AND NEW.Activo_Cosecha = 0 THEN
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Baja',
            CONCAT('Se eliminó la cosecha #', NEW.Id_Cosecha, '.'));
  ELSE
    INSERT INTO Bitacora (Id_Usuario, Accion_Bitacora, Detalle_Bitacora)
    VALUES (IFNULL(@usuario_actual, 1), 'Modificación',
            CONCAT('Se actualizó la cosecha #', NEW.Id_Cosecha, ' (', NEW.Cantidad_Kilos, ' kg).'));
  END IF;
END$$

DELIMITER ;

-- =====================================================================
--  PROCEDIMIENTOS ALMACENADOS
--  Alta / Actualizar / Baja (lógica) por módulo. Las bitácoras las
--  generan los triggers de arriba, no los procedimientos.
--  Antes de llamarlos, la aplicación debe fijar el usuario responsable:
--      SET @usuario_actual = <Id_Usuario del que está logueado>;
-- =====================================================================
DELIMITER $$

-- ---- Usuarios ----
CREATE PROCEDURE sp_Alta_Usuario(
  IN p_Nombre_Login VARCHAR(120), IN p_Correo_Login VARCHAR(120),
  IN p_Contrasena_Login VARCHAR(255), IN p_Rol VARCHAR(30)
)
BEGIN
  INSERT INTO Usuarios (Nombre_Login, Correo_Login, Contrasena_Login, Rol)
  VALUES (p_Nombre_Login, p_Correo_Login, p_Contrasena_Login, p_Rol);
END$$

CREATE PROCEDURE sp_Actualizar_Usuario(
  IN p_Id_Usuario INT UNSIGNED, IN p_Nombre_Login VARCHAR(120),
  IN p_Correo_Login VARCHAR(120), IN p_Rol VARCHAR(30)
)
BEGIN
  UPDATE Usuarios
     SET Nombre_Login = p_Nombre_Login, Correo_Login = p_Correo_Login, Rol = p_Rol
   WHERE Id_Usuario = p_Id_Usuario;
END$$

CREATE PROCEDURE sp_Cambiar_Contrasena_Usuario(
  IN p_Id_Usuario INT UNSIGNED, IN p_Contrasena_Login VARCHAR(255)
)
BEGIN
  UPDATE Usuarios SET Contrasena_Login = p_Contrasena_Login WHERE Id_Usuario = p_Id_Usuario;
END$$

CREATE PROCEDURE sp_Baja_Usuario(IN p_Id_Usuario INT UNSIGNED)
BEGIN
  UPDATE Usuarios SET Estado_Usuario = 'Inactivo' WHERE Id_Usuario = p_Id_Usuario;
END$$

-- ---- Huertos ----
CREATE PROCEDURE sp_Alta_Huerto(
  IN p_Nombre_Huerto VARCHAR(80), IN p_Descripcion_Huerto TEXT, IN p_Ubicacion_Huerto VARCHAR(150)
)
BEGIN
  INSERT INTO Huertos (Nombre_Huerto, Descripcion_Huerto, Ubicacion_Huerto)
  VALUES (p_Nombre_Huerto, p_Descripcion_Huerto, p_Ubicacion_Huerto);
END$$

CREATE PROCEDURE sp_Actualizar_Huerto(
  IN p_Id_Huerto INT UNSIGNED, IN p_Nombre_Huerto VARCHAR(80),
  IN p_Descripcion_Huerto TEXT, IN p_Ubicacion_Huerto VARCHAR(150)
)
BEGIN
  UPDATE Huertos
     SET Nombre_Huerto = p_Nombre_Huerto, Descripcion_Huerto = p_Descripcion_Huerto,
         Ubicacion_Huerto = p_Ubicacion_Huerto
   WHERE Id_Huerto = p_Id_Huerto;
END$$

CREATE PROCEDURE sp_Baja_Huerto(IN p_Id_Huerto INT UNSIGNED)
BEGIN
  UPDATE Huertos SET Activo_Huerto = 0 WHERE Id_Huerto = p_Id_Huerto;
END$$

-- ---- Parcelas ----
CREATE PROCEDURE sp_Alta_Parcela(
  IN p_Id_Huerto INT UNSIGNED, IN p_Nombre_Parcela VARCHAR(60), IN p_Ubicacion_Parcela VARCHAR(80)
)
BEGIN
  INSERT INTO Parcelas (Id_Huerto, Nombre_Parcela, Ubicacion_Parcela)
  VALUES (p_Id_Huerto, p_Nombre_Parcela, p_Ubicacion_Parcela);
END$$

CREATE PROCEDURE sp_Actualizar_Parcela(
  IN p_Id_Parcela INT UNSIGNED, IN p_Nombre_Parcela VARCHAR(60), IN p_Ubicacion_Parcela VARCHAR(80)
)
BEGIN
  UPDATE Parcelas SET Nombre_Parcela = p_Nombre_Parcela, Ubicacion_Parcela = p_Ubicacion_Parcela
   WHERE Id_Parcela = p_Id_Parcela;
END$$

CREATE PROCEDURE sp_Baja_Parcela(IN p_Id_Parcela INT UNSIGNED)
BEGIN
  UPDATE Parcelas SET Activo_Parcela = 0 WHERE Id_Parcela = p_Id_Parcela;
END$$

-- ---- Cultivos ----
CREATE PROCEDURE sp_Alta_Cultivo(
  IN p_Nombre_Cultivo VARCHAR(60), IN p_Tipo_Cultivo VARCHAR(60), IN p_Descripcion_Cultivo TEXT
)
BEGIN
  INSERT INTO Cultivos (Nombre_Cultivo, Tipo_Cultivo, Descripcion_Cultivo)
  VALUES (p_Nombre_Cultivo, p_Tipo_Cultivo, p_Descripcion_Cultivo);
END$$

CREATE PROCEDURE sp_Actualizar_Cultivo(
  IN p_Id_Cultivo INT UNSIGNED, IN p_Nombre_Cultivo VARCHAR(60),
  IN p_Tipo_Cultivo VARCHAR(60), IN p_Descripcion_Cultivo TEXT
)
BEGIN
  UPDATE Cultivos
     SET Nombre_Cultivo = p_Nombre_Cultivo, Tipo_Cultivo = p_Tipo_Cultivo,
         Descripcion_Cultivo = p_Descripcion_Cultivo
   WHERE Id_Cultivo = p_Id_Cultivo;
END$$

CREATE PROCEDURE sp_Baja_Cultivo(IN p_Id_Cultivo INT UNSIGNED)
BEGIN
  UPDATE Cultivos SET Activo_Cultivo = 0 WHERE Id_Cultivo = p_Id_Cultivo;
END$$

-- ---- Siembras ----
CREATE PROCEDURE sp_Alta_Siembra(
  IN p_Id_Cultivo INT UNSIGNED, IN p_Id_Parcela INT UNSIGNED,
  IN p_Fecha_Siembra DATE, IN p_Cantidad_Siembra INT UNSIGNED
)
BEGIN
  INSERT INTO Siembras (Id_Cultivo, Id_Parcela, Fecha_Siembra, Cantidad_Siembra)
  VALUES (p_Id_Cultivo, p_Id_Parcela, p_Fecha_Siembra, p_Cantidad_Siembra);
END$$

CREATE PROCEDURE sp_Actualizar_Siembra(
  IN p_Id_Siembra INT UNSIGNED, IN p_Cantidad_Siembra INT UNSIGNED, IN p_Estado_Siembra VARCHAR(30)
)
BEGIN
  UPDATE Siembras SET Cantidad_Siembra = p_Cantidad_Siembra, Estado_Siembra = p_Estado_Siembra
   WHERE Id_Siembra = p_Id_Siembra;
END$$

CREATE PROCEDURE sp_Baja_Siembra(IN p_Id_Siembra INT UNSIGNED)
BEGIN
  UPDATE Siembras SET Activo_Siembra = 0 WHERE Id_Siembra = p_Id_Siembra;
END$$

-- ---- Seguimientos ----
CREATE PROCEDURE sp_Alta_Seguimiento(
  IN p_Id_Siembra INT UNSIGNED, IN p_Fecha_Seguimiento DATE,
  IN p_Actividad_Seguimiento VARCHAR(60), IN p_Observacion_Siembra TEXT,
  IN p_Evidencia_Seguimiento VARCHAR(255)
)
BEGIN
  INSERT INTO Seguimientos (Id_Siembra, Fecha_Seguimiento, Actividad_Seguimiento, Observacion_Siembra, Evidencia_Seguimiento)
  VALUES (p_Id_Siembra, p_Fecha_Seguimiento, p_Actividad_Seguimiento, p_Observacion_Siembra, p_Evidencia_Seguimiento);
END$$

CREATE PROCEDURE sp_Actualizar_Seguimiento(
  IN p_Id_Seguimiento INT UNSIGNED, IN p_Actividad_Seguimiento VARCHAR(60),
  IN p_Observacion_Siembra TEXT, IN p_Evidencia_Seguimiento VARCHAR(255)
)
BEGIN
  UPDATE Seguimientos
     SET Actividad_Seguimiento = p_Actividad_Seguimiento, Observacion_Siembra = p_Observacion_Siembra,
         Evidencia_Seguimiento = p_Evidencia_Seguimiento
   WHERE Id_Seguimiento = p_Id_Seguimiento;
END$$

CREATE PROCEDURE sp_Baja_Seguimiento(IN p_Id_Seguimiento INT UNSIGNED)
BEGIN
  UPDATE Seguimientos SET Activo_Seguimiento = 0 WHERE Id_Seguimiento = p_Id_Seguimiento;
END$$

-- ---- Tipos_Incidencia ----
CREATE PROCEDURE sp_Alta_Tipo_Incidencia(
  IN p_Nombre_Incidencias VARCHAR(60), IN p_Descripcion_Incidencias TEXT
)
BEGIN
  INSERT INTO Tipos_Incidencia (Nombre_Incidencias, Descripcion_Incidencias)
  VALUES (p_Nombre_Incidencias, p_Descripcion_Incidencias);
END$$

CREATE PROCEDURE sp_Actualizar_Tipo_Incidencia(
  IN p_Id_Tipo_Incidencia INT UNSIGNED, IN p_Nombre_Incidencias VARCHAR(60), IN p_Descripcion_Incidencias TEXT
)
BEGIN
  UPDATE Tipos_Incidencia
     SET Nombre_Incidencias = p_Nombre_Incidencias, Descripcion_Incidencias = p_Descripcion_Incidencias
   WHERE Id_Tipo_Incidencia = p_Id_Tipo_Incidencia;
END$$

CREATE PROCEDURE sp_Baja_Tipo_Incidencia(IN p_Id_Tipo_Incidencia INT UNSIGNED)
BEGIN
  UPDATE Tipos_Incidencia SET Activo_Tipo_Incidencia = 0 WHERE Id_Tipo_Incidencia = p_Id_Tipo_Incidencia;
END$$

-- ---- Incidencias ----
CREATE PROCEDURE sp_Alta_Incidencia(
  IN p_Id_Tipo_Incidencia INT UNSIGNED, IN p_Id_Cultivo INT UNSIGNED, IN p_Fecha_Incidencia DATE,
  IN p_Severidad_Incidencia VARCHAR(10), IN p_Nueva_Incidencia TEXT, IN p_Evidencia_Incidencia VARCHAR(255)
)
BEGIN
  INSERT INTO Incidencias (Id_Tipo_Incidencia, Id_Cultivo, Fecha_Incidencia, Severidad_Incidencia, Nueva_Incidencia, Evidencia_Incidencia)
  VALUES (p_Id_Tipo_Incidencia, p_Id_Cultivo, p_Fecha_Incidencia, p_Severidad_Incidencia, p_Nueva_Incidencia, p_Evidencia_Incidencia);
END$$

CREATE PROCEDURE sp_Actualizar_Incidencia(
  IN p_Id_Incidencia INT UNSIGNED, IN p_Severidad_Incidencia VARCHAR(10),
  IN p_Estado_Incidencia VARCHAR(10), IN p_Nueva_Incidencia TEXT, IN p_Evidencia_Incidencia VARCHAR(255)
)
BEGIN
  UPDATE Incidencias
     SET Severidad_Incidencia = p_Severidad_Incidencia, Estado_Incidencia = p_Estado_Incidencia,
         Nueva_Incidencia = p_Nueva_Incidencia, Evidencia_Incidencia = p_Evidencia_Incidencia
   WHERE Id_Incidencia = p_Id_Incidencia;
END$$

CREATE PROCEDURE sp_Baja_Incidencia(IN p_Id_Incidencia INT UNSIGNED)
BEGIN
  UPDATE Incidencias SET Activo_Incidencia = 0 WHERE Id_Incidencia = p_Id_Incidencia;
END$$

-- ---- Cosechas ----
CREATE PROCEDURE sp_Alta_Cosecha(
  IN p_Id_Siembra INT UNSIGNED, IN p_Fecha_Cosecha DATE, IN p_Cantidad_Kilos DECIMAL(10,2),
  IN p_Observaciones_Cosechas TEXT, IN p_Evidencia_Cosecha VARCHAR(255)
)
BEGIN
  INSERT INTO Cosechas (Id_Siembra, Fecha_Cosecha, Cantidad_Kilos, Observaciones_Cosechas, Evidencia_Cosecha)
  VALUES (p_Id_Siembra, p_Fecha_Cosecha, p_Cantidad_Kilos, p_Observaciones_Cosechas, p_Evidencia_Cosecha);
END$$

CREATE PROCEDURE sp_Actualizar_Cosecha(
  IN p_Id_Cosecha INT UNSIGNED, IN p_Cantidad_Kilos DECIMAL(10,2),
  IN p_Observaciones_Cosechas TEXT, IN p_Evidencia_Cosecha VARCHAR(255)
)
BEGIN
  UPDATE Cosechas
     SET Cantidad_Kilos = p_Cantidad_Kilos, Observaciones_Cosechas = p_Observaciones_Cosechas,
         Evidencia_Cosecha = p_Evidencia_Cosecha
   WHERE Id_Cosecha = p_Id_Cosecha;
END$$

CREATE PROCEDURE sp_Baja_Cosecha(IN p_Id_Cosecha INT UNSIGNED)
BEGIN
  UPDATE Cosechas SET Activo_Cosecha = 0 WHERE Id_Cosecha = p_Id_Cosecha;
END$$

-- ---- Consultas con parámetros (los valores salen de los campos que NO se guardan) ----

-- RF-16 Total de siembras por periodo: Periodo_Inicio_Siembra [54] y Periodo_Fin_Siembra [51]
CREATE PROCEDURE sp_Reporte_Siembras_Periodo(
  IN p_Periodo_Inicio_Siembra DATE, IN p_Periodo_Fin_Siembra DATE
)
BEGIN
  SELECT COUNT(*) AS Siembras_Periodo, SUM(Cantidad_Siembra) AS Cantidad_Total
    FROM Siembras
   WHERE Activo_Siembra = 1
     AND Fecha_Siembra BETWEEN p_Periodo_Inicio_Siembra AND p_Periodo_Fin_Siembra;
END$$

-- RF-27 Historial de seguimiento: Cultivo_Seguimiento [20] se compara con Nombre_Cultivo
CREATE PROCEDURE sp_Historial_Seguimiento_Cultivo(IN p_Cultivo_Seguimiento VARCHAR(60))
BEGIN
  SELECT sg.Fecha_Seguimiento, sg.Actividad_Seguimiento, sg.Observacion_Siembra
    FROM Seguimientos sg
    JOIN Siembras s ON s.Id_Siembra = sg.Id_Siembra
    JOIN Cultivos c ON c.Id_Cultivo = s.Id_Cultivo
   WHERE sg.Activo_Seguimiento = 1 AND c.Nombre_Cultivo = p_Cultivo_Seguimiento;
END$$

-- RF-43 Reporte de incidencias: Periodo_Incidencias [52] (mes y año, ej. '2026-03')
CREATE PROCEDURE sp_Reporte_Incidencias_Periodo(IN p_Periodo_Incidencias CHAR(7))
BEGIN
  SELECT * FROM Incidencias
   WHERE Activo_Incidencia = 1 AND DATE_FORMAT(Fecha_Incidencia, '%Y-%m') = p_Periodo_Incidencias;
END$$

-- RF-51 Reporte de cosechas: Periodo_Inicio_Cosechas [53] y Periodo_Fin_Cosechas [50]
CREATE PROCEDURE sp_Reporte_Cosechas_Periodo(
  IN p_Periodo_Inicio_Cosechas DATE, IN p_Periodo_Fin_Cosechas DATE
)
BEGIN
  SELECT * FROM Cosechas
   WHERE Activo_Cosecha = 1 AND Fecha_Cosecha BETWEEN p_Periodo_Inicio_Cosechas AND p_Periodo_Fin_Cosechas;
END$$

-- Filtrar bitácora: Filtro_Bitacora [37] = nombre del usuario + fecha
CREATE PROCEDURE sp_Filtrar_Bitacora(IN p_Usuario VARCHAR(120), IN p_Fecha DATE)
BEGIN
  SELECT b.Fecha_Bitacora, u.Nombre_Login, b.Accion_Bitacora, b.Detalle_Bitacora
    FROM Bitacora b
    JOIN Usuarios u ON u.Id_Usuario = b.Id_Usuario
   WHERE u.Nombre_Login LIKE CONCAT('%', p_Usuario, '%') AND DATE(b.Fecha_Bitacora) = p_Fecha;
END$$

-- Iniciar sesión: Usuario_Login [64] se compara con Correo_Login
CREATE PROCEDURE sp_Iniciar_Sesion(IN p_Usuario_Login VARCHAR(120))
BEGIN
  SELECT Id_Usuario, Contrasena_Login, Rol FROM Usuarios
   WHERE Correo_Login = p_Usuario_Login AND Estado_Usuario = 'Activo';
END$$

DELIMITER ;

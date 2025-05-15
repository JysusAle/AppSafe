/***************************************

--------------- validaTriggers -----------------

Autores: 

Fecha: 11/05/2025

Descripcion: En este Script se encuentran cada uno
de los triggers, ejecuata un escenario para
validar el correcto funcionamiento de los triggers

------------------------------------------


******************************************/

use [APPSAFE_TEAM_UNO_DE_TRES]
go

-- Crea el trigger llamado 'trg_limitar_tarjetas' dentro del esquema INTERACCION
CREATE TRIGGER INTERACCION.trg_limitar_tarjetas
ON INTERACCION.TARJETA
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- CTEs para nuevas y existentes
    WITH Nuevos AS (
        SELECT i.ID_USUARIO, COUNT(*) AS CantidadNuevas
        FROM INSERTED i
        GROUP BY i.ID_USUARIO
    ),
    Existentes AS (
        SELECT t.ID_USUARIO, COUNT(*) AS CantidadExistentes
        FROM INTERACCION.TARJETA t
        GROUP BY t.ID_USUARIO
    )
    -- 1) Verificar si algún usuario intenta insertar más de 3 tarjetas en un solo lote
    DECLARE @UsuariosError NVARCHAR(100);
    SELECT @UsuariosError = STRING_AGG(CAST(ID_USUARIO AS NVARCHAR(5)), ', ')
    FROM Nuevos
    WHERE CantidadNuevas > 3;

    IF @UsuariosError IS NOT NULL
    BEGIN
        THROW 51001, CONCAT('Los siguientes usuarios intentan insertar más de 3 tarjetas: ', @UsuariosError), 1;
        RETURN;
    END;

    -- 2) Verificar si alguno ya tiene 3 o más tarjetas existentes
    DECLARE @UsuariosConMaximas NVARCHAR(100);
    SELECT @UsuariosConMaximas = STRING_AGG(CAST(n.ID_USUARIO AS NVARCHAR(5)), ', ')
    FROM Nuevos n
    JOIN Existentes e 
    ON n.ID_USUARIO = e.ID_USUARIO
    WHERE e.CantidadExistentes >= 3;

    IF @UsuariosConMaximas IS NOT NULL
    BEGIN
        THROW 51001, CONCAT('Los siguientes usuarios ya tienen 3 tarjetas: ', @UsuariosConMaximas), 2;
        RETURN;
    END;

    -- 3) Verificar que la suma de existentes + nuevas no supere 3
    DECLARE @UsuariosSuperanTotal NVARCHAR(MAX);
    SELECT @UsuariosSuperanTotal = STRING_AGG(CAST(n.ID_USUARIO AS NVARCHAR(10)), ', ')
    FROM Nuevos n
    LEFT JOIN Existentes e 
    ON n.ID_USUARIO = e.ID_USUARIO
    WHERE ISNULL(e.CantidadExistentes, 0) + n.CantidadNuevas > 3;

    IF @UsuariosSuperanTotal IS NOT NULL
    BEGIN
        THROW 51001, CONCAT('Los siguientes usuarios superarán el total de 3 tarjetas tras la inserción: ', @UsuariosSuperanTotal), 3;
        RETURN;
    END;

    -- Si pasa todas las validaciones, insertamos
    INSERT INTO INTERACCION.TARJETA (NUM_TARJETA, ID_USUARIO, VIGENCIA, BANCO)
    SELECT NUM_TARJETA, ID_USUARIO, VIGENCIA, BANCO
    FROM INSERTED;
END;
GO

-----------------------------------------------------------------------------------------------------------------
--- Limitar numero de autos por conductor a 2

CREATE TRIGGER trg_validar_auto
ON AUTO
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- CTEs para nuevas y existentes
    WITH Nuevos AS (
        SELECT i.ID_USUARIO, COUNT(*) AS CantidadNuevos
        FROM INSERTED i
        GROUP BY i.ID_USUARIO
    ),
    Existentes AS (
        SELECT a.ID_USUARIO, COUNT(*) AS CantidadExistentes
        FROM AUTO a
        GROUP BY a.ID_USUARIO
    )

    -- 1. Verificar si algún conductor intenta exceder el límite de 2 autos
    DECLARE @ConductoresExcedidos NVARCHAR(100);
    SELECT @ConductoresExcedidos = STRING_AGG(CAST(n.ID_USUARIO AS NVARCHAR(5)), ', ')
    FROM Nuevos n
    LEFT JOIN Existentes e
    ON n.ID_USUARIO = e.ID_USUARIO
    WHERE ISNULL(e.CantidadExistentes, 0) + n.CantidadNuevos > 2;

    IF @ConductoresExcedidos IS NOT NULL
    BEGIN
        THROW 51002, CONCAT('Los siguientes conductores excederían el límite de 2 autos: ', @ConductoresExcedidos), 1;
        RETURN;
    END;

    -- 2. Verificar si algún auto tiene más de 5 años de antigüedad
    DECLARE @AutosAntiguos NVARCHAR(100);
    SELECT @AutosAntiguos = STRING_AGG(CAST(ID_MODELO AS NVARCHAR(5)), ', ')
    FROM INSERTED
    WHERE AÑO < YEAR(GETDATE()) - 5;

    IF @AutosAntiguos IS NOT NULL
    BEGIN
        THROW 51002, CONCAT('Los siguientes autos tienen más de 5 años de antigüedad (ID_MODELO): ', @AutosAntiguos), 2;
        RETURN;
    END;

    -- Si todo está correcto, hace el INSERT
    INSERT INTO AUTO (ID_USUARIO, ID_MODELO, NUMPLACA, AÑO, DISPONIBLE)
    SELECT ID_USUARIO, ID_MODELO, NUMPLACA, AÑO, DISPONIBLE
    FROM INSERTED;
END;
GO

--------------------------------------------------------------------------------------------------------------------------------------

CREATE TRIGGER trg_queja_administrador
ON INTERACCION.QUEJA 
AFTER UPDATE
AS
BEGIN
    
    SET NOCOUNT ON;

    WITH USERS AS (
        SELECT ID_USUARIO
        FROM INSERTED i
        JOIN ADMINISTRADOR  a
        ON i.ID_USUARIO = a.ID_ADMINISTRADOR
    )
    IF EXISTS(SELECT 1 FROM USERS)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 51003, 'Un administrador no puede actualizar quejas relacionadas consigo mismo.' 1;
    END
END;
go

--------------------------------------------------------------------------------------------------------------------------------------

---Trigger que verifica que la solicitud no exceda mas de dos dias 
CREATE TRIGGER trg_FechaSolicitud
ON RECORRIDO.VIAJE
AFTER INSERT, UPDATE
AS
BEGIN

    SET NOCOUNT ON;

    IF EXISTS (
      SELECT 1 
      FROM INSERTED i 
      WHERE TIPO = 'N' AND CAST(i.FECHA_SOLICITUD AS DATE) != CAST (GETDATE() AS DATE)
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 51004, 'Tiene que seleccionar la fecha actual o cambiar el tipo de viaje', 1;
    END

    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        WHERE TIPO = 'P' AND CAST(i.FECHA_SOLICITUD AS DATE) > CAST(DATEADD(DAY, 2, GETDATE()) AS DATE)
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 51004, 'La fecha de solicitud no puede ser mayor a 2 días respecto a hoy.', 2;
    END
END
go

--------------------------------------------------------------------------------------------------------------------------------------

---Trigger que valida la transicion entre estatus

CREATE TRIGGER trg_ValidarTransicionEstatus
ON RECORRIDO.ESTATUS_VIAJE
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    WITH Nueva AS (
      SELECT 
        i.ID_VIAJE,
        i.CLAVE_ESTATUS               AS NuevoClave,
        e_new.NOMBRE_ESTATUS          AS NuevoEstatus,
        i.FECHA_ESTATUS,
        (
          SELECT TOP 1 ev_old.CLAVE_ESTATUS
          FROM RECORRIDO.ESTATUS_VIAJE ev_old
          WHERE ev_old.ID_VIAJE = i.ID_VIAJE
            AND ev_old.FECHA_ESTATUS < i.FECHA_ESTATUS
          ORDER BY ev_old.FECHA_ESTATUS DESC
        )                             AS PrevClave
      FROM INSERTED i
      JOIN RECORRIDO.ESTATUS e_new
        ON i.CLAVE_ESTATUS = e_new.CLAVE_ESTATUS
    ),
    Invalidas AS (
      -- Detectamos todas las filas cuya transición NO está permitida
      SELECT 
        n.ID_VIAJE,
        n.PrevClave,
        n.NuevoClave,
        e_prev.NOMBRE_ESTATUS AS PrevEstatus,
        n.NuevoEstatus
      FROM Nueva n
      LEFT JOIN RECORRIDO.ESTATUS e_prev
        ON n.PrevClave = e_prev.CLAVE_ESTATUS
      WHERE
        -- 1) Sin estado previo sólo se permite llegar a 'S'
        (n.PrevClave IS NULL AND n.NuevoClave <> 'S')
        -- 2) Desde 'S' sólo a 'G'
        OR (e_prev.NOMBRE_ESTATUS = 'S' AND n.NuevoClave <> 'G')
        -- 3) Desde 'G' sólo a 'C' o 'X'
        OR (e_prev.NOMBRE_ESTATUS = 'G' AND n.NuevoClave NOT IN ('C','X'))
        -- 4) Desde 'C' sólo a 'E'
        OR (e_prev.NOMBRE_ESTATUS = 'C' AND n.NuevoClave <> 'E')
        -- 5) Desde 'E' sólo a 'B'
        OR (e_prev.NOMBRE_ESTATUS = 'E' AND n.NuevoClave <> 'B')
        -- 6) Desde 'B' sólo a 'P' o 'A'
        OR (e_prev.NOMBRE_ESTATUS = 'B' AND n.NuevoClave NOT IN ('P','A'))
        -- 7) Desde 'P','A' ó 'X' sólo a 'T'
        OR (e_prev.NOMBRE_ESTATUS IN ('P','A','X') AND n.NuevoClave <> 'T')
        -- 8) Un estatus 'T' es terminal: no debe haber nuevos registros tras él
        OR (e_prev.NOMBRE_ESTATUS = 'T')
    )
    -- Si hay alguna transición inválida, abortamos todo y devolvemos un mensaje
    IF EXISTS (SELECT 1 FROM Invalidas)
    BEGIN
        DECLARE @ViajesError NVARCHAR(MAX) =
          (SELECT STRING_AGG(CAST(ID_VIAJE AS NVARCHAR(10)), ', ')
           FROM Invalidas);

        ROLLBACK TRANSACTION;
        THROW 51005,
              CONCAT(
                'Transición de estatus inválida para viaje(s): ',
                @ViajesError,
                '. Revisa la secuencia permitida.'
              ),
              1;
    END

    -- Si todas las transiciones son válidas, sincronizamos el estatus actual
    UPDATE v
    SET v.CLAVE_ACTUAL = n.NuevoClave
    FROM RECORRIDO.VIAJE v
    JOIN Nueva n
      ON v.ID_VIAJE = n.ID_VIAJE;
END;
GO
 
---------------------------------------------------------------------------------------------------------------------------------------

--- Trigers que valida la jerarquia

CREATE TRIGGER trg_jerarquiaC
ON PERSONA.CONDUCTOR
AFTER INSERT
AS
BEGI

    SET NOCOUNT ON;

    WITH INVALIDOS AS (
        SELECT u.ID_USUARIO
        FROM PERSONA.USUARIO AS u
        JOIN INSERTED i
        ON i.ID_USUARIO = u.ID_USUARIO
        WHERE TIPO_USUARIO != 'C'
    )

    DECLARE @UsuariosError NVARCHAR(100);
    SELECT @UsuariosError = STRING_AGG(CAST(ID_USUARIO AS NVARCHAR(5)), ', ')
    FROM INVALIDOS

    IF @UsuariosError IS NOT NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 51006, CONCAT('No puedes crear como conductores los siguientes usuarios (no son tipo ''C''): ', @UsuariosError), 1;
        RETURN;
    END;
END;
GO

------------

CREATE TRIGGER trg_jerarquiaA
ON PERSONA.ADMINISTRADOR
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    WITH INVALIDOS AS (
        SELECT u.ID_USUARIO
        FROM PERSONA.USUARIO AS u
        JOIN INSERTED i
        ON i.ID_USUARIO = u.ID_USUARIO
        WHERE TIPO_USUARIO != 'A'
    )

    DECLARE @UsuariosError NVARCHAR(100);
    SELECT @UsuariosError = STRING_AGG(CAST(ID_USUARIO AS NVARCHAR(5)), ', ')
    FROM INVALIDOS

    IF @UsuariosError IS NOT NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 51007, CONCAT('No puedes crear como administradores los siguientes usuarios (no son tipo ''A''): ', @UsuariosError), 1;
        RETURN;
    END;
END;
GO

------------ 

CREATE TRIGGER trg_jerarquiaU
ON PERSONA.USUARIO
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH INVALIDOS AS (
        SELECT u.ID_USUARIO
        FROM PERSONA.USUARIO AS u
        JOIN INSERTED i
        ON i.ID_USUARIO = u.ID_USUARIO
        LEFT JOIN PERSONA.CONDUCTOR as c
        ON u.ID_USUARIO = c.ID_USUARIO
        LEFT JOIN PERSONA.ADMINISTRADOR as a
        ON u.ID_USUARIO = a.ID_USUARIO
        WHERE (c.ID_USUARIO IS NOT NULL OR a.ID_USUARIO IS NOT NULL) AND i.TIPO_USUARIO != u.TIPO_USUARIO;
    )

    DECLARE @UsuariosError NVARCHAR(100);
    SELECT @UsuariosError = STRING_AGG(CAST(ID_USUARIO AS NVARCHAR(5)), ', ')
    FROM INVALIDOS

    IF @UsuariosError IS NOT NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 51008, CONCAT('No puedes alterar el tipo de usuario de los siguientes usuarios: ', @UsuariosError), 1;
        RETURN;
    END;
END;
GO

---------------------------------------------------------------------------------------------------------------------------------------------------

--- Triger que valide que el usuario que tenga la queja tenga relación con el conductor     
CREATE TRIGGER trg_queja_relacion
ON INTERACCION.QUEJA
INSTEAD OF INSERT 
AS 
BEGIN

    SET NOCOUNT ON;

    WITH INVALIDOS AS (
        SELECT i.ID_USUARIO
        FROM INSERTED i
        WHERE i.ID_USUARIO NOT IN (SELECT ID_USUARIO FROM RECORRIDO.VIAJE)
    ),
    USERS AS (
        SELECT i.ID_USUARIO, v.ID_AUTO
        FROM INSERTED i
        JOIN RECORRIDO.VIAJE v
        on v.ID_USUARIO = i.ID_USUARIO
        WHERE v.ID_AUTO = i.ID_AUTO
    )

    DECLARE @UsuariosInvalidos NVARCHAR(100);
    SELECT @UsuariosInvalidos = STRING_AGG(CAST(ID_USUARIO AS NVARCHAR(5)), ', ')
    FROM INVALIDOS
    IF @UsuariosInvalidos IS NOT NULL
    BEGIN
        THROW 51009, CONCAT('Los siguientes usuarios no tienen viajes', @UsuariosInvalidos), 1;
        RETURN;
    END 
    
    DECLARE @UsuariosError NVARCHAR(100);
    SELECT @UsuariosError = STRING_AGG(CAST(ID_USUARIO AS NVARCHAR(5)), ', ')
    FROM INSERTED i
    WHERE i.ID_USUARIO NOT IN (SELECT ID_USUARIO FROM USERS)
    IF @UsuariosError IS NOT NULL
    BEGIN
        THROW 51009, CONCAT('Los siguientes usuarios no pueden generar una queja debido a que no tienen relación con el auto mencionado: ', @UsuariosError), 2;
        RETURN;
    END

    INSERT INTO INTERACCION.QUEJA (ID_QUEJA, ID_USUARIO, ID_AUTO, ID_ADMINISTRADOR, TITULO, FECHA_EMISION)
    SELECT ID_QUEJA, ID_USUARIO, ID_AUTO, ID_ADMINISTRADOR, TITULO, FECHA_EMISION
    FROM INSERTED; 
END;
GO

-----------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Triger que valide que impida crear la tabla aceptado hasta que el estatus tome el valor de aceptado
CREATE TRIGGER trg_aceptado
ON ACEPTADO
INSTEAD OF INSERT
AS
BEGIN
    
    SET NOCOUNT ON;

    WITH USERS AS (
        SELECT i.ID_USUARIO, i.ID_VIAJE
        FROM INSERTED i
        JOIN ESTATUS_VIAJE ev
        ON i.ID_VIAJE = ev.ID_VIAJE
        WHERE NOMBRE_ESTATUS = "C" 
    )

    DECLARE @NotAcept NVARCHAR(100);
    SELECT @NotAcept = STRING_AGG(CAST(ID_VIAJE AS NVARCHAR(5)), ', ')
    FROM INSERTED i
    WHERE i.ID_VIAJE NOT IN (SELECT ID_VIAJE FROM USERS)
    IF @NotAcept IS NOT NULL
    BEGIN
        THROW 51010, CONCAT('Los siguientes viajes no cuentan con el estatus de aceptado: ', @NotAcept), 1;
        RETURN;
    END

END;
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Triger para la queja no tarde en resolverse más de 5 días
CREATE TRIGGER trg_resolucion
ON RESOLUCION
AFTER INSERT, UPDATE
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @ResolucionInvalida NVARCHAR(100);
    SELECT @ResolucionInvalida = STRING_AGG(CAST(i.ID_MODELO AS NVARCHAR(5)), ', ')
    FROM INSERTED i
    JOIN INTERACCION.QUEJA q
    ON i.ID_USUARIO = q.ID_USUARIO
    WHERE FECHA_EMISION < DATEADD(DAY, -5, FECHA_ATENDIDO) AND FECHA_EMISION < FECHA_ATENDIDO;

    IF @AutosAntiguos IS NOT NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 51011, CONCAT('Las siguientes quejas resoluciones tienen más de 5 días de antigüedad : ', @ResolucionInvalida), 1;
        RETURN;
    END;
END;
GO

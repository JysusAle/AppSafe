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

-- Crea el trigger llamado 'trg_limitar_tarjetas' dentro del esquema PERSONA
CREATE TRIGGER PERSONA.trg_limitar_tarjetas
ON INTERECCION.TARJETA
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UsuarioExcedido INT;

    SELECT TOP 1 @UsuarioExcedido = i.ID_USUARIO -- NO ES NECESARIO EL TOP 1
    FROM INSERTED i
    GROUP BY i.ID_USUARIO -- VERIFICAR
    HAVING 
        (SELECT COUNT() 
         FROM PERSONA.TARJETA t 
         WHERE t.ID_USUARIO = i.ID_USUARIO) > 3; --verificar (quitar count)

    IF @UsuarioExcedido IS NOT NULL
    BEGIN
        RAISERROR('El usuario con ID = %d ya tiene 3 tarjetas registradas.', 16, 1, @UsuarioExcedido);
        RETURN;
    END;

    INSERT INTO PERSONA.TARJETA (NUM_TARJETA, ID_USUARIO, VIGENCIA, BANCO)
    SELECT NUM_TARJETA, ID_USUARIO, VIGENCIA, BANCO
    FROM INSERTED;
END;

--Trigger que verifica que la cantidad de autos maxima de dos no sea excedida
CREATE TRIGGER trg_validar_auto
ON AUTO
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ConductorExcedido INT;

    -- 1. Verifica si algún conductor excede el límite de 2 autos
    SELECT TOP 1 @ConductorExcedido = i.ID_USUARIO
    FROM INSERTED i
    GROUP BY i.ID_USUARIO
    HAVING 
        (SELECT COUNT() 
         FROM AUTO a 
         WHERE a.ID_USUARIO = i.ID_USUARIO) 
        + COUNT() > 2;

    IF @ConductorExcedido IS NOT NULL
    BEGIN
        RAISERROR('El conductor con ID = %d ya tiene 2 autos registrados.', 16, 1, @ConductorExcedido);
        RETURN;
    END;

    -- 2. Verifica si algún auto tiene más de 5 años de antigüedad
    IF EXISTS (
        SELECT 1
        FROM INSERTED
        WHERE AÑO < DATEADD(YEAR, -5, CAST(GETDATE() AS DATE))  -- getdate se puede como check
    )
    BEGIN
        RAISERROR('El auto no puede tener más de 5 años de antigüedad.', 16, 1);
        RETURN;
    END;

    -- Si todo está correcto, hace el INSERT
    INSERT INTO AUTO (ID_USUARIO, ID_MODELO, NUMPLACA, AÑO, DISPONIBLE)
    SELECT ID_USUARIO, ID_MODELO, NUMPLACA, AÑO, DISPONIBLE
    FROM INSERTED;
END;
go

---Trigger que  verifica que un administrador no resuelva su propia vida
CREATE TRIGGER trg_queja_administrador
ON QUEJA 
AFTER UPDATE  --FOR UPDATE
AS
BEGIN
IF EXISTS(
    SELECT 1
    FROM INSERTED i
    WHERE i.ID_USUARIO = ID_ADMINISTRADOR
    )
    BEGIN

        ROLLBACK TRASACTION;

    END
END
go



---Trigger que verifica que la solicitud de un auto no exceda mas de dos dias 

--COMPROBAR QUE EL ESTUS ES PROGRAMADO
CREATE TRIGGER CK7_trg_FechaSolicitud_NO_MAS_DE_DOS_DIAS
ON VIAJE
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE FECHA_SOLICITUD < DATEADD(DAY, -2, GETDATE())
    )
    BEGIN
        RAISERROR('La fecha de solicitud no puede ser mayor a 2 días respecto a hoy.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END
go

---Trigger que valida la transicion entre estatus


CREATE OR ALTER TRIGGER TRG_ValidarTransicionEstatus
ON RECORRIDO.ESTATUS_VIAJE
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Nueva AS (
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
      FROM inserted i
      JOIN RECORRIDO.ESTATUS e_new
        ON i.CLAVE_ESTATUS = e_new.CLAVE_ESTATUS
    )

    IF EXISTS (
      SELECT 1
      FROM Nueva n
      JOIN RECORRIDO.ESTATUS e_prev
        ON n.PrevClave = e_prev.CLAVE_ESTATUS
      WHERE
        (n.PrevClave IS NULL   AND n.NuevoEstatus <> 'S')
        OR (e_prev.NOMBRE_ESTATUS = 'S' AND n.NuevoEstatus <> 'G')
        OR (e_prev.NOMBRE_ESTATUS = 'G' AND n.NuevoEstatus NOT IN ('C','X'))
        OR (e_prev.NOMBRE_ESTATUS = 'C' AND n.NuevoEstatus <> 'E')
        OR (e_prev.NOMBRE_ESTATUS = 'E' AND n.NuevoEstatus <> 'B')
        OR (e_prev.NOMBRE_ESTATUS = 'B' AND n.NuevoEstatus NOT IN ('P','A'))
        OR (e_prev.NOMBRE_ESTATUS = 'P' AND n.NuevoEstatus <> 'T')
        OR (e_prev.NOMBRE_ESTATUS = 'A' AND n.NuevoEstatus <> 'T')
        OR (e_prev.NOMBRE_ESTATUS = 'X' AND n.NuevoEstatus <> 'T')
        OR (e_prev.NOMBRE_ESTATUS = 'T')
    )
    BEGIN
        RAISERROR(
          'Transición de estatus inválida: no sigue la secuencia permitida.',
          16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Sincronizamos el código de estatus en VIAJE.CLAVE_ACTUAL
    UPDATE v
    SET v.CLAVE_ACTUAL = n.NuevoClave
    FROM RECORRIDO.VIAJE v
    JOIN Nueva n
      ON v.ID_VIAJE = n.ID_VIAJE;
END;
go

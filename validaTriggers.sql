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


-----------------------------------------------------------------
--El trigger trg_jerarquiaU tiene el propósito de validar cambios en el tipo de usuario en la tabla PERSONA.USUARIO

CREATE TRIGGER trg_jerarquiaU
ON PERSONA.USUARIO
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UsuariosError NVARCHAR(100);
    
    WITH INVALIDOS AS (
        SELECT u.ID_USUARIO
        FROM PERSONA.USUARIO AS u
        JOIN inserted as i
        ON i.ID_USUARIO = u.ID_USUARIO
		where u.TIPO_USUARIO != i.TIPO_USUARIO
    )

    SELECT @UsuariosError = STRING_AGG(CAST(ID_USUARIO AS NVARCHAR(5)), ', ')
    FROM INVALIDOS;

    IF @UsuariosError IS NOT NULL
    BEGIN
        ROLLBACK TRANSACTION;

        DECLARE @MensajeError NVARCHAR(200);
        SET @MensajeError = 'No puedes alterar el tipo de usuario de los siguientes usuarios: ' + @UsuariosError;
        THROW 51008, @MensajeError, 1;
        RETURN;
    END;

	UPDATE u
    SET 
		ID_USUARIO_RECOMIENDA = i.iD_USUARIO_RECOMIENDA,
        TIPO_USUARIO = i.TIPO_USUARIO,
        NOMBRE_PILA = i.NOMBRE_PILA,
        APELLIDOM = i.APELLIDOM,
        APELLIDOP = i.APELLIDOP,
        CLAVE_ACCESO = i.CLAVE_ACCESO,
        NUMERO_CELULAR = i.NUMERO_CELULAR,
        NOMBRE_USUARIO = i.NOMBRE_USUARIO,
        CORREO = i.CORREO,
        FECHA_REGISTRO = i.FECHA_REGISTRO
    FROM PERSONA.USUARIO u
    JOIN INSERTED i
    ON u.ID_USUARIO = i.ID_USUARIO;

END;
GO

----------------COMPROBACION----------------------------

INSERT INTO PERSONA.USUARIO VALUES (NULL, 'A', 'JESUS', 'MARTINEZ', 'TENORIO', '#324REG7$4', '5578290048', 'JESUS_MARTIN', 'JESUS@GAMAIL.COM', '2024-03-11');

UPDATE PERSONA.USUARIO
SET TIPO_USUARIO = 'D'
WHERE ID_USUARIO = 3

SELECT * FROM PERSONA.USUARIO

--------------------------------------------------------
-- Crea el trigger llamado 'trg_limitar_tarjetas' dentro del esquema INTERACCION

create trigger INTERACCION.trg_limitando_tarjeta_a_3
on INTERACCION.TARJETA
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @TOTAL_TARJETAS INT;
	DECLARE @MESSAGE_ERROR INT;

	SELECT @TOTAL_TARJETAS = COUNT(*)
	FROM INTERACCION.TARJETA t
	JOIN INSERTED i
	ON t.ID_USUARIO = i.ID_USUARIO;

	IF @TOTAL_TARJETAS = 3
	BEGIN 
		SET @MESSAGE_ERROR = 'No se pueden tener mas de tres tarjetas'
		ROLLBACK TRANSACTION;
        THROW 51008, @MESSAGE_ERROR , 1;
        RETURN;
	END;

	INSERT INTO INTERACCION.TARJETA (NUM_TARJETA, ID_USUARIO, MES, YEAR_TARJETA, ID_BANCO)
    SELECT NUM_TARJETA, ID_USUARIO, MES, YEAR_TARJETA, ID_BANCO
    FROM INSERTED;
END

		
-----------------COMPROBACION----------------------------

INSERT INTO INTERACCION.TARJETA (NUM_TARJETA, ID_USUARIO, MES, year_tarjeta, ID_BANCO) VALUES ('1234567890123456', 4, 3, 2025, 1);
INSERT INTO INTERACCION.TARJETA (NUM_TARJETA, ID_USUARIO, MES, year_tarjeta, ID_BANCO) VALUES ('1234746390123456', 4, 2, 2025, 2);
INSERT INTO INTERACCION.TARJETA (NUM_TARJETA, ID_USUARIO, MES, year_tarjeta, ID_BANCO) VALUES ('1234567828429956', 4, 5, 2025, 3);
INSERT INTO INTERACCION.TARJETA (NUM_TARJETA, ID_USUARIO, MES, year_tarjeta, ID_BANCO) VALUES ('1234568797878956', 4, 9, 2025, 3);

SELECT * FROM PERSONA.USUARIO

-----------------------------------------------------------------------------------------------------------------

-------Validamos que el usuario en la jerarquia sea del tipo correcto para administradores

CREATE TRIGGER trg_jerarquiaA
ON PERSONA.ADMINISTRADOR
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @UsuariosError NVARCHAR(100);
	DECLARE @MensajeError NVARCHAR(100);

    WITH INVALIDOS AS (
        SELECT u.ID_USUARIO
        FROM PERSONA.USUARIO AS u
        JOIN INSERTED i
        ON i.ID_USUARIO = u.ID_USUARIO
        WHERE TIPO_USUARIO != 'A'
    )


    SELECT @UsuariosError = STRING_AGG(CAST(ID_USUARIO AS NVARCHAR(5)), ', ')
    FROM INVALIDOS

    IF @UsuariosError IS NOT NULL
    BEGIN
        ROLLBACK TRANSACTION;
        SET @MensajeError = 'No puedes crear como administradores los siguientes usuarios (no son tipo ''A''): ' + @UsuariosError;
		THROW 51007, @MensajeError, 1;
        RETURN;
    END;
END;
GO

-----------------COMPROBACION-----------------------------

select * from persona.USUARIO

delete persona.administrador where ID_USUARIO = 4

insert into persona.ADMINISTRADOR values (4,'2024-01-02')
insert into persona.ADMINISTRADOR values (6,'2024-01-02')

---------------------------------------------------------------------------------------------------------------------------------------

--- Trigers que valida que la jerarquia tenga el tipo de usuario correcto para conductores 

CREATE TRIGGER trg_jerarquiaC
ON PERSONA.CONDUCTOR
AFTER INSERT
AS
BEGIN

    SET NOCOUNT ON;
	DECLARE @UsuariosError NVARCHAR(100);
	DECLARE @MensajeError NVARCHAR(100);

    WITH INVALIDOS AS (
        SELECT u.ID_USUARIO
        FROM PERSONA.USUARIO AS u
        JOIN INSERTED i
        ON i.ID_USUARIO = u.ID_USUARIO
        WHERE TIPO_USUARIO != 'D'
    )

 
    SELECT @UsuariosError = STRING_AGG(CAST(ID_USUARIO AS NVARCHAR(5)), ', ')
    FROM INVALIDOS

    IF @UsuariosError IS NOT NULL
    BEGIN
        ROLLBACK TRANSACTION;
		SET @MensajeError = 'No puedes crear como administradores los siguientes usuarios (no son tipo ''D''): ' + @UsuariosError;
		THROW 51007, @MensajeError, 1;        
		RETURN;
    END;
END;


-----------COMPROBACION-------------------------------

select * from persona.USUARIO

delete persona.CONDUCTOR where ID_USUARIO = 6

INSERT INTO PERSONA.CONDUCTOR (ID_USUARIO, FECHA_VIGENCIA, DESCRIPCION, FOTO_RECIENTE, NUM_LICENCIA) VALUES (6, '2026-07-01', 'Conductor experimentado con más de 5 años de experiencia.', 0x78901234, 78901234);
INSERT INTO PERSONA.CONDUCTOR (ID_USUARIO, FECHA_VIGENCIA, DESCRIPCION, FOTO_RECIENTE, NUM_LICENCIA) VALUES (4, '2026-07-01', 'Conductor experimentado con más de 5 años de experiencia.', 0x78901234, 78905674);


-------------------------------------------------------

--- Limitar numero de autos por conductor a 2

CREATE TRIGGER trg_validar_auto
ON VEHICULO
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @ConductoresExcedidos NVARCHAR(100);
	DECLARE @MensajeError NVARCHAR(100);

    -- CTEs para nuevas y existentes
    WITH Nuevos AS (
        SELECT i.ID_USUARIO, COUNT(*) AS CantidadNuevos
        FROM INSERTED i
        GROUP BY i.ID_USUARIO
    ),
    Existentes AS (
        SELECT a.ID_USUARIO, COUNT(*) AS CantidadExistentes
        FROM VEHICULO a
        GROUP BY a.ID_USUARIO
    )

    -- 1. Verificar si algún conductor intenta exceder el límite de 2 autos

    SELECT @ConductoresExcedidos = STRING_AGG(CAST(n.ID_USUARIO AS NVARCHAR(5)), ', ')
    FROM Nuevos n
    LEFT JOIN Existentes e
    ON n.ID_USUARIO = e.ID_USUARIO
    WHERE ISNULL(e.CantidadExistentes, 0) + n.CantidadNuevos > 2;

    IF @ConductoresExcedidos IS NOT NULL
    BEGIN
		SET @MensajeError = 'No se puede exceder el limite de dos autos';
        THROW 51002, @MensajeError, @ConductoresExcedidos;
        RETURN;
    END;

    -- 2. Verificar si algún auto tiene más de 5 años de antigüedad
    DECLARE @AutosAntiguos NVARCHAR(100);
    SELECT @AutosAntiguos = STRING_AGG(CAST(ID_MODELO AS NVARCHAR(5)), ', ')
    FROM INSERTED
    WHERE year_auto < YEAR(GETDATE()) - 5;

    IF @AutosAntiguos IS NOT NULL
    BEGIN
		SET @MensajeError = 'Los siguientes autos tienen mas de 5 años de antiguedad' + @AutosAntiguos;
        THROW 51002, @MensajeError, 2;
        RETURN;
    END;

    -- Si todo está correcto, hace el INSERT
    INSERT INTO VEHICULO(NUM_SERIE_VEHICULO,ID_USUARIO, ID_MODELO, NUM_PLACA, year_auto, DISPONIBLE, COLOR_VEHICULO)
    SELECT NUM_SERIE_VEHICULO,ID_USUARIO, ID_MODELO, NUM_PLACA, year_auto, DISPONIBLE, COLOR_VEHICULO
    FROM INSERTED;
END;
GO

--------------------COMPROBACION---------------------------------------------------
DELETE FROM VEHICULO WHERE ID_USUARIO = 6 OR ID_USUARIO = 9

INSERT INTO VEHICULO VALUES ('1HGCM82633A543210', 6, 5, 'MNO345', 2024, 1, 5)
INSERT INTO VEHICULO VALUES ('1HGCM82633A653210', 6, 5, 'MHO345', 2024, 1, 5)
INSERT INTO VEHICULO VALUES ('1HGCM82633A873210', 6, 5, 'MYO345', 2023, 1, 5)

INSERT INTO VEHICULO VALUES ('1HGCM82633A5GT210', 9, 5, 'MSO345', 2014, 1, 5)

SELECT * FROM PERSONA.USUARIO

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
    
    DECLARE @ViajesError NVARCHAR(MAX);
    DECLARE @MensajeError NVARCHAR(MAX);

    -- Identificar las nuevas transiciones
    WITH Nueva AS (
        SELECT 
            i.ID_VIAJE,
            i.CLAVE_ESTATUS AS NuevoClave,
            e_new.NOMBRE_ESTATUS AS NuevoEstatus,
            i.FECHA_ESTATUS,
            (
                SELECT TOP 1 ev_old.CLAVE_ESTATUS
                FROM RECORRIDO.ESTATUS_VIAJE ev_old
                WHERE ev_old.ID_VIAJE = i.ID_VIAJE
                AND ev_old.FECHA_ESTATUS < i.FECHA_ESTATUS
                ORDER BY ev_old.FECHA_ESTATUS DESC
            ) AS PrevClave
        FROM INSERTED i
        JOIN RECORRIDO.ESTATUS e_new
          ON i.CLAVE_ESTATUS = e_new.CLAVE_ESTATUS
    ),
    Invalidas AS (
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
            (n.PrevClave IS NULL AND n.NuevoClave <> 'S')
            OR (e_prev.NOMBRE_ESTATUS = 'S' AND n.NuevoClave <> 'G')
            OR (e_prev.NOMBRE_ESTATUS = 'G' AND n.NuevoClave NOT IN ('C','X'))
            OR (e_prev.NOMBRE_ESTATUS = 'C' AND n.NuevoClave <> 'E')
            OR (e_prev.NOMBRE_ESTATUS = 'E' AND n.NuevoClave <> 'B')
            OR (e_prev.NOMBRE_ESTATUS = 'B' AND n.NuevoClave NOT IN ('P','A'))
            OR (e_prev.NOMBRE_ESTATUS IN ('P','A','X') AND n.NuevoClave <> 'T')
            OR (e_prev.NOMBRE_ESTATUS = 'T')
    )

    -- Validación de transiciones inválidas
    SELECT @ViajesError = STRING_AGG(CAST(ID_VIAJE AS NVARCHAR(10)), ', ')
    FROM Invalidas;

    IF @ViajesError IS NOT NULL
    BEGIN
        SET @MensajeError = 'Transición de estatus inválida para viaje(s): ' + @ViajesError + '. Revisa la secuencia permitida.';
        
        ROLLBACK TRANSACTION;
        THROW 51005, @MensajeError, 1;
    END;

    -- Si todas las transiciones son válidas, sincronizamos el estatus actual
    UPDATE v
    SET v.CLAVE_ACTUAL = n.NuevoClave
    FROM RECORRIDO.VIAJE v
    JOIN Nueva n
      ON v.ID_VIAJE = n.ID_VIAJE;
END;
GO


 



-----------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Triger que impida crear la tabla aceptado hasta que el estatus tome el valor de aceptado
CREATE TRIGGER trg_aceptado
ON RECORRIDO.ACEPTADO
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

DROP TRIGGER trg_queja_administrador

--Este trigger verifica que un administrador no pueda actualizar quejas relacionadas consigo mismo
CREATE TRIGGER trg_queja_administrador
ON INTERACCION.QUEJA 
AFTER INSERT, UPDATE 
AS
BEGIN
    
    SET NOCOUNT ON;
	DECLARE @UsuariosError NVARCHAR(100);

    WITH USERS AS (
        SELECT i.ID_USUARIO
        FROM INSERTED i
        JOIN PERSONA.ADMINISTRADOR a
        ON i.ID_USUARIO = a.ID_USUARIO
    )

	SELECT @UsuariosError = STRING_AGG(CAST(ID_USUARIO AS NVARCHAR(5)), ', ')
    FROM USERS

    IF	@UsuariosError IS NOT NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 51003, 'Un administrador no puede actualizar quejas relacionadas consigo mismo.',1;
    END

END;
go

------------------COMPROBACION-------------------------------

INSERT INTO INTERACCION.QUEJA (ID_USUARIO, ID_VEHICULO, ID_ADMINISTRADOR, TITULO, FECHA_EMISION) VALUES (4, 13, 4, 'Retraso en el servicio', '2025-01-15');
select * from VEHICULO

--------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------------

--- Triger que valide que el usuario que tenga la queja tenga relación con el conductor     
CREATE TRIGGER trg_queja_relacion
ON INTERACCION.QUEJA
INSTEAD OF INSERT 
AS 
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UsuariosInvalidos NVARCHAR(MAX);
    DECLARE @UsuariosError NVARCHAR(MAX);
    DECLARE @MensajeError NVARCHAR(MAX);

    WITH INVALIDOS AS (
        SELECT i.ID_USUARIO
        FROM INSERTED i
        WHERE i.ID_USUARIO NOT IN (SELECT ID_USUARIO FROM RECORRIDO.VIAJE)
    )
    SELECT @UsuariosInvalidos = STRING_AGG(CAST(ID_USUARIO AS NVARCHAR(10)), ', ')
    FROM INVALIDOS;
    
    IF @UsuariosInvalidos IS NOT NULL
    BEGIN
        SET @MensajeError = 'Los siguientes usuarios no tienen viajes: ' + @UsuariosInvalidos;
        THROW 51009, @MensajeError, 1;
        RETURN;
    END;
    
    WITH USERS AS (
        SELECT i.ID_USUARIO, v.ID_VEHICULO
        FROM INSERTED i
        JOIN RECORRIDO.VIAJE v
        ON v.ID_USUARIO = i.ID_USUARIO
        WHERE v.ID_VEHICULO = i.ID_VEHICULO
    )
    SELECT @UsuariosError = STRING_AGG(CAST(i.ID_USUARIO AS NVARCHAR(10)), ', ')
    FROM INSERTED i
    WHERE i.ID_USUARIO NOT IN (SELECT ID_USUARIO FROM USERS);

    IF @UsuariosError IS NOT NULL
    BEGIN
        SET @MensajeError = 'Los siguientes usuarios no pueden generar una queja debido a que no tienen relación con el auto mencionado: ' + @UsuariosError;
        THROW 51009, @MensajeError, 2;
        RETURN;
    END;

    INSERT INTO INTERACCION.QUEJA (ID_QUEJA, ID_USUARIO, ID_VEHICULO, ID_ADMINISTRADOR, TITULO, FECHA_EMISION)
    SELECT ID_QUEJA, ID_USUARIO, ID_VEHICULO, ID_ADMINISTRADOR, TITULO, FECHA_EMISION
    FROM INSERTED;
END;
GO
----------------------COMPROBACION------------------------------------
INSERT INTO INTERACCION.QUEJA (ID_USUARIO, ID_VEHICULO, ID_ADMINISTRADOR, TITULO, FECHA_EMISION) VALUES (4, 13, 4, 'Retraso en el servicio', '2025-01-15');
select * from VEHICULO

-----------------------------------------------------------------------


--- Triger para la queja no tarde en resolverse más de 5 días

CREATE TRIGGER trg_resolucion
ON RESOLUCION
AFTER INSERT, UPDATE
AS
BEGIN 

	SET NOCOUNT ON;

	DECLARE @QUEJAS_ERROR NVARCHAR(MAX);

	DECLARE @MESSAGE_ERROR NVARCHAR(MAX);

	WITH QUEJAS_SOLUCIONADAS AS(

		SELECT i.ID_QUEJA
		FROM INSERTED AS i
		JOIN INTERACCION.QUEJA AS q 
		ON i.ID_QUEJA = q.ID_QUEJA
		WHERE DATEDIFF(DAY,FECHA_EMISION,GETDATE()) <= 5
	)
	SELECT @QUEJAS_ERROR = STRING_AGG(CAST(i.ID_QUEJA AS NVARCHAR(10)), ', ')
    FROM INSERTED i

	IF @QUEJAS_ERROR IS NOT NULL
	BEGIN
        ROLLBACK TRANSACTION;
		SET @MESSAGE_ERROR = 'La queja tienen más de 5 días de antigüedad';
        THROW 51011,@MESSAGE_ERROR , 1;
        RETURN;
    END;
END;

-----------------COMPROBACION-------------------------

INSERT INTO RESOLUCION (ID_QUEJA, DESCRIPCION_RESOLUCION, FECHA_ATENDIDO) VALUES (1, 'Reembolso parcial otorgado', '2025-01-20');

select * from INTERACCION.QUEJA

-----------------------------------------------------
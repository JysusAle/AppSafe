/***************************************

--------------- validaTriggers -----------------

Autores: Equipo 1 de 3

Fecha: 11/05/2025

Descripcion: En este Script se encuentran cada uno
de los triggers, ejecuata un escenario para
validar el correcto funcionamiento de los triggers

------------------------------------------


******************************************/

use [APPSAFE_TEAM_UNO_DE_TRES]
go


-----------------------------------------------------------------


--====================================================
--Nombre: PERSONA.trg_jerarquiaU
--Autores: TENORIO MARTINEZ JESUS ALEJANDRO, SALAZAR ISLAS LUIS DANIEL Y ARAIZA VALDEZ DIEGO ANTONIO
--Descripción: El trigger trg_jerarquiaU tiene el propósito de validar cambios en el tipo de usuario en la tabla PERSONA.USUARIO
--Fecha de elaboración: 25/05/2025
--====================================================

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

UPDATE PERSONA.USUARIO -- NO SE PUEDE CAMBIAR EL TIPO DE USUARIO 
SET TIPO_USUARIO = 'D'
WHERE ID_USUARIO = (SELECT * FROM PERSONA.USUARIO
WHERE APELLIDOP = 'TENORIO' AND NOMBRE_PILA = 'JESUS' AND APELLIDOM = 'MARTINEZ')

DELETE FROM PERSONA.USUARIO 
WHERE ID_USUARIO = (SELECT * FROM PERSONA.USUARIO
WHERE APELLIDOP = 'TENORIO' AND NOMBRE_PILA = 'JESUS' AND APELLIDOM = 'MARTINEZ')

--------------------------------------------------------


--====================================================
--Nombre: INTERACCION.trg_limitando_tarjeta_a_3
--Autores: TENORIO MARTINEZ JESUS ALEJANDRO, SALAZAR ISLAS LUIS DANIEL Y ARAIZA VALDEZ DIEGO ANTONIO
--Descripción: Crea el trigger llamado 'trg_limitar_tarjetas' dentro del esquema INTERACCION
--Fecha de elaboración: 24/05/2025
--====================================================

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

INSERT INTO PERSONA.USUARIO VALUES (NULL, 'A', 'JESUS', 'MARTINEZ', 'TENORIO', '#324REG7$4', '5578290048', 'JESUS_MARTIN', 'JESUS@GAMAIL.COM', '2024-03-11');

INSERT INTO INTERACCION.TARJETA (NUM_TARJETA, ID_USUARIO, MES, year_tarjeta, ID_BANCO) VALUES ('1234567890123451', (SELECT ID_USUARIO FROM PERSONA.USUARIO
WHERE APELLIDOP = 'TENORIO' AND NOMBRE_PILA = 'JESUS' AND APELLIDOM = 'MARTINEZ'), 3, 2025, 1);

INSERT INTO INTERACCION.TARJETA (NUM_TARJETA, ID_USUARIO, MES, year_tarjeta, ID_BANCO) VALUES ('1234746390123452', (SELECT ID_USUARIO FROM PERSONA.USUARIO
WHERE APELLIDOP = 'TENORIO' AND NOMBRE_PILA = 'JESUS' AND APELLIDOM = 'MARTINEZ'), 2, 2025, 2);

INSERT INTO INTERACCION.TARJETA (NUM_TARJETA, ID_USUARIO, MES, year_tarjeta, ID_BANCO) VALUES ('1234567828429953',(SELECT ID_USUARIO FROM PERSONA.USUARIO
WHERE APELLIDOP = 'TENORIO' AND NOMBRE_PILA = 'JESUS' AND APELLIDOM = 'MARTINEZ'), 5, 2025, 3);

-- EN LA TERCERA INSERCCION NO SE PERMITE DADO, QUE NO SSE PUEDEN TENER MAS DE TRES TARJETAS
INSERT INTO INTERACCION.TARJETA (NUM_TARJETA, ID_USUARIO, MES, year_tarjeta, ID_BANCO) VALUES ('1234568797878954', (SELECT ID_USUARIO FROM PERSONA.USUARIO
WHERE APELLIDOP = 'TENORIO' AND NOMBRE_PILA = 'JESUS' AND APELLIDOM = 'MARTINEZ'), 9, 2025, 3);

SELECT * FROM PERSONA.USUARIO

-----------------------------------------------------------------------------------------------------------------


--====================================================
--Nombre: PERSONA.trg_jerarquiaA
--Autores: TENORIO MARTINEZ JESUS ALEJANDRO, SALAZAR ISLAS LUIS DANIEL Y ARAIZA VALDEZ DIEGO ANTONIO
--Descripción: Validamos que el usuario en la jerarquia sea del tipo correcto para administradores
--Fecha de elaboración: 24/05/2025
--====================================================

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
INSERT INTO PERSONA.USUARIO VALUES (NULL, 'A', 'JESUS', 'MARTINEZ', 'TENORIO', '#324REG7$4', '5578290048', 'JESUS_MARTIN', 'JESUS@GAMAIL.COM', '2024-03-11');

delete persona.administrador where ID_USUARIO = (SELECT ID_USUARIO FROM PERSONA.USUARIO
WHERE APELLIDOP = 'TENORIO' AND NOMBRE_PILA = 'JESUS' AND APELLIDOM = 'MARTINEZ')

insert into persona.ADMINISTRADOR values ((SELECT ID_USUARIO FROM PERSONA.USUARIO --EL SIGUIENTE USUARIO ES ADMINISTRADOR 
WHERE APELLIDOP = 'TENORIO' AND NOMBRE_PILA = 'JESUS' AND APELLIDOM = 'MARTINEZ'),'2024-01-02')

--PERO SE RECHAZA A USUARIOS TIPO A
insert into persona.ADMINISTRADOR values ((SELECT TOP 1 ID_USUARIO FROM PERSONA.USUARIO WHERE TIPO_USUARIO != 'A'),'2024-01-02')

---------------------------------------------------------------------------------------------------------------------------------------


--====================================================
--Nombre: PERSONA.trg_jerarquiaC
--Autores: TENORIO MARTINEZ JESUS ALEJANDRO, SALAZAR ISLAS LUIS DANIEL Y ARAIZA VALDEZ DIEGO ANTONIO
--Descripción: Trigers que valida que la jerarquia tenga el tipo de usuario correcto para conductores 
--Fecha de elaboración: 23/05/2025
--====================================================

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

INSERT INTO PERSONA.USUARIO VALUES (NULL, 'D', 'Miguel', 'Mtz', 'Lopez', 'A7#TYu*929', 5522345678, 'miguel_M', 'miguel@hotmail.com', '2024-01-21');

insert into persona.CONDUCTOR values ((SELECT ID_USUARIO FROM PERSONA.USUARIO WHERE NOMBRE_PILA = 'Miguel' and APELLIDOM = 'Mtz' and APELLIDOP = 'Lopez'),'2024-01-02','DESCRIPCION',0x89012878,82132345)

-- NO FUNCIONA SI INSERTAMOS UN USUARIO QUE NO SEA CONDUCTOR 
insert into persona.CONDUCTOR values ((SELECT TOP 1 ID_USUARIO FROM PERSONA.USUARIO WHERE TIPO_USUARIO != 'D'),'2024-01-02','DESCRIPCION',0x89012345,89212345)

-------------------------------------------------------


--====================================================
--Nombre: trg_validar_auto
--Autores: TENORIO MARTINEZ JESUS ALEJANDRO, SALAZAR ISLAS LUIS DANIEL Y ARAIZA VALDEZ DIEGO ANTONIO
--Descripción: Limitar numero de autos por conductor a 2
--Fecha de elaboración: 23/05/2025
--====================================================

CREATE TRIGGER trg_validar_auto
ON VEHICULO
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @ConductoresExcedidos NVARCHAR(MAX);
	DECLARE @MensajeError NVARCHAR(MAX);

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

    SELECT @ConductoresExcedidos = STRING_AGG(CAST(n.ID_USUARIO AS NVARCHAR(10)), ', ')
    FROM Nuevos n
    LEFT JOIN Existentes e
    ON n.ID_USUARIO = e.ID_USUARIO
    WHERE ISNULL(e.CantidadExistentes, 0) + n.CantidadNuevos > 2;

    IF @ConductoresExcedidos IS NOT NULL
    BEGIN
		SET @MensajeError = 'Los siguientes conductores exceden el límite de dos autos: ' + @ConductoresExcedidos;
        THROW 51002, @MensajeError, 1;
        RETURN;
    END;

    -- 2. Verificar si algún auto tiene más de 5 años de antigüedad
    DECLARE @AutosAntiguos NVARCHAR(MAX);
    SELECT @AutosAntiguos = STRING_AGG(CAST(ID_MODELO AS NVARCHAR(10)), ', ')
    FROM INSERTED
    WHERE year_auto < YEAR(GETDATE()) - 5;

    IF @AutosAntiguos IS NOT NULL
    BEGIN
		SET @MensajeError = 'Los siguientes autos tienen más de 5 años de antigüedad: ' + @AutosAntiguos;
        THROW 51003, @MensajeError, 1;
        RETURN;
    END;

    -- Si todo está correcto, hace el INSERT
    INSERT INTO VEHICULO(NUM_SERIE_VEHICULO,ID_USUARIO, ID_MODELO, NUM_PLACA, year_auto, DISPONIBLE, COLOR_VEHICULO)
    SELECT NUM_SERIE_VEHICULO,ID_USUARIO, ID_MODELO, NUM_PLACA, year_auto, DISPONIBLE, COLOR_VEHICULO
    FROM INSERTED;
END;
GO


--------------------COMPROBACION---------------------------------------------------

--ESTA CONSULTA REGRESA LOS USUARIOS QUE YA TIENEN 2 AUTOS 
SELECT TOP 1 C.ID_USUARIO, COUNT(I.ID_VEHICULO) AS vehiculo
FROM PERSONA.CONDUCTOR C
JOIN VEHICULO I ON C.ID_USUARIO = I.ID_USUARIO
GROUP BY C.ID_USUARIO
HAVING COUNT(I.ID_VEHICULO) = 2
ORDER BY C.ID_USUARIO;

---SI INTENTAMOS INSERTAR A ALGUN USUARIO QUE YA TIENE DOS AUTOS, PRODUCE UN ERROR:

INSERT INTO VEHICULO VALUES ('1HGCM82633A543210', (SELECT TOP 1 C.ID_USUARIO
FROM PERSONA.CONDUCTOR C
JOIN VEHICULO I ON C.ID_USUARIO = I.ID_USUARIO
GROUP BY C.ID_USUARIO
HAVING COUNT(I.ID_VEHICULO) = 2
ORDER BY C.ID_USUARIO), 5, 'MNR445', 2024, 1, 5)

-- EN CAMBIO SI NO:

INSERT INTO VEHICULO VALUES ('1HGCM82633A543210', (SELECT TOP 1 C.ID_USUARIO
FROM PERSONA.CONDUCTOR C
JOIN VEHICULO I ON C.ID_USUARIO = I.ID_USUARIO
GROUP BY C.ID_USUARIO
HAVING COUNT(I.ID_VEHICULO) = 1
ORDER BY C.ID_USUARIO), 5, 'MNR445', 2024, 1, 5)

--------------------------------------------------------------------------------------------------------------------------------------



--====================================================
--Nombre: RECORRIDO.trg_FechaSolicitud
--Autores: TENORIO MARTINEZ JESUS ALEJANDRO, SALAZAR ISLAS LUIS DANIEL Y ARAIZA VALDEZ DIEGO ANTONIO
--Descripción: Trigger que verifica que la solicitud no exceda mas de dos dias 
--Fecha de elaboración: 24/05/2025
--====================================================
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
--------------------- COMPROBACION -----------------------------------

-- Viaje normal: fecha debe ser hoy
INSERT INTO RECORRIDO.VIAJE (ID_FACTURA, ID_VEHICULO, CLAVE_ACTUAL, ID_USUARIO, FECHA_SOLICITUD, LATITUD_DESTINO, LONGITUD_DESTINO, LONGITUD_ORIGEN, LATITUD_ORIGEN, TIPO, TIPO_PAGO, TARJETA_CLIENTE) 
VALUES (2, 1, 1, 2, GETDATE(), '19.346', '-93.1332', '-92.1400', '13.4400', 'N', 'T', '1234567890123456');

INSERT INTO RECORRIDO.VIAJE 
VALUES (1, 2, 1, 1, DATEADD(DAY, 1, GETDATE()), '19.4327', '-99.1333', '-99.1401', '19.4401', 'P', 'E', '2345678901234567');


-- Viaje programado: fecha puede ser hasta +2 días
INSERT INTO RECORRIDO.VIAJE 
VALUES (1, 2, 1, 1, DATEADD(DAY, 1, GETDATE()), '19.4327', '-99.1333', '-99.1401', '19.4401', 'P', 'E', '2345678901234567');

INSERT INTO RECORRIDO.VIAJE 
VALUES (1, 2, 1, 1, DATEADD(DAY, 5, GETDATE()), '19.4327', '-99.1333', '-99.1401', '19.4401', 'P', 'E', '2345678901234567');

--------------------------------------------------------------------------------------------------------------------------------------


--=====================================================
--Nombre: RECORRIDO.trg_ValidarTransicionEstatus
--Autores: TENORIO MARTINEZ JESUS ALEJANDRO, SALAZAR ISLAS LUIS DANIEL Y ARAIZA VALDEZ DIEGO ANTONIO
--Descripción: Trigger que valida la transicion entre estatus
--Fecha de elaboración: 25/05/2025
--====================================================
CREATE TRIGGER trg_ValidarTransicionEstatus
ON RECORRIDO.ESTATUS_VIAJE
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UsuariosInvalidos NVARCHAR(MAX);

    -- Paso 1: CTEs para obtener transiciones y detectar errores
    ;WITH Nueva AS (
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
            (n.PrevClave IS NULL AND n.NuevoEstatus <> 'S')
            OR (e_prev.NOMBRE_ESTATUS = 'S' AND n.NuevoEstatus <> 'G')
            OR (e_prev.NOMBRE_ESTATUS = 'G' AND n.NuevoEstatus NOT IN ('C','X'))
            OR (e_prev.NOMBRE_ESTATUS = 'C' AND n.NuevoEstatus <> 'E')
            OR (e_prev.NOMBRE_ESTATUS = 'E' AND n.NuevoEstatus <> 'B')
            OR (e_prev.NOMBRE_ESTATUS = 'B' AND n.NuevoEstatus NOT IN ('P','A'))
            OR (e_prev.NOMBRE_ESTATUS IN ('P','A','X') AND n.NuevoEstatus <> 'T')
            OR (e_prev.NOMBRE_ESTATUS = 'T')
    )
    SELECT @UsuariosInvalidos = STRING_AGG(CAST(ID_VIAJE AS NVARCHAR(10)), ', ')
    FROM Invalidas;

    -- Paso 2: Si hay errores, cancelar
    IF @UsuariosInvalidos IS NOT NULL
    BEGIN
        DECLARE @MensajeError NVARCHAR(MAX);
        SET @MensajeError = 'Transición de estatus inválida para viaje(s): ' + @UsuariosInvalidos + '. Revisa la secuencia permitida.';
        ROLLBACK TRANSACTION;
        THROW 51005, @MensajeError, 1;
    END;

    -- Paso 3: Hacer de nuevo la CTE para actualizar, ya que las CTEs no sobreviven al bloque anterior
    ;WITH Nueva AS (
        SELECT 
            i.ID_VIAJE,
            i.CLAVE_ESTATUS AS NuevoClave
        FROM INSERTED i
    )
    UPDATE v
    SET v.CLAVE_ACTUAL = n.NuevoClave
    FROM RECORRIDO.VIAJE v
    JOIN Nueva n ON v.ID_VIAJE = n.ID_VIAJE;
END;
GO

--------------------COMPROBACION-----------------------------
--PARA ESTE EJEMPLO CREAMOS UN EJEMPLO BASE

INSERT INTO RECORRIDO.VIAJE (
    ID_VEHICULO, CLAVE_ACTUAL, ID_USUARIO, FECHA_SOLICITUD,
    LATITUD_DESTINO, LONGITUD_DESTINO, LATITUD_ORIGEN, LONGITUD_ORIGEN,
    TIPO, TIPO_PAGO, TARJETA_CLIENTE
)
VALUES (
    1, -- ID_VEHICULO
    1, -- CLAVE_ACTUAL = 'S'
    (SELECT ID_USUARIO FROM PERSONA.USUARIO WHERE NOMBRE_USUARIO = 'JESUS_MARTIN'), -- ID_USUARIO
    GETDATE(),
    '19.4326', '-99.1332', '19.4270', '-99.1276',
    'N', 'T', '1234567890123451'
);

-- OBTENIENDO EL ID_VIAJE MAS RECIENTE (EL QUE ACABAMOS DE CREAR)
SELECT TOP 1 ID_VIAJE
FROM RECORRIDO.VIAJE
WHERE ID_USUARIO = (
    SELECT ID_USUARIO
    FROM PERSONA.USUARIO
    WHERE NOMBRE_USUARIO = 'JESUS_MARTIN'
)
ORDER BY FECHA_SOLICITUD DESC;


-- LA SIGUIENTE SECUENCIA NO CAUSA NINGUN ERROR
INSERT INTO RECORRIDO.ESTATUS_VIAJE (ID_VIAJE, CLAVE_ESTATUS, FECHA_ESTATUS) VALUES ((SELECT TOP 1 ID_VIAJE
FROM RECORRIDO.VIAJE
WHERE ID_USUARIO = (
    SELECT ID_USUARIO
    FROM PERSONA.USUARIO
    WHERE NOMBRE_USUARIO = 'JESUS_MARTIN'
)
ORDER BY FECHA_SOLICITUD DESC)
, 1, GETDATE());

INSERT INTO RECORRIDO.ESTATUS_VIAJE (ID_VIAJE, CLAVE_ESTATUS, FECHA_ESTATUS) VALUES ((SELECT TOP 1 ID_VIAJE
FROM RECORRIDO.VIAJE
WHERE ID_USUARIO = (
    SELECT ID_USUARIO
    FROM PERSONA.USUARIO
    WHERE NOMBRE_USUARIO = 'JESUS_MARTIN'
)
ORDER BY FECHA_SOLICITUD DESC), 2, GETDATE());

INSERT INTO RECORRIDO.ESTATUS_VIAJE (ID_VIAJE, CLAVE_ESTATUS, FECHA_ESTATUS) VALUES ((SELECT TOP 1 ID_VIAJE
FROM RECORRIDO.VIAJE
WHERE ID_USUARIO = (
    SELECT ID_USUARIO
    FROM PERSONA.USUARIO
    WHERE NOMBRE_USUARIO = 'JESUS_MARTIN'
)
ORDER BY FECHA_SOLICITUD DESC), 3, GETDATE());

INSERT INTO RECORRIDO.ESTATUS_VIAJE (ID_VIAJE, CLAVE_ESTATUS, FECHA_ESTATUS) VALUES ((SELECT TOP 1 ID_VIAJE
FROM RECORRIDO.VIAJE
WHERE ID_USUARIO = (
    SELECT ID_USUARIO
    FROM PERSONA.USUARIO
    WHERE NOMBRE_USUARIO = 'JESUS_MARTIN'
)
ORDER BY FECHA_SOLICITUD DESC), 4, GETDATE());

INSERT INTO RECORRIDO.ESTATUS_VIAJE (ID_VIAJE, CLAVE_ESTATUS, FECHA_ESTATUS) VALUES ((SELECT TOP 1 ID_VIAJE
FROM RECORRIDO.VIAJE
WHERE ID_USUARIO = (
    SELECT ID_USUARIO
    FROM PERSONA.USUARIO
    WHERE NOMBRE_USUARIO = 'JESUS_MARTIN'
)
ORDER BY FECHA_SOLICITUD DESC), 5, GETDATE());

INSERT INTO RECORRIDO.ESTATUS_VIAJE (ID_VIAJE, CLAVE_ESTATUS, FECHA_ESTATUS) VALUES ((SELECT TOP 1 ID_VIAJE
FROM RECORRIDO.VIAJE
WHERE ID_USUARIO = (
    SELECT ID_USUARIO
    FROM PERSONA.USUARIO
    WHERE NOMBRE_USUARIO = 'JESUS_MARTIN'
)
ORDER BY FECHA_SOLICITUD DESC), 6, GETDATE());

INSERT INTO RECORRIDO.ESTATUS_VIAJE (ID_VIAJE, CLAVE_ESTATUS, FECHA_ESTATUS) VALUES ((SELECT TOP 1 ID_VIAJE
FROM RECORRIDO.VIAJE
WHERE ID_USUARIO = (
    SELECT ID_USUARIO
    FROM PERSONA.USUARIO
    WHERE NOMBRE_USUARIO = 'JESUS_MARTIN'
)
ORDER BY FECHA_SOLICITUD DESC), 9, GETDATE());

--UNA SECUENCIA NO PERMITIDA ES COLOCAR CUALQUIER ESTATUS ANTERIOR

INSERT INTO RECORRIDO.ESTATUS_VIAJE (ID_VIAJE, CLAVE_ESTATUS, FECHA_ESTATUS) VALUES ((SELECT TOP 1 ID_VIAJE
FROM RECORRIDO.VIAJE
WHERE ID_USUARIO = (
    SELECT ID_USUARIO
    FROM PERSONA.USUARIO
    WHERE NOMBRE_USUARIO = 'JESUS_MARTIN'
)
ORDER BY FECHA_SOLICITUD DESC), 5, GETDATE());

select * from RECORRIDO.ESTATUS
-----------------------------------------------------------------------------------------------------------------------------------------------------------------

--====================================================
--Nombre: RECORRIDO.trg_aceptado
--Autores: TENORIO MARTINEZ JESUS ALEJANDRO, SALAZAR ISLAS LUIS DANIEL Y ARAIZA VALDEZ DIEGO ANTONIO
--Descripción: triger que impida crear la tabla aceptado hasta que el estatus tome el valor de aceptado
--Fecha de elaboración: 24/05/2025
--====================================================
CREATE TRIGGER trg_aceptado 
ON RECORRIDO.ACEPTADO
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NotAcept NVARCHAR(200);
    DECLARE @MESSAGE_ERROR NVARCHAR(MAX);

    -- CTE para obtener viajes válidos con estatus 'C' y su usuario
    WITH VIAJES_CONFIRMADOS AS (
        SELECT v.ID_VIAJE, v.ID_USUARIO
        FROM RECORRIDO.VIAJE v
        JOIN RECORRIDO.ESTATUS_VIAJE ev ON v.ID_VIAJE = ev.ID_VIAJE
        JOIN RECORRIDO.ESTATUS e ON ev.CLAVE_ESTATUS = e.CLAVE_ESTATUS
        WHERE e.NOMBRE_ESTATUS = 'C'
    )

    -- Detectamos los viajes que no están confirmados
    SELECT @NotAcept = STRING_AGG(CAST(i.ID_VIAJE AS NVARCHAR(5)), ', ')
    FROM INSERTED i
    WHERE NOT EXISTS (
        SELECT 1
        FROM VIAJES_CONFIRMADOS vc
        WHERE vc.ID_VIAJE = i.ID_VIAJE
    );

    IF @NotAcept IS NOT NULL
    BEGIN
        SET @MESSAGE_ERROR = 'Los siguientes viajes no cuentan con el estatus de confirmado (C): ' + @NotAcept;
        THROW 51010, @MESSAGE_ERROR, 1;
        RETURN;
    END;

    -- Si todo es válido, se realiza la inserción
    INSERT INTO RECORRIDO.ACEPTADO (
        ID_VIAJE, COMENTARIOS, PROPINA, CALIFICACION_CONDUCTOR,
        CALIFICACION_USUARIO, HORA_INICIO_CURSO, ID_ETIQUETA_ACEPTADO, IMPORTE
    )
    SELECT 
        ID_VIAJE, COMENTARIOS, PROPINA, CALIFICACION_CONDUCTOR,
        CALIFICACION_USUARIO, HORA_INICIO_CURSO, ID_ETIQUETA_ACEPTADO, IMPORTE
    FROM INSERTED;
END;
GO


------------COMPROBACION---------------------------------------------------------


INSERT INTO RECORRIDO.VIAJE (ID_FACTURA, ID_VEHICULO, CLAVE_ACTUAL, ID_USUARIO, FECHA_SOLICITUD, LATITUD_DESTINO, LONGITUD_DESTINO, LONGITUD_ORIGEN, LATITUD_ORIGEN, TIPO, TIPO_PAGO, TARJETA_CLIENTE) 
VALUES (NULL, 1, 1, 20, GETDATE(), '19.4326', '-99.1332', '-99.1400', '19.4400', 'N', 'T', '1234567890123456');

-- EN ESTE INSERT RECHAZA LA INSERCCION
INSERT INTO RECORRIDO.ACEPTADO (
    ID_VIAJE, COMENTARIOS, PROPINA, CALIFICACION_CONDUCTOR,
    CALIFICACION_USUARIO, HORA_INICIO_CURSO, ID_ETIQUETA_ACEPTADO, IMPORTE
)
VALUES (
    (SELECT TOP 1 ID_VIAJE FROM RECORRIDO.VIAJE ORDER BY FECHA_SOLICITUD DESC),
	'Buen servicio', 10, 5, 4, GETDATE(), NULL, 150.00
);

INSERT INTO RECORRIDO.ESTATUS_VIAJE (CLAVE_ESTATUS, ID_VIAJE, FECHA_ESTATUS) VALUES (1, 
	(SELECT TOP 1 ID_VIAJE FROM RECORRIDO.VIAJE ORDER BY FECHA_SOLICITUD DESC), 
	GETDATE());

INSERT INTO RECORRIDO.ESTATUS_VIAJE (CLAVE_ESTATUS, ID_VIAJE, FECHA_ESTATUS) VALUES (2, 
	(SELECT TOP 1 ID_VIAJE FROM RECORRIDO.VIAJE ORDER BY FECHA_SOLICITUD DESC), 
	GETDATE());

INSERT INTO RECORRIDO.ESTATUS_VIAJE (CLAVE_ESTATUS, ID_VIAJE, FECHA_ESTATUS) VALUES (3, 
	(SELECT TOP 1 ID_VIAJE FROM RECORRIDO.VIAJE ORDER BY FECHA_SOLICITUD DESC), 
	GETDATE());

-- DESPUES YA PODREMOS HACER LA INSERCCION

INSERT INTO RECORRIDO.ACEPTADO (
    ID_VIAJE, COMENTARIOS, PROPINA, CALIFICACION_CONDUCTOR,
    CALIFICACION_USUARIO, HORA_INICIO_CURSO, ID_ETIQUETA_ACEPTADO, IMPORTE
)
VALUES (
    (SELECT TOP 1 ID_VIAJE FROM RECORRIDO.VIAJE ORDER BY FECHA_SOLICITUD DESC),
	'Buen servicio', 10, 5, 4, GETDATE(), NULL, 150.00
);


----------------------------------------------------------------------------------------------------------------------------------------------------------------

--====================================================
--Nombre: INTERACCION.trg_queja_administrador
--Autores: TENORIO MARTINEZ JESUS ALEJANDRO, SALAZAR ISLAS LUIS DANIEL Y ARAIZA VALDEZ DIEGO ANTONIO
--Descripción: Este trigger verifica que un administrador no pueda actualizar quejas relacionadas consigo mismo
--Fecha de elaboración: 23/05/2025
--====================================================
CREATE TRIGGER trg_queja_administrador
ON INTERACCION.QUEJA 
AFTER INSERT, UPDATE 
AS
BEGIN
    
    SET NOCOUNT ON;
	DECLARE @UsuariosError NVARCHAR(100);
	
	IF EXISTS (
        SELECT 1 
        FROM INSERTED
        WHERE ID_ADMINISTRADOR = ID_USUARIO
    )

    BEGIN
		ROLLBACK TRANSACTION;
        THROW 51000, 'No se permite insertar filas donde el administrador revise su propia queja', 1;
        RETURN;
    END;

END;
go

------------------COMPROBACION-------------------------------

---NO PERMITE LA INSERCCION POR SER EL MISMO USUARIO QUIEN RESUELVE LA QUEJA

INSERT INTO INTERACCION.QUEJA (ID_USUARIO, ID_VEHICULO, ID_ADMINISTRADOR, ID_MOTIVO_QUEJA, DESCRIPCION, FECHA_EMISION) VALUES (4, 11, 4,1, 'Retraso en el servicio', '2025-01-15');

---NO PERMITE LA INSERCCION POR NO SER UN ADMINISTRADOR QUIEN RESUELVE LA DUDA
INSERT INTO INTERACCION.QUEJA (ID_USUARIO, ID_VEHICULO, ID_ADMINISTRADOR, ID_MOTIVO_QUEJA, DESCRIPCION, FECHA_EMISION) VALUES (4, 11, 2,1, 'Retraso en el servicio', '2025-01-15');

--------------------------------------------------------------------------------------------------------------------------------------


 
--====================================================
--Nombre: INTERACCION.trg_queja_relacion
--Autores: TENORIO MARTINEZ JESUS ALEJANDRO, SALAZAR ISLAS LUIS DANIEL Y ARAIZA VALDEZ DIEGO ANTONIO
--Descripción: Triger que valide que el usuario que tenga la queja tenga relación con el conductor  
--Fecha de elaboración: 24/05/2025
--====================================================
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

    INSERT INTO INTERACCION.QUEJA (ID_USUARIO, ID_VEHICULO, ID_ADMINISTRADOR, ID_MOTIVO_QUEJA, DESCRIPCION, FECHA_EMISION)
    SELECT ID_USUARIO, ID_VEHICULO, ID_ADMINISTRADOR, ID_MOTIVO_QUEJA, DESCRIPCION, FECHA_EMISION
    FROM INSERTED;
END;
GO
----------------------COMPROBACION------------------------------------
 -- SELECCIONAR UN ID DE ESTOS
SELECT ID_USUARIO FROM PERSONA.USUARIO
EXCEPT 
(
	SELECT I.ID_USUARIO 
	FROM PERSONA.USUARIO i
	INNER JOIN RECORRIDO.VIAJE V ON I.ID_USUARIO = V.ID_USUARIO
)

-- NO PERMITE LA INSERCCION DADO QUE NO TIENE VIAJES 
INSERT INTO INTERACCION.QUEJA (ID_USUARIO, ID_VEHICULO, ID_ADMINISTRADOR, ID_MOTIVO_QUEJA, DESCRIPCION, FECHA_EMISION) VALUES ((SELECT TOP 1 ID_USUARIO FROM PERSONA.USUARIO
EXCEPT 
(
	SELECT I.ID_USUARIO 
	FROM PERSONA.USUARIO i
	INNER JOIN RECORRIDO.VIAJE V ON I.ID_USUARIO = V.ID_USUARIO

)), 3, 1, 1, 'MOTIVO', '2025-05-25');

--- LAS RELACIONES ESTRE USUARIOS Y CONDUCTORES SON:
SELECT U.ID_USUARIO AS USUARIO, V.ID_VEHICULO AS VEHICULO
FROM PERSONA.USUARIO U 
INNER JOIN RECORRIDO.VIAJE V ON U.ID_USUARIO = V.ID_USUARIO
INNER JOIN VEHICULO H ON H.ID_VEHICULO = V.ID_VEHICULO

--- SI TRATAMOS DE INSERTAR UN USUARIO QUE NO ESTE RELAIONADO CON UN CONDUCTOR
--- NO PERMITA LA INSERCCION

INSERT INTO INTERACCION.QUEJA (ID_USUARIO, ID_VEHICULO, ID_ADMINISTRADOR, ID_MOTIVO_QUEJA, DESCRIPCION, FECHA_EMISION) VALUES ((SELECT TOP 1 U.ID_USUARIO
FROM PERSONA.USUARIO U 
INNER JOIN RECORRIDO.VIAJE V ON U.ID_USUARIO = V.ID_USUARIO
INNER JOIN VEHICULO H ON H.ID_VEHICULO = V.ID_VEHICULO), 2, 1, 1, 'MOTIVO', '2025-05-25');


-----------------------------------------------------------------------




--====================================================
--Nombre: trg_resolucion
--Autores: TENORIO MARTINEZ JESUS ALEJANDRO, SALAZAR ISLAS LUIS DANIEL Y ARAIZA VALDEZ DIEGO ANTONIO
--Descripción: Triger para la queja no tarde en resolverse más de 5 días
--Fecha de elaboración: 25/05/2025
--====================================================

CREATE TRIGGER trg_resolucion
ON RESOLUCION
AFTER INSERT, UPDATE
AS
BEGIN 
    SET NOCOUNT ON;

    DECLARE @QUEJAS_ERROR NVARCHAR(MAX);
    DECLARE @MESSAGE_ERROR NVARCHAR(MAX);

    SELECT @QUEJAS_ERROR = STRING_AGG(CAST(i.ID_QUEJA AS NVARCHAR(10)), ', ')
    FROM INSERTED i
    JOIN INTERACCION.QUEJA q ON i.ID_QUEJA = q.ID_QUEJA
    WHERE DATEDIFF(DAY, q.FECHA_EMISION, GETDATE()) > 5;

    IF @QUEJAS_ERROR IS NOT NULL
    BEGIN
        SET @MESSAGE_ERROR = 'No puedes registrar una resolución porque la(s) queja(s) tienen más de 5 días de antigüedad: ' + @QUEJAS_ERROR;
        ROLLBACK TRANSACTION;
        THROW 51011, @MESSAGE_ERROR, 1;
    END;
END;
GO

-----------------COMPROBACION-------------------------


INSERT INTO INTERACCION.QUEJA (ID_USUARIO, ID_VEHICULO, ID_ADMINISTRADOR, ID_MOTIVO_QUEJA, DESCRIPCION, FECHA_EMISION) VALUES (2, 5, 7, 5, 'DESCRIPCION', '2025-04-19');

SELECT ID_QUEJA FROM INTERACCION.QUEJA ---EL ID QUE TE SALGA AQUI PONLO EN LA INSERCCION DE ABAJO
WHERE DESCRIPCION = 'DESCRIPCION'

--- No permite la inserccion de la resolucion al tener 5 dias de existencia 
INSERT INTO RESOLUCION (ID_QUEJA, DESCRIPCION_RESOLUCION, FECHA_ATENDIDO) VALUES (6, 'Reembolso parcial otorgado', '2025-05-23');

-----------------------------------------------------


--====================================================
--Nombre: trg_disponibilidad
--Autores: TENORIO MARTINEZ JESUS ALEJANDRO, SALAZAR ISLAS LUIS DANIEL Y ARAIZA VALDEZ DIEGO ANTONIO
--Descripción: Triger para que el sistema solo asigne viajes a vehiculos disponibles
--Fecha de elaboración: 25/05/2025
--====================================================

CREATE TRIGGER trg_disponibilidad
ON RECORRIDO.VIAJE
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @VehiculosNoDisponibles NVARCHAR(MAX);
    DECLARE @MensajeError NVARCHAR(MAX);

    -- Detecta los vehículos no disponibles
    WITH VehiculosNoDisponibles AS (
        SELECT i.ID_VEHICULO
        FROM INSERTED i
        JOIN VEHICULO v ON i.ID_VEHICULO = v.ID_VEHICULO
        WHERE v.DISPONIBLE = 0
    )
    SELECT @VehiculosNoDisponibles = STRING_AGG(CAST(ID_VEHICULO AS NVARCHAR(10)), ', ')
    FROM VehiculosNoDisponibles;

    -- Si hay vehículos no disponibles, lanza error
    IF @VehiculosNoDisponibles IS NOT NULL
    BEGIN
        SET @MensajeError = 'Los siguientes vehículos no están disponibles: ' + @VehiculosNoDisponibles;
        THROW 51012, @MensajeError, 1;
        RETURN;
    END

    -- Si todo está bien, realiza el insert
    INSERT INTO RECORRIDO.VIAJE (
        ID_FACTURA, ID_VEHICULO, CLAVE_ACTUAL, ID_USUARIO, FECHA_SOLICITUD, LATITUD_DESTINO, LONGITUD_DESTINO,
		LONGITUD_ORIGEN, LATITUD_ORIGEN, TIPO, TIPO_PAGO, TARJETA_CLIENTE
    )
    SELECT 
        ID_FACTURA, ID_VEHICULO, CLAVE_ACTUAL, ID_USUARIO, FECHA_SOLICITUD, LATITUD_DESTINO, LONGITUD_DESTINO,
		LONGITUD_ORIGEN, LATITUD_ORIGEN, TIPO, TIPO_PAGO, TARJETA_CLIENTE
    FROM INSERTED;
END;
GO

---------------COMPROBACION----------------------

-- AL HACER UN NUEVO VIAJE SE VERIFICA SI SE TIENE DISPONIBILIDAD = 1 POR TANTO PERMITE LA INSERCCION

INSERT INTO RECORRIDO.VIAJE VALUES (NULL, (SELECT TOP 1 ID_VEHICULO FROM VEHICULO WHERE DISPONIBLE = 1), 1, 10, GETDATE(), '19.4270', '-99.1276', '-99.1332', '19.4326', 'P', 'E', '1234562480123401');


-- AL HACER UN NUEVO VIAJE SE VERIFICA SI SE TIENE DISPONIBILIDAD = 0 POR TANTO NO PERMITE LA INSERCCION

INSERT INTO RECORRIDO.VIAJE VALUES (NULL, (SELECT TOP 1 ID_VEHICULO FROM VEHICULO WHERE DISPONIBLE = 0), 1, 10, GETDATE(), '19.4270', '-99.1276', '-99.1332', '19.4326', 'P', 'E', '1234562480123401');

-------------------------------------------------

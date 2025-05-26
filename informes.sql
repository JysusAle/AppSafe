/***************************************

--------------- Informes -----------------

Autores: Equipo 1 de 3

Fecha: 25/05/2025

Descripcion: Este script es para las estadisticas
y/o informes solicitados

------------------------------------------


******************************************/

use [APPSAFE_TEAM_UNO_DE_TRES]
go

select * from Persona.Conductor;
select * from Recorrido.Viaje;
declare @fecha_inicio date='2000-01-01';
declare @fecha_fin date='2025-12-30';
SELECT 
    CAST(fecha_solicitud AS date) AS 'Fecha Solicitud',
    nombre_pila AS 'Nombre',
    apellidoP AS 'Apellido Paterno',
    ISNULL(apellidoM, 'sin apellido materno') AS 'Apellido Materno',
    COUNT(viaje.id_viaje) AS 'Número de Viajes'
	FROM PERSONA.Conductor AS Conductor
	JOIN PERSONA.Usuario AS usuario 
		ON Conductor.id_usuario = usuario.id_usuario
	JOIN VEHICULO 
		ON Conductor.ID_USUARIO = VEHICULO.ID_USUARIO
	JOIN RECORRIDO.Viaje AS viaje 
		ON viaje.ID_VEHICULO = vehiculo.ID_VEHICULO
	JOIN RECORRIDO.ACEPTADO AS aceptado 
		ON aceptado.id_viaje = viaje.id_viaje
	--WHERE (CAST(fecha_solicitud AS date) BETWEEN @fecha_inicio AND @fecha_fin) 
	GROUP BY 
		CAST(fecha_solicitud AS date),
		nombre_pila,
		apellidoP,
		apellidoM,
		usuario.ID_USUARIO

--2. Consolidado mensual; día, monto total, monto mensual



select * from recorrido.aceptado;
declare @fecha_inicio date='2025-01-01';
declare @fecha_fin date='2025-01-30';
SELECT 
    Fecha,
    ImporteTotalPorDia,
    SUM(ImporteTotalPorDia) OVER (ORDER BY Fecha) AS ImporteAcumulado
FROM (
    SELECT 
        CAST(HORA_INICIO_CURSO AS DATE) AS Fecha,
        SUM(IMPORTE) AS ImporteTotalPorDia
    FROM 
        RECORRIDO.ACEPTADO
    GROUP BY 
        CAST(HORA_INICIO_CURSO AS DATE)
) AS TotalesPorDia
WHERE Fecha between @fecha_inicio and @fecha_fin
ORDER BY 
    Fecha;
--3. Top 5 de conductores por un periodo de tiempo


declare @fecha_inicio date='2000-01-01';
declare @fecha_fin date='2025-12-30';
SELECT TOP 5 
    usu.NOMBRE_PILA AS 'Nombre',
    usu.APELLIDOP AS 'Apellido Paterno',
    ISNULL(usu.APELLIDOM, 'sin apellido materno') AS 'Apellido Materno',
    AVG(acept.CALIFICACION_CONDUCTOR) AS 'Calificación Promedio'
	FROM RECORRIDO.ACEPTADO AS acept
	JOIN RECORRIDO.VIAJE AS viaje
		ON acept.ID_VIAJE = viaje.ID_VIAJE
	JOIN VEHICULO AS coche
		ON coche.ID_VEHICULO = viaje.ID_VEHICULO
	JOIN PERSONA.CONDUCTOR AS driver
		ON driver.ID_USUARIO = coche.ID_USUARIO
	JOIN PERSONA.USUARIO AS usu
		ON usu.ID_USUARIO = driver.ID_USUARIO
	WHERE (CAST(FECHA_SOLICITUD AS date) BETWEEN @fecha_inicio AND @fecha_fin) 
	GROUP BY 
		usu.NOMBRE_PILA,
		usu.APELLIDOP,
		usu.APELLIDOM,
		usu.ID_USUARIO
	ORDER BY 
		AVG(acept.CALIFICACION_CONDUCTOR) DESC
	
--4. Top 5 de clientes, es decir, los clientes con mayor número de viajes (nombre completo y correo)
--Muestra de que hay usuarios con menos de 2
select top 10 usu.NOMBRE_PILA as 'Nombres',
	usu.APELLIDOP as 'Apellido Paterno',
	ISNULL(usu.APELLIDOM,'sin apellido materno') as 'Apellido Materno',
	count(acept.ID_ACEPTADO) as 'Número de viajes'
	from RECORRIDO.ACEPTADO as acept
	join RECORRIDO.VIAJE as viaje
		on acept.ID_VIAJE=viaje.ID_VIAJE
	join PERSONA.USUARIO as usu
		on usu.ID_USUARIO=viaje.ID_USUARIO
	group by usu.NOMBRE_PILA,usu.APELLIDOP,usu.APELLIDOM,usu.ID_USUARIO
	order by count(acept.ID_ACEPTADO) desc
select top 5 usu.NOMBRE_PILA as 'Nombres',
	usu.APELLIDOP as 'Apellido Paterno',
	ISNULL(usu.APELLIDOM,'sin apellido materno') as 'Apellido Materno',
	count(acept.ID_ACEPTADO) as 'Número de viajes'
	from RECORRIDO.ACEPTADO as acept
	join RECORRIDO.VIAJE as viaje
		on acept.ID_VIAJE=viaje.ID_VIAJE
	join PERSONA.USUARIO as usu
		on usu.ID_USUARIO=viaje.ID_USUARIO
	group by usu.NOMBRE_PILA,usu.APELLIDOP,usu.APELLIDOM,usu.ID_USUARIO
	order by count(acept.ID_ACEPTADO) desc

--5. Listado de conductores con más quejas y motivo (se maneja un catálogo, ejemplo, irrespetuoso, maneja
--muy rápido, no respeta las reglas de vialidad, etc.)

	select usu.NOMBRE_PILA as 'nombres',
		usu.APELLIDOP as 'Apellido Paterno',
		isnull(usu.APELLIDOM,'sin apellido materno') as 'Apellido Materno',
		count(usu.ID_USUARIO) as 'Número de quejas'
		from INTERACCION.QUEJA as complain
		join VEHICULO
			on VEHICULO.ID_VEHICULO=complain.ID_VEHICULO
		join PERSONA.CONDUCTOR as driver
			on driver.ID_USUARIO=VEHICULO.ID_USUARIO
		join PERSONA.USUARIO as usu
			on usu.ID_USUARIO=driver.ID_USUARIO
		group by usu.NOMBRE_PILA,usu.APELLIDOP,usu.APELLIDOM,usu.ID_USUARIO
		order by count(usu.ID_USUARIO) desc



--6. Listado de accidentes; fecha, ubicación, tipo, descripción, heridos si o no, monto gastado, nombre del
--conductor y auto, si el conductor fue el responsable o no. Con filtros para poder obtener el listado desde un
--día o un periodo de tiempo.


declare @fecha_inicio date='2000-01-01';
declare @fecha_fin date='2027-01-01';
select
	ac.FECHA_INCIDENTE as 'Fecha de Incidente',
	dir.CIUDAD as 'Ciudad',
	dir.CALLE as 'Calle',
	dir.NUM_EXTERIOR as 'Número exterior',
	tac.DESCRIPCION as 'Tipo de accidente',
	CASE 
		WHEN ac.HERIDOS=1 then 'Hubo Heridos'
		ELSE 'Sin Heridos'
	END as 'Presencia de Heridos',
	ac.MONTO_GASTADO as 'Monto Gastado',
	usu.NOMBRE_PILA as 'Nombres',
	usu.APELLIDOP as 'Apellido Paterno',
	usu.APELLIDOM as 'Apellido Materno',
	MODELO.MODELO as 'Modelo automóvil',
	CASE 
		WHEN ac.CONDUCTOR_RESPONSABLE=1 then 'Responsable'
		ELSE 'No Responsable'
	END as 'Responsabilidad del Accidente'
	from RECORRIDO.ACCIDENTE as ac
		join DIRECCION as dir
			on ac.UBICACION=dir.ID_DIRECCION
		join RECORRIDO.TIPO_ACCIDENTE as tac
			on tac.ID_TIPO_ACCIDENTE=ac.ID_TIPO_ACCIDENTE
		join RECORRIDO.ACEPTADO as acept
			on acept.ID_ACEPTADO=ac.ID_ACEPTADO
		join RECORRIDO.VIAJE as vj
			on vj.ID_VIAJE=acept.ID_VIAJE
		join VEHICULO as coche
			on coche.ID_VEHICULO=vj.ID_VEHICULO
		join PERSONA.CONDUCTOR as driver
			on driver.ID_USUARIO=coche.ID_USUARIO
		join PERSONA.USUARIO as usu
			on usu.ID_USUARIO=driver.ID_USUARIO
		join MODELO 
			on MODELO.ID_MODELO=coche.ID_MODELO
    	where ac.Fecha_Incidente between @Fecha_Inicio and @Fecha_Fin 

--7. Listado de los clientes con menos estrellas


SELECT
    usu.NOMBRE_PILA AS 'Nombre',
    usu.APELLIDOP AS 'Apellido Paterno',
    ISNULL(usu.APELLIDOM, 'sin apellido materno') AS 'Apellido Materno',
    AVG(acept.CALIFICACION_USUARIO) AS 'Calificación Promedio'
	FROM RECORRIDO.ACEPTADO AS acept
	JOIN RECORRIDO.VIAJE AS viaje
		ON acept.ID_VIAJE = viaje.ID_VIAJE
	JOIN PERSONA.USUARIO AS usu
		ON viaje.ID_USUARIO =usu.ID_USUARIO 
	GROUP BY 
		usu.NOMBRE_PILA,
		usu.APELLIDOP,
		usu.APELLIDOM,
		usu.ID_USUARIO
	ORDER BY 
		AVG(acept.CALIFICACION_USUARIO) asc



--8. Listado de los conductores con el total que les han dado por cada estrella

select 
    u.NOMBRE_PILA + ' ' + u.APELLIDOP AS 'Conductor',
    SUM(CASE WHEN a.CALIFICACION_CONDUCTOR = 1 THEN 1 ELSE 0 END) AS '1 Estrella',
    SUM(CASE WHEN a.CALIFICACION_CONDUCTOR = 2 THEN 1 ELSE 0 END) AS '2 Estrellas',
    SUM(CASE WHEN a.CALIFICACION_CONDUCTOR = 3 THEN 1 ELSE 0 END) AS '3 Estrellas',
    SUM(CASE WHEN a.CALIFICACION_CONDUCTOR = 4 THEN 1 ELSE 0 END) AS '4 Estrellas',
    SUM(CASE WHEN a.CALIFICACION_CONDUCTOR = 5 THEN 1 ELSE 0 END) AS '5 Estrellas',
    COUNT(a.ID_ACEPTADO) AS 'Total Calificaciones',
    AVG(a.CALIFICACION_CONDUCTOR) AS 'Promedio'
	FROM RECORRIDO.ACEPTADO a
		JOIN RECORRIDO.VIAJE v ON a.ID_VIAJE = v.ID_VIAJE
		JOIN VEHICULO as veh ON v.ID_VEHICULO = veh.ID_VEHICULO
		JOIN PERSONA.CONDUCTOR c ON veh.ID_USUARIO = c.ID_USUARIO
		JOIN PERSONA.USUARIO u ON c.ID_USUARIO = u.ID_USUARIO
	WHERE a.CALIFICACION_CONDUCTOR IS NOT NULL
	GROUP BY u.ID_USUARIO, u.NOMBRE_PILA, u.APELLIDOP
	ORDER BY AVG(a.CALIFICACION_CONDUCTOR) DESC

--9. Listado de autos, placa, número de serie, marca, modelo, año y color y su dueño

select NUM_PLACA as 'Número de placa',
	mark.MARCA as 'Marca',
	model.MODELO as 'Modelo',
	year_auto as 'Año del auto',
	usu.NOMBRE_PILA as 'Nombre conductor',
	usu.APELLIDOP as 'Apellido Paterno',
	isnull(usu.APELLIDOM,'sin apellido materno') as 'Apellido Materno'
	from VEHICULO
	join PERSONA.CONDUCTOR as driver
		on VEHICULO.ID_USUARIO=driver.ID_USUARIO
	join MODELO as model
		on model.ID_MODELO=VEHICULO.ID_MODELO
	join MARCA as mark
		on model.ID_MARCA=mark.ID_MARCA
	join PERSONA.USUARIO as usu
		on driver.ID_USUARIO=usu.ID_USUARIO

--10. Listado de quejas incluyendo el conductor y auto, con filtro para obtenerse por un periodo de tiempo o por
--conductor

select * from INTERACCION.QUEJA;

declare @fecha_inicio date='2000-01-01';
declare @fecha_fin date='2027-01-01';
select qm.descripcion as 'Queja',
	usu.NOMBRE_PILA as 'Nombres',
	usu.APELLIDOP as 'Apellido Paterno',
	usu.APELLIDOM as 'Apellido Materno',
	MODELO.MODELO as 'Modelo del coche'
	FROM INTERACCION.QUEJA as q
	join VEHICULO as v
		on v.ID_VEHICULO=q.ID_VEHICULO
	join PERSONA.USUARIO as usu
		on v.ID_USUARIO=usu.ID_USUARIO
	join QUEJA_MOTIVO as qm
		on qm.id_motivo_queja=q.id_motivo_queja
	join MODELO
		on v.ID_MODELO=MODELO.ID_MODELO
	where q.FECHA_EMISION between @Fecha_Inicio and @Fecha_Fin

	
	
	

	
		
    	
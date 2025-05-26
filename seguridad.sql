/***************************************

---------------Seguridad DCL-------------

Autores: 

Fecha: 11/05/2025

Descripcion: Este script es para la generacion de usuarios

------------------------------------------


******************************************/

USE [APPSAFE_TEAM_UNO_DE_TRES];
GO

-- Crear roles
CREATE ROLE [RolAdministradorAppSafe];
CREATE ROLE [RolLecturaAppSafe];
GO

-- Conceder permisos a los roles
GRANT CONTROL ON DATABASE::[APPSAFE_TEAM_UNO_DE_TRES] TO RolAdministradorAppSafe;

GRANT SELECT ON SCHEMA::[interaccion] TO RolLecturaAppSafe;
GRANT SELECT ON SCHEMA::[persona] TO RolLecturaAppSafe;
GRANT SELECT ON SCHEMA::[recorrido] TO RolLecturaAppSafe;
GRANT SELECT ON SCHEMA::[dbo] TO RolLecturaAppSafe;
GO

-- Crear logins
CREATE LOGIN [AdminAppSafe] WITH PASSWORD = N'Admin1234*', 
    DEFAULT_DATABASE = [APPSAFE_TEAM_UNO_DE_TRES],
    DEFAULT_LANGUAGE = [Español],
    CHECK_EXPIRATION = OFF, 
    CHECK_POLICY = OFF;

CREATE LOGIN [LecAppSafe] WITH PASSWORD = N'Lectura1234*', 
    DEFAULT_DATABASE = [APPSAFE_TEAM_UNO_DE_TRES],
    DEFAULT_LANGUAGE = [Español],
    CHECK_EXPIRATION = OFF, 
    CHECK_POLICY = OFF;
GO

-- Crear usuarios en la base de datos asociados a los logins
CREATE USER [AdminAppSafe] FOR LOGIN [AdminAppSafe];
CREATE USER [LecAppSafe] FOR LOGIN [LecAppSafe];
GO

-- Agregar usuarios a los roles
ALTER ROLE RolAdministradorAppSafe ADD MEMBER AdminAppSafe;
ALTER ROLE RolLecturaAppSafe ADD MEMBER LecAppSafe;
GO


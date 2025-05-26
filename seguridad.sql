/***************************************

---------------Seguridad DCL-------------

Autores: 

Fecha: 11/05/2025

Descripcion: Este script es para la generacion de usuarios

------------------------------------------


******************************************/

USE [APPSAFE_TEAM_UNO_DE_TRES];
GO

-- 1. LIMPIEZA DE USUARIOS Y ROLES EXISTENTES (SI EXISTEN)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'AdminAppSafe')
    DROP USER AdminAppSafe;
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'LecAppSafe')
    DROP USER LecAppSafe;
GO

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'AdminAppSafe')
    DROP LOGIN AdminAppSafe;
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'LecAppSafe')
    DROP LOGIN LecAppSafe;
GO

DROP ROLE IF EXISTS RolAdministradorAppSafe;
DROP ROLE IF EXISTS RolLecturaAppSafe;
GO


-- Crear roles
CREATE ROLE [RolAdministradorAppSafe];
CREATE ROLE [RolLecturaAppSafe];
GO

-- Conceder permisos a los roles
GRANT CONTROL ON DATABASE::[APPSAFE_TEAM_UNO_DE_TRES] TO RolAdministradorAppSafe;
GO

ALTER AUTHORIZATION ON SCHEMA::[INTERACCION] TO RolAdministradorAppSafe;
ALTER AUTHORIZATION ON SCHEMA::[PERSONA] TO RolAdministradorAppSafe;
ALTER AUTHORIZATION ON SCHEMA::[RECORRIDO] TO RolAdministradorAppSafe;
GRANT ALTER ON SCHEMA::dbo TO RolAdministradorAppSafe;
GRANT CONTROL ON SCHEMA::dbo TO RolAdministradorAppSafe;
GO

GRANT SELECT ON SCHEMA::[INTERACCION] TO RolLecturaAppSafe;
GRANT SELECT ON SCHEMA::[PERSONA] TO RolLecturaAppSafe;
GRANT SELECT ON SCHEMA::[RECORRIDO] TO RolLecturaAppSafe;
GRANT SELECT ON SCHEMA::[dbo] TO RolLecturaAppSafe;
GO

-- Crear logins
CREATE LOGIN [AdminAppSafe] WITH PASSWORD = N'Admin1234*', 
    DEFAULT_DATABASE = [APPSAFE_TEAM_UNO_DE_TRES],
    DEFAULT_LANGUAGE = [Español],
    CHECK_EXPIRATION = OFF, 
    CHECK_POLICY = OFF;
GO

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
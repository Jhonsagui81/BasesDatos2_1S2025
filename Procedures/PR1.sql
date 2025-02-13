USE [BD2]
GO

CREATE PROCEDURE [practica1].[PR1]
    @Firstname NVARCHAR(MAX),
    @Lastname NVARCHAR(MAX),
    @Email NVARCHAR(MAX),
    @DateOfBirth DATETIME2(7),
    @Password NVARCHAR(MAX),
    @Credits INT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Insertar el nuevo usuario en la tabla Usuarios
        DECLARE @UserId UNIQUEIDENTIFIER = NEWID();

        INSERT INTO [practica1].[Usuarios] (Id, Firstname, Lastname, Email, DateOfBirth, Password, LastChanges, EmailConfirmed)
        VALUES (@UserId, @Firstname, @Lastname, @Email, @DateOfBirth, @Password, GETDATE(), 1); 

        -- 2. Asignar el rol de "Student" al usuario en la tabla UsuarioRole
        DECLARE @StudentRoleId UNIQUEIDENTIFIER;
        SELECT @StudentRoleId = Id FROM [practica1].[Roles] WHERE RoleName = 'Student'; 

        INSERT INTO [practica1].[UsuarioRole] (RoleId, UserId, IsLatestVersion)
        VALUES (@StudentRoleId, @UserId, 1); 

        -- 3. Crear el perfil del estudiante en la tabla ProfileStudent
        INSERT INTO [practica1].[ProfileStudent] (UserId, Credits)
        VALUES (@UserId, @Credits);

        -- 4. Registrar el estado del segundo factor de autenticación (TFA) desactivado por defecto
        INSERT INTO [practica1].[TFA] (UserId, Status, LastUpdate)
        VALUES (@UserId, 0, GETDATE()); 

        -- 5. Enviar una notificación al usuario
        INSERT INTO [practica1].[Notification] (UserId, Message, Date)
        VALUES (@UserId, 'Bienvenido al sistema. Tu registro ha sido exitoso.', GETDATE());

        COMMIT TRANSACTION;

        INSERT INTO [practica1].[HistoryLog] (Date, Description)
        VALUES (GETDATE(), 'Registro de usuario exitoso para: ' + @Email);
    END TRY
    BEGIN CATCH
     
        ROLLBACK TRANSACTION;

        INSERT INTO [practica1].[HistoryLog] (Date, Description)
        VALUES (GETDATE(), 'Error en el registro de usuario para: ' + @Email + '. Error: ' + ERROR_MESSAGE());

        THROW;
    END CATCH
END;
GO


EXEC [practica1].[PR1]
    @Firstname = 'Juan',
    @Lastname = 'Pérez',
    @Email = 'juan.perez@gmail.com',
    @DateOfBirth = '2001-02-03',
    @Password = 'password123',
    @Credits = 100;
GO
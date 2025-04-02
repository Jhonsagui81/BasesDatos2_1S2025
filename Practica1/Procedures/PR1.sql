USE BD2;
GO

IF OBJECT_ID('practica1.PR1', 'P') IS NOT NULL
    DROP PROCEDURE practica1.PR1;
GO
CREATE PROCEDURE [practica1].[PR1]
(
    @Firstname NVARCHAR(MAX),
    @Lastname NVARCHAR(MAX),
    @Email NVARCHAR(MAX),
    @DateOfBirth DATETIME2(7),
    @Password NVARCHAR(MAX),
    @Credits INT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Insertar el nuevo usuario en la tabla Usuarios
        DECLARE @UserId UNIQUEIDENTIFIER = NEWID();

        INSERT INTO [practica1].[Usuarios] 
        (
            Id, 
            Firstname, 
            Lastname, 
            Email, 
            DateOfBirth, 
            Password, 
            LastChanges, 
            EmailConfirmed
        )
        VALUES 
        (
            @UserId, 
            @Firstname, 
            @Lastname, 
            @Email, 
            @DateOfBirth, 
            @Password, 
            GETDATE(), 
            1  -- Se asume que el correo está confirmado
        );

        -- 2. Asignar el rol de "Student" al usuario en la tabla UsuarioRole
        DECLARE @StudentRoleId UNIQUEIDENTIFIER;
        SELECT @StudentRoleId = Id 
        FROM [practica1].[Roles] 
        WHERE RoleName = 'Student'; 

        IF @StudentRoleId IS NULL
        BEGIN
            RAISERROR('No se encontró el rol Student. Verifique que exista en la tabla Roles.', 16, 1);
        END

        INSERT INTO [practica1].[UsuarioRole] 
        (
            RoleId, 
            UserId, 
            IsLatestVersion
        )
        VALUES 
        (
            @StudentRoleId, 
            @UserId, 
            1
        );

        -- 3. Crear el perfil del estudiante en la tabla ProfileStudent
        INSERT INTO [practica1].[ProfileStudent] 
        (
            UserId, 
            Credits
        )
        VALUES 
        (
            @UserId, 
            @Credits
        );

        -- 4. Registrar el estado del segundo factor de autenticación (TFA) desactivado por defecto
        INSERT INTO [practica1].[TFA] 
        (
            UserId, 
            Status, 
            LastUpdate
        )
        VALUES 
        (
            @UserId, 
            0, 
            GETDATE()
        );

        -- 5. Enviar una notificación al usuario
        INSERT INTO [practica1].[Notification] 
        (
            UserId, 
            Message, 
            Date
        )
        VALUES 
        (
            @UserId, 
            'Bienvenido al sistema. Tu registro ha sido exitoso.', 
            GETDATE()
        );

        -- 6. Validar datos con PR6 (si falla, saltará al bloque CATCH y hará ROLLBACK)
        EXEC practica1.PR6;

        -- 7. Finalizar la transacción con éxito
        COMMIT TRANSACTION;

        -- 8. Registrar en el HistoryLog que el registro fue exitoso
        INSERT INTO [practica1].[HistoryLog] (Date, Description)
        VALUES (GETDATE(), 'Registro de usuario exitoso para: ' + @Email);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        INSERT INTO [practica1].[HistoryLog] (Date, Description)
        VALUES (GETDATE(), 'Error en el registro de usuario para: ' + @Email + '. Error: ' + ERROR_MESSAGE());

        THROW;
    END CATCH
END;
GO

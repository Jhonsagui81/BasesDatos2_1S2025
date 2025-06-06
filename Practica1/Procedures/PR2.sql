----------------------------------PR2
CREATE PROCEDURE [practica1].[PR2]
    @Email NVARCHAR(MAX),
    @CodCourse INT
AS
BEGIN
    BEGIN TRANSACTION; 
    BEGIN TRY
        DECLARE @UserId UNIQUEIDENTIFIER;
        DECLARE @EmailConfirmed BIT;

        SELECT @UserId = Id, @EmailConfirmed = EmailConfirmed
        FROM [practica1].[Usuarios]
        WHERE Email = @Email;

        IF @UserId IS NULL
        BEGIN
            RAISERROR('El usuario no existe en el sistema.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @EmailConfirmed = 0
        BEGIN
            RAISERROR('El usuario no tiene una cuenta activa.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

         -- Verificar que el usuario sea un student
        DECLARE @StudentRoleId UNIQUEIDENTIFIER;
        SELECT @StudentRoleId = Id FROM [practica1].[Roles] WHERE RoleName = 'Student';

        IF NOT EXISTS (
            SELECT 1
            FROM [practica1].[UsuarioRole]
            WHERE UserId = @UserId AND RoleId = @StudentRoleId
        )
        BEGIN
            RAISERROR('El usuario no tiene el rol de Student.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificar que no sea tutor ya
        DECLARE @TutorRoleId UNIQUEIDENTIFIER;
        SELECT @TutorRoleId = Id FROM [practica1].[Roles] WHERE RoleName = 'Tutor';

        IF NOT EXISTS (
            SELECT 1
            FROM [practica1].[UsuarioRole]
            WHERE UserId = @UserId AND RoleId = @TutorRoleId
        )
        BEGIN
            RAISERROR('El usuario ya tiene el rol de Tutor.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificar que el curso existe en DB
        IF NOT EXISTS (
            SELECT 1
            FROM [practica1].[Course]
            WHERE CodCourse = @CodCourse
        )
        BEGIN
            RAISERROR('El curso especificado no existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insertar el nuevo rol del usuario 
        INSERT INTO [practica1].[UsuarioRole] (RoleId, UserId, IsLatestVersion)
        VALUES (@TutorRoleId, @UserId, 1);

        -- Crear perfil de tutor
        DECLARE @TutorCode NVARCHAR(MAX) = NEWID();
        INSERT INTO [practica1].[TutorProfile] (UserId, TutorCode)
        VALUES (@UserId, @TutorCode);

        -- Asignar curso al tutor
        INSERT INTO [practica1].[CourseTutor] (TutorId, CourseCodCourse)
        VALUES (@TutorCode, @CodCourse);

        -- Crear la notificacion 
        INSERT INTO [practica1].[Notification] (UserId, Message, Date)
        VALUES (@UserId, 'Has sido promovido a Tutor en el curso con código: ' + CAST(@CodCourse AS NVARCHAR(10)), GETDATE());

        COMMIT TRANSACTION;

        INSERT INTO [practica1].[HistoryLog] (Date, Description)
        VALUES (GETDATE(), 'Agregado rol de Tutor exitosamente para: ' + @Email);
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        INSERT INTO [practica1].[HistoryLog] (Date, Description)
        VALUES (GETDATE(), 'Error al agregar rol de Tutor para: ' + @Email + '. Error: ' + ERROR_MESSAGE());

        THROW;
    END CATCH
END;

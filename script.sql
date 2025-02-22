---------------------------------------------PROCEDURES------------------------------------------

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
----------------------------------PR2
CREATE PROCEDURE [practica1].[PR2]
    @Email NVARCHAR(MAX)
    @CodCourse INT
AS
BEGIN
    BEGIN TRANSACTION 
    BEGIN TRY
        DECLARE @UserId UNIQUEIDENTIFIER;
        DECLARE @EmailConfirmed BIT;

        SELECT @UserId = Id, @EmailConfirmed = EmailConfirmed
        FROM [practica1].[Usuarios]
        WHERE Email = @Email;

        IF @UserId IS NULL
        BEGIN
            THROW 50000, 'El usuario no existe en el sistema.', 1;
        END

        IF @EmailConfirmed = 0
        BEGIN
            THROW 50001, 'El usuario no tiene una cuenta activa.', 1;
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
            THROW 50002, 'El usuario no tiene el rol de Student.', 1;
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
            THROW 50003, 'El usuario ya es un tutor academico.', 1;
        END

        -- Verificar que el curso existe en DB
        IF NOT EXISTS (
            SELECT 1
            FROM [practica1].[Course]
            WHERE CodCourse = @CodCourse;
        )
        BEGIN
            THROW 50003, 'El curso que se pretende asignar no existe', 1;
        END

        -- Insertar el nuevo rol del usuario 
        INSERT INTO [practica1].[UsuarioRole] (RoleId, UserId, IsLatesVersion)
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


--------------------------------------------- PR3
CREATE PROCEDURE PR3
    @Email NVARCHAR(MAX)
    @CodCourse INT
AS
BEGIN 
    BEGIN TRANSACTION
    BEGIN TRY
        DECLARE @UserId UNIQUEIDENTIFIER;
        DECLARE @EmailConfirmed BIT;

        SELECT @UserId = Id, @EmailConfirmed = EmailConfirmed
        FROM [practica1].[Usuarios]
        WHERE Email = @Email

        IF @UserId IS NULL
        BEGIN
            THROW 50000, 'El usuario no existe en el sistema.', 1;
        END

        IF @EmailConfirmed = 0
        BEGIN
            THROW 50001, 'El usuario no tiene una cuenta activa.', 1;
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
            THROW 50002, 'El usuario no tiene el rol de Student.', 1;
        END

        -- Verificar que el curso existe en DB

        IF NOT EXISTS (
            SELECT 1
            FROM [practica1].[Course]
            WHERE CodCourse = @CodCourse;
        )
        BEGIN
            THROW 50003, 'El curso que se pretende asignar no existe', 1;
        END

        -- verificar que estudiante cumpla con creditos
        DECLARE @CreditsStudent INT;
        SELECT @CreditsStudent = Credits FROM [practica1].[ProfileStudent] WHERE UserId = @UserId;

        DECLARE @CourseCredits INT;
        SELECT @CourseCredits = CreditsRequired FROM [practica1].[Course] WHERE CodCourse = @CodCourse;

        IF (@CreditsStudent < @CourseCreditsa)
        BEGIN
            THROW 50004, 'El estudiante no cuenta con los creditos necesarios para el este curso', 1;
        END

        -- Asignar estudiante al curso 
        INSERT INTO [practica1].[CourseAssignment] (StudentId, CourseCodCourse) 
        VALUES (@UserId, @CodCourse) 

        -- notificar al estudiante 
        INSERT INTO [practica1].[Notification] (UserId, Message, Date)
        VALUES (@UserId, 'Has sido asiganado al curso con codigo ' + CAST(@CodCourse AS NVARCHAR(10)), GETDATE());

        -- OBtener el id del tutor que imparte el curso para notificar asignacion 
        DECLARE @TutorId UNIQUEIDENTIFIER;
        SELECT @TutorId = TutorId FROM [practica1].[CourseTutor] WHERE CourseCodCourse = @CodCourse;

        DECLARE @UserIdTutor UNIQUEIDENTIFIER;
        SELECT @UserIdTutor = UserId FROM [practica1].[TutorProfile] WHERE TutorCode = @TutorId;

        --Notificar al tutor
        INSERT INTO [practica1].[Notification] (UserId, Message, Date)
        VALUES (@UserId, 'Se asigno el estudiante con email: ' + CAST(@Email AS NVARCHAR(10)), GETDATE());

        COMMIT TRANSACTION

        INSERT INTO [practica1].[HistoryLog] (Date, Description)
        VALUES (GETDATE(), 'Se asigno el curso a ' + @Email);
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        INSERT INTO [practica1].[HistoryLog] (Date, Description)
        VALUES (GETDATE(), 'Error al agregar curso al estudiante: ' + @Email + '. Error: ' + ERROR_MESSAGE());

        THROW;
    END CATCH
END;

--------------------------------------------- PR4
USE BD2;
GO

IF OBJECT_ID('practica1.PR4', 'P') IS NOT NULL
    DROP PROCEDURE practica1.PR4;
GO
CREATE PROCEDURE practica1.PR4
    @RoleName NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO practica1.Roles (Id, RoleName)
        VALUES (NEWID(), @RoleName);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000),
                @ErrorSeverity INT,
                @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

--------------------------------------------- PR5

USE [BD2];
GO

IF OBJECT_ID('dbo.PR5', 'P') IS NOT NULL
    DROP PROCEDURE dbo.PR5;
GO

CREATE PROCEDURE dbo.PR5
    @CodCourse INT,
    @Name VARCHAR(100),
    @CredistRequired INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Insertar el nuevo curso en la tabla practica1.Course
        INSERT INTO practica1.Course (CodCourse, Name, CreditsRequired)
        VALUES (@CodCourse, @Name, @CredistRequired);

        -- 2. Llamar a PR6 para validar los datos (si PR6 detecta algún error, lanzará una excepción)
        EXEC practica1.PR6;

        -- 3. Confirmar la transacción si la validación es exitosa
        COMMIT TRANSACTION;

        -- 4. Registrar en HistoryLog el éxito de la operación
        INSERT INTO practica1.HistoryLog (Date, Description)
        VALUES (GETDATE(), 'PR5, Success');
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        INSERT INTO practica1.HistoryLog (Date, Description)
        VALUES (GETDATE(), 'PR5, Failed: ' + ERROR_MESSAGE());

        THROW;
    END CATCH
END;
GO
--------------------------------------------- PR6

USE BD2;
GO

IF OBJECT_ID('practica1.PR6', 'P') IS NOT NULL
    DROP PROCEDURE practica1.PR6;
GO

CREATE PROCEDURE practica1.PR6
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InvalidUsuarios INT, @InvalidCourses INT;

    -- Validar en Usuarios: que Firstname y Lastname contengan solo letras (A-Z y a-z)
    SELECT @InvalidUsuarios = COUNT(*)
    FROM practica1.Usuarios
    WHERE Firstname LIKE '%[^A-Za-z]%' 
       OR Lastname LIKE '%[^A-Za-z]%';

    -- Validar en Course: que CreditsRequired sea mayor a 0
    SELECT @InvalidCourses = COUNT(*)
    FROM practica1.Course
    WHERE CreditsRequired <= 0;

    IF @InvalidUsuarios > 0 OR @InvalidCourses > 0
    BEGIN
        RAISERROR('PR6: Data validation failed. Invalid Usuarios: %d, Invalid Courses: %d', 16, 1, @InvalidUsuarios, @InvalidCourses);
    END
    ELSE
    BEGIN
        PRINT 'PR6: Data validation passed. All records are valid.';
    END
END;
GO

---------------------------------------------FUNCIONES------------------------------------------
--------------------------------------------- F1
USE BD2;
GO
IF OBJECT_ID('practica1.F1', 'IF') IS NOT NULL
    DROP FUNCTION practica1.F1;
GO
CREATE FUNCTION practica1.F1
(
    @CodCourse INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        U.Id,
        U.Firstname,
        U.Lastname,
        U.Email,
        U.DateOfBirth,
        U.EmailConfirmed
    FROM practica1.Usuarios U
    INNER JOIN practica1.CourseAssignment CA ON U.Id = CA.StudentId
    WHERE CA.CourseCodCourse = @CodCourse
);
GO

--------------------------------------------- F2
USE BD2;
GO
IF OBJECT_ID('practica1.F2', 'IF') IS NOT NULL
    DROP FUNCTION practica1.F2;
GO
CREATE FUNCTION practica1.F2
(
    @TutorProfileId INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        C.CodCourse,
        C.Name,
        C.CreditsRequired
    FROM practica1.Course C
    INNER JOIN practica1.CourseTutor CT ON C.CodCourse = CT.CourseCodCourse
    INNER JOIN practica1.TutorProfile TP ON CT.TutorId = TP.UserId
    WHERE TP.Id = @TutorProfileId
);
GO
--------------------------------------------- F3
USE BD2;
GO
IF OBJECT_ID('practica1.F3', 'IF') IS NOT NULL
    DROP FUNCTION practica1.F3;
GO
CREATE FUNCTION practica1.F3
(
    @UserId UNIQUEIDENTIFIER
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        Id,
        Message,
        Date
    FROM practica1.Notification
    WHERE UserId = @UserId
);
GO
--------------------------------------------- F4
USE BD2;
GO
IF OBJECT_ID('practica1.F4', 'IF') IS NOT NULL
    DROP FUNCTION practica1.F4;
GO
CREATE FUNCTION practica1.F4()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        Id,
        Date,
        Description
    FROM practica1.HistoryLog
);
GO

--------------------------------------------- F5

USE BD2;
GO
IF OBJECT_ID('practica1.F5', 'IF') IS NOT NULL
    DROP FUNCTION practica1.F5;
GO
CREATE FUNCTION practica1.F5
(
    @UserId UNIQUEIDENTIFIER
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        U.Firstname,
        U.Lastname,
        U.Email,
        U.DateOfBirth,
        PS.Credits,
        R.RoleName
    FROM practica1.Usuarios U
    INNER JOIN practica1.ProfileStudent PS ON U.Id = PS.UserId
    INNER JOIN practica1.UsuarioRole UR ON U.Id = UR.UserId AND UR.IsLatestVersion = 1
    INNER JOIN practica1.Roles R ON UR.RoleId = R.Id
    WHERE U.Id = @UserId
);
GO


---------------------------------------------TRIGERS------------------------------------------
    
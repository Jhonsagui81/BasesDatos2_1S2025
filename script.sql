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


/** ENTIDAD Roles **/
CREATE TRIGGER trgRolesInsert
ON practica1.Roles
AFTER INSERT
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[Rol inserted] Id: ' + CAST(Id AS NVARCHAR(36)) + ', RoleName: ' + RoleName
    FROM inserted;
END;
GO


/** ENTIDAD Course **/
CREATE TRIGGER trgCourseInsert
ON practica1.Course
AFTER INSERT
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[Course inserted] CodCourse: ' + CAST(CodCourse AS NVARCHAR) + ', Name: ' + Name + ', Credits Required: ' + CAST(CreditsRequired AS NVARCHAR)
    FROM inserted;
END;
GO


/** ENTIDAD ProfileStudent **/
CREATE TRIGGER trgProfileStudentInsert
ON practica1.ProfileStudent
AFTER INSERT
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[ProfileStudent inserted] Id: ' + CAST(Id AS NVARCHAR) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', Credits: ' + CAST(Credits AS NVARCHAR)
    FROM inserted;
END;
GO


/** ENTIDAD Notification **/
CREATE TRIGGER trgNotificationInsert
ON practica1.Notification
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[Notification inserted] Id: ' + CAST(Id AS NVARCHAR) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', Message: ' + Message
    FROM inserted;
END
GO

/** ENTIDAD TFA **/
CREATE TRIGGER trgTFAInsert
ON practica1.TFA
AFTER INSERT
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[TFA inserted] Id: ' + CAST(Id AS NVARCHAR) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', Status: ' + CAST(Status AS NVARCHAR) + ', LastUpdate: ' + CAST(LastUpdate AS NVARCHAR)
    FROM inserted;
END
GO

/** ENTIDAD TutorProfile **/
CREATE TRIGGER trgTutorProfileInsert
ON practica1.TutorProfile
AFTER INSERT
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[TutorProfile inserted] Id:' + CAST(Id AS NVARCHAR) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', TutorCode: ' + TutorCode
    FROM inserted;
END
GO

/** ENTIDAD UsuarioRole **/
CREATE TRIGGER trgUsuarioRoleInsert
ON practica1.UsuarioRole
AFTER INSERT
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[UsuarioRole inserted] Id:' + CAST(Id AS NVARCHAR) + ', RoleId: ' + CAST(RoleId AS NVARCHAR(36)) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', IsLatestVersion: ' + CAST(IsLatestVersion AS NVARCHAR)
    FROM inserted;
END
GO

/** ENTIDAD Usuarios **/
CREATE TRIGGER trgUsuariosInsert
ON practica1.Usuarios
AFTER INSERT
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[Usuarios inserted] Id:' + CAST(Id AS NVARCHAR(36)) + ', Firstname: ' + Firstname + ', Lastname: ' + Lastname + ', Email: ' + Email + ', DateOfBirth: ' + CAST(DateOfBirth AS NVARCHAR) + ', LastChanges: ' + CAST(LastChanges AS NVARCHAR) + ', EmailConfirmed: ' + CAST(EmailConfirmed AS NVARCHAR)
    FROM inserted;
END
GO

/** ENTIDAD CourseAssignment **/
CREATE TRIGGER trgCourseAssignmentInsert
ON practica1.CourseAssignment
AFTER INSERT
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[CourseAssignment inserted] Id:' + CAST(Id AS NVARCHAR) + ', StudentId: ' + CAST(StudentId AS NVARCHAR(36)) + ', CourseCodCourse: ' + CAST(CourseCodCourse AS NVARCHAR)
    FROM inserted;
END
GO

/** ENTIDAD CourseTutor **/
CREATE TRIGGER trgCourseTutorInsert
ON practica1.CourseTutor
AFTER INSERT
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[CourseTutor inserted] Id:' + CAST(Id AS NVARCHAR) + ', TutorId: ' + CAST(TutorId AS NVARCHAR(36)) + ', CourseCodCourse: ' + CAST(CourseCodCourse AS NVARCHAR)
    FROM inserted;
END
GO


/** Entidad Roles **/
CREATE TRIGGER trgRolesDelete
ON practica1.Roles
AFTER DELETE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[Rol deleted] Id: ' + CAST(Id AS NVARCHAR(36)) + ', RoleName: ' + RoleName
    FROM deleted;
END;
GO

/** Entidad Course **/
CREATE TRIGGER trgCourseDelete
ON practica1.Course
AFTER DELETE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[Course deleted] CodCourse: ' + CAST(CodCourse AS NVARCHAR) + ', Name: ' + Name + ', Credits Required: ' + CAST(CreditsRequired AS NVARCHAR)
    FROM deleted;
END;
GO

/** Entidad ProfileStudent **/
CREATE TRIGGER trgProfileStudentDelete
ON practica1.ProfileStudent
AFTER DELETE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[ProfileStudent deleted] Id: ' + CAST(Id AS NVARCHAR) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', Credits: ' + CAST(Credits AS NVARCHAR)
    FROM deleted;
END;
GO

/** Entidad Notification **/
CREATE TRIGGER trgNotificationDelete
ON practica1.Notification
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[Notification deleted] Id: ' + CAST(Id AS NVARCHAR) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', Message: ' + Message
    FROM deleted;
END
GO

/** Entidad TFA **/
CREATE TRIGGER trgTFADelete
ON practica1.TFA
AFTER DELETE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[TFA deleted] Id: ' + CAST(Id AS NVARCHAR) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', Status: ' + CAST(Status AS NVARCHAR) + ', LastUpdate: ' + CAST(LastUpdate AS NVARCHAR)
    FROM deleted;
END
GO

/** Entidad TutorProfile **/
CREATE TRIGGER trgTutorProfileDelete
ON practica1.TutorProfile
AFTER DELETE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[TutorProfile deleted] Id: ' + CAST(Id AS NVARCHAR) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', TutorCode: ' + TutorCode
    FROM deleted;
END
GO

/** Entidad UsuarioRole **/
CREATE TRIGGER trgUsuarioRoleDelete
ON practica1.UsuarioRole
AFTER DELETE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[UsuarioRole deleted] Id: ' + CAST(Id AS NVARCHAR) + ', RoleId: ' + CAST(RoleId AS NVARCHAR(36)) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', IsLatestVersion: ' + CAST(IsLatestVersion AS NVARCHAR)
    FROM deleted;
END
GO

/** Entidad Usuarios **/
CREATE TRIGGER trgUsuariosDelete
ON practica1.Usuarios
AFTER DELETE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[Usuarios deleted] Id: ' + CAST(Id AS NVARCHAR(36)) + ', Firstname: ' + Firstname + ', Lastname: ' + Lastname + ', Email: ' + Email + ', DateOfBirth: ' + CAST(DateOfBirth AS NVARCHAR) + ', LastChanges: ' + CAST(LastChanges AS NVARCHAR) + ', EmailConfirmed: ' + CAST(EmailConfirmed AS NVARCHAR)
    FROM deleted;
END
GO

/** Entidad CourseAssignment **/
CREATE TRIGGER trgCourseAssignmentDelete
ON practica1.CourseAssignment
AFTER DELETE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[CourseAssignment deleted] Id: ' + CAST(Id AS NVARCHAR) + ', StudentId: ' + CAST(StudentId AS NVARCHAR(36)) + ', CourseCodCourse: ' + CAST(CourseCodCourse AS NVARCHAR)
    FROM deleted;
END
GO

/** Entidad CourseTutor **/
CREATE TRIGGER trgCourseTutorDelete
ON practica1.CourseTutor
AFTER DELETE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), '[CourseTutor deleted] Id: ' + CAST(d.Id AS NVARCHAR) + ', TutorId: ' + CAST(d.TutorId AS NVARCHAR(36)) + ', CourseCodCourse: ' + CAST(d.CourseCodCourse AS NVARCHAR)
    FROM deleted d;
END;
GO

/*** ENTIDAD ROLES ***/

CREATE TRIGGER trgRolesUpdate
ON practica1.Roles
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[Rol updated] Id: ' + CAST(i.Id AS NVARCHAR(36)) + 
        '. Cambios realizados: ' +
        CASE WHEN i.RoleName <> d.RoleName THEN 'RoleName actualizado de ' + d.RoleName + ' a ' + i.RoleName + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.RoleName <> d.RoleName;
END;
GO


/*** ENTIDAD COURSE ***/
CREATE TRIGGER trgCourseUpdate
ON practica1.Course
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[Course updated] CodCourse: ' + CAST(i.CodCourse AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.Name <> d.Name THEN 'Name actualizado de ' + d.Name + ' a ' + i.Name + '. ' ELSE '' END +
        CASE WHEN i.CreditsRequired <> d.CreditsRequired THEN 'CreditsRequired actualizado de ' + CAST(d.CreditsRequired AS NVARCHAR) + ' a ' + CAST(i.CreditsRequired AS NVARCHAR) + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.CodCourse = d.CodCourse
    WHERE i.Name <> d.Name OR i.CreditsRequired <> d.CreditsRequired; 
END;
GO


/*** ENTIDAD PROFILE STUDENT ***/
CREATE TRIGGER trgProfileStudentUpdate
ON practica1.ProfileStudent
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[ProfileStudent updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.UserId <> d.UserId THEN 'UserId actualizado de ' + CAST(d.UserId AS NVARCHAR(36)) + ' a ' + CAST(i.UserId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.Credits <> d.Credits THEN 'Credits actualizado de ' + CAST(d.Credits AS NVARCHAR) + ' a ' + CAST(i.Credits AS NVARCHAR) + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.UserId <> d.UserId OR i.Credits <> d.Credits; 
END;
GO

/*** ENTIDAD NOTIFICATION ***/
CREATE TRIGGER trgNotificationUpdate
ON practica1.Notification
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[Notification updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.UserId <> d.UserId THEN 'UserId actualizado de ' + CAST(d.UserId AS NVARCHAR(36)) + ' a ' + CAST(i.UserId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.Message <> d.Message THEN 'Message actualizado de "' + d.Message + '" a "' + i.Message + '". ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.UserId <> d.UserId OR i.Message <> d.Message;
END;
GO


/*** ENTIDAD TFA ***/
CREATE TRIGGER trgTFAUpdate
ON practica1.TFA
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[TFA updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.UserId <> d.UserId THEN 'UserId actualizado de ' + CAST(d.UserId AS NVARCHAR(36)) + ' a ' + CAST(i.UserId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.Status <> d.Status THEN 'Status actualizado de ' + CAST(d.Status AS NVARCHAR) + ' a ' + CAST(i.Status AS NVARCHAR) + '. ' ELSE '' END +
        CASE WHEN i.LastUpdate <> d.LastUpdate THEN 'LastUpdate actualizado de ' + CAST(d.LastUpdate AS NVARCHAR) + ' a ' + CAST(i.LastUpdate AS NVARCHAR) + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.UserId <> d.UserId OR i.Status <> d.Status OR i.LastUpdate <> d.LastUpdate;
END;
GO


/*** ENTIDAD TUTOR PROFILE ***/
CREATE TRIGGER trgTutorProfileUpdate
ON practica1.TutorProfile
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[TutorProfile updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.UserId <> d.UserId THEN 'UserId actualizado de ' + CAST(d.UserId AS NVARCHAR(36)) + ' a ' + CAST(i.UserId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.TutorCode <> d.TutorCode THEN 'TutorCode actualizado de ' + d.TutorCode + ' a ' + i.TutorCode + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.UserId <> d.UserId OR i.TutorCode <> d.TutorCode;
END;
GO


/*** ENTIDAD USUARIO ROLE ***/
CREATE TRIGGER trgUsuarioRoleUpdate
ON practica1.UsuarioRole
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[UsuarioRole updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.RoleId <> d.RoleId THEN 'RoleId actualizado de ' + CAST(d.RoleId AS NVARCHAR(36)) + ' a ' + CAST(i.RoleId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.UserId <> d.UserId THEN 'UserId actualizado de ' + CAST(d.UserId AS NVARCHAR(36)) + ' a ' + CAST(i.UserId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.IsLatestVersion <> d.IsLatestVersion THEN 'IsLatestVersion actualizado de ' + CAST(d.IsLatestVersion AS NVARCHAR) + ' a ' + CAST(i.IsLatestVersion AS NVARCHAR) + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.RoleId <> d.RoleId OR i.UserId <> d.UserId OR i.IsLatestVersion <> d.IsLatestVersion;
END;
GO

/*** ENTIDAD USUARIOS ***/ 
CREATE TRIGGER trgUsuariosUpdate
ON practica1.Usuarios
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[Usuarios updated] Id: ' + CAST(i.Id AS NVARCHAR(36)) + 
        '. Cambios realizados: ' +
        CASE WHEN i.Firstname <> d.Firstname THEN 'Firstname actualizado de ' + d.Firstname + ' a ' + i.Firstname + '. ' ELSE '' END +
        CASE WHEN i.Lastname <> d.Lastname THEN 'Lastname actualizado de ' + d.Lastname + ' a ' + i.Lastname + '. ' ELSE '' END +
        CASE WHEN i.Email <> d.Email THEN 'Email actualizado de ' + d.Email + ' a ' + i.Email + '. ' ELSE '' END +
        CASE WHEN i.DateOfBirth <> d.DateOfBirth THEN 'DateOfBirth actualizado de ' + CAST(d.DateOfBirth AS NVARCHAR) + ' a ' + CAST(i.DateOfBirth AS NVARCHAR) + '. ' ELSE '' END +
        CASE WHEN i.LastChanges <> d.LastChanges THEN 'LastChanges actualizado de ' + CAST(d.LastChanges AS NVARCHAR) + ' a ' + CAST(i.LastChanges AS NVARCHAR) + '. ' ELSE '' END +
        CASE WHEN i.EmailConfirmed <> d.EmailConfirmed THEN 'EmailConfirmed actualizado de ' + CAST(d.EmailConfirmed AS NVARCHAR) + ' a ' + CAST(i.EmailConfirmed AS NVARCHAR) + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.Firstname <> d.Firstname 
       OR i.Lastname <> d.Lastname
       OR i.Email <> d.Email
       OR i.DateOfBirth <> d.DateOfBirth
       OR i.LastChanges <> d.LastChanges
       OR i.EmailConfirmed <> d.EmailConfirmed;
END;
GO

/*** ENTIDAD COURSE ASSIGNMENT ***/
CREATE TRIGGER trgCourseAssignmentUpdate
ON practica1.CourseAssignment
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[CourseAssignment updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.StudentId <> d.StudentId THEN 'StudentId actualizado de ' + CAST(d.StudentId AS NVARCHAR(36)) + ' a ' + CAST(i.StudentId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.CourseCodCourse <> d.CourseCodCourse THEN 'CourseCodCourse actualizado de ' + CAST(d.CourseCodCourse AS NVARCHAR) + ' a ' + CAST(i.CourseCodCourse AS NVARCHAR) + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.StudentId <> d.StudentId OR i.CourseCodCourse <> d.CourseCodCourse; 
END;
GO

/*** ENTIDAD COURSE TUTOR ***/
CREATE TRIGGER trgCourseTutorUpdate
ON practica1.CourseTutor
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[CourseTutor updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.TutorId <> d.TutorId THEN 'TutorId actualizado de ' + CAST(d.TutorId AS NVARCHAR(36)) + ' a ' + CAST(i.TutorId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.CourseCodCourse <> d.CourseCodCourse THEN 'CourseCodCourse actualizado de ' + CAST(d.CourseCodCourse AS NVARCHAR) + ' a ' + CAST(i.CourseCodCourse AS NVARCHAR) + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.TutorId <> d.TutorId OR i.CourseCodCourse <> d.CourseCodCourse; -- Filtra solo si hubo cambios reales
END;
GO

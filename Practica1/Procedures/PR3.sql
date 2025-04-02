CREATE PROCEDURE [practica1].[PR3]
    @Email NVARCHAR(MAX),
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

        -- verificar que estudiante cumpla con creditos
        DECLARE @CreditsStudent INT;
        SELECT @CreditsStudent = Credits FROM [practica1].[ProfileStudent] WHERE UserId = @UserId;

        DECLARE @CourseCredits INT;
        SELECT @CourseCredits = CreditsRequired FROM [practica1].[Course] WHERE CodCourse = @CodCourse;

        IF (@CreditsStudent < @CourseCredits)
        BEGIN
            RAISERROR('El estudiante no cumple con los créditos requeridos para el curso.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
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
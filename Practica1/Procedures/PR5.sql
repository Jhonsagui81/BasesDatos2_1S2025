USE [BD2];
GO

IF OBJECT_ID('practica1.PR5', 'P') IS NOT NULL
    DROP PROCEDURE practica1.PR5;
GO

CREATE PROCEDURE practica1.PR5
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
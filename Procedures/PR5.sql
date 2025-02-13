use [BD2];
go

CREATE PROCEDURE PR5
    @CodCourse INT,
    @Name VARCHAR(100),
    @CredistRequired INT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO practica1.Course(CodCourse, Name, CreditsRequired)
        VALUES (@CodCourse, @Name, @CredistRequired);

        COMMIT TRANSACTION;

        INSERT INTO practica1.HistoryLog(Date, Description)
        VALUES ( GETDATE(), 'PR5, Success');
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        INSERT INTO practica1.HistoryLog(Date, Description)
        VALUES (GETDATE(), 'PR5, Failed');
    END CATCH
END;
go


EXEC [dbo].[PR5] @CodCourse = 797, @Name = 'Seminario de Sistemas 1', @CredistRequired = 170;
GO
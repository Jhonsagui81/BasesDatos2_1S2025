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

    -- Validar en Usuarios: que Firstname y Lastname contengan únicamente letras (A-Z, a-z)
    SELECT @InvalidUsuarios = COUNT(*)
    FROM practica1.Usuarios
    WHERE Firstname LIKE '%[^A-Za-z]%' 
       OR Lastname  LIKE '%[^A-Za-z]%';

    -- Validar en Course: que CreditsRequired sea mayor a 0
    SELECT @InvalidCourses = COUNT(*)
    FROM practica1.Course
    WHERE CreditsRequired <= 0;

    IF @InvalidUsuarios > 0 OR @InvalidCourses > 0
    BEGIN
        RAISERROR('Data validation failed. Invalid Usuarios: %d, Invalid Courses: %d', 16, 1, @InvalidUsuarios, @InvalidCourses);
    END
    ELSE
    BEGIN
        PRINT 'Data validation passed. All records are valid.';
    END
END
GO

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

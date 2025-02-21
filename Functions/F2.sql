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

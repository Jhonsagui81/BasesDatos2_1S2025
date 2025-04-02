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

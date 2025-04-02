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

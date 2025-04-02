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

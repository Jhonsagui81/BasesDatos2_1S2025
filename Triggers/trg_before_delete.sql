/** Entidad Roles **/
CREATE TRIGGER trg_Roles_Delete
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
CREATE TRIGGER trg_Course_Delete
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
CREATE TRIGGER trg_ProfileStudent_Delete
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
CREATE TRIGGER trg_Notification_Delete
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
CREATE TRIGGER trg_TFA_Delete
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
CREATE TRIGGER trg_TutorProfile_Delete
ON [practica1].[TutorProfile]
AFTER DELETE
AS
BEGIN
    INSERT INTO [practica1].[HistoryLog] (Date, Description)
    SELECT GETDATE(), '[TutorProfile deleted] Id: ' + CAST(Id AS NVARCHAR) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', TutorCode: ' + TutorCode
    FROM deleted;
END
GO

/** Entidad UsuarioRole **/
CREATE TRIGGER trg_UsuarioRole_Delete
ON [practica1].[UsuarioRole]
AFTER DELETE
AS
BEGIN
    INSERT INTO [practica1].[HistoryLog] (Date, Description)
    SELECT GETDATE(), '[UsuarioRole deleted] Id: ' + CAST(Id AS NVARCHAR) + ', RoleId: ' + CAST(RoleId AS NVARCHAR(36)) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', IsLatestVersion: ' + CAST(IsLatestVersion AS NVARCHAR)
    FROM deleted;
END
GO

/** Entidad Usuarios **/
CREATE TRIGGER trg_Usuarios_Delete
ON [practica1].[Usuarios]
AFTER DELETE
AS
BEGIN
    INSERT INTO [practica1].[HistoryLog] (Date, Description)
    SELECT GETDATE(), '[Usuarios deleted] Id: ' + CAST(Id AS NVARCHAR(36)) + ', Firstname: ' + Firstname + ', Lastname: ' + Lastname + ', Email: ' + Email + ', DateOfBirth: ' + CAST(DateOfBirth AS NVARCHAR) + ', LastChanges: ' + CAST(LastChanges AS NVARCHAR) + ', EmailConfirmed: ' + CAST(EmailConfirmed AS NVARCHAR)
    FROM deleted;
END
GO

/** Entidad CourseAssignment **/
CREATE TRIGGER trg_CourseAssignment_Delete
ON [practica1].[CourseAssignment]
AFTER DELETE
AS
BEGIN
    INSERT INTO [practica1].[HistoryLog] (Date, Description)
    SELECT GETDATE(), '[CourseAssignment deleted] Id: ' + CAST(Id AS NVARCHAR) + ', StudentId: ' + CAST(StudentId AS NVARCHAR(36)) + ', CourseCodCourse: ' + CAST(CourseCodCourse AS NVARCHAR)
    FROM deleted;
END
GO

/** Entidad CourseTutor **/
CREATE TRIGGER trg_CourseTutor_Delete
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


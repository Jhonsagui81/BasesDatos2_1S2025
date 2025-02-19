/** Entidad Roles **/
CREATE TRIGGER trg_Roles_Insert
ON practica1.Roles
AFTER INSERT
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[Rol inserted] Id: ' + CAST(Id AS NVARCHAR(36)) + ', RoleName: ' + RoleName
    FROM inserted;
END;
GO


/** Ent
idad Course **/
CREATE TRIGGER trg_Course_Insert
ON practica1.Course
AFTER INSERT
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[Course inserted] CodCourse: ' + CAST(CodCourse AS NVARCHAR) + ', Name: ' + Name + ', Credits Required: ' + CAST(CreditsRequired AS NVARCHAR)
    FROM inserted;
END;
GO


/** Entidad ProfileStudent **/
CREATE TRIGGER trg_ProfileStudent_Insert
ON practica1.ProfileStudent
AFTER INSERT
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[ProfileStudent inserted] Id: ' + CAST(Id AS NVARCHAR) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', Credits: ' + CAST(Credits AS NVARCHAR)
    FROM inserted;
END;
GO


/** Entidad Notification **/
CREATE TRIGGER trg_Notification_Insert
ON practica1.Notification
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[Notification inserted] Id: ' + CAST(Id AS NVARCHAR) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', Message: ' + Message
    FROM inserted;
END
GO

/** Entidad TFA **/
CREATE TRIGGER trg_TFA_Insert
ON practica1.TFA
AFTER INSERT
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT GETDATE(), '[TFA inserted] Id: ' + CAST(Id AS NVARCHAR) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', Status: ' + CAST(Status AS NVARCHAR) + ', LastUpdate: ' + CAST(LastUpdate AS NVARCHAR)
    FROM inserted;
END
GO

/** Entidad TutorProfile **/
CREATE TRIGGER trg_TutorProfile_Insert
ON [practica1].[TutorProfile]
AFTER INSERT
AS
BEGIN
    INSERT INTO [practica1].[HistoryLog] (Date, Description)
    SELECT GETDATE(), '[TutorProfile inserted] Id:' + CAST(Id AS NVARCHAR) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', TutorCode: ' + TutorCode
    FROM inserted;
END
GO

/** Entidad UsuarioRole **/
CREATE TRIGGER trg_UsuarioRole_Insert
ON [practica1].[UsuarioRole]
AFTER INSERT
AS
BEGIN
    INSERT INTO [practica1].[HistoryLog] (Date, Description)
    SELECT GETDATE(), '[UsuarioRole inserted] Id:' + CAST(Id AS NVARCHAR) + ', RoleId: ' + CAST(RoleId AS NVARCHAR(36)) + ', UserId: ' + CAST(UserId AS NVARCHAR(36)) + ', IsLatestVersion: ' + CAST(IsLatestVersion AS NVARCHAR)
    FROM inserted;
END
GO

/** Entidad Usuarios **/
CREATE TRIGGER trg_Usuarios_Insert
ON [practica1].[Usuarios]
AFTER INSERT
AS
BEGIN
    INSERT INTO [practica1].[HistoryLog] (Date, Description)
    SELECT GETDATE(), '[Usuarios inserted] Id:' + CAST(Id AS NVARCHAR(36)) + ', Firstname: ' + Firstname + ', Lastname: ' + Lastname + ', Email: ' + Email + ', DateOfBirth: ' + CAST(DateOfBirth AS NVARCHAR) + ', LastChanges: ' + CAST(LastChanges AS NVARCHAR) + ', EmailConfirmed: ' + CAST(EmailConfirmed AS NVARCHAR)
    FROM inserted;
END
GO

/** Entidad CourseAssignment **/
CREATE TRIGGER trg_CourseAssignment_Insert
ON [practica1].[CourseAssignment]
AFTER INSERT
AS
BEGIN
    INSERT INTO [practica1].[HistoryLog] (Date, Description)
    SELECT GETDATE(), '[CourseAssignment inserted] Id:' + CAST(Id AS NVARCHAR) + ', StudentId: ' + CAST(StudentId AS NVARCHAR(36)) + ', CourseCodCourse: ' + CAST(CourseCodCourse AS NVARCHAR)
    FROM inserted;
END
GO

/** Entidad CourseTutor **/
CREATE TRIGGER trg_CourseTutor_Insert
ON [practica1].[CourseTutor]
AFTER INSERT
AS
BEGIN
    INSERT INTO [practica1].[HistoryLog] (Date, Description)
    SELECT GETDATE(), '[CourseTutor inserted] Id:' + CAST(Id AS NVARCHAR) + ', TutorId: ' + CAST(TutorId AS NVARCHAR(36)) + ', CourseCodCourse: ' + CAST(CourseCodCourse AS NVARCHAR)
    FROM inserted;
END
GO


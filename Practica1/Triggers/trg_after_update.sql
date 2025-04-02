/*** ENTIDAD ROLES ***/

CREATE TRIGGER trg_Roles_Update
ON practica1.Roles
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[Rol updated] Id: ' + CAST(i.Id AS NVARCHAR(36)) + 
        '. Cambios realizados: ' +
        CASE WHEN i.RoleName <> d.RoleName THEN 'RoleName actualizado de ' + d.RoleName + ' a ' + i.RoleName + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.RoleName <> d.RoleName;
END;
GO


/*** ENTIDAD COURSE ***/
CREATE TRIGGER trg_Course_Update
ON practica1.Course
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[Course updated] CodCourse: ' + CAST(i.CodCourse AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.Name <> d.Name THEN 'Name actualizado de ' + d.Name + ' a ' + i.Name + '. ' ELSE '' END +
        CASE WHEN i.CreditsRequired <> d.CreditsRequired THEN 'CreditsRequired actualizado de ' + CAST(d.CreditsRequired AS NVARCHAR) + ' a ' + CAST(i.CreditsRequired AS NVARCHAR) + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.CodCourse = d.CodCourse
    WHERE i.Name <> d.Name OR i.CreditsRequired <> d.CreditsRequired; 
END;
GO


/*** ENTIDAD PROFILE STUDENT ***/
CREATE TRIGGER trg_ProfileStudent_Update
ON practica1.ProfileStudent
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[ProfileStudent updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.UserId <> d.UserId THEN 'UserId actualizado de ' + CAST(d.UserId AS NVARCHAR(36)) + ' a ' + CAST(i.UserId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.Credits <> d.Credits THEN 'Credits actualizado de ' + CAST(d.Credits AS NVARCHAR) + ' a ' + CAST(i.Credits AS NVARCHAR) + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.UserId <> d.UserId OR i.Credits <> d.Credits; 
END;
GO

/*** ENTIDAD NOTIFICATION ***/
CREATE TRIGGER trg_Notification_Update
ON practica1.Notification
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[Notification updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.UserId <> d.UserId THEN 'UserId actualizado de ' + CAST(d.UserId AS NVARCHAR(36)) + ' a ' + CAST(i.UserId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.Message <> d.Message THEN 'Message actualizado de "' + d.Message + '" a "' + i.Message + '". ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.UserId <> d.UserId OR i.Message <> d.Message;
END;
GO


/*** ENTIDAD TFA ***/
CREATE TRIGGER trg_TFA_Update
ON practica1.TFA
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[TFA updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.UserId <> d.UserId THEN 'UserId actualizado de ' + CAST(d.UserId AS NVARCHAR(36)) + ' a ' + CAST(i.UserId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.Status <> d.Status THEN 'Status actualizado de ' + CAST(d.Status AS NVARCHAR) + ' a ' + CAST(i.Status AS NVARCHAR) + '. ' ELSE '' END +
        CASE WHEN i.LastUpdate <> d.LastUpdate THEN 'LastUpdate actualizado de ' + CAST(d.LastUpdate AS NVARCHAR) + ' a ' + CAST(i.LastUpdate AS NVARCHAR) + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.UserId <> d.UserId OR i.Status <> d.Status OR i.LastUpdate <> d.LastUpdate;
END;
GO


/*** ENTIDAD TUTOR PROFILE ***/
CREATE TRIGGER trg_TutorProfile_Update
ON practica1.TutorProfile
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[TutorProfile updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.UserId <> d.UserId THEN 'UserId actualizado de ' + CAST(d.UserId AS NVARCHAR(36)) + ' a ' + CAST(i.UserId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.TutorCode <> d.TutorCode THEN 'TutorCode actualizado de ' + d.TutorCode + ' a ' + i.TutorCode + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.UserId <> d.UserId OR i.TutorCode <> d.TutorCode;
END;
GO


/*** ENTIDAD USUARIO ROLE ***/
CREATE TRIGGER trg_UsuarioRole_Update
ON practica1.UsuarioRole
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[UsuarioRole updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.RoleId <> d.RoleId THEN 'RoleId actualizado de ' + CAST(d.RoleId AS NVARCHAR(36)) + ' a ' + CAST(i.RoleId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.UserId <> d.UserId THEN 'UserId actualizado de ' + CAST(d.UserId AS NVARCHAR(36)) + ' a ' + CAST(i.UserId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.IsLatestVersion <> d.IsLatestVersion THEN 'IsLatestVersion actualizado de ' + CAST(d.IsLatestVersion AS NVARCHAR) + ' a ' + CAST(i.IsLatestVersion AS NVARCHAR) + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.RoleId <> d.RoleId OR i.UserId <> d.UserId OR i.IsLatestVersion <> d.IsLatestVersion;
END;
GO

/*** ENTIDAD USUARIOS ***/ 
CREATE TRIGGER trg_Usuarios_Update
ON practica1.Usuarios
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[Usuarios updated] Id: ' + CAST(i.Id AS NVARCHAR(36)) + 
        '. Cambios realizados: ' +
        CASE WHEN i.Firstname <> d.Firstname THEN 'Firstname actualizado de ' + d.Firstname + ' a ' + i.Firstname + '. ' ELSE '' END +
        CASE WHEN i.Lastname <> d.Lastname THEN 'Lastname actualizado de ' + d.Lastname + ' a ' + i.Lastname + '. ' ELSE '' END +
        CASE WHEN i.Email <> d.Email THEN 'Email actualizado de ' + d.Email + ' a ' + i.Email + '. ' ELSE '' END +
        CASE WHEN i.DateOfBirth <> d.DateOfBirth THEN 'DateOfBirth actualizado de ' + CAST(d.DateOfBirth AS NVARCHAR) + ' a ' + CAST(i.DateOfBirth AS NVARCHAR) + '. ' ELSE '' END +
        CASE WHEN i.LastChanges <> d.LastChanges THEN 'LastChanges actualizado de ' + CAST(d.LastChanges AS NVARCHAR) + ' a ' + CAST(i.LastChanges AS NVARCHAR) + '. ' ELSE '' END +
        CASE WHEN i.EmailConfirmed <> d.EmailConfirmed THEN 'EmailConfirmed actualizado de ' + CAST(d.EmailConfirmed AS NVARCHAR) + ' a ' + CAST(i.EmailConfirmed AS NVARCHAR) + '. ' ELSE '' END
        CASE WHEN i.Password <> d.Password THEN 'Se editó la contraseña. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.Firstname <> d.Firstname 
       OR i.Lastname <> d.Lastname
       OR i.Email <> d.Email
       OR i.DateOfBirth <> d.DateOfBirth
       OR i.LastChanges <> d.LastChanges
       OR i.EmailConfirmed <> d.EmailConfirmed
       OR i.Password <> d.Password;
END;
GO

/*** ENTIDAD COURSE ASSIGNMENT ***/  REVISAR
CREATE TRIGGER trg_CourseAssignment_Update
ON practica1.CourseAssignment
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[CourseAssignment updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.StudentId <> d.StudentId THEN 'StudentId actualizado de ' + CAST(d.StudentId AS NVARCHAR(36)) + ' a ' + CAST(i.StudentId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.CourseCodCourse <> d.CourseCodCourse THEN 'CourseCodCourse actualizado de ' + CAST(d.CourseCodCourse AS NVARCHAR) + ' a ' + CAST(i.CourseCodCourse AS NVARCHAR) + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.StudentId <> d.StudentId OR i.CourseCodCourse <> d.CourseCodCourse; 
END;
GO

/*** ENTIDAD COURSE TUTOR ***/
CREATE TRIGGER trg_CourseTutor_Update
ON practica1.CourseTutor
AFTER UPDATE
AS
BEGIN
    INSERT INTO practica1.HistoryLog (Date, Description)
    SELECT 
        GETDATE(), 
        '[CourseTutor updated] Id: ' + CAST(i.Id AS NVARCHAR) + 
        '. Cambios realizados: ' +
        CASE WHEN i.TutorId <> d.TutorId THEN 'TutorId actualizado de ' + CAST(d.TutorId AS NVARCHAR(36)) + ' a ' + CAST(i.TutorId AS NVARCHAR(36)) + '. ' ELSE '' END +
        CASE WHEN i.CourseCodCourse <> d.CourseCodCourse THEN 'CourseCodCourse actualizado de ' + CAST(d.CourseCodCourse AS NVARCHAR) + ' a ' + CAST(i.CourseCodCourse AS NVARCHAR) + '. ' ELSE '' END
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE i.TutorId <> d.TutorId OR i.CourseCodCourse <> d.CourseCodCourse; -- Filtra solo si hubo cambios reales
END;
GO
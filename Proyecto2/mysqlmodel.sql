DROP TABLE IF EXISTS `Pacientes`;
CREATE TABLE `Pacientes` (`idPaciente` INT, `edad` INT, `genero` VARCHAR(255));

DROP TABLE IF EXISTS `Habitaciones`;
CREATE TABLE `Habitaciones` (`idHabitacion` INT, `habitacion` VARCHAR(255));

DROP TABLE IF EXISTS `LogHabitacion`;
CREATE TABLE `LogHabitacion` (`idHabitacion` INT, `timestamp` DATETIME, `status` VARCHAR(255));

DROP TABLE IF EXISTS `LogActividades1`;
CREATE TABLE `LogActividades1` (`timestamp` DATETIME, `actividad` VARCHAR(255), `idHabitacion` INT, `idPaciente` INT);

DROP TABLE IF EXISTS `LogActividades2`;
CREATE TABLE `LogActividades2` (`timestamp` DATETIME, `actividad` VARCHAR(255), `idHabitacion` INT, `idPaciente` INT);


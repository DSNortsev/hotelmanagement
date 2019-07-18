START TRANSACTION;

SET sql_mode = "ONLY_FULL_GROUP_BY";

DROP DATABASE IF EXISTS hotelmanagementProject;

CREATE DATABASE hotelmanagementProject;
USE hotelmanagementProject;

############
###TABLES###
############

CREATE TABLE `hotel` (
  `name` VARCHAR(30) NOT NULL PRIMARY KEY,
  `street-number` VARCHAR(10) NOT NULL,
  `street-name` VARCHAR(50) NOT NULL,
  `city` VARCHAR(30) NOT NULL,
  `zip` VARCHAR(10) NOT NULL, 
  `phone` VARCHAR(15) NOT NULL UNIQUE,
  `manager-name` VARCHAR(30) NOT NULL,
   UNIQUE(`street-number`,`street-name`,`city`,`zip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `capacity` (
 `hotel-id` VARCHAR(30) NOT NULL,
 `type` VARCHAR(7) NOT NULL, 
 `number` INT(5) NOT NULL,
 PRIMARY KEY (`hotel-id`, `type`),
 CONSTRAINT `hotel_id_fk` FOREIGN KEY (`hotel-id`) REFERENCES `hotel`(`name`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `customer` (
 `cust-id` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
 `name` VARCHAR(30) NOT NULL,
 `number` VARCHAR(20) NOT NULL,
 `street` VARCHAR(50) NOT NULL,
 `city` VARCHAR(30) NOT NULL,
 `zip`  VARCHAR(10) NOT NULL,
 `status` VARCHAR(8) NOT NULL,
  UNIQUE(`name`,`number`,`street`,`city`,`zip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE  `reservation` (
 `hotel-name` VARCHAR(30) NOT NULL,
 `cust-id` INTEGER NOT NULL,
 `room-type` VARCHAR(7) NOT NULL,
 `begin-date` DATE NOT NULL,
 `end-date` DATE NOT NULL,
 `credit-card-number` VARCHAR(16) NOT NULL,
 `exp-date` DATE NOT NULL,
 PRIMARY KEY (`hotel-name`,`cust-id`,`begin-date`,`end-date`),
 CONSTRAINT `hotel_name_and_room_type_reservation_fk` FOREIGN KEY (`hotel-name`,`room-type`) REFERENCES `capacity`(`hotel-id`,`type`) ON DELETE NO ACTION,
 CONSTRAINT `cust_id_reservation_fk` FOREIGN KEY (`cust-id`) REFERENCES `customer`(`cust-id`) ON DELETE NO ACTION
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE  `occupancy` (
 `hotel-name` VARCHAR(30) NOT NULL,
 `type` VARCHAR(7) NOT NULL,
 `number` INT(5) NOT NULL, 
 PRIMARY KEY (`hotel-name`,`type`),
 CONSTRAINT `hotel_name_and_room_type_occupancy_fk` FOREIGN KEY (`hotel-name`,`type`) REFERENCES `capacity`(`hotel-id`,`type`) ON DELETE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE  `prefferedcustomer` (
 `cust-id` INT(10) NOT NULL PRIMARY KEY, 
 `cust-name` VARCHAR(30) NOT NULL,
 `hotel-name` VARCHAR(30) NOT NULl, 
 CONSTRAINT `cust_id_name_prefferedcustomer_fk` FOREIGN KEY (`cust-id`) REFERENCES `customer`(`cust-id`) ON DELETE NO ACTION, 
 CONSTRAINT `hotel_name_prefferedcustomer_fk` FOREIGN KEY (`hotel-name`) REFERENCES `hotel`(`name`) ON DELETE NO ACTION
)ENGINE=InnoDB DEFAULT CHARSET=utf8;


###############
###FUNCTIONS###
###############

-- ZIP code validation

DELIMITER $$
CREATE PROCEDURE proc_zip (IN zip VARCHAR(10), IN table_name VARCHAR(30))
BEGIN
declare MSG varchar(128);
IF NOT zip REGEXP '^[0-9]{5}$' THEN
    SET MSG = concat('[table:', table_name, '] - zip is not valid, expected 5 digits: ', zip);
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = MSG;
END IF;
END $$
DELIMITER ;

-- PHONE validation

DELIMITER $$
CREATE PROCEDURE proc_phone (IN phone VARCHAR(15), IN table_name VARCHAR(30))
BEGIN
declare MSG varchar(128);
IF NOT phone REGEXP '^[0-9]{10}$' THEN
    SET MSG = concat('[table:', table_name, '] - phone number not valid, shoud be 10 digits: ', phone);
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = MSG;
END IF;
END $$
DELIMITER ;

-- Room type validation 

DELIMITER $$
CREATE PROCEDURE proc_room_type (IN type VARCHAR(7), IN table_name VARCHAR(30))
BEGIN
declare MSG varchar(128);
IF NOT type REGEXP '^(regular|extra|family|suite)$' THEN
    SET MSG = concat('[table:', table_name, '] - Invalid room type (regular,extra,family,suite) : ', type); 
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = MSG;
END IF;
END $$
DELIMITER ;

-- Customer status validation 

DELIMITER $$
CREATE PROCEDURE proc_customer_status (IN status VARCHAR(8), IN table_name VARCHAR(30))
BEGIN
declare MSG varchar(128);
IF NOT status REGEXP '^(gold|silver|business)$' THEN
    SET MSG = concat('[table:', table_name, '] - Invalid customer status (silver,gold,business) : ', status);
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = MSG;
END IF;
END $$
DELIMITER ;

-- Reservation date validation

DELIMITER $$
CREATE PROCEDURE proc_reserv_date (IN starttime DATE, IN endtime DATE, IN table_name VARCHAR(30))
BEGIN
declare MSG varchar(128);
IF starttime >= endtime THEN
    SET MSG = concat('[table:', table_name, '] - begin-date should not be equal or greater than end-date');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = MSG;
END IF;
END $$
DELIMITER ;

-- Credit card number validation

DELIMITER $$
CREATE PROCEDURE proc_cc_check (IN cc_number VARCHAR(16), IN table_name VARCHAR(30))
BEGIN
declare MSG varchar(128);
IF NOT cc_number REGEXP '^[0-9]{15,16}$' THEN
    SET MSG = concat('[table:', table_name, '] - Invalid credit card number. The card must be 15 or 16 digits in length: ',cc_number );
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = MSG;
END IF;
END $$
DELIMITER ;

-- Expiration date validation

DELIMITER $$
CREATE PROCEDURE proc_cc_expr_date (IN expr_date DATE, IN table_name VARCHAR(30))
BEGIN
declare MSG varchar(128);
IF DATE_FORMAT(CURRENT_DATE(), "%Y%m") > DATE_FORMAT(expr_date, "%Y%m") THEN
    SET MSG = concat('[table:', table_name, '] - Invalid expiration date. it should be equal to or greater than current date: ', expr_date);
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = MSG; 
END IF;
END $$
DELIMITER ;

-- Update occupancy table when inserting 

DELIMITER $$
CREATE PROCEDURE proc_check_occupancy(IN hotel_name VARCHAR(30), IN room_type VARCHAR(7),
									  IN begin_date DATE, IN end_date DATE)
BEGIN
declare MSG varchar(128);
declare current_occupancy INT(5); 
declare capacity INT(5);
declare total_occupancy INT(5);

SET current_occupancy = (SELECT IFNULL(SUM(DATEDIFF(`end-date`,`begin-date`)), 0) 
						 FROM reservation 
						 WHERE `hotel-name` = hotel_name and `room-type` = room_type);
SET capacity = (SELECT IFNULL(`number`, 0) 
				FROM capacity 
				WHERE `hotel-id` = hotel_name and `type` = room_type);
SET total_occupancy = (current_occupancy + DATEDIFF(end_date,begin_date));

IF total_occupancy > capacity THEN 
	SET MSG = concat('[table:reservation] - ',hotel_name,'-',room_type,' is not available. Maximum capacity:',capacity,'. Attempt to enter:',total_occupancy);
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = MSG;
ELSE
    REPLACE INTO `occupancy` VALUES (hotel_name,room_type,total_occupancy);
END IF;
END $$
DELIMITER ;

-- Update prefferedcustomer table 

DELIMITER $$
CREATE PROCEDURE proc_pref_cust (IN cust_id INT(5))
BEGIN
declare cust_name VARCHAR(30);
declare favorite_hotel VARCHAR(30);
declare total INT(5);

SET total = (SELECT SUM(DATEDIFF(`end-date`,`begin-date`)) 
	     FROM reservation
	     WHERE `cust-id` = cust_id);

IF total >= 100 THEN
	SET favorite_hotel = (SELECT `hotel-name` 
	                  	  FROM (SELECT `hotel-name`, SUM(DATEDIFF(`end-date`,`begin-date`)) as `total-days` 
	                  	    	FROM reservation 
	                  	        WHERE `cust-id` = cust_id 
	                  	        GROUP BY `hotel-name` 
	                  	        ORDER BY `total-days` DESC 
	                  	        LIMIT 1) as total);
	SET cust_name = (SELECT `name` FROM `customer` WHERE `cust-id` = cust_id);

	REPLACE INTO `prefferedcustomer` VALUES (cust_id,cust_name,favorite_hotel);
ELSE 
	DELETE FROM `prefferedcustomer` WHERE `cust-id` = cust_id;
END IF;
END $$
DELIMITER ;


##############
###TRIGGERS###
##############

-- HOTEL table 

DELIMITER $$
CREATE TRIGGER hotel_insert BEFORE INSERT ON hotel
FOR EACH ROW 
BEGIN
    CALL proc_zip(NEW.zip,'hotel');
    CALL proc_phone(NEW.phone, 'hotel');
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER hotel_update BEFORE UPDATE ON hotel
FOR EACH ROW
BEGIN
    CALL proc_zip(NEW.zip,'hotel');
    CALL proc_phone(NEW.phone, 'hotel');
END$$
DELIMITER ;


-- CAPACITY table

DELIMITER $$
CREATE TRIGGER capacity_insert BEFORE INSERT ON capacity
FOR EACH ROW
BEGIN
    CALL proc_room_type(NEW.type, 'capacity');
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER capacity_update BEFORE UPDATE ON capacity
FOR EACH ROW
BEGIN
    CALL proc_room_type(NEW.type, 'capacity');
END$$
DELIMITER ;


-- CUSTOMER table

DELIMITER $$
CREATE TRIGGER customer_insert BEFORE INSERT ON customer
FOR EACH ROW
BEGIN
    CALL proc_zip(NEW.zip, 'customer');
    CALL proc_customer_status(NEW.status, 'customer');
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER customer_update BEFORE UPDATE ON customer
FOR EACH ROW
BEGIN
    CALL proc_zip(NEW.zip, 'customer');
    CALL proc_customer_status(NEW.status, 'customer');
END$$
DELIMITER ;

-- RESERVATION table 

DELIMITER $$
CREATE TRIGGER reservation_insert BEFORE INSERT ON reservation
FOR EACH ROW
BEGIN
    CALL proc_reserv_date(NEW.`begin-date`, NEW.`end-date`, 'reservation');
    CALL proc_cc_check(NEW.`credit-card-number`, 'reservation');
    CALL proc_cc_expr_date(NEW.`exp-date`, 'reservation');
    SET NEW.`exp-date` = LAST_DAY(NEW.`exp-date`);
    CALL proc_check_occupancy(NEW.`hotel-name`, NEW.`room-type`, NEW.`begin-date`, NEW.`end-date`);
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER reservation_update BEFORE UPDATE ON reservation
FOR EACH ROW
BEGIN
    CALL proc_reserv_date(NEW.`begin-date`, NEW.`end-date`, 'reservation');
    CALL proc_cc_check(NEW.`credit-card-number`, 'reservation');
    CALL proc_cc_expr_date(NEW.`exp-date`, 'reservation');
    SET NEW.`exp-date` = LAST_DAY(NEW.`exp-date`);
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER reservation_after_insert AFTER INSERT ON reservation
FOR EACH ROW
BEGIN
    CALL proc_pref_cust(NEW.`cust-id`);
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER reservation_after_update AFTER UPDATE ON reservation
FOR EACH ROW
BEGIN
    CALL proc_pref_cust(NEW.`cust-id`);   
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER reservation_after_delete AFTER DELETE ON reservation
FOR EACH ROW
BEGIN
IF (SELECT `cust-id` FROM reservation WHERE `cust-id` = OLD.`cust-id` LIMIT 1) THEN
     CALL proc_pref_cust(OLD.`cust-id`);
ELSE
    DELETE FROM prefferedcustomer WHERE `cust-id` = OLD.`cust-id`;
END IF;
END$$
DELIMITER ;

###############
###INSERTION###
###############

INSERT INTO `hotel` VALUES
('Omni Louisville Hotel', 400, 'S 2nd St', 'Louisville', '40202', '5023136664', 'Scott Stuckey'),
('The Galt House Hotel', 140, 'N Fourth St', 'Louisville', '40202', '5025895200', 'Jose Rolon'),
('The Seelbach Hilton Louisville', 500, 'S 4th St', 'Louisville', '40202', '5025853200', 'Paul Emil Moosmiller'),
('Aloft Louisville Downtown', 102, 'W Main St', 'Louisville', '40202', '5025831888', 'Lauren Jenney'),
('Hyatt Regency Louisville', 320, 'W Jefferson St', 'Louisville', '40202', '5025811234', 'Emily Powell');

INSERT INTO `capacity` VALUES
('Omni Louisville Hotel', 'regular', 200),
('Omni Louisville Hotel', 'extra', 150), 
('Omni Louisville Hotel', 'family', 329),
('Omni Louisville Hotel', 'suite', 30),
('The Galt House Hotel', 'regular', 400),
('The Galt House Hotel', 'extra', 89),
('The Galt House Hotel', 'family', 120),
('The Galt House Hotel', 'suite', 57),
('The Seelbach Hilton Louisville', 'regular', 300),
('The Seelbach Hilton Louisville', 'extra', 125),
('The Seelbach Hilton Louisville', 'family', 85),
('The Seelbach Hilton Louisville', 'suite', 35);

INSERT INTO `customer`(`name`, `number`, `street`, `city`, `zip`, `status`) VALUES
('Daria Livingston', 8703, 'East Gonzales St.', 'Downingtown', '19335', 'gold'),
('Kuba Mccartney', 958, 'Bridgeton Drive', 'Indian Trail', '28079', 'silver'),
('Maheen Jennings', 799, 'Livingston St.', 'Poughkeepsie', '12601', 'business'),
('Haydon Blaese', 415, 'Bay Meadows Court', 'Alexandria', '22304', 'silver'),
('Shayan Tran', 201, 'South Pumpkin Hill St.', 'Parkville', '21234', 'silver');

INSERT INTO `reservation` VALUES
('Omni Louisville Hotel',(SELECT `cust-id` FROM `customer` WHERE `name` = 'Daria Livingston'), 'regular', CURRENT_DATE(),  DATE_ADD(CURRENT_DATE(), INTERVAL 3 DAY), '4024007160787049', '2020-04-01'),
('Omni Louisville Hotel',(SELECT `cust-id` FROM `customer` WHERE `name` = 'Kuba Mccartney'), 'family', CURRENT_DATE(),  DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY), '5326125032210511', '2020-11-01'),
('Omni Louisville Hotel',(SELECT `cust-id` FROM `customer` WHERE `name` = 'Maheen Jennings'), 'suite', CURRENT_DATE(),  DATE_ADD(CURRENT_DATE(), INTERVAL 5 DAY), '6011108726680668', '2022-01-01'),
('Omni Louisville Hotel',(SELECT `cust-id` FROM `customer` WHERE `name` = 'Haydon Blaese'), 'extra', DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY), DATE_ADD(CURRENT_DATE(), INTERVAL 35 DAY), '342454133969564', '2019-12-01'),
('The Galt House Hotel',(SELECT `cust-id` FROM `customer` WHERE `name` = 'Daria Livingston'), 'regular', DATE_ADD(CURRENT_DATE(), INTERVAL 10 DAY), DATE_ADD(CURRENT_DATE(), INTERVAL 15 DAY), '4024007160787049', '2020-04-01'),
('The Galt House Hotel',(SELECT `cust-id` FROM `customer` WHERE `name` = 'Maheen Jennings'), 'family', CURRENT_DATE(), DATE_ADD(CURRENT_DATE(), INTERVAL 14 DAY), '6011084208622439', '2021-07-01'),
('The Seelbach Hilton Louisville',(SELECT `cust-id` FROM `customer` WHERE `name` = 'Shayan Tran'), 'regular', DATE_ADD(CURRENT_DATE(), INTERVAL 10 DAY), DATE_ADD(CURRENT_DATE(), INTERVAL 155 DAY), '5172133286160288', '2020-05-01'),
('The Seelbach Hilton Louisville',(SELECT `cust-id` FROM `customer` WHERE `name` = 'Maheen Jennings'), 'suite', CURRENT_DATE(),  DATE_ADD(CURRENT_DATE(), INTERVAL 3 DAY), '4716643762661175', '2021-10-01');

COMMIT;

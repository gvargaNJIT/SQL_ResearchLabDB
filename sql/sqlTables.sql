CREATE TABLE MEMBER
(fName VARCHAR(15) NOT NULL,
lName VARCHAR(15),
joinDate DATE NOT NULL,
memID CHAR(5) NOT NULL,
mentorID CHAR(5),
mentorStartDate DATE,
mentorEndDate DATE,
PRIMARY KEY (memID),
CHECK (memID REGEXP '^[fse][0-9]{4}$'),
CHECK (mentorStartDate IS NULL OR 
       mentorEndDate IS NULL OR 
       mentorStartDate <= mentorEndDate),
CONSTRAINT mentorIDMem
    FOREIGN KEY (mentorID) REFERENCES MEMBER(memID)
    ON DELETE SET NULL
    ON UPDATE CASCADE
);

CREATE TABLE STUDENT
  (studentNo INT PRIMARY KEY 
     CHECK (studentNo BETWEEN 10000 AND 99999),
   academicLevel VARCHAR(10) NOT NULL 
     CHECK (academicLevel IN ('Freshman', 'Sophomore', 'Junior', 'Senior', 'Masters', 'PhD')),
   major VARCHAR(40), 
   memID CHAR(5) NOT NULL,
   CONSTRAINT STUDENTFK
   FOREIGN KEY (memID) REFERENCES MEMBER(memID)
   ON DELETE CASCADE ON UPDATE CASCADE 
);


CREATE TABLE EXTCOLLAB
  (memID CHAR(5) PRIMARY KEY,
   affiliation VARCHAR(30) NOT NULL,
   bio VARCHAR(200),
   CONSTRAINT EXTCOLLABFK
   FOREIGN KEY (memID) REFERENCES MEMBER(memID)
   ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE FACULTY
  (memID CHAR(5) PRIMARY KEY,
   department VARCHAR(20),
   CONSTRAINT FACULTYFK
   FOREIGN KEY (memID) REFERENCES MEMBER(memID)
   ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE PROJECT
(memID CHAR(5) NOT NULL,
projID CHAR(5) NOT NULL,
title VARCHAR(50),
expDuration INT,
startDate DATE,
endDate DATE,
statusProj VARCHAR(9) NOT NULL DEFAULT 'active',
PRIMARY KEY (projID),
CHECK (statusProj IN ('active','paused','completed')),
CHECK (startDate IS NULL OR 
       endDate IS NULL OR 
       startDate <= endDate),
CONSTRAINT proj_leader_FK
        FOREIGN KEY (memID) REFERENCES FACULTY(memID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);

CREATE TABLE WORK_ON
(memID CHAR(5) NOT NULL,
projID CHAR(5) NOT NULL,
roleWO VARCHAR(15),
weeklyHours INT,
FOREIGN KEY (memID) REFERENCES MEMBER(memID),
FOREIGN KEY (projID) REFERENCES PROJECT(projID),
PRIMARY KEY (memID, projID),
CHECK (weeklyHours >= 0)
);

CREATE TABLE GRANT (
    grantID CHAR(5) PRIMARY KEY
        CHECK (grantID BETWEEN '00000' AND '99999'),
    source VARCHAR(25) NOT NULL,
    budget INT NOT NULL,
    startDate DATE,
    duration INT
);

CREATE TABLE FUNDED_BY (
    projID CHAR(5) NOT NULL,
    grantID CHAR(5) NOT NULL,
    PRIMARY KEY (projID, grantID),
    CONSTRAINT FK_FundedBy_Proj
    FOREIGN KEY (projID) REFERENCES PROJECT(projID)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_FundedBy_Grant
    FOREIGN KEY (grantID) REFERENCES GRANT(grantID)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE EQUIPMENT (
    equipID CHAR(5) PRIMARY KEY,
    name VARCHAR(15) NOT NULL,
    type VARCHAR(15) NOT NULL,
    purchaseDate DATE,
    status VARCHAR(15) DEFAULT 'Available',
    CONSTRAINT CHK_Equipment_Status
        CHECK (status IN ('Available', 'In Use', 'Retired'))
);

CREATE TABLE USES (
    memID CHAR(5) NOT NULL,
    equipID CHAR(5) NOT NULL,
    purpose VARCHAR(50) NOT NULL,
    startDate DATE NOT NULL,
    endDate DATE NOT NULL,
    PRIMARY KEY (memID, equipID, startDate),
    CONSTRAINT FK_Uses_Member
        FOREIGN KEY (memID) REFERENCES MEMBER(memID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_Uses_Equipment
        FOREIGN KEY (equipID) REFERENCES EQUIPMENT(equipID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE PUBLICATION (
    pubID CHAR(5) PRIMARY KEY,
    publicationDate DATE NOT NULL,
    title VARCHAR(100) NOT NULL,
    venue VARCHAR(50) NOT NULL,
    month TINYINT NOT NULL,
    year SMALLINT NOT NULL,
    DOI VARCHAR(100) DEFAULT NULL,
    CHECK (month BETWEEN 1 AND 12),
    CHECK (year >= 1900)
);

CREATE TABLE AUTHORED_BY (
    pubID CHAR(5) NOT NULL,
    memID CHAR(5) NOT NULL,
    PRIMARY KEY (pubID, memID),
    CONSTRAINT FK_AuthoredBy_Publication
        FOREIGN KEY (pubID) REFERENCES PUBLICATION(pubID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_AuthoredBy_Member
        FOREIGN KEY (memID) REFERENCES MEMBER(memID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

DELIMITER $$
CREATE TRIGGER prevent_student_mentoring_faculty
BEFORE UPDATE ON MEMBER
FOR EACH ROW
BEGIN
    IF NEW.mentorID IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM STUDENT WHERE memID = NEW.mentorID) 
           AND EXISTS (SELECT 1 FROM FACULTY WHERE memID = NEW.memID) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'A STUDENT cannot mentor a FACULTY member';
        END IF;
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER faculty_prefix_check
BEFORE INSERT ON FACULTY
FOR EACH ROW
BEGIN
    IF SUBSTRING(NEW.memID, 1, 1) <> 'f' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'FACULTY memID must start with f';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER student_prefix_check
BEFORE INSERT ON STUDENT
FOR EACH ROW
BEGIN
    IF SUBSTRING(NEW.memID, 1, 1) <> 's' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'STUDENT memID must start with s';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER extcollab_prefix_check
BEFORE INSERT ON EXTCOLLAB
FOR EACH ROW
BEGIN
    IF SUBSTRING(NEW.memID, 1, 1) <> 'e' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'EXTCOLLAB memID must start with e';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER check_member_has_project_student
AFTER INSERT ON STUDENT
FOR EACH ROW
BEGIN
    DECLARE project_count INT;
    SELECT COUNT(*) INTO project_count 
    FROM WORK_ON 
    WHERE memID = NEW.memID;
    
    IF project_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Member must be assigned to at least one project';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER check_member_has_project_faculty
AFTER INSERT ON FACULTY
FOR EACH ROW
BEGIN
    DECLARE project_count INT;
    SELECT COUNT(*) INTO project_count 
    FROM WORK_ON 
    WHERE memID = NEW.memID;
    
    IF project_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Member must be assigned to at least one project';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER check_member_has_project_extcollab
AFTER INSERT ON EXTCOLLAB
FOR EACH ROW
BEGIN
    DECLARE project_count INT;
    SELECT COUNT(*) INTO project_count 
    FROM WORK_ON 
    WHERE memID = NEW.memID;
    
    IF project_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Member must be assigned to at least one project';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER work_on_before_delete
BEFORE DELETE ON WORK_ON
FOR EACH ROW
BEGIN
    DECLARE cnt INT;
    SELECT COUNT(*) INTO cnt FROM WORK_ON WHERE memID = OLD.memID;
    IF cnt <= 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Member must be assigned to at least one project';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER uses_before_insert
BEFORE INSERT ON USES
FOR EACH ROW
BEGIN
    DECLARE cnt INT;
    SELECT COUNT(DISTINCT u.memID) INTO cnt
    FROM USES u
    WHERE u.equipID = NEW.equipID
      AND NOT (u.endDate < NEW.startDate OR u.startDate > NEW.endDate);
    IF cnt >= 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Equipment already in use by 3 members during that interval';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER uses_before_update
BEFORE UPDATE ON USES
FOR EACH ROW
BEGIN
    DECLARE cnt INT;
    SELECT COUNT(DISTINCT u.memID) INTO cnt
    FROM USES u
    WHERE u.equipID = NEW.equipID
      AND NOT (u.memID = OLD.memID AND u.equipID = OLD.equipID AND u.startDate = OLD.startDate)
      AND NOT (u.endDate < NEW.startDate OR u.startDate > NEW.endDate);
    IF cnt >= 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Equipment already in use by 3 members during that interval';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER publication_must_have_author
AFTER DELETE ON AUTHORED_BY
FOR EACH ROW
BEGIN
    DECLARE author_count INT;
    SELECT COUNT(*) INTO author_count 
    FROM AUTHORED_BY 
    WHERE pubID = OLD.pubID;
    IF author_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Publication must have at least one author';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER grant_must_fund_project
AFTER DELETE ON FUNDED_BY
FOR EACH ROW
BEGIN
    DECLARE project_count INT;
    SELECT COUNT(*) INTO project_count 
    FROM FUNDED_BY 
    WHERE grantID = OLD.grantID;
    IF project_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Grant must fund at least one project';
    END IF;
END$$
DELIMITER ;
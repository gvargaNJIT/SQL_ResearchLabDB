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

CREATE TRIGGER prevent_student_mentoring_faculty
BEFORE UPDATE ON MEMBER
FOR EACH ROW
WHEN NEW.mentorID IS NOT NULL 
    AND EXISTS (SELECT 1 FROM STUDENT WHERE memID = NEW.mentorID)
    AND EXISTS (SELECT 1 FROM FACULTY WHERE memID = NEW.memID)
BEGIN
    SELECT RAISE(ABORT, 'A STUDENT cannot mentor a FACULTY member');
END;

CREATE TRIGGER faculty_prefix_check
BEFORE INSERT ON FACULTY
FOR EACH ROW
WHEN SUBSTR(NEW.memID, 1, 1) <> 'f'
BEGIN
    SELECT RAISE(ABORT, 'FACULTY memID must start with f');
END;

CREATE TRIGGER student_prefix_check
BEFORE INSERT ON STUDENT
FOR EACH ROW
WHEN SUBSTR(NEW.memID, 1, 1) <> 's'
BEGIN
    SELECT RAISE(ABORT, 'STUDENT memID must start with s');
END;

CREATE TRIGGER extcollab_prefix_check
BEFORE INSERT ON EXTCOLLAB
FOR EACH ROW
WHEN SUBSTR(NEW.memID, 1, 1) <> 'e'
BEGIN
    SELECT RAISE(ABORT, 'EXTCOLLAB memID must start with e');
END;

CREATE TRIGGER check_member_has_project_student
AFTER INSERT ON STUDENT
FOR EACH ROW
WHEN (SELECT COUNT(*) FROM WORK_ON WHERE memID = NEW.memID) = 0
BEGIN
    SELECT RAISE(ABORT, 'Member must be assigned to at least one project');
END;

CREATE TRIGGER check_member_has_project_faculty
AFTER INSERT ON FACULTY
FOR EACH ROW
WHEN (SELECT COUNT(*) FROM WORK_ON WHERE memID = NEW.memID) = 0
BEGIN
    SELECT RAISE(ABORT, 'Member must be assigned to at least one project');
END;

CREATE TRIGGER check_member_has_project_extcollab
AFTER INSERT ON EXTCOLLAB
FOR EACH ROW
WHEN (SELECT COUNT(*) FROM WORK_ON WHERE memID = NEW.memID) = 0
BEGIN
    SELECT RAISE(ABORT, 'Member must be assigned to at least one project');
END;

CREATE TRIGGER work_on_before_delete
BEFORE DELETE ON WORK_ON
FOR EACH ROW
WHEN (SELECT COUNT(*) FROM WORK_ON WHERE memID = OLD.memID) <= 1
BEGIN
    SELECT RAISE(ABORT, 'Member must be assigned to at least one project');
END;

CREATE TRIGGER uses_before_insert
BEFORE INSERT ON USES
FOR EACH ROW
WHEN (
    SELECT COUNT(DISTINCT u.memID) 
    FROM USES u
    WHERE u.equipID = NEW.equipID
      AND NOT (u.endDate < NEW.startDate OR u.startDate > NEW.endDate)
) >= 3
BEGIN
    SELECT RAISE(ABORT, 'Equipment already in use by 3 members during that interval');
END;

CREATE TRIGGER uses_before_update
BEFORE UPDATE ON USES
FOR EACH ROW
WHEN (
    SELECT COUNT(DISTINCT u.memID) 
    FROM USES u
    WHERE u.equipID = NEW.equipID
      AND NOT (u.memID = OLD.memID AND u.equipID = OLD.equipID AND u.startDate = OLD.startDate)
      AND NOT (u.endDate < NEW.startDate OR u.startDate > NEW.endDate)
) >= 3
BEGIN
    SELECT RAISE(ABORT, 'Equipment already in use by 3 members during that interval');
END;

CREATE TRIGGER publication_must_have_author
AFTER DELETE ON AUTHORED_BY
FOR EACH ROW
WHEN (SELECT COUNT(*) FROM AUTHORED_BY WHERE pubID = OLD.pubID) = 0
BEGIN
    SELECT RAISE(ABORT, 'Publication must have at least one author');
END;

CREATE TRIGGER grant_must_fund_project
AFTER DELETE ON FUNDED_BY
FOR EACH ROW
WHEN (SELECT COUNT(*) FROM FUNDED_BY WHERE grantID = OLD.grantID) = 0
BEGIN
    SELECT RAISE(ABORT, 'Grant must fund at least one project');
END;
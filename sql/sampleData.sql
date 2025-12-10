INSERT INTO MEMBER (fName, lName, joinDate, memID, mentorID, mentorStartDate, mentorEndDate) 
VALUES 
('Alice', 'Johnson', '2015-09-01', 'f1234', NULL, NULL, NULL),
('Robert', 'Chen', '2017-01-15', 'f7788', NULL, NULL, NULL),
('Maria', 'Rodriguez', '2018-08-20', 'f9876', NULL, NULL, NULL),
('David', 'Kim', '2019-03-10', 'f5555', NULL, NULL, NULL),
('Emily', 'Watson', '2022-09-01', 's3321', NULL, NULL, NULL),
('Michael', 'Brown', '2021-09-01', 's4564', NULL, NULL, NULL),
('Sarah', 'Davis', '2023-01-15', 's6399', NULL, NULL, NULL),
('James', 'Wilson', '2020-09-01', 's1352', NULL, NULL, NULL),
('Lisa', 'Martinez', '2023-09-01', 's4756', NULL, NULL, NULL),
('Dr. John', 'Smith', '2020-06-01', 'e1212', NULL, NULL, NULL),
('Dr. Emma', 'Thompson', '2021-03-15', 'e9034', NULL, NULL, NULL),
('Dr. Alan', 'Zhang', '2022-11-01', 'e0036', NULL, NULL, NULL);

INSERT INTO PROJECT (memID, projID, title, expDuration, startDate, endDate, statusProj) 
VALUES 
('f1234', 'p0992', 'Machine Learning for Healthcare', 24, '2023-01-01', '2024-12-31', 'active'),
('f1234', 'p4633', 'Neural Network Optimization', 18, '2023-06-01', NULL, 'active'),
('f7788', 'p2221', 'Quantum Computing Applications', 36, '2022-09-01', '2025-08-31', 'active'),
('f9876', 'p5912', 'Robotics and Automation', 24, '2023-03-01', NULL, 'active'),
('f5555', 'p8035', 'Natural Language Processing', 30, '2022-01-01', '2024-06-30', 'completed'),
('f7788', 'p2378', 'Distributed Systems Research', 12, '2024-01-01', NULL, 'paused');

INSERT INTO WORK_ON (memID, projID, roleWO, weeklyHours) 
VALUES 
('f1234', 'p0992', 'Lead', 20),
('f1234', 'p4633', 'Lead', 15),
('f7788', 'p2221', 'Lead', 25),
('f7788', 'p2378', 'Lead', 10),
('f9876', 'p5912', 'Lead', 20),
('f5555', 'p8035', 'Lead', 15),
('f9876', 'p0992', 'Collaborator', 5),
('s3321', 'p0992', 'Research Asst', 20),
('s3321', 'p4633', 'Research Asst', 10),
('s4564', 'p2221', 'PhD Researcher', 30),
('s6399', 'p0992', 'Research Asst', 15),
('s1352', 'p5912', 'Research Asst', 20),
('s1352', 'p8035', 'Research Asst', 15),
('s4756', 'p4633', 'Research Asst', 10),
('e1212', 'p0992', 'Consultant', 10),
('e9034', 'p2221', 'Advisor', 8),
('e0036', 'p5912', 'Consultant', 12);

INSERT INTO FACULTY (memID, department) 
VALUES 
('f1234', 'Computer Science'),
('f7788', 'Computer Science'),
('f9876', 'Engineering'),
('f5555', 'Data Science');

INSERT INTO STUDENT (studentNo, academicLevel, major, memID) 
VALUES 
(65230, 'Junior', 'Computer Science', 's3321'),
(34111, 'PhD', 'Computer Science', 's4564'),
(90200, 'Sophomore', 'Data Science', 's6399'),
(87767, 'Masters', 'Engineering', 's1352'),
(45399, 'Freshman', 'Computer Science', 's4756');

INSERT INTO EXTCOLLAB (memID, affiliation, bio) 
VALUES 
('e1212', 'Stanford University', 'Expert in machine learning and healthcare applications'),
('e9034', 'MIT', 'Quantum computing researcher with 15 years of experience'),
('e0036', 'Google Research', 'Robotics and AI specialist');

UPDATE MEMBER SET mentorID = 'f1234', mentorStartDate = '2022-09-01', mentorEndDate = NULL 
WHERE memID = 's3321';

UPDATE MEMBER SET mentorID = 'f7788', mentorStartDate = '2021-09-01', mentorEndDate = NULL 
WHERE memID = 's4564';

UPDATE MEMBER SET mentorID = 'f1234', mentorStartDate = '2023-01-15', mentorEndDate = NULL 
WHERE memID = 's6399';

UPDATE MEMBER SET mentorID = 'f9876', mentorStartDate = '2020-09-01', mentorEndDate = NULL 
WHERE memID = 's1352';

UPDATE MEMBER SET mentorID = 's4564', mentorStartDate = '2023-09-01', mentorEndDate = NULL 
WHERE memID = 's4756';

INSERT INTO GRANT (grantID, source, budget, startDate, duration) 
VALUES 
('11121', 'National Science Foundation', 500000, '2023-01-01', 36),
('98445', 'Department of Defense', 750000, '2022-09-01', 48),
('46656', 'Google Research Grant', 300000, '2023-06-01', 24),
('22318', 'NIH', 600000, '2022-01-01', 36);

INSERT INTO FUNDED_BY (projID, grantID) 
VALUES 
('p0992', '11121'),
('p0992', '22318'),
('p4633', '46656'),
('p2221', '98445'),
('p5912', '11121'),
('p8035', '22318');

INSERT INTO EQUIPMENT (equipID, name, type, purchaseDate, status) 
VALUES 
('eq523', 'GPU Server 1', 'Computing', '2022-01-15', 'In Use'),
('eq691', 'GPU Server 2', 'Computing', '2022-01-15', 'Available'),
('eq787', 'Robot Arm', 'Robotics', '2023-03-10', 'Available'),
('eq556', 'Microscope', 'Lab Equipment', '2021-06-20', 'Available'),
('eq423', '3D Printer', 'Fabrication', '2023-09-01', 'Available'),
('eq908', 'Oscilloscope', 'Electronics', '2020-11-15', 'Retired');

INSERT INTO USES (memID, equipID, purpose, startDate, endDate) 
VALUES 
('s3321', 'eq523', 'Training ML models', '2024-01-01', '2024-12-31'),
('s4564', 'eq523', 'Quantum simulations', '2024-01-01', '2024-12-31'),
('f1234', 'eq523', 'Model testing', '2024-01-01', '2024-06-30'),
('s6399', 'eq691', 'Data processing', '2024-01-01', '2024-12-31'),
('s1352', 'eq691', 'Simulation runs', '2024-01-01', '2024-12-31'),
('s1352', 'eq787', 'Testing robot algorithms', '2024-02-01', '2024-12-31'),
('f9876', 'eq787', 'Research experiments', '2024-02-01', '2024-12-31'),
('s1352', 'eq423', 'Prototype fabrication', '2024-03-01', '2024-12-31'),
('s3321', 'eq523', 'Previous project work', '2023-01-01', '2023-12-31'),
('s4564', 'eq691', 'Initial experiments', '2023-06-01', '2023-12-31');

INSERT INTO PUBLICATION (pubID, publicationDate, title, venue, month, year, DOI) 
VALUES 
('pb211', '2023-06-15', 'Deep Learning for Medical Diagnosis', 'Nature Medicine', 6, 2023, '10.1038/s41591-023-12345'),
('pb321', '2023-09-20', 'Quantum Algorithms for Optimization', 'Science', 9, 2023, '10.1126/science.abc1234'),
('pb883', '2024-03-10', 'Robotic Control Systems Review', 'IEEE Robotics', 3, 2024, '10.1109/TRO.2024.56789'),
('pb907', '2023-12-01', 'NLP Advances in 2023', 'ACL Conference', 12, 2023, NULL),
('pb089', '2024-01-15', 'Neural Network Optimization Techniques', 'ICML', 1, 2024, '10.5555/icml2024.789');

INSERT INTO AUTHORED_BY (pubID, memID) 
VALUES 
('pb211', 'f1234'),
('pb211', 's3321'),
('pb211', 's6399'),
('pb211', 'e1212'),
('pb321', 'f7788'),
('pb321', 's4564'),
('pb321', 'e9034'),
('pb883', 'f9876'),
('pb883', 's1352'),
('pb883', 'e0036'),
('pb907', 'f5555'),
('pb907', 's1352'),
('pb089', 'f1234'),
('pb089', 's3321'),
('pb089', 's4756');

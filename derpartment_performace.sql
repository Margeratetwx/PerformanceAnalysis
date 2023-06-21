# Part 1: Design/Create Database
DROP DATABASE IF EXISTS kpi;
CREATE DATABASE IF NOT EXISTS kpi; 
USE kpi;

DROP TABLE IF EXISTS project_info,
                     employee,
                     performance,
                     project_progress;
 
CREATE TABLE project_info (
    project_code	CHAR(10)       	NOT NULL,
    project_name	VARCHAR(50)		NOT NULL,
    project_domain	CHAR(1)			NOT NULL,
    PRIMARY KEY (project_code)
);

CREATE TABLE employee (
    emp_id 		INT 			NOT NULL		AUTO_INCREMENT,
    first_name 	VARCHAR(50) 	NOT NULL,
    last_name 	VARCHAR(50) 	NOT NULL,
    gender 		ENUM('M','F') 	NOT NULL,
    hired_date 	DATE 			NOT NULL,
    dept_no 	SMALLINT 		NOT NULL,
    dept_name 	VARCHAR(50) 	NOT NULL,
    PRIMARY KEY (emp_id)
);
    
CREATE TABLE performance (
    project_code 	CHAR(10)					NOT NULL,
    emp_id 			INT 						NOT NULL,
    customer 		VARCHAR(50) 				NOT NULL,
    progress 		ENUM('finished', 'ongoing') NOT NULL,
    project_amt 	INT 						NOT NULL,
    start_date 		DATE 						NOT NULL,
    end_date 		DATE 						NULL			DEFAULT NULL
);

ALTER TABLE performance
ADD FOREIGN KEY (project_code)	REFERENCES project_info (project_code)	ON DELETE CASCADE,
ADD FOREIGN KEY (emp_id)		REFERENCES employee (emp_id)			ON DELETE CASCADE;

# Creating trigger where when progress is updated as 'finished' then end_date will be updated as today automatically
DROP TRIGGER trig_end_date;
DELIMITER //
CREATE TRIGGER trig_end_date
BEFORE UPDATE ON performance FOR EACH ROW
BEGIN 
	IF NEW.progress = 'finished' THEN 
		SET NEW.end_date = sysdate();    
	END IF;
END //
DELIMITER ;

# Testing on trigger
UPDATE performance
SET progress = 'finished'
WHERE project_code = '0728957120';
# Successful

CREATE TABLE project_progress (
    project_code 		CHAR(10) 		NOT NULL,
    progress_detail 	VARCHAR(200) 	NULL,
	PRIMARY KEY (project_code)
);

ALTER TABLE project_progress
ADD FOREIGN KEY (project_code)	REFERENCES project_info (project_code)	ON DELETE CASCADE;

# disable only full group by
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY','')); 
SELECT @@sql_mode;


# Part 2: Department Performance Analysis
# Monthly progress of each employee
SELECT 
	p.project_code, p.emp_id, e.first_name, e.last_name, p.customer, p.progress
    FROM 
    performance p
    JOIN employee e ON e.emp_id = p.emp_id;
	
    # Project done this year
SELECT 
	p.project_code, p.emp_id, e.first_name, e.last_name, p.customer, p.progress
    FROM 
    performance p
    JOIN employee e ON e.emp_id = p.emp_id
    WHERE end_date < sysdate() AND end_date > '2022-12-31';

# which department has the most number of projects
 SELECT 
    e.dept_no, e.dept_name, COUNT(p.progress) AS no_of_project
FROM
    performance p
        JOIN
    employee e ON p.emp_id = e.emp_id
GROUP BY dept_no
ORDER BY dept_no;
 
# which employee has the most number of projects
SELECT 
    e.emp_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    p.progress,
    COUNT(p.progress) AS no_of_project
FROM
    performance p
        JOIN
    employee e ON p.emp_id = e.emp_id
GROUP BY e.emp_id , p.progress
ORDER BY e.emp_id , p.progress;

SELECT 
    e.emp_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    COUNT(p.progress) AS no_of_project
FROM
    performance p
        JOIN
    employee e ON p.emp_id = e.emp_id
GROUP BY emp_id
ORDER BY emp_id;

# which employee has the highest amount of projects
SELECT 
    e.emp_id,  CONCAT(e.first_name, ' ', e.last_name) AS full_name, SUM(project_amt) as total_project_amt
FROM
    performance p
    JOIN employee e ON p.emp_id = e.emp_id
GROUP BY emp_id
ORDER BY emp_id;

# project average time
SELECT 
    *, DATEDIFF(end_date, start_date)/365 as year_diff
FROM
    performance
WHERE
    progress = 'finished';
    
SELECT 
    AVG(a.day_diff) AS avg_day
FROM
    (SELECT 
        *, DATEDIFF(end_date, start_date)/365 AS day_diff
    FROM
        performance
    WHERE
        progress = 'finished') a;

# which project took longest time/take a look at the progress detail
SELECT 
    p.project_code, p.start_date, pp.progress_detail
FROM
    performance p
        JOIN
    project_progress pp ON p.project_code = pp.project_code
WHERE
    progress = 'ongoing' AND start_date < '2020-01-01';

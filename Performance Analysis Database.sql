# Part I : Creating Database
DROP DATABASE IF EXISTS department_performance;
CREATE DATABASE IF NOT EXISTS department_performance; 
USE department_performance;

DROP TABLE IF EXISTS performance,
                     employee,
                     region,
                     customers,
                     companies;

CREATE TABLE performance (
    project_code 	CHAR(10)			NOT NULL,
    emp_id 		INT 				NOT NULL,
    customer_id 	VARCHAR(10) 			NOT NULL,
    progress 		ENUM('finished', 'ongoing') 	NOT NULL,
    project_amt 	INT 				NOT NULL,
    start_date 		DATE 				NOT NULL,
    end_date 		DATE 				NULL			DEFAULT NULL,
    PRIMARY KEY (project_code)
);
# Remember to create all tables before adding foreign key
ALTER TABLE performance
ADD FOREIGN KEY (emp_id)		REFERENCES employee (emp_id)				ON DELETE CASCADE,
ADD FOREIGN KEY (customer_id)		REFERENCES customers (customer_id)			ON DELETE CASCADE;

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

CREATE TABLE employee (
    emp_id 	INT 		NOT NULL		AUTO_INCREMENT,
    first_name 	VARCHAR(50) 	NOT NULL,
    last_name 	VARCHAR(50) 	NOT NULL,
    gender 	ENUM('M','F') 	NOT NULL,
    hired_date 	DATE 		NOT NULL,
    region_id 	INT	 	NOT NULL,
    PRIMARY KEY (emp_id)
);
# Remember to create all tables before adding foreign key
ALTER TABLE employee
ADD FOREIGN KEY (region_id)	REFERENCES region (region_id)	ON DELETE CASCADE;

CREATE TABLE region (
    region_id 	INT 		NOT NULL,
    city 	VARCHAR(50) 	NOT NULL,
    state	VARCHAR(50)	NOT NULL,
    country	VARCHAR(50)	NOT NULL,
	PRIMARY KEY (region_id)
);
    
CREATE TABLE customers (
    customer_id 	VARCHAR(10) 	NOT NULL,
    customer 		VARCHAR(50) 	NOT NULL,
    phone_no 		VARCHAR(50) 	NULL,
    email_add		VARCHAR(50)	UNIQUE,
    company_id		INT		NOT NULL,
	PRIMARY KEY (customer_id)
);
# Remember to create all tables before adding foreign key
ALTER TABLE customers
ADD FOREIGN KEY (company_id)	REFERENCES companies (company_id)	ON DELETE CASCADE;

CREATE TABLE companies (
	company_id	INT		NOT NULL,
    	company_name 	VARCHAR(50)	NOT NULL,
    	hq_phone_no	VARCHAR(50)	NULL,
    	PRIMARY KEY (company_id)
    );

# Testing on trigger trig_end_date
# save
COMMIT;
# Update the progress for P188 project to be "finished"
UPDATE performance
SET progress = 'finished'
WHERE project_code = 'P188';
# Check the end_date to see if it's the current date
SELECT 
    *
FROM
    performance
WHERE
    project_code = 'P188';
# Undo the testing to revert back to original state
ROLLBACK;
# Successful

# disable only full group by
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY','')); 
SELECT @@sql_mode;

		
# Part II : Analyse Data
# Monthly received projects
SELECT 
    CONCAT(YEAR(start_date), '-', MONTH(start_date)) AS YearMonth,
    COUNT(*) AS projects_count
FROM
    performance
GROUP BY YEAR(start_date) , MONTH(start_date)
ORDER BY YEAR(start_date) , MONTH(start_date);
    
# Monthly finished projects
SELECT 
    CONCAT(YEAR(end_date), '-', MONTH(end_date)) AS YearMonth,
    COUNT(*) AS projects_count
FROM
    performance
WHERE
    progress = 'finished'
GROUP BY YEAR(end_date) , MONTH(end_date)
ORDER BY YEAR(end_date) , MONTH(end_date);
	
# Project done this year (2023)
SELECT 
    p.project_code,
    p.emp_id,
    e.first_name,
    e.last_name,
    p.progress,
    p.start_date,
    p.end_date
FROM
    performance p
        JOIN
    employee e ON e.emp_id = p.emp_id
WHERE
    end_date < SYSDATE()
        AND end_date > '2022-12-31';
    
# Number of projects done in this year
SELECT 
    COUNT(project_code) AS Project_done
FROM
    performance p
WHERE
    end_date < SYSDATE()
        AND end_date > '2022-12-31';

# number of projects each employee have taken
 SELECT 
    e.emp_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    COUNT(p.progress) AS no_of_project
FROM
    performance p
        JOIN
    employee e ON p.emp_id = e.emp_id
GROUP BY e.emp_id
ORDER BY no_of_project DESC;
 
# progress of projects for each employee
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

# which employee has the highest amount of projects
SELECT 
    e.emp_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    SUM(project_amt) AS total_project_amt
FROM
    performance p
        JOIN
    employee e ON p.emp_id = e.emp_id
GROUP BY emp_id
ORDER BY total_project_amt DESC
LIMIT 1;

# Time taken for each project to finish
SELECT 
    project_code,
    start_date,
    end_date,
    DATEDIFF(end_date, start_date) AS day_diff
FROM
    performance
WHERE
    progress = 'finished';

# Average time taken for projects to finish
SELECT 
    ROUND(AVG(a.diff), 0) AS avg_day
FROM
    (SELECT 
        *, DATEDIFF(end_date, start_date) AS diff
    FROM
        performance
    WHERE
        progress = 'finished') a;

# which project take more than 6 months to complate and still ongoing
SELECT 
    project_code, start_date
FROM
    performance
WHERE
    progress = 'ongoing'
        AND start_date < '2022-12-31'
GROUP BY project_code
ORDER BY start_date;

# Top 10 Customers
SELECT 
    c.company_name, SUM(p.project_amt) AS total_project_amount
FROM
    companies c
        JOIN
    customers c1 ON c.company_id = c1.company_id
        JOIN
    performance p ON c1.customer_id = p.customer_id
GROUP BY company_name
ORDER BY total_project_amount DESC
LIMIT 10;

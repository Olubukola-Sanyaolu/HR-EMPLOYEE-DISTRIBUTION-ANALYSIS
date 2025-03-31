CREATE TABLE HR(
id VARCHAR,
first_name VARCHAR,
last_name VARCHAR,
birth_date DATE,
gender	VARCHAR,
race	VARCHAR,
department	VARCHAR,
job_title VARCHAR,
location VARCHAR,
hire_date VARCHAR,
term_date DATE,
location_city VARCHAR,
location_state VARCHAR

)
SELECT * FROM HR

--CHANGE HIRE  DATE TO DATE FORMAT

ALTER TABLE HR
ALTER COLUMN hire_date TYPE DATE 
USING hire_date::DATE;

--the terminated date (Term_date)shows null for thsoe that aint terminated yet,
--so we want to replace it with 9999-12-31(a common placeholder for "Active")
--and then changing the colunm name to term_date_replacement

SELECT *, 
       COALESCE(term_date, '9999-12-31') AS term_date_replacement
FROM hr;

--Since we want to create another table with the new data from the one above as hrr

CREATE TABLE HRR AS 
SELECT *, 
       COALESCE(term_date, '9999-12-31') AS term_date_replacement
FROM hr;

--so lets drop the intial colunm(term_date) since we have a new column which is term_date_replacement

ALTER TABLE hrr
DROP COLUMN term_date;

--Lets select the new table hrr

SELECT * FROM hrr

--Lets add anew column which is Age

ALTER TABLE hrr ADD COLUMN Age int;

--To calculate our age ,since we have create our age column

UPDATE hrr 
SET Age = EXTRACT(YEAR FROM AGE(birth_date));


--Note,ur age column is showing negative due to some birthdate that are in the future,so lets eradicate the negative age

SELECT id, birth_date, 
       CASE 
           WHEN birth_date > CURRENT_DATE THEN NULL  -- Handles future birthdates
           ELSE EXTRACT(YEAR FROM AGE(birth_date)) 
       END AS age
FROM hrr;

--Lets prevent the negative age from being stored

UPDATE hrr 
SET age = CASE 
             WHEN birth_date > CURRENT_DATE THEN NULL
             ELSE EXTRACT(YEAR FROM AGE(birth_date)) 
          END;



SELECT AGE FROM HRR

--some of the rows are showing null because they are calualated in the future,so let remove the null and replace with 0

UPDATE hrr
SET age = COALESCE(age, 0);

SELECT * FROM HRR

--Lets check for the min and max age

SELECT MAX(AGE ) FROM HRR

--Lets check for the min age,
--but note that we change the null values in the age column to 0,
--so it will want to return the min age to 0,which will be incorrect
--so we say where age is > 0

SELECT MIN(age) 
FROM HRR 
WHERE age > 0;

SELECT * FROM hrr


                  --QUESTIONS

--1. What is the gender breakdown of employees in the company
--NOTE ,OUR MIN AGE IS 22

SELECT GENDER, Count(gender) AS COUNT
FROM HRR
WHERE AGE >=22
AND Term_date_replacement='9999-12-31'
GROUP BY GENDER

--2.What is the breakdown of employees in the company

SELECT RACE, COUNT(RACE) AS COUNT
FROM HRR
WHERE AGE >=22
AND Term_date_replacement='9999-12-31'
GROUP BY RACE
ORDER BY COUNT DESC

--3.What is the age distribution of employees in the company


SELECT MIN(AGE) AS YOUNGEST,MAX(AGE) AS OLDEST
FROM HRR
WHERE AGE >=22
AND Term_date_replacement='9999-12-31'

--AGE GROUP
SELECT 
    CASE
	  WHEN AGE >=22 AND AGE <=28 THEN '22-28'
	  WHEN AGE >=29 AND AGE <=38 THEN '29-38'
	  WHEN AGE >=39 AND AGE <=48 THEN '39-48'
	  WHEN AGE >=49 AND AGE <=58 THEN '49-58'
	  WHEN AGE >=59 AND AGE <=68 THEN '59-68'
	  ELSE '69+'
	END AS AGE_GROUP,
	COUNT(*) AS COUNT
FROM HRR 
WHERE AGE >=22
AND Term_date_replacement='9999-12-31'
GROUP BY AGE_GROUP
ORDER BY AGE_GROUP

	
--AGE GROUP GENDER
SELECT 
    CASE
        WHEN AGE BETWEEN 22 AND 28 THEN '22-28'
        WHEN AGE BETWEEN 29 AND 38 THEN '29-38'
        WHEN AGE BETWEEN 39 AND 48 THEN '39-48'
        WHEN AGE BETWEEN 49 AND 58 THEN '49-58'
        WHEN AGE BETWEEN 59 AND 68 THEN '59-68'
        ELSE '69+'
    END AS AGE_GROUP,
    GENDER,
    COUNT(*) AS COUNT
FROM HRR 
WHERE AGE >= 22
AND Term_date_replacement = '9999-12-31'
GROUP BY 
    CASE
        WHEN AGE BETWEEN 22 AND 28 THEN '22-28'
        WHEN AGE BETWEEN 29 AND 38 THEN '29-38'
        WHEN AGE BETWEEN 39 AND 48 THEN '39-48'
        WHEN AGE BETWEEN 49 AND 58 THEN '49-58'
        WHEN AGE BETWEEN 59 AND 68 THEN '59-68'
        ELSE '69+'
    END,
    GENDER
ORDER BY AGE_GROUP, GENDER;

--4. How amny employee works at headquaters versus remote location
SELECT LOCATION,Count(*) as COUNT
FROM HRR
WHERE AGE>=22 
AND Term_date_replacement='9999-12-31'
GROUP BY LOCATION


--5. What is the average length of employment for employees who has been terminated

SELECT 
    ROUND(AVG((TERM_DATE_REPLACEMENT - HIRE_DATE)) / 365,0) AS avg_length_employment
FROM HRR
WHERE 
    TERM_DATE_REPLACEMENT <= CURRENT_DATE
    AND TERM_DATE_REPLACEMENT <> '9999-12-31'::DATE
    AND AGE >= 22;

--THE AVEG YEAR IS 7.6,SO MOST OF THE WORK FOR ATLEAST 8YEARS BY ROUNDING IT UP

--6. How does the gender ditributiom vary across the department and job title

SELECT DEPARTMENT ,GENDER ,Count(*) AS COUNT
FROM HRR
WHERE AGE >=22
AND Term_date_replacement='9999-12-31'
GROUP BY DEPARTMENT,GENDER
ORDER BY DEPARTMENT


--7.What is the distribution of job title across the company

SELECT JOB_TITLE,count(*) AS COUNT
FROM HRR
WHERE AGE >=22
AND Term_date_replacement='9999-12-31'
GROUP BY JOB_TITLE
ORDER BY JOB_TITLE DESC

--8.Which department has the highest turn over rate

SELECT 
    DEPARTMENT, 
    TOTAL_COUNT, 
    TERMINATED_COUNT, 
    (TERMINATED_COUNT::FLOAT / TOTAL_COUNT) AS TERMINATION_RATE
FROM (
    SELECT 
        DEPARTMENT, 
        COUNT(*) AS TOTAL_COUNT,
        SUM(CASE 
            WHEN TERM_DATE_REPLACEMENT <> '9999-12-31' 
                 AND TERM_DATE_REPLACEMENT <= CURRENT_DATE 
            THEN 1 
            ELSE 0 
        END) AS TERMINATED_COUNT
    FROM HRR
    WHERE AGE >= 22
    GROUP BY DEPARTMENT
) AS SUB_QUERY
ORDER BY TERMINATION_RATE DESC;


--9. What is the distribution of employees across loactions by city and states

SELECT LOCATION_STATE,count(*) as COUNT
FROM HRR
WHERE AGE >=22 AND Term_date_replacement='9999-12-31'
GROUP BY LOCATION_STATE
ORDER BY COUNT DESC

--10.How has the companys employee count changed over time based on hire date and term_date
SELECT 
    YEAR, 
    HIRES, 
    TERMINATIONS, 
    HIRES - TERMINATIONS AS NET_CHANGE, 
    ROUND(((HIRES - TERMINATIONS) * 100.0 / HIRES)::NUMERIC, 2) AS NET_CHANGE_PERCENTAGE
FROM (
    SELECT 
        EXTRACT(YEAR FROM HIRE_DATE) AS YEAR, 
        COUNT(*) AS HIRES, 
        SUM(CASE 
                WHEN TERM_DATE_REPLACEMENT <> '9999-12-31' 
                     AND TERM_DATE_REPLACEMENT <= CURRENT_DATE 
                THEN 1 
                ELSE 0 
            END) AS TERMINATIONS
    FROM HRR
    WHERE AGE >= 18
    GROUP BY EXTRACT(YEAR FROM HIRE_DATE)
) AS SUBQUERY
ORDER BY YEAR ASC;


--11.What is the tenure distribution for each department

SELECT 
    DEPARTMENT, 
    ROUND(AVG(EXTRACT(YEAR FROM AGE(TERM_DATE_REPLACEMENT, HIRE_DATE))), 0) AS AVG_TENURE
FROM HRR
WHERE 
    TERM_DATE_REPLACEMENT <= CURRENT_DATE
    AND TERM_DATE_REPLACEMENT <> '9999-12-31'
    AND AGE >= 22
GROUP BY DEPARTMENT;


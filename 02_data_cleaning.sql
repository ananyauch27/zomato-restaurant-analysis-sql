USE zomato_db;

-- Null / blank profiling 
SELECT
    SUM(RestaurantName IS NULL OR TRIM(RestaurantName) = '') AS blank_name,
    SUM(City IS NULL OR TRIM(City) = '') AS blank_city,
    SUM(Locality IS NULL OR TRIM(Locality) = '') AS blank_locality,
    SUM(Cuisines IS NULL OR TRIM(Cuisines) = '') AS blank_cuisines,
    SUM(Rating IS NULL) AS null_rating
FROM zomatodata;

-- Duplicate check
SELECT RestaurantID, COUNT(*) AS cnt
FROM zomatodata
GROUP BY RestaurantID
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- If duplicates exist, keep one row per RestaurantID
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY RestaurantID ORDER BY Votes DESC) AS rn
    FROM zomatodata
) t
WHERE rn = 1;

SELECT *
FROM zomatodata
WHERE CountryCode NOT IN (SELECT country_code FROM zomato_country);



-- Add Country Name 
ALTER TABLE zomatodata ADD COLUMN COUNTRY_NAME VARCHAR(50);
 
SELECT * FROM zomatodata;

UPDATE zomatodata A
JOIN zomato_country B ON A.CountryCode = B.country_code
SET A.COUNTRY_NAME = B.country;

SELECT * FROM zomatodata;
-- Verify no row was left unmapped
SELECT COUNT(*) AS unmapped FROM zomatodata WHERE COUNTRY_NAME IS NULL;

-- Clean City 
-- Misspelled characters like 'Bras?lia'
SELECT DISTINCT City FROM zomatodata WHERE City LIKE '%?%';

UPDATE zomatodata
SET City = REPLACE(City, '?', 'i')
WHERE City LIKE '%?%';

UPDATE zomatodata SET City = TRIM(City), Locality = TRIM(Locality);

-- Drop columns not needed for analysis 
-- ALTER TABLE zomatodata DROP COLUMN Address;
-- ALTER TABLE zomatodata DROP COLUMN LocalityVerbose;
-- ALTER TABLE zomatodata DROP COLUMN Switch_to_order_menu;   -- single value only

-- Cuisines: handle blanks
UPDATE zomatodata
SET Cuisines = 'Not Specified'
WHERE Cuisines IS NULL OR TRIM(Cuisines) = '';


-- Standardise Yes/No columns
SELECT DISTINCT Has_Table_booking, Has_Online_delivery, Is_delivering_now FROM zomatodata;

UPDATE zomatodata
SET Has_Table_booking   = UPPER(Has_Table_booking),
    Has_Online_delivery = UPPER(Has_Online_delivery),
    Is_delivering_now   = UPPER(Is_delivering_now);

-- Fix data types 
ALTER TABLE zomatodata MODIFY COLUMN Votes INT;
ALTER TABLE zomatodata MODIFY COLUMN Average_Cost_for_two FLOAT;
ALTER TABLE zomatodata MODIFY COLUMN Rating DECIMAL(3,1);

--  Range validation 
SELECT MIN(Votes) AS min_votes, ROUND(AVG(Votes)) AS avg_votes, MAX(Votes) AS max_votes
FROM zomatodata;

SELECT Currency,
       MIN(Average_Cost_for_two) AS min_cost,
       ROUND(AVG(Average_Cost_for_two)) AS avg_cost,
       MAX(Average_Cost_for_two) AS max_cost
FROM zomatodata
GROUP BY Currency;

SELECT MIN(Rating) AS min_rating, ROUND(AVG(Rating),1) AS avg_rating, MAX(Rating) AS max_rating
FROM zomatodata;

SELECT DISTINCT Price_range FROM zomatodata ORDER BY 1;

SELECT COUNT(*) AS final_rows FROM zomatodata;
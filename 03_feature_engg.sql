USE zomato_db;

-- Rating category 
ALTER TABLE zomatodata ADD COLUMN RATE_CATEGORY VARCHAR(20);

UPDATE zomatodata
SET RATE_CATEGORY =
    CASE
        WHEN Rating = 0                      THEN 'NOT RATED'
        WHEN Rating >= 1   AND Rating < 2.5  THEN 'POOR'
        WHEN Rating >= 2.5 AND Rating < 3.5  THEN 'GOOD'
        WHEN Rating >= 3.5 AND Rating < 4.5  THEN 'GREAT'
        WHEN Rating >= 4.5                   THEN 'EXCELLENT'
    END;
    
SELECT * FROM zomatodata;

-- Price category (India)
ALTER TABLE zomatodata ADD COLUMN PRICE_CATEGORY VARCHAR(30);

UPDATE zomatodata
SET PRICE_CATEGORY =
    CASE
        WHEN Average_Cost_for_two < 300   THEN 'Budget (<300)'
        WHEN Average_Cost_for_two < 700   THEN 'Mid (300-699)'
        WHEN Average_Cost_for_two < 1500  THEN 'Premium (700-1499)'
        ELSE 'Fine Dining (1500+)'
    END
WHERE CountryCode = 1;

SELECT * FROM zomatodata;

-- Split multi-valued Cuisines into a bridge table 
-- 'North Indian, Chinese' becomes 2 rows
DROP TABLE IF EXISTS restaurant_cuisines;

CREATE TABLE restaurant_cuisines AS
WITH RECURSIVE split AS (
    SELECT RestaurantID,
           TRIM(SUBSTRING_INDEX(Cuisines, ',', 1)) cuisine,
           SUBSTRING(Cuisines, LOCATE(',', Cuisines) + 1) rest
    FROM zomatodata

    UNION ALL

    SELECT RestaurantID,
           TRIM(SUBSTRING_INDEX(rest, ',', 1)),
           SUBSTRING(rest, LOCATE(',', rest) + 1)
    FROM split
    WHERE rest LIKE '%,%'
)
SELECT RestaurantID, cuisine
FROM split;

SELECT cuisine, COUNT(*) FROM restaurant_cuisines GROUP BY cuisine ORDER BY 2 DESC LIMIT 10;
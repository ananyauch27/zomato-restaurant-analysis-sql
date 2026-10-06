USE zomato_db;

-- Dataset overview
SELECT COUNT(*) AS total_restaurants,
       COUNT(DISTINCT COUNTRY_NAME) AS countries,
       COUNT(DISTINCT City) AS cities,
       COUNT(DISTINCT Locality) AS localities
FROM zomatodata;

-- Rating distribution (India)
SELECT Rating, COUNT(*) AS cnt
FROM zomatodata
WHERE CountryCode = 1
GROUP BY Rating
ORDER BY Rating;

-- Rating category distribution
SELECT RATE_CATEGORY, COUNT(*) AS cnt,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM zomatodata
GROUP BY RATE_CATEGORY
ORDER BY cnt DESC;

-- Restaurants per city per country  
SELECT COUNTRY_NAME, City, COUNT(*) AS total_rest
FROM zomatodata
GROUP BY COUNTRY_NAME, City
ORDER BY COUNTRY_NAME, total_rest DESC;

-- Currency usage
SELECT Currency, COUNT(*) AS cnt FROM zomatodata GROUP BY Currency ORDER BY cnt DESC;

-- Service availability
SELECT Has_Table_booking, COUNT(*) FROM zomatodata GROUP BY 1;
SELECT Has_Online_delivery, COUNT(*) FROM zomatodata GROUP BY 1;
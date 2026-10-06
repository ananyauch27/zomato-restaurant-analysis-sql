USE zomato_db;
-- A. MARKET OVERVIEW

-- Q1. What share of all listed restaurants does each country hold?
SELECT COUNTRY_NAME,
       COUNT(*) AS rest_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_share
FROM zomatodata
GROUP BY COUNTRY_NAME
ORDER BY rest_count DESC;
-- (Window function replaces your CROSS JOIN + 4 versions of the view.)
-- Q2. Top 10 Indian cities by number of restaurants
SELECT City, COUNT(*) AS total_rest
FROM zomatodata
WHERE COUNTRY_NAME = 'India'
GROUP BY City
ORDER BY total_rest DESC
LIMIT 10;

-- B. LOCALITY ANALYSIS (India)

-- Q3. Rolling count of restaurants by locality within each city  
SELECT City, Locality,
       COUNT(*) AS rest_count,
       SUM(COUNT(*)) OVER (PARTITION BY City ORDER BY Locality) AS rolling_count
FROM zomatodata
WHERE COUNTRY_NAME = 'India'
GROUP BY City, Locality
ORDER BY City, Locality;

-- Q4. Which city and locality has the most restaurants?
WITH loc AS (
    SELECT City, Locality, COUNT(*) AS rest_count
    FROM zomatodata
    WHERE COUNTRY_NAME = 'India'
    GROUP BY City, Locality
)
SELECT * FROM loc
WHERE rest_count = (SELECT MAX(rest_count) FROM loc);

-- Q5. Which localities have the fewest listings?
WITH loc AS (
    SELECT City, Locality, COUNT(*) AS rest_count
    FROM zomatodata
    WHERE COUNTRY_NAME = 'India'
    GROUP BY City, Locality
)
SELECT * FROM loc
WHERE rest_count = (SELECT MIN(rest_count) FROM loc)
ORDER BY City;

-- Q6. Top 5 localities per city by restaurant count (window function)
WITH loc AS (
    SELECT City, Locality, COUNT(*) AS rest_count,
           DENSE_RANK() OVER (PARTITION BY City ORDER BY COUNT(*) DESC) AS rnk
    FROM zomatodata
    WHERE COUNTRY_NAME = 'India'
    GROUP BY City, Locality
)
SELECT * FROM loc WHERE rnk <= 5 ORDER BY City, rnk;

-- C. SERVICE AVAILABILITY

-- Q7. Online delivery penetration by country
SELECT COUNTRY_NAME,
       COUNT(*) AS total_rest,
       SUM(Has_Online_delivery = 'YES') AS online_delivery_rest,
       ROUND(SUM(Has_Online_delivery = 'YES') * 100.0 / COUNT(*), 2) AS online_delivery_pct
FROM zomatodata
GROUP BY COUNTRY_NAME
ORDER BY online_delivery_pct DESC;

-- Q8. Table booking vs no table booking: rating impact (India, all cities)
SELECT City,
       ROUND(AVG(CASE WHEN Has_Table_booking = 'YES' THEN Rating END), 2) AS avg_rating_with_booking,
       ROUND(AVG(CASE WHEN Has_Table_booking = 'NO'  THEN Rating END), 2) AS avg_rating_without_booking
FROM zomatodata
WHERE COUNTRY_NAME = 'India' AND Rating > 0
GROUP BY City
HAVING COUNT(*) > 50
ORDER BY City;

-- Q9. Does online delivery relate to higher votes?
SELECT Has_Online_delivery,
       COUNT(*) AS restaurants,
       ROUND(AVG(Votes)) AS avg_votes,
       ROUND(AVG(Rating), 2) AS avg_rating
FROM zomatodata
WHERE COUNTRY_NAME = 'India' AND Rating > 0
GROUP BY Has_Online_delivery;


-- D. CUISINE ANALYSIS

-- Q10. Most popular cuisines in India
SELECT rc.cuisine, COUNT(*) AS restaurants
FROM restaurant_cuisines rc
JOIN zomatodata z ON z.RestaurantID = rc.RestaurantID
WHERE z.COUNTRY_NAME = 'India'
GROUP BY rc.cuisine
ORDER BY restaurants DESC
LIMIT 10;

-- Q11. Cuisines in the locality with the most restaurants  <- your query, fixed to join on City too
SELECT rc.cuisine, COUNT(*) AS restaurants
FROM zomatodata z
JOIN restaurant_cuisines rc ON z.RestaurantID = rc.RestaurantID
WHERE z.Country_NAME = 'India'
  AND (z.City, z.Locality) = (
      SELECT City, Locality
      FROM zomatodata
      WHERE COUNTRY_NAME = 'India'
      GROUP BY City, Locality
      ORDER BY COUNT(*) DESC
      LIMIT 1
  )
GROUP BY rc.cuisine
ORDER BY restaurants DESC;

-- Q12. Highest-rated cuisines (at least 50 restaurants, to avoid small-sample bias)
SELECT rc.cuisine,
       COUNT(*) AS restaurants,
       ROUND(AVG(z.Rating), 2) AS avg_rating
FROM zomatodata z
JOIN restaurant_cuisines rc ON z.RestaurantID = rc.RestaurantID
WHERE z.COUNTRY_NAME = 'India' AND z.Rating > 0
GROUP BY rc.cuisine
HAVING COUNT(*) >= 50
ORDER BY avg_rating DESC
LIMIT 10;


-- E. PRICE AND VALUE ANALYSIS

-- Q13. Price category vs average rating  <- your query
SELECT PRICE_CATEGORY,
       COUNT(*) AS restaurant_count,
       ROUND(AVG(Rating), 2) AS avg_rating,
       ROUND(AVG(Votes))     AS avg_votes
FROM zomatodata
WHERE CountryCode = 1 AND Rating > 0
GROUP BY PRICE_CATEGORY
ORDER BY avg_rating DESC;

-- Q14. Best-value restaurants (high rating, low cost, high votes)  <- your query
SELECT RestaurantName, City, Cuisines, Average_Cost_for_two, Rating, Votes
FROM zomatodata
WHERE CountryCode = 1
  AND Rating >= 4.0
  AND Average_Cost_for_two <= 500
  AND Votes >= 200
ORDER BY Rating DESC, Votes DESC
LIMIT 20;

-- Q15. Best moderate-cost Indian restaurants with table booking + delivery  <- your query, cleaned
SELECT RestaurantName, City, Locality, Average_Cost_for_two, Rating, Votes
FROM zomatodata
WHERE COUNTRY_NAME = 'India'
  AND Has_Table_booking = 'YES'
  AND Has_Online_delivery = 'YES'
  AND Price_range <= 3
  AND Votes > 1000
  AND Average_Cost_for_two < 1000
  AND Rating > 4
  AND Cuisines LIKE '%Indian%'
ORDER BY Rating DESC, Votes DESC;

-- Q16. High-rated (4.5+) restaurants with table booking, by price range  
SELECT Price_range, COUNT(*) AS no_of_rest
FROM zomatodata
WHERE Rating >= 4.5 AND Has_Table_booking = 'YES'
GROUP BY Price_range
ORDER BY Price_range;

-- =====================================================
-- F. RATINGS AND VOTES (advanced)
-- =====================================================

-- Q17. Top 3 restaurants in every Indian city 
SELECT City, RestaurantName, Rating, Votes
FROM (
    SELECT City, RestaurantName, Rating, Votes,
           ROW_NUMBER() OVER (
               PARTITION BY City
               ORDER BY Rating DESC, Votes DESC
           ) rn
    FROM zomatodata
    WHERE COUNTRY_NAME = 'India' AND Votes >= 100
) x
WHERE rn <= 3
ORDER BY City, rn;

-- Q18. Hidden gems: rating at or above 4.3 but fewer than 100 votes
SELECT RestaurantName, City, Cuisines, Rating, Votes
FROM zomatodata
WHERE COUNTRY_NAME = 'India' AND Rating >= 4.3 AND Votes < 100
ORDER BY Rating DESC;


-- Q19. Popular but poorly rated: lots of votes, rating below 3
SELECT RestaurantName, City, Rating, Votes
FROM zomatodata
WHERE COUNTRY_NAME = 'India' AND Rating BETWEEN 1 AND 2.9 AND Votes > 500
ORDER BY Votes DESC;

-- Q20. Restaurants rated above their city's average
WITH city_avg AS (
    SELECT City, AVG(Rating) AS city_avg_rating
    FROM zomatodata
    WHERE COUNTRY_NAME = 'India' AND Rating > 0
    GROUP BY City
)
SELECT z.RestaurantName, z.City, z.Rating, ROUND(c.city_avg_rating, 2) AS city_avg
FROM zomatodata z
JOIN city_avg c ON z.City = c.City
WHERE z.COUNTRY_NAME = 'India' AND z.Rating > c.city_avg_rating + 1
ORDER BY z.Rating DESC;

-- Q21. Divide restaurants into quartiles by votes (NTILE)
SELECT RestaurantName, Votes,
       NTILE(4) OVER (ORDER BY Votes DESC) AS popularity_quartile
FROM zomatodata
WHERE COUNTRY_NAME = 'India';

-- Q22. Average rating by price_range and table booking
SELECT Price_range, Has_Table_booking,
       COUNT(*) AS restaurants,
       ROUND(AVG(Rating), 2) AS avg_rating
FROM zomatodata
WHERE COUNTRY_NAME = 'India' AND Rating > 0
GROUP BY Price_range, Has_Table_booking
ORDER BY Price_range, Has_Table_booking;
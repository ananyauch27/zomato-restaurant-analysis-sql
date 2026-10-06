USE zomato_db;

-- Master view: one clean row per restaurant
CREATE OR REPLACE VIEW vw_restaurant_master AS
SELECT RestaurantID, RestaurantName, COUNTRY_NAME, City, Locality, Cuisines, Currency,
       Has_Table_booking, Has_Online_delivery, Is_delivering_now,
       Price_range, PRICE_CATEGORY, Average_Cost_for_two, Votes, Rating, RATE_CATEGORY
FROM zomatodata;

-- Country summary
CREATE OR REPLACE VIEW vw_country_summary AS
SELECT COUNTRY_NAME,
       COUNT(*) AS total_restaurants,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_share,
       ROUND(AVG(NULLIF(Rating, 0)), 2) AS avg_rating,
       ROUND(SUM(Has_Online_delivery = 'YES') * 100.0 / COUNT(*), 2) AS online_delivery_pct,
       ROUND(SUM(Has_Table_booking = 'YES') * 100.0 / COUNT(*), 2) AS table_booking_pct
FROM zomatodata
GROUP BY COUNTRY_NAME;

-- City summary
CREATE OR REPLACE VIEW vw_city_summary AS
SELECT COUNTRY_NAME, City,
       COUNT(*) AS total_restaurants,
       ROUND(AVG(NULLIF(Rating, 0)), 2) AS avg_rating,
       ROUND(AVG(Votes)) AS avg_votes
FROM zomatodata
GROUP BY COUNTRY_NAME, City;

-- Cuisine summary (uses the bridge table)
CREATE OR REPLACE VIEW vw_cuisine_summary AS
SELECT z.COUNTRY_NAME, rc.cuisine,
       COUNT(*) AS restaurants,
       ROUND(AVG(NULLIF(z.Rating, 0)), 2) AS avg_rating
FROM zomatodata z
JOIN restaurant_cuisines rc ON z.RestaurantID = rc.RestaurantID
GROUP BY z.COUNTRY_NAME, rc.cuisine;

-- Locality summary
CREATE OR REPLACE VIEW vw_locality_summary AS
SELECT COUNTRY_NAME, City, Locality,
       COUNT(*) AS total_restaurants,
       ROUND(AVG(NULLIF(Rating, 0)), 2) AS avg_rating
FROM zomatodata
GROUP BY COUNTRY_NAME, City, Locality;

-- Fact table
CREATE OR REPLACE VIEW fact_restaurant AS
SELECT RestaurantID, RestaurantName, COUNTRY_NAME, City, Locality,
       Cuisines, Currency, Has_Table_booking, Has_Online_delivery,
       Is_delivering_now, Price_range, PRICE_CATEGORY,
       Average_Cost_for_two, Votes, Rating, RATE_CATEGORY
FROM zomatodata;

-- Geography dimension
CREATE OR REPLACE VIEW dim_geography AS
SELECT DISTINCT COUNTRY_NAME, City, Locality FROM zomatodata;

-- Cuisine dimension and bridge
CREATE OR REPLACE VIEW dim_cuisine AS
SELECT DISTINCT cuisine FROM restaurant_cuisines;

CREATE OR REPLACE VIEW bridge_cuisine AS
SELECT RestaurantID, cuisine FROM restaurant_cuisines;

-- Rating category dimension WITH sort order (so charts don't sort alphabetically)
CREATE OR REPLACE VIEW dim_rating_category AS
SELECT 'EXCELLENT' AS RATE_CATEGORY, 1 AS sort_order, '4.5 - 5.0' AS rating_band UNION ALL
SELECT 'GREAT', 2, '3.5 - 4.4' UNION ALL
SELECT 'GOOD', 3, '2.5 - 3.4' UNION ALL
SELECT 'POOR', 4, '1.0 - 2.4' UNION ALL
SELECT 'NOT RATED', 5, '0';

-- Price category dimension with sort order
CREATE OR REPLACE VIEW dim_price_category AS
SELECT 'Budget (<300)' AS PRICE_CATEGORY, 1 AS sort_order UNION ALL
SELECT 'Mid (300-699)', 2 UNION ALL
SELECT 'Premium (700-1499)', 3 UNION ALL
SELECT 'Fine Dining (1500+)', 4;

-- Data quality summary, powers the "About the Data" page
CREATE OR REPLACE VIEW vw_data_quality AS
SELECT 'Total rows (raw backup)'        AS metric, COUNT(*) AS value FROM zomatodata_backup
UNION ALL SELECT 'Total rows (cleaned)',             COUNT(*) FROM zomatodata
UNION ALL SELECT 'Rows removed',
       (SELECT COUNT(*) FROM zomatodata_backup) - (SELECT COUNT(*) FROM zomatodata)
UNION ALL SELECT 'Unrated restaurants (Rating = 0)', SUM(Rating = 0) FROM zomatodata
UNION ALL SELECT 'Blank cuisines replaced',          SUM(Cuisines = 'Not Specified') FROM zomatodata
UNION ALL SELECT 'Countries',                        COUNT(DISTINCT COUNTRY_NAME) FROM zomatodata
UNION ALL SELECT 'Cities',                           COUNT(DISTINCT City) FROM zomatodata
UNION ALL SELECT 'Localities',                       COUNT(DISTINCT Locality) FROM zomatodata;
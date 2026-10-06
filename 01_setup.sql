CREATE DATABASE IF NOT EXISTS zomato_db;

SELECT DATABASE();
DESCRIBE zomatodata;

SELECT COUNT(*) AS TOTAL_ROWS
FROM zomatodata;

-- Row-count sanity check after import
SELECT COUNT(*) AS total_rows FROM zomatodata;
SELECT * FROM zomato_country;

CREATE TABLE IF NOT EXISTS zomatodata_backup AS
SELECT * FROM zomatodata;

SELECT COUNT(*) AS BACKUP_ROWS
FROM zomatodata_backup;







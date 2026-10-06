# Zomato Restaurant Analysis 

End-to-end SQL project: cleaning a multi-country Zomato restaurant dataset and analysing market share, localities, cuisines, pricing, ratings and services

## Dataset Source: kaggle.com/datasets/shrutimehta/zomato-restaurants-data

## Business Questions
- Which countries, cities and localities have the most restaurants?
- Which cuisines are most popular and which rate highest?
- Do table booking and online delivery relate to better ratings?
- How do price categories relate to ratings and votes?
- Which restaurants are best value, hidden gems, or popular but poorly rated?

## Tools and Skills
MySQL 8.0, MySQL Workbench | Joins, UPDATE with JOIN, CTEs, recursive CTE, window functions (RANK, DENSE_RANK, ROW_NUMBER, NTILE), views, CASE, aggregation

## Workflow
Raw data → Import → Backup → Cleaning → Feature engineering → EDA → Business analysis → Views

## Data Cleaning
- Created backup table before any changes
- Checked duplicates on `RestaurantID`
- Removed corrupted rows
- Added `COUNTRY_NAME` using UPDATE with JOIN
- Fixed corrupted characters in `City`
- Replaced blank cuisines with `Not Specified`
- Converted data types (Votes, Cost, Rating)
- Dropped unneeded columns (Address, LocalityVerbose, Switch_to_order_menu)

## Key Insights
- [Country] holds [X]% of all listings
- [City] has the most restaurants; [Locality] is its densest hub
- Table booking avg rating: [X] vs [Y] without
- [Price category] has the highest average rating
- [N] hidden gems (rating 4.3+ with under 100 votes)

## How to Run
1. Import the CSVs into a MySQL schema named `zomato_db`
2. Run the scripts in numeric order

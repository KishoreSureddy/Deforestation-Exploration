1. Global Situation
-- Created view for Forestation by adding a % of land to forest column
DROP VIEW IF EXISTS forestation;
CREATE VIEW forestation AS (
      SELECT 
       r.country_code AS country_code,
  	 r.country_name AS country_name,
  	 r.region AS region,
  	 f.year AS year,
   	 ROUND(f.forest_area_sqkm :: NUMERIC,2) AS forest_area,
  	 ROUND((l.total_area_sq_mi * 2.59) :: NUMERIC,2) AS total_area,
  	 ROUND((SUM(f.forest_area_sqkm) * 100 / SUM(l.total_area_sq_mi * 2.59)) :: NUMERIC, 2) AS percent_forest_to_total_area,
  	 r.income_group AS income_group
      FROM regions r
      JOIN forest_area f
            ON f.country_code = r.country_code
      JOIN land_area l
  	      ON r.country_code = l.country_code
  	      AND f.country_code = l.country_code
  	      AND l.year = f.year
      GROUP BY 1,2,3,4,5,6,7,8);


-- Total Forest Area of the World in the year 1990
SELECT 
      forest_area forest_area_1990
FROM  forestation
WHERE year = 1990
	AND country_name = 'World';


-- Total Forest Area of the world in the year 2016
SELECT 
      forest_area forest_area_2016
FROM  forestation
WHERE year = 2016
      AND country_name = 'World';

-- Total loss of forest area as on 2016 using WITH clause
WITH forest_area_1990 AS (
      SELECT 
            forest_area forest_area_1990
      FROM  forestation
      WHERE year = 1990 
            AND country_name = 'World'),
     forest_area_2016 AS (
      SELECT 
            forest_area forest_area_2016
      FROM  forestation
      WHERE year = 2016
            AND country_name = 'World')
SELECT (forest_area_1990 - forest_area_2016) AS loss_of_forest_area
FROM forest_area_1990,forest_area_2016;


-- Total loss of forest area from 1990 to 2016 in percentage
WITH forest_area_1990 AS (
      SELECT 
            forest_area forest_area_1990
      FROM  forestation
      WHERE year = 1990 
            AND country_name = 'World'),
     forest_area_2016 AS (
      SELECT 
            forest_area forest_area_2016
      FROM  forestation
      WHERE year = 2016
            AND country_name = 'World')
SELECT ROUND((forest_area_1990 - forest_area_2016)*100/forest_area_1990 :: NUMERIC, 2) AS percent_loss_of_forest_area
FROM   forest_area_1990,forest_area_2016;

-- The lost area of forest is equal to the total land area of country
SELECT 
	country_name, 
	total_area
FROM  forestation
WHERE year = 2016 
	AND total_area <= 1324449.00
GROUP BY 1,2
ORDER BY total_area DESC
LIMIT 1;



2. Regional Outlook

-- Total % of forest to land area in 2016
SELECT
     region,
     ROUND((SUM(forest_area) *100/SUM(total_area)) :: NUMERIC,2) percent_of_2016
FROM forestation
WHERE year = 2016
      AND percent_forest_to_total_area IS NOT NULL
GROUP BY year, 1;


-- Total % of forest to land in the year 1990
SELECT
     region,
     ROUND((SUM(forest_area) *100/SUM(total_area)) :: NUMERIC,2) percent_of_1990
FROM forestation
WHERE year = 1990
GROUP BY year, 1
ORDER BY percent_of_1990 DESC;


-- Using the WITH clause showing the differences of forest arae percentages from 1990 to 2016 
WITH forest_percent_1990 AS (
     SELECT
            region,
            ROUND((SUM(forest_area) *100/SUM(total_area)) :: NUMERIC,2) percent_of_1990
      FROM forestation
      WHERE year = 1990
      GROUP BY year, 1
      ORDER BY percent_of_1990 DESC),
      forest_percent_2016 AS (
      SELECT
            region,
            ROUND((SUM(forest_area) *100/SUM(total_area)) :: NUMERIC,2) percent_of_2016
      FROM forestation
      WHERE year = 2016
      AND percent_forest_to_total_area IS NOT NULL
      GROUP BY year, 1)
SELECT
      fp1990.region,
      percent_of_1990,
      percent_of_2016,
      (percent_of_1990 - percent_of_2016) AS difference
FROM  forest_percent_1990 fp1990
JOIN  forest_percent_2016 fp2016
      ON fp2016.region = fp1990.region
GROUP BY 1,2,3
ORDER BY difference;


3. Country-Level Details

## A. Success Stories

-- 

## B. Largest Concern

-- Top 5 countries 5 countries saw the largest amount decrease in forest area from 1990 to 2016
WITH forest_area_1990 AS (
      SELECT
            country_name,
  	      region,
            SUM(forest_area) forest_area_1990
      FROM forestation
      WHERE year = 1990
	      AND forest_area IS NOT NULL
            AND country_name != 'World'
      GROUP BY 1,2
      ORDER BY forest_area_1990 DESC),
      forest_area_2016 AS (
       SELECT
            country_name,
  	      region,
            SUM(forest_area) forest_area_2016
      FROM forestation
      WHERE year = 2016
	      AND forest_area IS NOT NULL
      AND country_name != 'World'
      GROUP BY 1,2
      ORDER BY forest_area_2016 DESC)
SELECT 
	fa1990.country_name,
      fa1990.region,
      (forest_area_1990-forest_area_2016) AS Difference_in_sqkm
FROM  forest_area_1990 fa1990
JOIN  forest_area_2016 fa2016
      ON fa2016.country_name = fa1990.country_name
GROUP BY 1,2,forest_area_1990, forest_area_2016
ORDER BY Difference_in_sqkm DESC
LIMIT 5;


-- Top 5 countries saw the largest percent decrease in forest area from 1990 to 2016
WITH forest_area_1990 AS (
      SELECT
            country_name,
  	      region,
            SUM(forest_area) forest_area_1990
      FROM forestation
      WHERE year = 1990
	      AND forest_area IS NOT NULL
            AND country_name != 'World'
      GROUP BY 1,2
      ORDER BY forest_area_1990 DESC),
      forest_area_2016 AS (
       SELECT
            country_name,
  	      region,
            SUM(forest_area) forest_area_2016
      FROM forestation
      WHERE year = 2016
	      AND forest_area IS NOT NULL
      AND country_name != 'World'
      GROUP BY 1,2
      ORDER BY forest_area_2016 DESC)
SELECT 
	fa1990.country_name,
      fa1990.region,
      ROUND((forest_area_1990-forest_area_2016)*100/forest_area_1990 :: NUMERIC,2) AS pct_forest_area_change
FROM  forest_area_1990 fa1990
JOIN  forest_area_2016 fa2016
      ON fa2016.country_name = fa1990.country_name
GROUP BY 1,2,forest_area_1990, forest_area_2016
ORDER BY pct_forest_area_change DESC
LIMIT 5;

## C.Quartiles

-- If countries were grouped by percent forestation in quartiles, which group had the most countries in it in 2016
SELECT DISTINCT(quartiles) quartiles,
       COUNT(country_name) OVER (PARTITION BY quartiles) no_of_countries
FROM(SELECT
	      country_name,
            region,
     CASE   WHEN percent_forest_to_total_area <= 25 THEN '0%-25%'
            WHEN percent_forest_to_total_area >25 AND percent_forest_to_total_area <= 50 THEN '25%-50%'
            WHEN percent_forest_to_total_area >50 AND percent_forest_to_total_area <=75 THEN '50%-75%'
            ELSE '75% -100%' END AS quartiles
      FROM forestation
      WHERE year = 2016
            AND percent_forest_to_total_area IS NOT NULL
            AND forest_area IS NOT NULL
            AND total_area IS NOT NULL
            AND country_name != 'World') Quartiles
ORDER BY quartiles;

-- List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016
SELECT 
      country_name,
      region,
      percent_forest_to_total_area forest_percent
FROM  forestation
WHERE percent_forest_to_total_area > 75 AND year = 2016
ORDER BY forest_percent;
   
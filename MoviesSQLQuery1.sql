
-- NETFLIX MOVIES ANALYSIS
-- by YAMEEN AHMED

-- Data Sources:
-- https://www.kaggle.com/datasets/mitchellharrison/top-500-movies-budget
-- https://www.kaggle.com/datasets/ariyoomotade/netflix-data-cleaning-analysis-and-visualization


-- DATA CLEANING

-- CHECK FOR DUPLICATE ROWS
SELECT title, COUNT(*) as count
FROM Portfolio1..['top-500-movies$']
GROUP BY title
HAVING COUNT(*) > 1;
-- godzilla and robin hood occur twice

-- Investigate
SELECT * 
FROM Portfolio1..['top-500-movies$']
WHERE title = 'Godzilla'
SELECT * 
FROM Portfolio1..['top-500-movies$']
WHERE title = 'Robin Hood'
-- They are different movies so not duplicates

-- STANDARDIZE RELEASE_DATE COLUMN
UPDATE Portfolio1..['top-500-movies$']
SET release_date = CAST(release_date AS DATE)
ALTER TABLE Portfolio1..['top-500-movies$']
ALTER COLUMN release_date DATE;

-- INVESTIGATE NULL VALUES

SELECT * FROM Portfolio1..['top-500-movies$']
WHERE title IS NULL
   OR release_date IS NULL
   OR genre IS NULL
   OR production_cost IS NULL
   OR domestic_gross IS NULL
   OR worldwide_gross IS NULL
   OR opening_weekend IS NULL
   OR mpaa IS NULL
   OR theaters IS NULL
   OR runtime IS NULL
   OR year IS NULL;

-- Delete rows where opening_weekend is null since domestic/worldwide_gross will also be 0 hence they are not helpful for our analysis
DELETE FROM Portfolio1..['top-500-movies$']
WHERE opening_weekend IS NULL ;

-- Where runtime is null we replace with average runtime of a movie
UPDATE Portfolio1..['top-500-movies$']
SET runtime = 120
WHERE runtime IS NULL;

-- Create month table
ALTER TABLE Portfolio1..['top-500-movies$']
ADD [month] INT;

-- Populate month table
UPDATE Portfolio1..['top-500-movies$']
SET [month] = MONTH(CAST(release_date AS DATE));

-- Delete url column since it's not needed
ALTER TABLE Portfolio1..['top-500-movies$']
DROP COLUMN url;


-- DATA ANALYSIS

-- JOIN TOP MOVIES WITH NETFLIX MOVIES AND INSERT INTO NEW TABLE
SELECT rank, release_date, movies.title, production_cost, domestic_gross, worldwide_gross, opening_weekend, theaters, runtime, type, director, country, release_year, month, rating, genre
INTO Portfolio1.dbo.combined_movies_data
FROM Top500Movies..['top-500-movies$'] AS movies
INNER JOIN Portfolio1.dbo.netflix1$ AS netflix
ON movies.title = netflix.title
ORDER BY rank ASC;

-- The top movies by worldwide-gross revnue
SELECT title, worldwide_gross, domestic_gross, opening_weekend
FROM Portfolio1..combined_movies_data
ORDER BY worldwide_gross DESC

-- Average worldwide gross revenue by genre
SELECT 
    genre, 
	ROUND(AVG(worldwide_gross), 0) AS avg_worldwide_gross,
    ROUND(AVG(domestic_gross), 0) AS avg_domestic_gross
FROM 
    Portfolio1..combined_movies_data
GROUP BY 
    genre
ORDER BY 
    avg_worldwide_gross DESC;

-- Worldwide revenue by country
SELECT 
    country,
	SUM(worldwide_gross) AS total_worldwide_gross,
    SUM(domestic_gross) AS total_domestic_grosse
FROM 
    Portfolio1..combined_movies_data
GROUP BY 
    country
ORDER BY 
    total_worldwide_gross DESC;

-- Worlwide revenue by director
SELECT 
    director,
    SUM(worldwide_gross) AS total_worldwide_revenue,
	SUM(domestic_gross) AS total_domestic_revenue
FROM 
    Portfolio1..combined_movies_data
WHERE
	director != 'Not Given'
GROUP BY 
    director
ORDER BY 
    total_worldwide_revenue DESC;

-- ROI (return on investment) by movie
SELECT 
    title,
	worldwide_gross,
    production_cost,
    ROUND(((worldwide_gross - production_cost) / production_cost) * 100, 1) AS ROI_percentage
FROM 
    Portfolio1..combined_movies_data
WHERE 
    production_cost > 0
ORDER BY
	 ROI_percentage DESC

-- Average worldwide revenue by age rating
SELECT 
    rating, 
	ROUND(AVG(worldwide_gross), 0) AS avg_worldwide_gross,
    ROUND(AVG(domestic_gross), 0) AS avg_domestic_gross
FROM 
    Portfolio1..combined_movies_data
GROUP BY 
    rating
ORDER BY 
    avg_worldwide_gross DESC;

-- Average gross revenue and number of movies released each month.
-- Can help film producer decide which release month will bring in most revenue and have least competition.
SELECT 
    month, 
	ROUND(AVG(worldwide_gross), 0) AS avg_worldwide_gross,
    ROUND(AVG(domestic_gross), 0) AS avg_domestic_gross,
    COUNT(*) AS num_movies
FROM 
    Portfolio1..combined_movies_data
GROUP BY 
    month
ORDER BY 
    avg_worldwide_gross desc;

-- Average runtime and number of movies released per year
SELECT 
    release_year,
    ROUND(AVG(runtime), 0) AS avg_runtime,
    COUNT(*) AS num_movies_released
FROM 
    Portfolio1..combined_movies_data
GROUP BY 
    release_year
ORDER BY 
    release_year;

-- Which film/director made the most in opening weekend
SELECT rank, title, director, opening_weekend
FROM Portfolio1..combined_movies_data
ORDER BY opening_weekend DESC;

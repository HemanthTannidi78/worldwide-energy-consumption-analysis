CREATE DATABASE ENERGYDB2;
USE ENERGYDB2;

-- 1. country table
CREATE TABLE country_3 (
    CID VARCHAR(10) PRIMARY KEY,
    Country VARCHAR(100) UNIQUE
);

select * from country_3;


-- 2. emission_3 table
CREATE TABLE emission_3 (
    country VARCHAR(100),
    energy_type VARCHAR(50),
    year INT,
    emission INT,
    per_capita_emission DOUBLE,
    FOREIGN KEY (country) REFERENCES country_3(Country)
);

select * from country_3;
select * from emission_3;


-- 3. population table
CREATE TABLE population (
    countries VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (countries) REFERENCES country_3(Country)
);

select * from country_3;
select * from emission_3;
select * from population;


-- 4. production table
CREATE TABLE production_3 (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    production INT,
    FOREIGN KEY (country) REFERENCES country_3(Country)
);


select * from country_3;
select * from emission_3;
select * from population;
select * from production_3;

-- 5. gdp_3 table
CREATE TABLE gdp_3 (
    Country VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (Country) REFERENCES country_3(Country)
);







-- 6. consumption table
CREATE TABLE consum_3 (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    consumption INT,
    FOREIGN KEY (country) REFERENCES country_3(Country)
);

select * from country_3;
select * from emission_3;
select * from population;
select * from production_3;
select * from gdp_3;
select * from consum_3;


-- Data Analysis Questions
-- General & Comparative Analysis
-- What is the total emission per country for the most recent year available?
select country,SUM(emission) as total_emission
from emission_3
where year = 2023
group by country
order by total_emission DESC;


-- What are the top 5 countries by GDP in the most recent year?
select * from gdp_3
where year = 2024
order by Value desc
limit 5;

-- Compare energy production and consumption by country and year. 

select c.country, c.year, c.consumption, p.production
from consum_3 c 
inner join production_3 p 
on c.country = p.country
and c.year = p.year
order by c.consumption desc;

-- Which energy types contribute most to emissions across all countries?

select energy_type,SUM(emission) as total_emission
from emission_3
group by energy_type
order by total_emission desc;


--  Trend Analysis Over Time
-- How have global emissions changed year over year?

select year,SUM(emission) AS total_emission
from emission_3
group by year
order by year;





-- What is the trend in GDP for each country over the given years?
select country, year, value AS gdp
from gdp_3
order by country, year;



-- How has population growth affected total emissions in each country?
select e.country, e.year, SUM(e.emission) AS total_emission, p.value AS population
from emission_3 e
join population p
on e.country = p.countries
and e.year = p.year
group by e.country, e.year, p.value
order by e.country, e.year;


-- Has energy consumption increased or decreased over the years for major economies?
select country, year, SUM(consumption) AS total_consumption
from consum_3
group by country, year
order by total_consumption desc;


-- What is the average yearly change in emissions per capita for each country?

select country, year, per_capita_emission, lag(per_capita_emission) over 
		(partition by country order by year) AS prev_value,
       per_capita_emission - lag(per_capita_emission) over 
       (partition by country order by year) AS diff
from emission_3;


--  Ratio & Per Capita Analysis
-- What is the emission-to-GDP ratio for each country by year?

select e.country, e.year, SUM(e.emission) / g.value AS emission_gdp_ratio
from emission_3 e
join gdp_3 g
on e.country = g.country
and e.year = g.year
group by e.country, e.year, g.value
order by e.country, year;


-- What is the energy consumption per capita for each country over the last decade?

select c.country, c.year, SUM(c.consumption) / p.value AS consumption_per_capita
from consum_3 c
join population p
on c.country = p.countries
and c.year = p.year
group by c.country, c.year, p.value
order by c.year desc;

-- How does energy production per capita vary across countries?


select pr.country, pr.year, SUM(pr.production) / MAX(p.value) AS production_per_capita
from production_3 pr
join population p
on pr.country = p.countries
and pr.year = p.year
group by pr.country, pr.year
order by pr.country, pr.year;

-- Which countries have the highest energy consumption relative to GDP?

select c.country, SUM(c.consumption) / MAX(g.value) AS consumption_gdp_ratio
from consum_3 c
join gdp_3 g
on c.country = g.country
and c.year = g.year
where c.year = (select MAX(year) from consum_3)
group by c.country
order by consumption_gdp_ratio DESC
LIMIT 10;


-- What is the correlation between GDP growth and energy production growth?

WITH production_agg AS (
    SELECT country,
           year,
           SUM(production) AS total_production
    FROM production_3
    GROUP BY country, year
),
growth_data AS (
    SELECT g.country,
           g.year,
           g.value - LAG(g.value) OVER (
               PARTITION BY g.country ORDER BY g.year
           ) AS gdp_growth,
           p.total_production - LAG(p.total_production) OVER (
               PARTITION BY p.country ORDER BY p.year
           ) AS prod_growth
    FROM gdp_3 g
    JOIN production_agg p
    ON g.country = p.country
    AND g.year = p.year
)
SELECT country,
       (
         AVG(gdp_growth * prod_growth) -
         AVG(gdp_growth) * AVG(prod_growth)
       ) /
       (
         STDDEV(gdp_growth) * STDDEV(prod_growth)
       ) AS correlation
FROM growth_data
GROUP BY country
order by correlation;




--  Global Comparisons

-- What are the top 10 countries by population and how do their emissions compare?

WITH latest_year AS (
    SELECT MAX(year) AS yr FROM population
)
SELECT p.countries AS country,
       MAX(p.value) AS population,
       SUM(e.emission) AS total_emission
FROM population p
JOIN emission_3 e
ON p.countries = e.country
GROUP BY p.countries
ORDER BY population DESC
LIMIT 10;



-- Which countries have improved (reduced) their per capita emissions the most over the last decade?

SELECT country,
       MAX(CASE WHEN year = (SELECT MIN(year) FROM emission_3)
                THEN per_capita_emission END)
     -
       MAX(CASE WHEN year = (SELECT MAX(year) FROM emission_3)
                THEN per_capita_emission END) AS reduction
FROM emission_3
GROUP BY country
ORDER BY reduction DESC
LIMIT 10;

SELECT country, year, per_capita_emission
FROM emission_3
ORDER BY per_capita_emission desc;


-- What is the global share (%) of emissions by country?

SELECT country,
       SUM(emission) * 100.0 / 
       (SELECT SUM(emission) FROM emission_3) AS emission_share_percent
FROM emission_3
GROUP BY country
ORDER BY emission_share_percent DESC;


-- What is the global average GDP, emission, and population by year?

SELECT e.year,
       AVG(e.emission) AS avg_emission,
       AVG(g.value) AS avg_gdp,
       AVG(p.value) AS avg_population
FROM emission_3 e
JOIN gdp_3 g
ON e.country = g.country AND e.year = g.year
JOIN population p
ON e.country = p.countries AND e.year = p.year
GROUP BY e.year
ORDER BY e.year;











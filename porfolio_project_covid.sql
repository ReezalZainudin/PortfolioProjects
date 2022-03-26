CREATE SCHEMA portfolio_projects; 

USE portfolio_projects;

CREATE TABLE covid_deaths (
	covid_deaths_id BIGINT,
	iso_code VARCHAR(10),
    continent VARCHAR(15),
    location VARCHAR(65),
    date DATE,
    population BIGINT,
    total_cases BIGINT,
	new_cases BIGINT,  
    new_cases_smoothed DECIMAL(65,3),
    total_deaths BIGINT,
    new_deaths BIGINT, 
    new_deaths_smoothed DECIMAL(65,3),
    total_cases_per_million DECIMAL(65,3),
    new_cases_per_million DECIMAL(65,3),
    new_cases_smoothed_per_million DECIMAL(65,3),
    total_deaths_per_million DECIMAL(65,3),
    new_deaths_per_million DECIMAL(65,3),
    new_deaths_smoothed_per_million DECIMAL(65,3),
    reproduction_rate DECIMAL(65,2),
    icu_patients BIGINT, 
	icu_patients_per_million DECIMAL(65,3),
    hosp_patients BIGINT,
    hosp_patients_per_million DECIMAL(65,3),
    weekly_icu_admissions BIGINT,
    weekly_icu_admissions_per_million DECIMAL(65,3),
    weekly_hosp_admissions BIGINT,
    weekly_hosp_admissions_per_million DECIMAL(65,3)
    );

CREATE TABLE covid_vaccinations (
	covid_vaccination_id BIGINT,
    iso_code VARCHAR(10),	
    continent VARCHAR(15),
    location VARCHAR(65),
    date DATE,
	total_tests BIGINT,
    new_tests BIGINT,
    total_tests_per_thousand DECIMAL(65,3),
    new_tests_per_thousand DECIMAL(65,3),
    new_tests_smoothed BIGINT,
    new_tests_smoothed_per_thousand DECIMAL(65,3),
    positive_rate DECIMAL(65,4),
    tests_per_case DECIMAL(65,1),
    tests_units VARCHAR(20),
    total_vaccinations BIGINT,
    people_vaccinated BIGINT,
    people_fully_vaccinated BIGINT,
    total_boosters BIGINT,
    new_vaccinations BIGINT,
    new_vaccinations_smoothed BIGINT,
    total_vaccinations_per_hundred DECIMAL(65,2),
    people_vaccinated_per_hundred DECIMAL(65,2),
    people_fully_vaccinated_per_hundred DECIMAL(65,2),
    total_boosters_per_hundred DECIMAL(65,2),
    new_vaccinations_smoothed_per_million BIGINT,
    new_people_vaccinated_smoothed BIGINT,
    new_people_vaccinated_smoothed_per_hundred DECIMAL(65,3),
    stringency_index DECIMAL(65,2),
    population_density DECIMAL(65,3),
    median_age DECIMAL(4,1),
    aged_65_older DECIMAL(65,3),
    aged_70_older DECIMAL(65,3),
    gdp_per_capita DECIMAL(65,3),
    extreme_poverty DECIMAL(65,1),
    cardiovasc_death_rate DECIMAL(65,3),
    diabetes_prevalence DECIMAL(65,2),
    female_smokers DECIMAL(65,3),
    male_smokers DECIMAL(65,3),
    handwashing_facilities DECIMAL(65,3),
    hospital_beds_per_thousand DECIMAL(65,3),
    life_expectancy DECIMAL(5,2),
    human_development_index DECIMAL(65,3),
    excess_mortality_cumulative_absolute DECIMAL(65,2),
    excess_mortality_cumulative DECIMAL(65,2),
    excess_mortality DECIMAL(65,2),
    excess_mortality_cumulative_per_million DECIMAL(65,6)
    );
    
SHOW VARIABLES LIKE 'local_infile';
SET  global local_infile = 0;

SHOW VARIABLES LIKE 'local_infile';
SET global local_infile = 1;
SELECT @@local_infile;

LOAD DATA LOCAL INFILE 'C:\\Users\\reezal93\\Documents\\Data Analyst\\covid_deaths.csv'
INTO TABLE covid_deaths
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:\\Users\\reezal93\\Documents\\Data Analyst\\covid_vaccinations.csv'
INTO TABLE covid_vaccinations
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

SELECT
	COUNT(*)
FROM covid_vaccinations;

SELECT
	COUNT(*)
FROM covid_deaths;

SELECT * FROM covid_deaths;

SELECT * FROM covid_vaccinations;

-- Fatality Rate (Death Percentage  or Percent of Total Deaths per Total Cases)

-- First 

SELECT 
	date,
	total_cases,
    total_deaths,
    FORMAT((total_deaths / total_cases) * 100, 2) AS fatality_rate
FROM covid_deaths
WHERE 
	location = 'Malaysia';

-- Second

CREATE TEMPORARY TABLE cases_vs_deaths
SELECT 
	continent,
    location,
    date,
    new_cases,
    SUM(new_cases) OVER(PARTITION BY location ORDER BY date) AS cumulative_cases,
    SUM(new_cases) OVER(PARTITION BY location) AS overall_total_cases,
    new_deaths,
    SUM(new_deaths) OVER(PARTITION BY location ORDER BY date) AS cumulative_deaths,
    SUM(new_deaths) OVER(PARTITION BY location) AS overall_total_deaths
FROM covid_deaths
WHERE
	NOT continent = 'N/A'
ORDER BY
	location,
    date;

SELECT * FROM cases_vs_deaths;

SELECT
	continent,
    location,
    date,
    cumulative_cases,
    cumulative_deaths,
	(cumulative_deaths / cumulative_cases) * 100 AS fatality_rate
FROM cases_vs_deaths;
    
-- Infection Rate (Percent of Total Cases per Population)

SELECT
	date,
	population,
    total_cases,
    FORMAT((total_cases / population) * 100, 3) AS infection_rate
FROM covid_deaths
WHERE
	location = 'Malaysia';

-- Ranked Countries by Infection Rate (Percent of Total Cases per Population)

SELECT
	location,
    MAX(population) AS population,
    MAX(total_cases) AS highest_infection_count,
    (MAX(total_cases) / MAX(population)) * 100 AS infection_rate
FROM covid_deaths
WHERE
	NOT continent = 'N/A'
GROUP BY
	location
ORDER BY
	infection_rate DESC;

-- Ranked Countries by Mortality Rate (Percent of Total Deaths per Population)

SELECT
	location,
    MAX(population) AS population,
    MAX(total_deaths) AS total_deaths_count,
    (MAX(total_deaths) / MAX(population)) * 100 AS mortality_rate
FROM covid_deaths
WHERE
	continent NOT IN ('N/A')
GROUP BY
	location
ORDER BY
	mortality_rate DESC;

-- Ranked countries by death count (Total Deaths Count)

SELECT
	location,
    MAX(total_deaths) AS total_deaths_count
FROM covid_deaths
WHERE
	continent NOT IN ('N/A')
GROUP BY
	location
ORDER BY
	total_deaths_count DESC;

-- Ranked continents by deaths count (Total Deaths Count)

-- First

SELECT
	continent,
	SUM(new_deaths) AS total_deaths_count
FROM covid_deaths
WHERE
	continent NOT IN ('N/A')
GROUP BY
	continent
ORDER BY
	total_deaths_count DESC;

-- Second

SELECT
	location,
	SUM(new_deaths) AS total_deaths_count
FROM covid_deaths
WHERE
	continent IN ('N/A')
GROUP BY
	location
ORDER BY
	total_deaths_count DESC;

-- Third

SELECT
	location,
	MAX(total_deaths) AS total_deaths_count
FROM covid_deaths
WHERE 
	continent IN ('N/A')
GROUP BY
	location
ORDER BY
	total_deaths_count DESC;
    
-- Explore data by World (Fatality Rate Mortality Rate, Total Deaths, Infection Rate, New Deaths by New Cases)

SELECT * FROM covid_deaths;

--  First

SELECT 
	date,
    SUM(new_cases) AS total_cases,
    SUM(new_deaths) AS total_deaths,
    (SUM(new_deaths) / SUM(new_cases)) * 100 AS fatality_rate
FROM covid_deaths
WHERE 
	NOT continent = 'N/A'
GROUP BY
	date
ORDER BY
	date;

-- Second

SELECT 
    SUM(new_cases) AS total_cases,
    SUM(new_deaths) AS total_deaths,
    (SUM(new_deaths) / SUM(new_cases)) * 100 AS fatality_rate
FROM covid_deaths
WHERE 
	NOT continent = 'N/A' ;

-- Vaccinations Rates

SELECT * FROM covid_deaths;
SELECT * FROM covid_vaccinations;

SELECT 
    CD.date,
    CD.population,
    CV.people_vaccinated AS total_vaccinations,
    (CV.people_vaccinated / CD.population) * 100 AS vaccination_rates
FROM covid_deaths AS CD
	LEFT JOIN covid_vaccinations AS CV
		ON CV.location = CD.location 
        AND CV.date = CD.date
WHERE
	CD.location = 'Malaysia';

-- Creating View to store data for visualizations

CREATE VIEW ranked_continents_by_deaths_counts AS
SELECT
	continent,
	SUM(new_deaths) AS total_deaths_count
FROM covid_deaths
WHERE
	continent NOT IN ('N/A')
GROUP BY
	continent
ORDER BY
	total_deaths_count DESC;
    
SELECT * FROM ranked_continents_by_deaths_counts;
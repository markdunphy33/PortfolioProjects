/*
COVID-19 Data Exploration
Worldwide COVID-19 Data as of September 8, 2022 provided by https://ourworldindata.org/covid-deaths
Skills used: CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- This is the base data used for analysis
-- Second code chunk shows data types for each column

SELECT *
FROM PortfolioProject..CovidDataAll
WHERE continent IS NOT NULL

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'CovidDataAll'



-- Total Cases vs Total Deaths

-- Shows likelihood of dying if you contract COVID-19 by country (Case Fatality Rate a.k.a. CFR)

SELECT 
	location, SUM(new_cases) as Total_Cases, SUM(CAST(new_deaths as INT)) as Total_Deaths, ROUND((SUM(CAST(new_deaths as INT))/SUM(new_cases))*100,2) as CFR
FROM 
	PortfolioProject..CovidDataAll
WHERE 
	continent IS NOT NULL
GROUP BY location
ORDER BY IFR DESC


-- Shows daily timeline of Case Fatality Rate by country
	-- Using the United States in below code

SELECT
	location, date, total_cases, total_deaths , ROUND((total_deaths / total_cases)*100,2) AS Daily_IFR
FROM 
	PortfolioProject..CovidDataAll
WHERE 
	continent IS NOT NULL AND
	total_cases IS NOT NULL AND
	location = 'United States'
ORDER BY date ASC



-- Total Cases vs Population

-- Shows timeline of what percentage of population has had COVID-19

SELECT 
	location, date, total_cases, population , ROUND((total_cases / population)*100,5) AS Cases_By_Pop
FROM 
	PortfolioProject..CovidDataAll
WHERE location = 'United States'
ORDER BY 1,2


-- Looking at Countries with highest infection rates compared to Population

SELECT 
	location, MAX(total_cases) as Highest_Infection_Count, population , ROUND(MAX((total_cases / population))*100,2) AS Pop_Infection_Rate
FROM
	PortfolioProject..CovidDataAll
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Pop_Infection_Rate DESC



-- Total Deaths vs Population

-- Showing Continents with highest death count

SELECT
	location, SUM(CAST(new_deaths as INT)) as total_death_count
FROM 
	PortfolioProject..CovidDataAll
WHERE 
	continent IS NULL
	AND location NOT LIKE '%income%'
	AND location <> 'World' 
	AND location <> 'European Union'
	AND location <> 'International'
GROUP BY location
ORDER BY total_death_count DESC


-- Shows % of Population that has died due to COVID-19

SELECT
	location, 
	population, 
	MAX(CAST(total_deaths as INT)) as Total_Death_Count, 
	ROUND(MAX(CAST(total_deaths as INT)/ population)*100,2) AS Percent_Pop_Lost
FROM 
	PortfolioProject..CovidDataAll
WHERE continent IS NOT NULL 
GROUP BY location, population
ORDER BY Percent_Pop_Lost DESC



-- Total Cases vs Vaccinations

-- Shows timeline of new case rate based on vaccinations

SELECT
	location, 
	date, 
	people_fully_vaccinated, 
	new_cases, 
	ROUND((new_cases/population)*100,5) as case_rate, ROUND((people_fully_vaccinated / population)*100,5) as vaccination_rate
FROM 
	PortfolioProject..CovidDataAll
WHERE 
	continent IS NOT NULL AND
	location = 'United States'
ORDER BY date ASC



-- New Cases & New Deaths vs Vaccinations

-- Shows rolling case and death data using PARTITION BY
-- Calculating % of population that contracted COVID-19, % of population that has passed away due to COVID, and % of population fully vaccinated

WITH cte_data AS

	(SELECT
		location, 
		date, 
		population, 
		people_fully_vaccinated, 
		SUM(new_cases) OVER(PARTITION BY location ORDER BY location, date) as rolling_cases,
		SUM(CAST(new_deaths as INT)) OVER(PARTITION BY location ORDER BY location, date) AS rolling_deaths
	FROM
		PortfolioProject..CovidDataAll
	WHERE 
		continent IS NOT NULL)

SELECT
	location,
	date,
	ROUND((rolling_cases / population)*100,5) AS Percent_Pop_Contracted,
	ROUND((rolling_deaths/population)*100,5) AS Percent_Pop_Lost,
	(people_fully_vaccinated/population)*100 AS Percent_Fully_Vaccinated
FROM cte_data
WHERE location = 'United States'
ORDER BY 1,2


-- Using Temp Table to perform above calculation on PARTITION BY data

DROP TABLE IF EXISTS VacCaseDeath
CREATE TABLE VacCaseDeath
(
Location NVARCHAR(255),
Date DATE,
Population NUMERIC,
people_fully_vaccinated NUMERIC,
rolling_cases NUMERIC,
rolling_deaths NUMERIC
)

INSERT INTO VacCaseDeath
	SELECT
		location, 
		date, 
		population, 
		people_fully_vaccinated, 
		SUM(new_cases) OVER(PARTITION BY location ORDER BY location, date) as rolling_cases,
		SUM(CAST(new_deaths as INT)) OVER(PARTITION BY location ORDER BY location, date) AS rolling_deaths
	FROM
		PortfolioProject..CovidDataAll
	WHERE 
		continent IS NOT NULL AND
		location = 'United States'

SELECT
	location,
	date,
	(rolling_cases / population)*100 AS Percent_Pop_Contracted,
	(rolling_deaths/population)*100 AS Percent_Pop_Lost,
	(people_fully_vaccinated/population)*100 AS Percent_Fully_Vaccinated
FROM VacCaseDeath
ORDER BY 1,2


-- Creating view to store later for Tableau visualization

CREATE VIEW PercentPopulationLost
AS
	(SELECT
		location, 
		population, 
	 	MAX(CAST(total_deaths as INT)) as Total_Death_Count, 
	 	ROUND(MAX(CAST(total_deaths as INT)/ population)*100,2) AS Percent_Pop_Lost
	FROM 
		PortfolioProject..CovidDataAll
	WHERE 
		continent IS NOT NULL 
	GROUP BY 
	 	location, population)



-- Accessing and dropping created view

SELECT *
FROM dbo.PercentPopulationLost
ORDER BY Percent_Pop_Lost DESC

DROP VIEW PercentPopulationLost

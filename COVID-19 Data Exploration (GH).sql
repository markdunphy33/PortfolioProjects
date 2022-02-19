/*
COVID-19 Data Exploration
Worldwide COVID-19 Data as of February 9, 2022 provided by https://ourworldindata.org/covid-deaths

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


-- Select base data for both data sets

SELECT location, date, total_cases, new_cases, total_deaths, new_deaths,  population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

SELECT location, date, total_tests, positive_rate, people_fully_vaccinated, total_boosters, new_vaccinations, total_vaccinations
FROM PortfolioProject..CovidVaccinations
WHERE continent is NOT NULL
ORDER BY 1,2


-- Total Cases vs Total Deaths

-- Shows likelihood of dying if you contract COVID-19 by country (Infection Fatality Rate)

SELECT location, SUM(new_cases) AS Total_Cases,SUM(CAST(new_deaths AS INT)) AS Total_Deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS IFR
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 4 DESC


-- Shows timeline of Infection Fatality Rate if you contract COVID-19 in your country

SELECT location, FORMAT(date,'yyyy-MM-dd') AS Date, total_cases, total_deaths , (total_deaths / total_cases)*100 AS Daily_IFR
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2


-- Total Cases vs Population


-- Shows timeline of what percentage of population has had COVID-19

SELECT location, FORMAT(date,'yyyy-MM-dd') AS Date, total_cases, population , (total_cases / population)*100 AS Cases_By_Pop
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1,2


-- Looking at Countries with highest infection rates compared to Population

SELECT location, MAX(total_cases) as Highest_Infection_Count, population , MAX((total_cases / population))*100 AS Pop_Infection_Percent
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY Pop_Infection_Percent DESC


-- Total Deaths vs Population


-- Showing Continents with highest death count

SELECT  location, MAX(cast(total_deaths as INT)) as Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL 
AND location NOT LIKE '%income%'
AND location <> 'World' 
AND location <> 'European Union'
GROUP BY  location
ORDER BY Total_Death_Count DESC


-- Shows % of Population that has died due to COVID-19

SELECT location, population AS Total_Population, MAX(cast(total_deaths as INT)) as Total_Death_Count, MAX(cast(total_deaths as INT)/ population)*100 AS Percent_Pop_Lost
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location, population
ORDER BY Percent_Pop_Lost DESC


-- Total Cases vs Vaccinations


-- Shows timeline of new case rate based on vaccinations

SELECT dea.location, FORMAT(dea.date,'yyyy-MM-dd') AS Date, vac.people_fully_vaccinated, dea.new_cases,
(dea.new_cases / dea.population)*100 AS Case_Rate
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND dea.location LIKE '%states%'
ORDER BY 1,2


-- Total Vaccinations vs Population


-- Shows increase in percentage of fully vaccinated population

SELECT dea.location, FORMAT(dea.date,'yyyy-MM-dd') AS Date, dea.population, vac.people_fully_vaccinated,(vac.people_fully_vaccinated/dea.population)*100 AS Percent_Pop_FullyVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND dea.location = 'United States'
ORDER BY 1,2


-- New Cases & New Deaths vs Vaccinations

-- Shows rolling case and death data using PARTITION BY
-- Calculating % of population that contracted COVID-19 and % of population that has passed away due to COVID


-- Using CTE to perform above calculation on PARTITION BY data

WITH VACvsCASESvsDEATHS (location, date, population, Fully_Vaccinated, Rolling_Cases, Rolling_Deaths)
AS
(
SELECT dea.location, FORMAT(dea.date,'yyyy-MM-dd') AS Date, dea.population, vac.people_fully_vaccinated,
SUM(CONVERT(BIGINT,dea.new_cases)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Cases,
SUM(CONVERT(BIGINT,dea.new_deaths)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Deaths
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *,(Rolling_Cases/population)*100 AS Percent_Pop_Contracted, (Rolling_Deaths/population)*100 AS Percent_Pop_Lost,
(Fully_Vaccinated/population)*100 AS Percent_Fully_Vaccinated
FROM VACvsCASESvsDEATHS
WHERE location = 'United States'
ORDER BY 1,2


-- Using Temp Table to perform above calculation on PARTITION BY data

DROP TABLE IF EXISTS VacCaseDeath
CREATE TABLE VacCaseDeath
(
Location NVARCHAR(255),
Date DATE,
Population NUMERIC,
Fully_Vaccinated NUMERIC,
Rolling_Cases NUMERIC,
Rolling_Deaths NUMERIC
)

INSERT INTO VacCaseDeath
SELECT dea.location, FORMAT(dea.date,'yyyy-MM-dd') AS Date, dea.population, vac.people_fully_vaccinated,
SUM(CONVERT(BIGINT,dea.new_cases)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Cases,
SUM(CONVERT(BIGINT,dea.new_deaths)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Deaths
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *,(Rolling_Cases/population)*100 AS Percent_Pop_Contracted, (Rolling_Deaths/population)*100 AS Percent_Pop_Lost,
(Fully_Vaccinated/population)*100 AS Percent_Fully_Vaccinated
FROM VacCaseDeath
WHERE location = 'United States'
ORDER BY 1,2


-- Creating view to store later for Tableu visualization

CREATE VIEW RollingPercentData 
AS
WITH VACvsCASESvsDEATHS (location, date, population, Fully_Vaccinated, Rolling_Cases, Rolling_Deaths)
AS
(
SELECT dea.location, FORMAT(dea.date,'yyyy-MM-dd') AS Date, dea.population, vac.people_fully_vaccinated,
SUM(CONVERT(BIGINT,dea.new_cases)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Cases,
SUM(CONVERT(BIGINT,dea.new_deaths)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Deaths
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *,(Rolling_Cases/population)*100 AS Percent_Pop_Contracted, (Rolling_Deaths/population)*100 AS Percent_Pop_Lost,
(Fully_Vaccinated/population)*100 AS Percent_Fully_Vaccinated
FROM VACvsCASESvsDEATHS


-- Accessing and dropping created view

SELECT *
FROM dbo.RollingPercentData

DROP VIEW RollingPercentData

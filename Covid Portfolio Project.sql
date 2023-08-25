-- Looking at all of the data

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE CONTINENT IS NOT NULL
ORDER BY 3,4

SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
WHERE CONTINENT IS NOT NULL
ORDER BY 3,4

-- Looking at the data I'm interested in working with (Covid Deaths)

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE CONTINENT IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths in the United States
-- Shows likelihood of dying if you contract COVID in your country

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float))*100 AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Looking at Total Cases vs Population in the United States
-- Shows what percentage of the U.S. population has had Covid

SELECT location, date, total_cases, population, (CAST(total_cases AS float) / CAST(population AS float))*100 AS percent_population_infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population size

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((CAST(total_cases AS float) / CAST(population AS float)))*100 AS percent_population_infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE CONTINENT IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC

-- Looking at countries with highest death count per population

SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Looking at the total death count by continent

SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL
AND location IN ('Europe', 'Asia', 'North America', 'South America', 'Africa', 'Oceania')
GROUP BY location
ORDER BY total_death_count DESC

-- Looking at countries with the highest death counts in North America

SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent = 'North America'
GROUP BY location
ORDER BY total_death_count DESC

-- Looking at the countries with the highest death counts in Europe

SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent = 'Europe'
GROUP BY location
ORDER BY total_death_count DESC

-- Looking at worldwide cases, deaths, & death percentage by date

SELECT date, SUM(new_cases) AS total_cases_worldwide, SUM(new_deaths) AS total_deaths_worldwide, 
    (SUM(CAST(new_deaths AS float))/NULLIF(SUM(CAST(new_cases AS float)), 0))*100 AS death_percentage_worldwide
FROM PortfolioProject.dbo.CovidDeaths
WHERE CONTINENT IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Looking at Total Population vs Vaccination with a CTE

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

Select *, (CAST(rolling_people_vaccinated AS FLOAT)/population)*100 AS percent_people_vaccinated
FROM PopvsVac


-- Looking at Total Population vs Vaccination with a Temp Table

CREATE TABLE #percent_population_vaccinated
(
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    rolling_people_vaccinated NUMERIC
)

INSERT INTO #percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
    ON dea.location = vac.location 
    AND dea.date = vac.date

Select *, (CAST(rolling_people_vaccinated AS FLOAT)/population)*100 AS percent_people_vaccinated
FROM #percent_population_vaccinated

-- Creating view to store data for later visualizations

CREATE VIEW percent_population_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

CREATE VIEW global_numbers AS
SELECT date, SUM(new_cases) AS total_cases_worldwide, SUM(new_deaths) AS total_deaths_worldwide, 
    (SUM(CAST(new_deaths AS float))/NULLIF(SUM(CAST(new_cases AS float)), 0))*100 AS death_percentage_worldwide
FROM PortfolioProject.dbo.CovidDeaths
WHERE CONTINENT IS NOT NULL
GROUP BY date

CREATE VIEW europe_deaths AS
SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent = 'Europe'
GROUP BY location

CREATE VIEW north_america_deaths AS
SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent = 'North America'
GROUP BY location

CREATE VIEW deaths_by_continent AS
SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL
AND location IN ('Europe', 'Asia', 'North America', 'South America', 'Africa', 'Oceania')
GROUP BY location

CREATE VIEW deaths_by_country AS
SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location

CREATE VIEW percent_population_infected AS
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((CAST(total_cases AS float) / CAST(population AS float)))*100 AS percent_population_infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE CONTINENT IS NOT NULL
GROUP BY location, population

CREATE VIEW US_percent_population_infected AS
SELECT location, date, total_cases, population, (CAST(total_cases AS float) / CAST(population AS float))*100 AS percent_population_infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%states%'

CREATE VIEW US_death_percentage AS
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float))*100 AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%states%'
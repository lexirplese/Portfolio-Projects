SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1, 2

-- U.S. Total Cases vs. Total Deaths
--What is the likelihood of dying if you contract COVID-19 in the United States?

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float))*100 AS mortality_rate
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'United States'
ORDER BY 1, 2  

-- New Zealand Total Cases vs. Total Deaths
--What is the likelihood of dying if you contract COVID-19 in New Zealand?

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float))*100 AS mortality_rate
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'New Zealand'
ORDER BY 1, 2 

-- U.S. Total Cases vs. Population
--What percent of the U.S. population has had COVID?

SELECT location, date, total_cases, population, (CAST(total_cases AS float) / CAST(population AS float))*100 AS percent_population_infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'United States'
ORDER BY 1, 2

-- New Zealand Total Cases vs. Population
--What percent of New Zealand's population has had COVID?

SELECT location, date, total_cases, population, (CAST(total_cases AS float) / CAST(population AS float))*100 AS percent_population_infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'New Zealand'
ORDER BY 1, 2

-- Which countries had the highest infection rate?

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((CAST(total_cases AS float) / CAST(population AS float)))*100 AS percent_population_infected
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location, population
ORDER BY percent_population_infected DESC

-- Which countries had the highest death tolls?

SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- What was the death toll on each continent?

SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL
AND location IN ('Europe', 'Asia', 'North America', 'South America', 'Africa', 'Oceania')
GROUP BY [location]
ORDER BY total_death_count DESC

-- Which countries in North America had the highest death tolls?

SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent = 'North America'
GROUP BY [location]
ORDER BY total_death_count DESC

-- Which countries in Europe had the highest death counts?

SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent = 'Europe'
GROUP BY [location]
ORDER BY total_death_count DESC

-- How many cases and deaths were there globally each day? 
-- What was the global death percentage each day?

SELECT date, SUM(new_cases) AS global_cases, SUM(new_deaths) AS global_deaths, 
    (SUM(CAST(new_deaths AS float))/NULLIF(SUM(CAST(new_cases AS float)), 0))*100 AS global_death_rate 
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date ASC

-- How much of the total population has been vaccinated?
-- Joining CovidDeaths with CovidVaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations
FROM PortfolioProject.dbo.CovidDeaths dea 
JOIN PortfolioProject.dbo.CovidVaccinations vac
    ON dea.location = vac.[location]
    AND dea.date = vac.[date]
WHERE dea.continent IS NOT NULL
ORDER BY location, date ASC

-- How much of the total population has been vaccinated? (CTE)

WITH PopvsVac (continent, location, date, population, new_vaccinations, total_vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations
FROM PortfolioProject.dbo.CovidDeaths dea 
JOIN PortfolioProject.dbo.CovidVaccinations vac
    ON dea.location = vac.[location]
    AND dea.date = vac.[date]
WHERE dea.continent IS NOT NULL
)

SELECT *, (CAST(total_vaccinations AS float)/population)*100 AS percent_population_vaccinated 
FROM PopvsVac

-- How much of the total population has been vaccinated? (Temp Table)

DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    Total_vaccinations NUMERIC
)

INSERT INTO #percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations
FROM PortfolioProject.dbo.CovidDeaths dea 
JOIN PortfolioProject.dbo.CovidVaccinations vac
    ON dea.location = vac.[location]
    AND dea.date = vac.[date]
WHERE dea.continent IS NOT NULL

SELECT *, (CAST(total_vaccinations AS float)/population)*100 AS percent_population_vaccinated 
FROM #percent_population_vaccinated

-- Creating views of data for later visualization

CREATE VIEW USCasesVsDeaths AS 
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float))*100 AS mortality_rate
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'United States'

CREATE VIEW NZCasesVsDeaths AS
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float))*100 AS mortality_rate
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'New Zealand'

CREATE VIEW USInfectionRate AS
SELECT location, date, total_cases, population, (CAST(total_cases AS float) / CAST(population AS float))*100 AS percent_population_infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'United States'

CREATE VIEW NZInfectionRate AS
SELECT location, date, total_cases, population, (CAST(total_cases AS float) / CAST(population AS float))*100 AS percent_population_infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'New Zealand'

CREATE VIEW InfectionRateByCountry AS
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((CAST(total_cases AS float) / CAST(population AS float)))*100 AS percent_population_infected
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location, population

CREATE VIEW DeathTollByCountry AS
SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location

CREATE VIEW DeathTollByContinent AS
SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL
AND location IN ('Europe', 'Asia', 'North America', 'South America', 'Africa', 'Oceania')
GROUP BY [location]

CREATE VIEW DeathTollNorthAmerica AS
SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent = 'North America'
GROUP BY [location]

CREATE VIEW DeathTollEurope AS
SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent = 'Europe'
GROUP BY [location]

CREATE VIEW GlobalData AS
SELECT date, SUM(new_cases) AS global_cases, SUM(new_deaths) AS global_deaths, 
    (SUM(CAST(new_deaths AS float))/NULLIF(SUM(CAST(new_cases AS float)), 0))*100 AS global_death_rate 
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date

CREATE VIEW Vaccinations AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations
FROM PortfolioProject.dbo.CovidDeaths dea 
JOIN PortfolioProject.dbo.CovidVaccinations vac
    ON dea.location = vac.[location]
    AND dea.date = vac.[date]
WHERE dea.continent IS NOT NULL

CREATE VIEW PercentVaccinated AS
WITH PopvsVac (continent, location, date, population, new_vaccinations, total_vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations
FROM PortfolioProject.dbo.CovidDeaths dea 
JOIN PortfolioProject.dbo.CovidVaccinations vac
    ON dea.location = vac.[location]
    AND dea.date = vac.[date]
WHERE dea.continent IS NOT NULL
)

SELECT *, (CAST(total_vaccinations AS float)/population)*100 AS percent_population_vaccinated 
FROM PopvsVac

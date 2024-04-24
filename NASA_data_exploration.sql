-- Data Source: https://www.kaggle.com/datasets/nasa/astronaut-yearbook (last updated 2018)

SELECT * FROM PortfolioProject.dbo.astronauts

-- What are the 10 most common undergraduate majors of NASA astronauts?

SELECT TOP 10 Undergraduate_Major, COUNT(Undergraduate_Major) AS Quantity
FROM PortfolioProject.dbo.astronauts
GROUP BY Undergraduate_Major
ORDER BY Quantity DESC

-- What are the least common undergraduate majors of NASA astronauts? (CTE Table)
 
WITH Undergrad_Major_Quantities AS (
SELECT Undergraduate_Major, COUNT(Undergraduate_Major) AS Quantity
FROM PortfolioProject.dbo.astronauts
GROUP BY Undergraduate_Major
)

SELECT * 
FROM Undergrad_Major_Quantities
WHERE Quantity = 1

-- What are the 10 most common graduate majors of NASA astronauts?

SELECT TOP 10 Graduate_Major, COUNT(Graduate_Major) AS Quantity
FROM PortfolioProject.dbo.astronauts
GROUP BY Graduate_Major
ORDER BY Quantity DESC

-- What are the least common graduate majors of NASA astronauts?

DROP TABLE IF EXISTS #Graduate_Major_Quantities
CREATE TABLE #Graduate_Major_Quantities (
    Graduate_Major NVARCHAR(255),
    Quantity NUMERIC
);

INSERT INTO #Graduate_Major_Quantities
SELECT Graduate_Major, COUNT(Graduate_Major) AS Quantity
From PortfolioProject.dbo.astronauts
GROUP BY Graduate_Major

SELECT *
FROM #Graduate_Major_Quantities
WHERE Quantity = 1

-- What are the statuses of all NASA astronauts?

SELECT Status, COUNT(Status) AS Quantity
FROM PortfolioProject.dbo.astronauts
GROUP BY Status

-- What percentage of all NASA astronauts are active? deceased? retired?

DROP TABLE IF EXISTS #Status

CREATE TABLE #Status (Status NVARCHAR(255), Quantity NUMERIC)

INSERT INTO #Status
SELECT Status, COUNT(Status) AS Quantity
 FROM PortfolioProject.dbo.astronauts
GROUP BY Status

SELECT Status, Quantity, (Quantity/(SELECT SUM(Quantity) FROM #Status))*100 AS Percentage
FROM #Status
GROUP BY Status, Quantity


-- How many inactive astronauts (retired and deceased) were male vs. female?

SELECT Gender, COUNT(Gender) AS Quantity
FROM PortfolioProject.dbo.astronauts
WHERE Status IN ('Deceased', 'Retired')
GROUP BY Gender

-- What percentage of inactive astronauts (retired and deceased) were male vs. female? (Temp Table)

DROP TABLE IF EXISTS #Inactive_Genders

CREATE TABLE #Inactive_Genders (Gender NVARCHAR(255), Quantity NUMERIC)

INSERT INTO #Inactive_Genders
SELECT Gender, COUNT(Gender) AS Quantity
FROM PortfolioProject.dbo.astronauts
WHERE Status IN ('Deceased', 'Retired')
GROUP BY Gender

SELECT Gender, Quantity, (Quantity/(SELECT SUM(Quantity) FROM #Inactive_Genders))*100 AS Percentage_Inactive_Astronauts
FROM #Inactive_Genders
GROUP BY Gender, Quantity

-- How many active astronauts are male vs. female?

SELECT Gender, COUNT(Gender) AS Quantity
FROM PortfolioProject.dbo.astronauts
WHERE Status = 'Active'
GROUP BY Gender

-- What percentage of active astronauts are male vs. female? (CTE)

DROP TABLE IF EXISTS #Active_Genders

CREATE TABLE #Active_Genders (Gender NVARCHAR(255), Quantity NUMERIC)

INSERT INTO #Active_Genders 
SELECT Gender, COUNT(Gender) AS Quantity
FROM PortfolioProject.dbo.astronauts
WHERE Status = 'Active'
GROUP BY Gender

SELECT Gender, Quantity, (Quantity/(SELECT SUM(Quantity) FROM #Active_Genders))*100 AS Percentage_Active_Astronauts
FROM #Active_Genders
GROUP BY Gender, Quantity

-- What generations do NASA astronauts belong to?

DROP TABLE IF EXISTS #Generations

CREATE TABLE #Generations 
(
    Name NVARCHAR(255), 
    Generation NVARCHAR(255)
)

INSERT INTO #Generations
SELECT Name,
CASE
    WHEN Birth_Date BETWEEN '1890-01-01' AND '1915-12-31' THEN 'Lost Generation 1890-1915'
    WHEN Birth_Date BETWEEN '1901-01-01' AND '1913-12-31' THEN 'Interbellum Generation 1901-1913'
    WHEN Birth_Date BETWEEN '1910-01-01' AND '1924-12-31' THEN 'Greatest Generation 1910-1924'
    WHEN Birth_Date BETWEEN '1925-01-01' AND '1945-12-31' THEN 'Silent Generation 1925-1945'
    WHEN Birth_Date BETWEEN '1946-01-01' AND '1964-12-31' THEN 'Baby Boomer 1946-1964'
    WHEN Birth_Date BETWEEN '1965-01-01' AND '1979-12-31' THEN 'Generation X 1965-1979'
    WHEN Birth_Date BETWEEN '1980-01-01' AND '1995-12-31' THEN 'Millenial 1980-1995'
    WHEN Birth_Date BETWEEN '1996-01-01' AND '2010-12-31' THEN 'Generation Z 1996-2010'
    WHEN Birth_Date BETWEEN '2011-01-01' AND '2025-12-31' THEN 'Generation Alpha 2011-2025'
END AS 'Generation'
FROM PortfolioProject.dbo.astronauts

-- What percentage of NASA astronauts belong to each generation?

DROP TABLE IF EXISTS #Generation_Quantities

CREATE TABLE #Generation_Quantities 
(
    Generation NVARCHAR(255), 
    Quantity NUMERIC
)

INSERT INTO #Generation_Quantities
SELECT Generation, COUNT(Generation) AS Quantity
FROM #Generations
GROUP BY Generation
ORDER BY Quantity DESC

SELECT Generation, Quantity, (Quantity/(SELECT SUM(Quantity) FROM #Generation_Quantities))*100 AS Percentage_NASA_Astronauts
FROM #Generation_Quantities

-- What percentage of NASA astronauts are/were in each military branch? 

DROP TABLE IF EXISTS #Military

CREATE TABLE #Military (Name NVARCHAR(255), Military_Branch NVARCHAR(255), Quantity NUMERIC)

INSERT INTO #Military
SELECT Name, Military_Branch, COUNT(Name) OVER (PARTITION BY Military_Branch) AS Quantity
FROM PortfolioProject.dbo.astronauts
GROUP BY Name, Military_Branch


DROP TABLE IF EXISTS #Military_Groups

CREATE TABLE #Military_Groups (Name NVARCHAR(255), Military NVARCHAR (255))

INSERT INTO #Military_Groups
SELECT Name,
CASE 
    WHEN Military_Branch LIKE '%Air Force%' THEN 'US Air Force'
    WHEN Military_Branch LIKE '%Army%' THEN 'US Army'
    WHEN Military_Branch LIKE '%Navy%' THEN 'US Navy'
    WHEN Military_Branch LIKE '%Naval%' THEN 'US Navy'
    WHEN Military_Branch LIKE'%Marine Corps%' THEN 'US Marine Corps'
    WHEN Military_Branch LIKE '%Coast Guard%' THEN 'US Coast Guard'
    WHEN Military_Branch IS NULL THEN 'Non-military'
END AS 'Military'
FROM #Military

DROP TABLE IF EXISTS #MilitaryData

CREATE TABLE #MilitaryData (Military NVARCHAR(255), Quantity NUMERIC)

INSERT INTO #MilitaryData
SELECT Military, COUNT(Military) AS Quantity
FROM #Military_Groups
GROUP BY Military

SELECT Military, Quantity, (Quantity/(SELECT SUM(Quantity) FROM #MilitaryData))*100 AS Percentage
FROM #MilitaryData
GROUP BY Military, Quantity

-- What military ranks did NASA astronauts achieve? 

UPDATE PortfolioProject.dbo.astronauts
SET Military_Rank = 'Nonmilitary' 
WHERE Military_Rank IS NULL

DROP TABLE IF EXISTS #Military_Rank
CREATE TABLE #Military_Rank (Military_rank NVARCHAR(50), Quantity NUMERIC)

INSERT INTO #Military_Rank
SELECT Military_Rank, COUNT(Military_Rank) AS Quantity
FROM PortfolioProject.dbo.astronauts
GROUP BY Military_Rank

SELECT * FROM #Military_Rank

SELECT Military_Rank, Quantity, (Quantity / (SELECT SUM(Quantity) FROM #Military_Rank))*100 AS Percentage
FROM #Military_Rank
ORDER BY Quantity DESC

-- How many space flights do NASA astronauts complete, on average? MIN? MAX?

SELECT AVG(Space_Flights) AS avg_spaceflights, MIN(Space_Flights) AS fewest_spaceflights, MAX(Space_Flights) AS most_spaceflights
FROM PortfolioProject.dbo.astronauts

-- How many space flights do male vs. female NASA astronauts complete, on average? MIN? MAX?

SELECT gender, AVG(Space_Flights) AS avg_spaceflights, MIN(Space_Flights) AS fewest_spaceflights, MAX(Space_Flights) AS most_spaceflights
FROM PortfolioProject.dbo.astronauts
GROUP BY gender

-- How many space walks do NASA astronauts complete, on average? MIN? MAX?

SELECT AVG(Space_Walks) AS avg_spacewalks, MIN(Space_Walks) AS fewest_spacewalks, MAX(Space_Walks) AS most_spacewalks
FROM PortfolioProject.dbo.astronauts

-- How many space walks do male vs. female NASA astronauts complete, on average? MIN? MAX?

SELECT gender, AVG(Space_Walks) AS avg_spacewalks, MIN(Space_Walks) AS fewest_spacewalks, MAX(Space_Walks) AS most_spacewalks
FROM PortfolioProject.dbo.astronauts
GROUP BY gender

SELECT * FROM PortfolioProject.dbo.astronauts

-- How many space flight hours do NASA astronauts complete, on average? MIN? MAX?

SELECT AVG(Space_Flight_hr) AS avg_spaceflight_hrs, MIN(Space_Flight_hr) AS fewest_spaceflight_hrs, MAX(Space_Flight_hr) AS most_spaceflight_hrs
FROM PortfolioProject.dbo.astronauts

-- How many space flight hours do male vs. female NASA astronauts complete, on average? MIN? MAX?

SELECT gender, AVG(Space_Flight_hr) AS avg_spaceflight_hrs, MIN(Space_Flight_hr) AS fewest_spaceflight_hrs, MAX(Space_Flight_hr) AS most_spaceflight_hrs
FROM PortfolioProject.dbo.astronauts
GROUP BY gender

-- How many space walk hours do NASA astronauts complete, on average? MIN? MAX?

SELECT AVG(Space_Walks_hr) AS avg_spacewalk_hrs, MIN(Space_Walks_hr) AS fewest_spacewalk_hrs, MAX(Space_Walks_hr) AS most_spacewalk_hrs
FROM PortfolioProject.dbo.astronauts

-- How many space walk hours do male vs. female NASA astronauts complete, on average? MIN? MAX?

SELECT gender, AVG(Space_Walks_hr) AS avg_spacewalk_hrs, MIN(Space_Walks_hr) AS fewest_spacewalk_hrs, MAX(Space_Walks_hr) AS most_spacewalk_hrs
FROM PortfolioProject.dbo.astronauts
GROUP BY gender

-- Which NASA missions have resulted in deathes? How many?

SELECT Death_Mission, COUNT(Death_Mission) AS Deaths
FROM PortfolioProject.dbo.astronauts
WHERE Death_Mission IS NOT NULL
GROUP BY Death_Mission

-- Which astronauts died during a NASA mission? What mission?

SELECT Name, Death_Mission
FROM PortfolioProject.dbo.astronauts
WHERE Death_Mission IS NOT NULL
ORDER BY 2 

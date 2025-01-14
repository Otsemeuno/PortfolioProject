--Checking the data copied correctly to both tables
--SELECT *
--FROM PortfolioProject.dbo.CovidVaccinations
--ORDER BY 3,4

--SELECT *
--FROM PortfolioProject.dbo.CovidDeaths
--ORDER BY 3,4

--Selecting data used for the project
SELECT country, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


--Data Exploration
--Finding out how many died vs how many cases in my current location
--Filter by your country or current location
SELECT country, date, total_cases, total_deaths, (total_deaths/total_cases) *100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE total_cases <> 0 AND country LIKE '%kingdom%'
ORDER BY 1,2

--Total Cases vs Population in my current location
SELECT country, date, population, total_deaths, (total_deaths/population) *100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE total_cases <> 0 AND country LIKE '%kingdom%'
ORDER BY 1,2

--Find out countries with highest rate compared to population
SELECT country, Population, MAX(total_cases) AS TotalCases,  MAX(total_cases/population) *100 AS PopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY country, population
ORDER BY 4 DESC

--Find out countries with highest death count per population
SELECT country, Population, MAX(total_deaths) AS TotalDeath, MAX(total_deaths/population) *100 AS PopulationDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY country, population
ORDER BY 3 DESC

--Find out continents with highest death count per population
WITH country_max
AS
(SELECT country, continent, MAX(Population) AS Total_Population, MAX(total_deaths) AS TotalDeath, MAX(total_deaths/population) *100 AS PopulationDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY country, continent
)
SELECT continent, SUM(TotalDeath) AS DeathInContinent
FROM country_max
GROUP BY continent
ORDER BY 2 DESC

--OR (The first one will give a more accurate info based on the content of the data

SELECT country, Population, MAX(total_deaths) AS TotalDeath, MAX(total_deaths/population) *100 AS PopulationDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS  NULL
GROUP BY country, population
ORDER BY 2 DESC

--finding all the countries in a certain continent

SELECT country
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND continent LIKE '%africa%'
GROUP BY country
ORDER BY 1

--Finding out number of new cases each day all over the world

SELECT date, SUM(new_cases) AS WorldCaseCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

--Global Numbers
SELECT date, SUM(new_cases) AS WorldCaseDailyCount, SUM(new_deaths) AS WorldDailyDeathCount, SUM(new_deaths)/SUM(new_cases) * 100 AS DailyDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND new_cases <> 0
GROUP BY date
ORDER BY 1

--Total world count

SELECT SUM(new_cases) AS WorldCaseCount, SUM(new_deaths) AS WorldDeathCount, SUM(new_deaths)/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND new_cases <> 0
ORDER BY 1

--Total vaccinated people compared to population
SELECT deat.continent, deat.country, deat.date, deat.population, vacc.new_vaccinations
, SUM(TRY_CAST(ROUND(TRY_CAST(vacc.new_vaccinations AS FLOAT),0)AS BIGINT)) OVER (PARTITION BY deat.country) AS parted
--convert from vchar to float first before converting to int
--used nig int because the sum of values in the column were greater than abs(2,147,483,648)
FROM PortfolioProject..CovidDeaths deat
JOIN PortfolioProject..CovidVaccinations vacc
ON deat.country = vacc.country AND deat.date = vacc.date
WHERE deat.continent IS NOT NULL AND vacc.new_vaccinations IS NOT NULL AND TRY_CAST(vacc.new_vaccinations AS FLOAT) <> 0
ORDER BY 2,3


--Arranged better and clearer
SELECT 
    deat.continent, 
    deat.country, 
    deat.date, 
    deat.population, 
    vacc.new_vaccinations,
    SUM(CAST(ROUND(CAST(vacc.new_vaccinations AS FLOAT), 0) AS BIGINT)) 
        OVER (PARTITION BY deat.country ORDER BY deat.country, deat.date) AS RollingTotalVaccinations
FROM 
    PortfolioProject..CovidDeaths deat
JOIN 
    PortfolioProject..CovidVaccinations vacc
ON 
    deat.country = vacc.country 
    AND deat.date = vacc.date
WHERE 
    deat.continent IS NOT NULL 
   -- AND TRY_CAST(vacc.new_vaccinations AS FLOAT) IS NOT NULL
    AND TRY_CAST(vacc.new_vaccinations AS FLOAT) <> 0
ORDER BY 
    deat.country, deat.date;

--Total population vs vaccination using CTE
WITH poptable(continent, country, date, population, new_vaccines, rollingtotal_vaccinations)  
AS
(SELECT 
    deat.continent, 
    deat.country, 
    deat.date, 
    deat.population, 
    vacc.new_vaccinations,
    SUM(CAST(ROUND(CAST(vacc.new_vaccinations AS FLOAT), 0) AS BIGINT)) 
        OVER (PARTITION BY deat.country ORDER BY deat.country, deat.date) AS RollingTotalVaccinations
FROM 
    PortfolioProject..CovidDeaths deat
JOIN 
    PortfolioProject..CovidVaccinations vacc
ON 
    deat.country = vacc.country 
    AND deat.date = vacc.date
WHERE 
    deat.continent IS NOT NULL 
   -- AND TRY_CAST(vacc.new_vaccinations AS FLOAT) IS NOT NULL
    AND TRY_CAST(vacc.new_vaccinations AS FLOAT) <> 0
)
SELECT *, (rollingtotal_vaccinations/population)*100 AS VACCPERCENTAGE
FROM poptable

-- Do something similar using temp table
DROP TABLE IF EXISTS #TempPopTable
CREATE TABLE #TempPopTable
(continent nvarchar (255),
country nvarchar (255),
date datetime,
population bigint,
new_vaccines int,
rollingtotal_vaccinations BIGINT
)

INSERT INTO #TempPopTable
SELECT 
    deat.continent, 
    deat.country, 
    deat.date, 
    deat.population, 
    vacc.new_vaccinations,
    SUM(CAST(ROUND(CAST(vacc.new_vaccinations AS FLOAT), 0) AS BIGINT)) 
        OVER (PARTITION BY deat.country ORDER BY deat.country, deat.date) AS RollingTotalVaccinations
FROM 
    PortfolioProject..CovidDeaths deat
JOIN 
    PortfolioProject..CovidVaccinations vacc
ON 
    deat.country = vacc.country 
    AND deat.date = vacc.date
WHERE 
    deat.continent IS NOT NULL 
   -- AND TRY_CAST(vacc.new_vaccinations AS FLOAT) IS NOT NULL
    AND TRY_CAST(vacc.new_vaccinations AS FLOAT) <> 0

--Creating Views for future manipulations or description
CREATE VIEW PerPopVacc
AS
SELECT deat.continent, deat.country, deat.date, deat.population, vacc.new_vaccinations
, SUM(TRY_CAST(ROUND(TRY_CAST(vacc.new_vaccinations AS FLOAT),0)AS BIGINT)) 
	 OVER (PARTITION BY deat.country ORDER BY deat.country, deat.date) AS RollingTotalVaccinations
--convert from vchar to float first before converting to int
--used nig int because the sum of values in the column were greater than abs(2,147,483,648)
FROM PortfolioProject..CovidDeaths deat
JOIN PortfolioProject..CovidVaccinations vacc
ON deat.country = vacc.country AND deat.date = vacc.date
WHERE deat.continent IS NOT NULL AND vacc.new_vaccinations IS NOT NULL AND TRY_CAST(vacc.new_vaccinations AS FLOAT) <> 0

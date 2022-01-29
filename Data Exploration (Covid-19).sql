-- Data exploration with SQL

-- 1.
-- Starting with a simple query


SELECT *
FROM   coviddeaths
WHERE  continent IS NOT NULL  -- As some data in location column is not correct where continent column is NULL

-- 2.


SELECT   location,
         date,
	     total_cases,
	     new_cases,
	     total_deaths,
	     population
FROM     coviddeaths
WHERE    continent IS NOT NULL
ORDER BY location,
		 date

-- 3.
-- Looking at total cases vs total deaths


SELECT   location,
         date,
	     total_cases,
	     total_deaths,
	     ROUND((total_deaths/total_cases)*100,2) AS 'Death Percentage'
FROM     coviddeaths
WHERE    continent IS NOT NULL
ORDER BY location,
		 date

-- 4.
-- Looking at the death percentage of Pakistan
-- Shows the likelihood of dying if you caught covid-19 in Pakistan


SELECT   location,
         date,
		-- new_cases,
		-- new_deaths,
		-- CASE WHEN new_cases != 0 THEN ROUND((new_deaths/new_cases)*100,2) ELSE '' END AS 'Daily Death Percentage',
	     total_cases,
	     total_deaths,
	     (total_deaths/total_cases)*100 AS 'Total Death Percentage'
FROM     coviddeaths
WHERE    continent IS NOT NULL
AND      location = 'Pakistan'
    

-- 5.
-- Looking at total cases vs population 
-- Shows what percentage of population got covid


SELECT   location,
         date,
		 population,
	     total_cases,
	     (total_cases/population)*100 AS 'Percent Population Infected'
FROM     coviddeaths
WHERE    continent IS NOT NULL
-- WHERE    location = 'Pakistan'
ORDER BY location,
         date

-- 6.
-- Looking at countries with highest infection count


SELECT   location,
		 population,
	     MAX (total_cases) AS 'Highest Infection Count',
	     MAX (total_cases/population)*100 AS 'Percent Population Infected'
FROM     coviddeaths
WHERE    continent IS NOT NULL
GROUP BY location,
		 population
ORDER BY 'Percent Population Infected' DESC

-- 7.
-- Showing countries with highest death count per population


SELECT   location,
	     MAX (CAST (total_deaths AS INT)) AS 'Highest Death Count'
	    -- MAX (total_deaths/population)*100 AS 'Percent Population Died'
FROM     coviddeaths
WHERE    continent IS NOT NULL
GROUP BY location
ORDER BY 'Highest Death Count' DESC

-- 8.
-- Let's break things by continent


SELECT   continent,
	     MAX (CAST (total_deaths AS INT)) AS 'Total Death Count'
	    -- MAX (total_deaths/population)*100 AS 'Percent Population Died'
FROM     coviddeaths
WHERE    continent IS NOT NULL
GROUP BY continent
ORDER BY 'Total Death Count' DESC

-- 9.
-- Global numbers


SELECT  --date,
         SUM (new_cases)  AS 'Total Cases',
	     SUM (CAST (new_deaths AS INT)) AS 'Total Deaths',
		 SUM (CAST (new_deaths AS INT))/SUM (new_cases)*100 AS 'Death Percentage'
FROM     coviddeaths
--WHERE    new_cases != 0
WHERE     continent IS NOT NULL
--GROUP BY date
--ORDER BY date

-- 10.
-- Global numbers per day


SELECT  date,
         SUM (new_cases)  AS 'Total Cases',
	     SUM (CAST (new_deaths AS INT)) AS 'Total Deaths',
		 SUM (CAST (new_deaths AS INT))/SUM (new_cases)*100 AS 'Death Percentage'
FROM     coviddeaths
--WHERE    new_cases != 0
WHERE      continent IS NOT NULL
GROUP BY date
ORDER BY date

-- 11.
-- Joining coviddeaths with covidvaccination


SELECT   *
FROM     coviddeaths cd
JOIN     covidvaccination cv ON  cd.location = cv.location
                             AND cd.date = cv.date  
ORDER BY cd.date

-- 12.
-- Looking at total population vs total vaccination


SELECT   cd.continent,
         cd.location,
         cd.date,
		 cd.population,
		 cv.new_vaccinations
FROM     coviddeaths cd 
JOIN     covidvaccination cv ON cd.location = cv.location
AND                             cd.date = cv.date
WHERE    cd.continent IS NOT NULL
ORDER BY cd.location,
         cd.date

-- 13.         
-- Rolling people vaccination using windowing and convert


SELECT   cd.continent,
         cd.location,
         cd.date,
		 cd.population,
		 cv.new_vaccinations,
		 SUM (CONVERT (BIGINT, cv.new_vaccinations)) OVER (PARTITION BY cd.location 
		                                                   ORDER BY     cd.location, cd.date) AS 'Rolling People Vaccinated'
FROM     coviddeaths cd 
JOIN     covidvaccination cv ON cd.location = cv.location
AND                             cd.date = cv.date
WHERE    cd.continent IS NOT NULL
ORDER BY cd.location,
         cd.date

-- 14.
--Using CTE 


WITH PopvsVac (continent,
               location,
               date,
		       population,
		       new_vaccinations,
			   RollingPeopleVaccinated)
AS
(
SELECT   cd.continent,
         cd.location,
         cd.date,
		 cd.population,
		 cv.new_vaccinations,
		 SUM (CONVERT (BIGINT, cv.new_vaccinations)) OVER (PARTITION BY cd.location 
		                                                   ORDER BY     cd.location, cd.date) AS 'RollingPeopleVaccinated'
FROM     coviddeaths cd 
JOIN     covidvaccination cv ON cd.location = cv.location
AND                             cd.date = cv.date
WHERE    cd.continent IS NOT NULL
--ORDER BY cd.location,
         --cd.date
)
SELECT *,
       (RollingPeopleVaccinated/population)*100 
FROM   PopvsVac

-- 15.
-- TEMP Table


DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent               nvarchar (255),
location                nvarchar (255),
date                    datetime,
population              bigint,
new_vaccination         bigint,
RollingPeopleVaccinated bigint
)
INSERT INTO #PercentPopulationVaccinated
SELECT   cd.continent,
         cd.location,
         cd.date,
		 cd.population,
		 cv.new_vaccinations,
		 SUM (CONVERT (BIGINT, cv.new_vaccinations)) OVER (PARTITION BY cd.location 
		                                                   ORDER BY     cd.location, cd.date) AS 'RollingPeopleVaccinated'
FROM     coviddeaths cd 
JOIN     covidvaccination cv ON cd.location = cv.location
AND                             cd.date = cv.date
WHERE    cd.continent IS NOT NULL
--ORDER BY cd.location,
         --cd.date

SELECT *,
       (RollingPeopleVaccinated/population)*100 
FROM   #PercentPopulationVaccinated

-- 16.
--Creating View to store data fot later visualization


CREATE VIEW PercentPopulationVaccinated
AS 
SELECT   cd.continent,
         cd.location,
         cd.date,
		 cd.population,
		 cv.new_vaccinations,
		 SUM (CONVERT (BIGINT, cv.new_vaccinations)) OVER (PARTITION BY cd.location 
		                                                   ORDER BY     cd.location, cd.date) AS 'RollingPeopleVaccinated'
FROM     coviddeaths cd 
JOIN     covidvaccination cv ON cd.location = cv.location
AND                             cd.date = cv.date
WHERE    cd.continent IS NOT NULL
--ORDER BY cd.location,
         --cd.date
GO 

SELECT *
FROM   PercentPopulationVaccinated




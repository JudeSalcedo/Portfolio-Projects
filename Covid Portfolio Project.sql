SELECT *
FROM PortfolioProject.DBO.CovidDeaths
Where continent is not null
ORDER BY 3, 4

-- Select data that to be used

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.DBO.CovidDeaths
ORDER BY 1, 2

-- Looking at total case and total deaths

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 As DeathPercent
FROM PortfolioProject..CovidDeaths
Where location like '%Philippines%'
and continent is not null
Group By location, date, total_cases, total_deaths
ORDER BY 2 desc

--Use ALTER table and Alter column if a column is nvarchar
-- integer for whole numbers, float for decimals

Alter table PortfolioProject..CovidDeaths
Alter column total_cases float

-- Total Cases vs Population


SELECT Location, date, total_cases, total_deaths, population, (total_cases/population)*100 As CasePercentage
FROM PortfolioProject..CovidDeaths
Where location like '%Philippines%'
ORDER BY 2 desc

--Highest infection rate

SELECT Location, population, MAX(total_cases) As MaxCases, MAX((total_cases/population))*100 As InfectionPercent
FROM PortfolioProject..CovidDeaths
--Where location like '%Philippines%'
Where continent is not null
Group by location, population
ORDER BY 4 desc

--Death Count of a Population

SELECT Location, Population, MAX(total_deaths) As TotalDeaths
FROM PortfolioProject..CovidDeaths
--Where location like '%Philippines%'
Where continent is not null
Group by location, population
ORDER BY 2 desc 

--By Continent

--Continents with highest death count per population

SELECT continent, MAX(total_deaths) As TotalDeaths
FROM PortfolioProject..CovidDeaths
--Where continent like '%Asia%'
Where continent is not null
Group by continent

--Global Numbers
--Use Nullif directly on the possible zero columns

SELECT sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths, (sum(new_deaths)/(sum(new_cases)))*100 As DeathPercent
FROM PortfolioProject..CovidDeaths
--Where location like '%Philippines%'
Where continent is not null


--Total population vs Vaccination


Select *
From PortfolioProject..CovidVaccination

Select *
From PortfolioProject..CovidDeaths

Select dea.location, dea.population, vac.date, vac.total_vaccinations
From PortfolioProject.dbo.CovidDeaths dea 
	JOIN PortfolioProject..CovidVaccination vac
	On dea.location = vac.location
	--and dea.date = vac.date
--Where dea.location like '%Philippines%'
Group by vac.date, dea.Location, dea.population, vac.date, vac.total_vaccinations
Order by 3 desc

-- total vaccination

Select dea.location, dea.population, vac.total_vaccinations, (vac.total_vaccinations)/(dea.population)*100 AS PercentVax
From PortfolioProject.dbo.CovidDeaths dea 
	JOIN PortfolioProject..CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.location like '%Philippines%'
Group by  dea.Location, dea.population, vac.total_vaccinations
Order by 4 desc

--Aside from Alter, use cast or convert to modify data types

sum(cast(nullif(vac.new_vaccinations,0) as bigint))
sum(convert,(bigint,vac.new_vaccincations))

--Rolling Count / Cumulative count by date using Over and Partition By

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(vac.new_vaccinations) --sum(cast(nullif(vac.new_vaccinations,0) as bigint))
OVER (Partition by dea.location Order by dea.location, dea.date) As RollingCountVax
--(RollingCountVax/population)*100
From PortfolioProject.dbo.CovidDeaths dea
Inner Join PortfolioProject.dbo.CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
And dea.Location like '%Philippines%'
Group by dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
order by 2,3

--using CTE
--Convert computational values from int or nvarchar to float to show significant values from division

Alter table PortfolioProject..CovidDeaths
Alter column population float

Alter table PortfolioProject..CovidVaccination
Alter column new_vaccinations float


With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingCountVax)
AS
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(vac.new_vaccinations) --sum(cast(nullif(vac.new_vaccinations,0) as bigint))
OVER (Partition by dea.location Order by dea.location, dea.date) As RollingCountVax
--(RollingCountVax/population)*100
From PortfolioProject.dbo.CovidDeaths dea
Inner Join PortfolioProject.dbo.CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Group by dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--order by 2,3
)

Select *, (RollingCountVax/Population)*100 As PercentVax
From PopvsVac
Where RollingCountVax is not null
AND Location like '%Philippines%'
Order by 6 desc

--Using Insert
Drop Table if exists #PercentPopulationVaccinated

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingCountVax numeric
)

Insert into #PercentPopulationVaccinated

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(vac.new_vaccinations) --sum(cast(nullif(vac.new_vaccinations,0) as bigint))
OVER (Partition by dea.location Order by dea.location, dea.date) As RollingCountVax
--(RollingCountVax/population)*100
From PortfolioProject.dbo.CovidDeaths dea
Inner Join PortfolioProject.dbo.CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
--Where dea.continent is not null
Group by dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--order by 2,3

Select *, (RollingCountVax/Population)*100 As PercentVax
From #PercentPopulationVaccinated
Where Location like '%Philippines%'
Order By 7 desc

--Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(vac.new_vaccinations) 
OVER (Partition by dea.location Order by dea.location, dea.date) As RollingCountVax
From PortfolioProject.dbo.CovidDeaths dea
Inner Join PortfolioProject.dbo.CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Group by dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--order by 2,3

Create View CovidDeathRate as
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 As DeathPercent
FROM PortfolioProject..CovidDeaths
Where location like '%Philippines%'
and continent is not null
Group By location, date, total_cases, total_deaths

Create View AsiaCovidDeathToll as
SELECT continent, location, MAX(total_deaths) As TotalDeaths
FROM PortfolioProject..CovidDeaths
Where continent like '%Asia%'
and  continent is not null
Group by continent, location

Create View GlobalNumbers as
SELECT sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths, (sum(new_deaths)/(sum(new_cases)))*100 As DeathPercent
FROM PortfolioProject..CovidDeaths
--Where location like '%Philippines%'
Where continent is not null


--Collection of Views compiled

Select *
From PercentPopulationVaccinated

Select *
From CovidDeathRate

Select *
From AsiaCovidDeathToll

Select *
From GlobalNumbers
-- covid data exploratory project

select *
from coviddeaths
where trim(coviddeaths.continent) <> ''
order by 3,4;

select *
from covidvaccinations
order by 3,4;

select location,date,total_cases,new_cases,total_deaths,population
from coviddeaths
order by 1,2;

select date ,
str_to_date(date,'%m/%d/%Y')
from coviddeaths;

update coviddeaths
set date = str_to_date(date,'%m/%d/%Y');

alter table coviddeaths
modify column date DATE;

select date ,
str_to_date(date,'%m/%d/%Y')
from covidvaccinations;

update covidvaccinations
set date = str_to_date(date,'%m/%d/%Y');

alter table covidvaccinations
modify column date DATE;


select new_deaths,
cast(new_deaths as unsigned)
from coviddeaths;
UPDATE coviddeaths
SET new_deaths = 0
WHERE new_deaths = '';
ALTER TABLE coviddeaths
MODIFY COLUMN new_deaths BIGINT;


select date ,
str_to_date(date,'%m/%d/%Y')
from covidvaccinations;

update covidvaccinations
set date = str_to_date(date,'%m/%d/%Y');

alter table covidvaccinations
modify column date DATE;

-- looking at total cases vs total deaths
-- shows likelyhood of dying if you contract covid
select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as death_percentage
from coviddeaths
where location like '%india%'
order by 1,2;


-- looking at total cases vs population 
-- shows percentage of population affected by the virus
select location,date,total_cases,population,(total_cases/population)*100 as percentage_affected
from coviddeaths
-- where location like '%india%'
order by 1,2;

-- looking at countries with highest infection rate compared to population
select location,population,max(total_cases) as highest_infection_count,max((total_cases/population))*100 as percentage_population_affected 
from coviddeaths
group by population , location 
order by percentage_population_affected desc;

-- looking at countries with highest death count per population 
select location,max(cast(total_deaths as unsigned)) as total_death_count
from coviddeaths
where continent is not null and continent != ''
group by  location 
order by total_death_count desc;

-- showing continents with highest death count 
Select continent, SUM(new_deaths) as TotalDeathCount
From coviddeaths
where trim(coviddeaths.continent) <> ''
and location not in ('World', 'European Union', 'International')
Group by continent 
order by TotalDeathCount desc;

-- global numbers
select  sum(new_cases) as totalcases, sum(new_deaths) as totaldeath,(sum(new_deaths)/sum(new_cases))*100 as deathpercentage
from coviddeaths
where trim(continent) <> ''
order by 1,2;


-- joining coviddeaths and vaccinations 
select *
from coviddeaths
join covidvaccinations
	on coviddeaths.location = covidvaccinations.location 
    and coviddeaths.date = covidvaccinations.date;

    
-- looking at total population vs vaccinations 
select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(new_vaccinations) over ( partition by d.location order by d.location,d.date) as rolling_vaccinations
from coviddeaths d
join covidvaccinations v
	on d.location = v.location 
    and d.date = v.date
where trim(d.continent) <> ''
order by 2,3;


-- using CTE
with popvsvac ( continent , location , date , population ,new_vaccinations, rolling_vaccinations)
as (
select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(new_vaccinations) over ( partition by d.location order by d.location,d.date) as rolling_vaccinations
from coviddeaths d
join covidvaccinations v
	on d.location = v.location 
    and d.date = v.date
where trim(d.continent) <> ''
)
select * , ( rolling_vaccinations/population)*100
from popvsvac
where location like '%india%';


-- usign temp table
drop table if exists percentpopvaccinated;
create table percentpopvaccinated
(continent nvarchar(255), location nvarchar(255), date datetime , population numeric,new_vaccinations numeric, rolling_vaccinations numeric);

update covidvaccinations
set new_vaccinations = '0'
where new_vaccinations = '';

insert into percentpopvaccinated
select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(new_vaccinations) over ( partition by d.location order by d.location,d.date) as rolling_vaccinations
from coviddeaths d
join covidvaccinations v
	on d.location = v.location 
    and d.date = v.date
where trim(d.continent) <> '';

select * , ( rolling_vaccinations/population)*100
from percentpopvaccinated
where location like '%india%';


-- creating view to store data for later visulizations 

create view populationrollingvaccinated as 
select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(new_vaccinations) over ( partition by d.location order by d.location,d.date) as rolling_vaccinations
from coviddeaths d
join covidvaccinations v
	on d.location = v.location 
    and d.date = v.date
where trim(d.continent) <> ''
order by 2,3;

create view populationaffected as 
select location,population,max(total_cases) as highest_infection_count,max((total_cases/population))*100 as percentage_population_affected 
from coviddeaths
group by population , location 
order by percentage_population_affected desc;


create view continentdeathcount as 
Select continent, SUM(new_deaths) as TotalDeathCount
From coviddeaths
where trim(coviddeaths.continent) <> ''
and location not in ('World', 'European Union', 'International')
Group by continent 
order by TotalDeathCount desc;


create view countryhighestdeathcount as 
select location,max(cast(total_deaths as unsigned)) as total_death_count
from coviddeaths
where continent is not null and continent != ''
group by  location 
order by total_death_count desc;

create view percentageaffected as 
select location,date,total_cases,population,(total_cases/population)*100 as percentage_affected
from coviddeaths
order by 1,2;

create view globalnumbers as 
select  sum(new_cases) as totalcases, sum(new_deaths) as totaldeath,(sum(new_deaths)/sum(new_cases))*100 as deathpercentage
from coviddeaths
where trim(continent) <> ''
order by 1,2;



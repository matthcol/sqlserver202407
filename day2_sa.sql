-- date and times
-- conforme à l'ISO 8061
-- https://learn.microsoft.com/fr-fr/sql/t-sql/functions/date-and-time-data-types-and-functions-transact-sql?view=sql-server-ver16
--
-- date: année mois jour
-- time: heure minute seconde, fraction (7 chiffres après la virgule)
-- datetime: date + time, précision en ms
-- datetime2: date + time, précision (7 chiffres après la virgule)
-- smalldatetime: date + time: 1900-01-01 à 2079-06-06 et précision à la seconde

-- functions: YEAR, MONTH, DAY

select 
	name,
	birthdate,
	YEAR(birthdate) as birth_year,
	datepart(year, birthdate) as bith_year2
from person
where YEAR(birthdate) = 1930;

select
	CURRENT_TIMESTAMP -- datetime
	, GETDATE()  -- datetime
	, SYSDATETIME() -- datetime2
	, DATEPART(hour, CURRENT_TIMESTAMP) as heure
	-- CURRENT_DATE,
	-- CURRENT_TIME
;

-- https://learn.microsoft.com/fr-fr/sql/t-sql/functions/cast-and-convert-transact-sql?view=sql-server-ver16
-- tableau de styles pour les conversions (temporel, numérique et monnaie)
select
	CAST(CURRENT_TIMESTAMP as date) as aujourdhui
	, CAST(CURRENT_TIMESTAMP as time) as maintenant
;

select
	CONVERT(date, '16/07/2024', 103)  -- 103 = dd/mm/yyyy
;

-- implicit conversion
set dateformat ymd;
select * from person where birthdate = '1930-08-25';
select * from person where birthdate between '1930-07-01' and '1930-08-31';

set dateformat dmy;
select * from person where birthdate = '25/08/1930';

-- liste complète des fonctions
-- https://learn.microsoft.com/fr-fr/sql/t-sql/functions/functions?view=sql-server-ver16

-- aggregat vs fenetrage (analytique, classement, ...)
select
	year,
	count(*) as nb_movie
from movie
where year between 1980 and 1989
group by year
order by year;

select
	title,
	year,
	count(*) over (partition by year) as nb_movie_year
from movie
where year between 1980 and 1989
order by year;
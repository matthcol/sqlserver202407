select title, year, synopsis from movie where year = 2024;
select count(*) from person;

create view v_movie_current_year as
	select title, year, synopsis 
	from movie 
	where year = YEAR(current_timestamp);

select * from v_movie_current_year;
select count(*) from person;

SELECT * FROM INFORMATION_SCHEMA.TABLES;
select * from v_movie_current_year;
select title, year, synopsis from movie where year >= 2020;

-- after grant insert and update privileges
insert into v_movie_current_year (title, year) values ('Despicable 4', 2024);
select * from v_movie_current_year;
-- ko: insert into v_movie_current_year (title, year) values ('Despicable', 2010);
-- ko: update v_movie_current_year set year = 2023 where title = 'Dune: Part Two';
update v_movie_current_year set synopsis = 'a movie with bad and ugly people' where title = 'Despicable 4';
select * from v_movie_current_year;
-- ko: update v_movie_current_year set title = 'Despicable 44' where title = 'Despicable 4';
-- ko: delete from v_movie_current_year where title = 'Despicable 4';





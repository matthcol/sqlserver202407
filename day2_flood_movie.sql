use dbmovie2;
go

DECLARE @Iteration INT = 1000;
WHILE @Iteration < 32768
BEGIN
	INSERT INTO movie (title, year) values (concat('Star Wars ', @Iteration), 2024 + @Iteration);
	SET @Iteration += 1;
END;
go

-- select max(year) from movie;


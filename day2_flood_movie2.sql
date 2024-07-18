use dbmovie2;
go

DECLARE @Iteration INT = 0;
WHILE @Iteration < 1000000
BEGIN
	INSERT INTO movie (title, year) values (concat('Despicable ', @Iteration), 2025);
	SET @Iteration += 1;
END;
go

-- select max(year) from movie;


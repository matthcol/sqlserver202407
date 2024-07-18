use dbmovie;
go

DECLARE @Iteration INT = 0;
WHILE @Iteration < 1000000
BEGIN
	INSERT INTO movie (title, year) values (concat('Jeudi', @Iteration), 2029);
	SET @Iteration += 1;
END;
go

-- 1_000_000 insert => 7'50
-- select max(year) from movie;


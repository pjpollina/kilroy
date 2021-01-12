DROP FUNCTION IF EXISTS SEMESTER;
DROP FUNCTION IF EXISTS MONTH_IS;
DROP FUNCTION IF EXISTS SEMESTER_IS;
DROP PROCEDURE IF EXISTS WEEK_RUNS;
DROP PROCEDURE IF EXISTS MONTH_RUNS;
DROP PROCEDURE IF EXISTS SEMESTER_RUNS;
DROP PROCEDURE IF EXISTS YEAR_RUNS;

DELIMITER #
CREATE FUNCTION SEMESTER(cd_date DATE) RETURNS INTEGER DETERMINISTIC
BEGIN
  RETURN ((MONTH(cd_date) > 6) + 1);
END#

CREATE FUNCTION MONTH_IS(cd_date DATE, year INTEGER, month INTEGER) RETURNS INTEGER DETERMINISTIC
BEGIN
  RETURN (MONTH(cd_date)=month AND YEAR(cd_date)=year);
END#

CREATE FUNCTION SEMESTER_IS(cd_date DATE, year INTEGER, semester INTEGER) RETURNS INTEGER DETERMINISTIC
BEGIN
  RETURN (SEMESTER(cd_date)=semester AND YEAR(cd_date)=year);
END#

CREATE PROCEDURE WEEK_RUNS(sday DATE, fday DATE)
BEGIN
  SELECT cd_mph AS speed, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance
  FROM cardio WHERE cd_date BETWEEN sday AND fday GROUP BY speed
  UNION ALL
  SELECT "ALL" AS speed, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance
  FROM cardio WHERE cd_date BETWEEN sday AND fday ORDER BY speed;
END #

CREATE PROCEDURE MONTH_RUNS(month INTEGER, year INTEGER)
BEGIN
  SELECT cd_mph AS speed, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance
  FROM cardio WHERE MONTH_IS(cd_date, year, month) GROUP BY speed
  UNION ALL
  SELECT "ALL" AS speed, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance
  FROM cardio WHERE MONTH_IS(cd_date, year, month) ORDER BY speed;
END #

CREATE PROCEDURE SEMESTER_RUNS(semester INTEGER, year INTEGER)
BEGIN
  SELECT cd_mph AS speed, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance
  FROM cardio WHERE SEMESTER_IS(cd_date, year, semester) GROUP BY speed
  UNION ALL
  SELECT "ALL" AS speed, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance
  FROM cardio WHERE SEMESTER_IS(cd_date, year, semester) ORDER BY speed;
END #

CREATE PROCEDURE YEAR_RUNS(year INTEGER)
BEGIN
  SELECT cd_mph AS speed, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance
  FROM cardio WHERE YEAR(cd_date)=year GROUP BY speed
  UNION ALL
  SELECT "ALL" AS speed, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance
  FROM cardio WHERE YEAR(cd_date)=year ORDER BY speed;
END #
DELIMITER ;

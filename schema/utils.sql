DROP FUNCTION IF EXISTS SEMESTER;
DROP PROCEDURE IF EXISTS MONTH_RUNS;
DROP PROCEDURE IF EXISTS SEMESTER_RUNS;
DROP PROCEDURE IF EXISTS YEAR_RUNS;

DELIMITER #
CREATE FUNCTION SEMESTER(cd_date DATE) RETURNS INTEGER DETERMINISTIC
BEGIN
  RETURN ((MONTH(cd_date) > 6) + 1);
END#

CREATE PROCEDURE MONTH_RUNS(month INTEGER, year INTEGER)
BEGIN
  SELECT cd_mph AS speed, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance
  FROM cardio WHERE MONTH(cd_date)=month AND YEAR(cd_date)=year
  GROUP BY speed ORDER BY speed;
END #

CREATE PROCEDURE SEMESTER_RUNS(semester INTEGER, year INTEGER)
BEGIN
  SELECT cd_mph AS speed, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance
  FROM cardio WHERE SEMESTER(cd_date)=semester AND YEAR(cd_date)=year
  GROUP BY speed ORDER BY speed;
END #

CREATE PROCEDURE YEAR_RUNS(year INTEGER)
BEGIN
  SELECT cd_mph AS speed, SUM(cd_minutes) AS minutes, SUM(cd_distance) AS distance
  FROM cardio WHERE YEAR(cd_date)=year
  GROUP BY speed ORDER BY speed;
END #
DELIMITER ;

CREATE TABLE cardio (
  cd_date      DATE         NOT NULL,
  cd_mph       FLOAT(3, 1)  NOT NULL,
  cd_minutes   INTEGER      NOT NULL,
  cd_incline   FLOAT(3, 1)  DEFAULT 0.0,
  cd_distance  FLOAT(4, 3)  AS ((cd_mph / 60) * cd_minutes)
);

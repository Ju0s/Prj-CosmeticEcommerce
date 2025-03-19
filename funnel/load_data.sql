SET GLOBAL local_infile = true;

LOAD DATA LOCAL INFILE 'C:/Program Files/MySQL/MySQL Server 8.0/Uploads/2019-Dec.csv' IGNORE
INTO TABLE cosmetics_shop.dec19
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
lines terminated by '\n' STARTING BY ''
IGNORE 1 ROWS;

SELECT * FROM dec19;

LOAD DATA LOCAL INFILE 'C:/Program Files/MySQL/MySQL Server 8.0/Uploads/2020-Jan.csv' IGNORE
INTO TABLE cosmetics_shop.jan20
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
lines terminated by '\n' STARTING BY ''
IGNORE 1 ROWS;

SELECT * FROM jan20;

LOAD DATA LOCAL INFILE 'C:/Program Files/MySQL/MySQL Server 8.0/Uploads/2020-Feb.csv' IGNORE
INTO TABLE cosmetics_shop.feb20
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
lines terminated by '\n' STARTING BY ''
IGNORE 1 ROWS;

SELECT * FROM feb20;

CREATE TABLE all_months AS
SELECT * FROM dec19
UNION ALL
SELECT * FROM jan20
UNION ALL
SELECT * FROM feb20;

LOAD DATA LOCAL INFILE 'C:/Program Files/MySQL/MySQL Server 8.0/Uploads/cleaned_data.csv'
INTO TABLE cosmetics_shop.cosmetics 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM cosmetics;

LOAD DATA LOCAL INFILE 'C:/Program Files/MySQL/MySQL Server 8.0/Uploads/filtered_data.csv'
INTO TABLE cosmetics_shop.cosmetics 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM cosmetics;


LOAD DATA LOCAL INFILE 'C:/Program Files/MySQL/MySQL Server 8.0/Uploads/filtered_data2.csv'
INTO TABLE cosmetics_shop.cosmetics
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM cosmetics;
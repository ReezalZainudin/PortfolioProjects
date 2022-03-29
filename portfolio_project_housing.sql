USE portfolio_projects;

CREATE TABLE housing (
	housing_id BIGINT,
    parcel_id VARCHAR(30),
    land_use VARCHAR(65),
    property_address VARCHAR(250),
    sale_date DATETIME,
    sale_price BIGINT,
    legal_reference VARCHAR(20),
    sold_as_vacant VARCHAR(5),
    owner_name VARCHAR(80),
    owner_address VARCHAR(250),
    acreage DECIMAL(10,2),
    tax_district VARCHAR(30),
    land_value BIGINT,
    building_value BIGINT,
    total_value BIGINT,
    year_built SMALLINT,
    bedrooms TINYINT,
    full_bath TINYINT,
    half_bath TINYINT
    );

SHOW VARIABLES LIKE 'local_infile';
SET  global local_infile = 0;

SHOW VARIABLES LIKE 'local_infile';
SET global local_infile = 1;
SELECT @@local_infile;

LOAD DATA LOCAL INFILE 'C:\\Users\\reezal93\\Documents\\Data Analyst\\nashville_housing_data_for_data_cleaning.csv'
INTO TABLE housing
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM housing;

SELECT * FROM housing;

-- standardize date format

SET SQL_SAFE_UPDATES = 0;

SELECT sale_date FROM housing;

ALTER TABLE housing
ADD COLUMN sale_date_converted DATE;

UPDATE housing
SET 
	sale_date_converted = CAST(sale_date AS DATE);

SET SQL_SAFE_UPDATES = 1;

-- populate property address data 

SET SQL_SAFE_UPDATES = 0;

UPDATE housing
SET 
	property_address = NULL
WHERE 
	property_address = '';

CREATE TEMPORARY TABLE complete_empty_property_address
SELECT 
	b.parcel_id AS parcel_id,
	a.housing_id AS empty_housing_id,
    a.property_address AS empty_property_address,
    b.housing_id AS complete_housing_id,
    b.property_address AS complete_property_address
FROM housing AS a
	LEFT JOIN housing AS b
		ON a.parcel_id = b.parcel_id
		AND a.housing_id != b.housing_id
WHERE 
	a.property_address IS NULL
    OR a.property_address = '';

SELECT * FROM complete_empty_property_address;

UPDATE housing
LEFT JOIN complete_empty_property_address 
		ON complete_empty_property_address.parcel_id = housing.parcel_id
SET housing.property_address = IFNULL(housing.property_address, complete_empty_property_address.complete_property_address)
WHERE 
	housing.property_address IS NULL;

SELECT 
	b.parcel_id AS parcel_id,
	a.housing_id AS empty_housing_id,
    a.property_address AS empty_property_address,
    b.housing_id AS complete_housing_id,
    b.property_address AS complete_property_address,
    IFNULL(a.property_address, b.property_address)
FROM housing AS a
	LEFT JOIN housing AS b
		ON a.parcel_id = b.parcel_id
		AND a.housing_id != b.housing_id
WHERE 
	a.property_address IS NULL
    OR a.property_address = '';
    
SELECT * FROM complete_empty_property_address;

SELECT * 
FROM housing
WHERE 
	housing_id IN (43076, 39432, 45290);

SET SQL_SAFE_UPDATES = 1;

-- Breaking out address into individual columns (‘address’, ‘city’, ‘state’)

SET SQL_SAFE_UPDATES = 0;

SELECT 
	property_address
FROM housing;

SELECT
	housing_id,
	SUBSTRING(property_address, 2, POSITION(',' IN property_address) - 2) AS address,
    SUBSTRING(property_address, POSITION(',' IN property_address) + 1, LENGTH(property_address)) AS city
FROM housing;

ALTER TABLE housing
ADD COLUMN split_address VARCHAR(250);

ALTER TABLE housing
ADD COLUMN split_city VARCHAR(250);

SELECT * FROM housing;

UPDATE housing
SET 
	split_address = SUBSTRING(property_address, 2, POSITION(',' IN property_address) - 2);

UPDATE housing
SET 
	split_city = SUBSTRING(property_address, POSITION(',' IN property_address) + 1, LENGTH(property_address));

SELECT * FROM housing;

UPDATE housing
SET
	split_city = SUBSTRING(split_city, 1, POSITION('"' IN split_city) - 1);
    
SELECT * FROM housing;

SELECT 
	housing_id,
	owner_address 
FROM housing;

SELECT 
	SUBSTRING_INDEX(owner_address,',',1) AS owner_address, 
	SUBSTRING_INDEX(SUBSTRING_INDEX(owner_address, ',', 2), ',', -1) AS owner_city,
    SUBSTRING_INDEX(owner_address, ',', -1) AS owner_state
FROM housing;

ALTER TABLE housing
ADD COLUMN owner_split_address VARCHAR(250);

ALTER TABLE housing
ADD COLUMN owner_split_city VARCHAR(250);

ALTER TABLE housing
ADD COLUMN owner_split_state VARCHAR(250);

UPDATE housing
SET owner_split_address = SUBSTRING_INDEX(owner_address,',',1);

UPDATE housing
SET owner_split_address = SUBSTRING(owner_split_address, 2, LENGTH(owner_split_address));

SELECT * FROM housing;

UPDATE housing
SET owner_split_city = SUBSTRING_INDEX(SUBSTRING_INDEX(owner_address, ',', -2), ',', 1);

SELECT * FROM housing;

UPDATE housing
SET owner_split_state = SUBSTRING_INDEX(owner_address, ',', -1);

UPDATE housing
SET owner_split_state  = SUBSTRING(owner_split_state, 1, POSITION('"' IN owner_split_state) -1);

SELECT * FROM housing;

SET SQL_SAFE_UPDATES = 1;

-- Change ‘Y’ and ‘N’ to ‘Yes’ and ‘No’ in “sold as Vacant field”

SET SQL_SAFE_UPDATES = 0;

SELECT 
	sold_as_vacant,
    COUNT(sold_as_vacant) AS total_rows
FROM housing
GROUP BY
	sold_as_vacant
ORDER BY
	total_rows DESC;
    
SELECT 
	sold_as_vacant,
    CASE 
		WHEN sold_as_vacant = 'N' THEN 'No'
        WHEN sold_as_vacant = 'Y' THEN 'Yes'
		ELSE sold_as_vacant
    END AS sold_as_vacant_clean
FROM housing;

UPDATE housing
SET
	sold_as_vacant =  
			CASE 
				WHEN sold_as_vacant = 'N' THEN 'No'
				WHEN sold_as_vacant = 'Y' THEN 'Yes'
				ELSE sold_as_vacant
			END;

SELECT * FROM housing;

SET SQL_SAFE_UPDATES = 1;

-- Remove duplicates

SET SQL_SAFE_UPDATES = 0;

SELECT * FROM housing;

SELECT 
	*,
    ROW_NUMBER() OVER (PARTITION BY parcel_id, property_address, sale_date, sale_price, legal_reference ORDER BY housing_id) AS row_num
FROM housing
ORDER BY parcel_id;

CREATE TEMPORARY TABLE housing_duplicates
SELECT 
	*,
    ROW_NUMBER() OVER (PARTITION BY parcel_id, property_address, sale_date, sale_price, legal_reference ORDER BY housing_id) AS row_num
FROM housing
ORDER BY
	housing_id;

SELECT COUNT(*) FROM housing;

SELECT COUNT(*) FROM housing_duplicates
WHERE
	row_num < 2;

SELECT * FROM housing_duplicates
WHERE
	row_num < 2;

CREATE TABLE housing_clean_duplicates
SELECT
	a.housing_id,
    a.parcel_id,
    a.land_use,
    a.property_address,
    a.sale_date,
    a.sale_price,
    a.legal_reference,
    a.sold_as_vacant,
    a.owner_name,
    a.owner_address,
    a.tax_district,
    a.land_value,
    a.building_value,
    a.total_value,
    a.year_built,
    a.bedrooms,
    a.full_bath,
    a.half_bath
FROM housing AS a
	INNER JOIN housing_duplicates as b
		ON b.housing_id = a.housing_id
        AND b.row_num < 2;

SELECT COUNT(*) FROM housing_clean_duplicates;

SELECT * FROM housing_clean_duplicates;

SET SQL_SAFE_UPDATES = 1;

-- Delete unused columns

ALTER TABLE housing_clean_duplicates
DROP COLUMN property_address,
-- DROP COLUMN sale_date,
DROP COLUMN owner_address,
DROP COLUMN tax_district;

SELECT * FROM housing_clean_duplicates;
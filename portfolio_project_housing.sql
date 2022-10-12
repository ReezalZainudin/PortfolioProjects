USE portfolio_projects;

DROP TABLE housing;
DROP TABLE housing_clean;

CREATE TABLE housing (
	housing_id BIGINT UNIQUE auto_increment,
    parcel_id VARCHAR(30),
    land_use VARCHAR(65),
    property_address VARCHAR(250),
    sale_date DATETIME,
    sale_price INT,
    legal_reference VARCHAR(20),
    sold_as_vacant VARCHAR(5),
    owner_name VARCHAR(250),
    owner_address VARCHAR(250),
    acreage DECIMAL(5,2),
    tax_district VARCHAR(30),
    land_value INT,
    building_value INT,
    total_value INT,
    year_built SMALLINT,
    bedrooms SMALLINT,
    full_bath SMALLINT,
    half_bath SMALLINT
    );

SHOW VARIABLES LIKE 'local_infile';
SET global local_infile = 1;
SELECT @@local_infile;

LOAD DATA LOCAL INFILE 'C:\\Users\\reezal93\\Documents\\Data Analyst\\mysql_cleaning_portfolio\\nashville_housing_data_for_data_cleaning.csv'
INTO TABLE housing
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- 1. Inspecting a table for unwanted columns

SELECT * FROM housing;

-- 2. Removing duplicative rows

CREATE TABLE housing_clean
WITH row_num_cte AS (
SELECT 
	*,
	ROW_NUMBER() OVER (PARTITION BY Parcel_ID, Property_Address, Sale_Price, Sale_Date, Legal_Reference ORDER BY housing_ID) AS row_num
FROM housing
)
SELECT 
	*
FROM row_num_cte
WHERE
	row_num < 2
ORDER BY 
	housing_id;

ALTER TABLE housing_clean
DROP COLUMN row_num;

SELECT * FROM housing_clean;

SELECT COUNT(*) FROM housing;

SELECT COUNT(*) FROM housing_clean;

-- 3. Changing the data type of the sale_date column

DESC housing_clean;

ALTER TABLE housing_clean
MODIFY sale_date DATE;

SELECT * FROM housing_clean;

-- 4. Extracting values from the property address and owner address columns into individual columns

SET SQL_SAFE_UPDATES = 0;

ALTER TABLE housing_clean
ADD COLUMN property_street VARCHAR(250);

ALTER TABLE housing_clean
ADD COLUMN property_city VARCHAR(250);

UPDATE housing_clean
SET property_street = SUBSTRING(property_address, 1, POSITION(',' IN property_address) - 1);

UPDATE housing_clean
SET property_city = SUBSTRING(property_address, INSTR(property_address, ",") + 2);

ALTER TABLE housing_clean
ADD COLUMN owner_street VARCHAR(250);

ALTER TABLE housing_clean
ADD COLUMN owner_city VARCHAR(250);

ALTER TABLE housing_clean
ADD COLUMN owner_state VARCHAR(250);

UPDATE housing_clean
SET owner_street = SUBSTRING(owner_address, 1, POSITION(',' IN owner_address) - 1);

UPDATE housing_clean
SET owner_city = SUBSTRING_INDEX(SUBSTRING_INDEX(owner_address, ', ', 2), ', ', -1);

UPDATE housing_clean
SET owner_state = SUBSTRING_INDEX(owner_address, ', ', -1);

ALTER TABLE housing_clean
DROP COLUMN property_address,
DROP COLUMN owner_address;

SELECT * FROM housing_clean;

SET SQL_SAFE_UPDATES = 1;

-- 5. Correcting typos in the sold_as_vacant column

SET SQL_SAFE_UPDATES = 0;

SELECT
	sold_as_vacant,
    COUNT(sold_as_vacant) AS total_rows
FROM housing_clean
GROUP BY
	sold_as_vacant
ORDER BY
	total_rows DESC;

UPDATE housing_clean
SET sold_as_vacant = 
		CASE 
			WHEN sold_as_vacant = 'N' THEN 'No'
			WHEN sold_as_vacant = 'Y' THEN 'Yes'
			ELSE sold_as_vacant
		END;

SET SQL_SAFE_UPDATES = 1;

-- 6. Inputting missing values in property address columns based on other observations

SET SQL_SAFE_UPDATES = 0;

CREATE TEMPORARY TABLE missing_property_address
SELECT
	b.parcel_id AS parcel_id,
	a.housing_id AS missing_housing_id,
    a.property_street AS missing_property_street,
    a.property_city AS missing_property_city,
    b.housing_id AS comp_housing_id,
    b.property_street AS comp_property_street,
    b.property_city AS comp_property_city
FROM housing_clean AS a
	LEFT JOIN housing_clean AS b
		ON a.parcel_id = b.parcel_id
		AND a.housing_id != b.housing_id
WHERE 
	a.parcel_id IS NOT NULL
	AND a.property_street IS NULL;

SELECT * FROM missing_property_address;

UPDATE housing_clean
	LEFT JOIN missing_property_address
		ON missing_property_address.parcel_id = housing_clean.parcel_id
SET 
	housing_clean.property_street = IFNULL(housing_clean.property_street, missing_property_address.comp_property_street),
    housing_clean.property_city = IFNULL(housing_clean.property_city, missing_property_address.comp_property_city);

SELECT
	b.parcel_id AS parcel_id,
	a.housing_id AS missing_housing_id,
    a.property_street AS missing_property_street,
    a.property_city AS missing_property_city,
    b.housing_id AS comp_housing_id,
    b.property_street AS comp_property_street,
    b.property_city AS comp_property_city
FROM housing_clean AS a
	LEFT JOIN housing_clean AS b
		ON a.parcel_id = b.parcel_id
		AND a.housing_id != b.housing_id
WHERE 
	a.parcel_id IS NOT NULL
	AND a.property_street IS NULL;

SELECT 
	housing_id,
    property_street,
    property_city
FROM housing_clean
WHERE housing_id IN (11478, 22775, 43151, 43080, 3299, 45349);

SET SQL_SAFE_UPDATES = 1;

-- 7. Finding the percentage of missing values in every column

SELECT

	ROUND(SUM(CASE WHEN parcel_id IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_parcel,
	
	ROUND(SUM(CASE WHEN land_use IS NULL THEN 1 ELSE 0 END)  / 
		COUNT(housing_id) * 100, 2) AS pct_null_land_use,
	
	ROUND(SUM(CASE WHEN sale_date IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_sale_date,
	
	ROUND(SUM(CASE WHEN sale_price IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_sale_price,
	
	ROUND(SUM(CASE WHEN legal_reference IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_legal_reference,
	
	ROUND(SUM(CASE WHEN sold_as_vacant IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_sold_as_vacant,
	
	ROUND(SUM(CASE WHEN owner_name IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_owner_name,
	
	ROUND(SUM(CASE WHEN acreage IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_acreage,
	
	ROUND(SUM(CASE WHEN tax_district IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_tax_district,
	
	ROUND(SUM(CASE WHEN land_value IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_land_value,
	
	ROUND(SUM(CASE WHEN building_value IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_building_value,
	
	ROUND(SUM(CASE WHEN total_value IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_total_value,
	
	ROUND(SUM(CASE WHEN year_built IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_year_built,
	
	ROUND(SUM(CASE WHEN bedrooms IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_bedrooms,
	
	ROUND(SUM(CASE WHEN full_bath IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_full_bath,
	
	ROUND(SUM(CASE WHEN half_bath IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_half_bath,
	
	ROUND(SUM(CASE WHEN property_street IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_property_street,
	
	ROUND(SUM(CASE WHEN property_city IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_property_city,
	
	ROUND(SUM(CASE WHEN owner_street IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_owner_street,
	
	ROUND(SUM(CASE WHEN owner_city IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_owner_city,
	
	ROUND(SUM(CASE WHEN owner_state IS NULL THEN 1 ELSE 0 END) / 
		COUNT(housing_id) * 100, 2) AS pct_null_owner_state

FROM housing_clean;

-- 8. Validate and QA

-- 8.1 Does the data make sense?

SELECT 
	MAX(sale_price) AS most_expensive_property
FROM housing_clean;

SELECT
	housing_id,
    parcel_id,
    land_use,
	property_street,
    property_city,
	legal_reference,
    sale_date,
    sale_price
FROM housing_clean
WHERE 
	sale_price = 54278060;

CREATE TEMPORARY TABLE total_property_sales_table
SELECT 
	legal_reference,
    property_street,
    property_city,
    sale_date,
    sale_price,
	COUNT(housing_id) AS total_property_sales
FROM housing_clean
GROUP BY
	legal_reference,
    sale_date,
    sale_price
ORDER BY 
	sale_price DESC;

SELECT * FROM total_property_sales_table;

SELECT 
	COUNT(*) AS legal_reference_with_multiple_transactions 
FROM total_property_sales_table
WHERE
	total_property_sales > 1;
    
SELECT 
	SUM(total_property_sales) AS total_number_of_properties_involved_in_multiple_transactions
FROM total_property_sales_table
WHERE
	total_property_sales > 1;

-- 8.2 Is there enough data for my needs?

SELECT * FROM housing_clean;

SELECT 
sum(case when owner_name IS NOT NULL THEN 1 ELSE NULL END) AS xxx
FROM HOUSING_CLEAN;

SELECT
	COUNT(*) AS total_number_of_rows,
	COUNT(CASE WHEN owner_name IS NOT NULL AND acreage IS NOT NULL AND tax_district IS NOT NULL AND land_value IS NOT NULL AND building_value IS NOT NULL AND total_value IS NOT NULL AND year_built IS NOT NULL AND bedrooms IS NOT NULL AND full_bath IS NOT NULL AND half_bath IS NOT NULL AND owner_street IS NOT NULL THEN 1 ELSE NULL END) AS total_number_of_complete_rows,
    ROUND(COUNT(CASE WHEN owner_name IS NOT NULL AND acreage IS NOT NULL AND tax_district IS NOT NULL AND land_value IS NOT NULL AND building_value IS NOT NULL AND total_value IS NOT NULL AND year_built IS NOT NULL AND bedrooms IS NOT NULL AND full_bath IS NOT NULL AND half_bath IS NOT NULL AND owner_street IS NOT NULL THEN 1 ELSE NULL END) /  
		COUNT(*) * 100, 2) AS percentage_of_complete_rows
FROM housing_clean;
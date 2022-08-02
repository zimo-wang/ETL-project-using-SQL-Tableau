# cleaning data with MySQL
# prior to importing data into MySQL, I removed all listing URLs, region URLs and image URLs as they take too much memory space and they are not helpful in the purpose of this project


SELECT *
FROM us_housing_raw; # taking a general look at the data, finding duplicates among prices, sqfeet, latitude and longitude


# 1. rename some columns to avoid conflict with SQL language and remove duplicates with CTE and window function


ALTER TABLE us_housing_raw RENAME COLUMN type TO house_type;


ALTER TABLE us_housing_raw 
CHANGE COLUMN `long` `lon` DOUBLE NULL DEFAULT NULL;


CREATE TABLE us_housing_e1 LIKE us_housing_raw;


INSERT INTO us_housing_e1
WITH find_dup AS 
(
	SELECT *, ROW_NUMBER()OVER(PARTITION BY region, house_type, price, sqfeet, lat, lon) AS rn
	FROM us_housing_raw
)
SELECT id,region,price,house_type,sqfeet,beds,baths,cats_allowed,dogs_allowed,smoking_allowed,wheelchair_access,electric_vehicle_charge,comes_furnished,laundry_options,parking_options,lat,lon,state
FROM find_dup
WHERE rn = 1;


# 2. check null values for some columns and replace with meaningful content if possible


SELECT DISTINCT laundry_options
FROM us_housing_e1;


SELECT laundry_options, COUNT(*)
FROM us_housing_e1
WHERE laundry_options = ''; # I tried to check nulls but it worked with ''(empty string)


# the blanks in laundry_options are very likely meaning "no laundry on site", so we replace them with "no laundry on site"
SET SQL_SAFE_UPDATES = 0; # Had to turn off the safe update feature
UPDATE us_housing_e1
SET laundry_options = CASE WHEN laundry_options = '' THEN 'no laundry on site' ELSE laundry_options END;
SET SQL_SAFE_UPDATES = 1; # Turning safe update feature back on 


# Same procedure with the parking information, blanks are likely to be "no parking"
SELECT parking_options, COUNT(*)
FROM us_housing_e1
GROUP BY 1;


SET SQL_SAFE_UPDATES = 0; # Turning off safe update feature
UPDATE us_housing_e1
SET parking_options = CASE WHEN parking_options = '' THEN 'no parking' ELSE parking_options END;
SET SQL_SAFE_UPDATES = 1; # Turning safe update feature back on


# 3. check price range and avoid irrational data


SELECT price, ROW_NUMBER()OVER(ORDER BY price DESC)
FROM us_housing_e1;
# Since we are looking at the rent per month, any price over $10000 or under $300(could be only renting a room) will be out of our consideration
# By using window function, we can tell that houses with price over $10000 or under $300 are only a tiny portion of the whole data, so we can safely remove them whtiout affecting the big picture


SET SQL_SAFE_UPDATES = 0;
DELETE
FROM us_housing_e1
WHERE price <300 OR price > 10000;
SET SQL_SAFE_UPDATES = 1;


# Same for sqfeet, accroding to researches, we determine that the minimum sqfeet for a room is 100 and the maximum sqfeet for a whole house is 10000
SELECT sqfeet, ROW_NUMBER()OVER(ORDER BY sqfeet DESC)
FROM us_housing_e1;


SET SQL_SAFE_UPDATES = 0;
DELETE
FROM us_housing_e1
WHERE sqfeet <100 OR sqfeet > 10000;
SET SQL_SAFE_UPDATES = 1;


# Upon checking the house type, assisted living and land does not have enough data so we eliminate these rows
SELECT house_type, COUNT(*)
FROM us_housing_e1
GROUP BY 1;


SET SQL_SAFE_UPDATES = 0;
DELETE
FROM us_housing_e1
WHERE house_type = 'land' OR house_type = 'assisted living';
SET SQL_SAFE_UPDATES = 1;


# Upon checking the beds and baths quantity, some irrational data could be eliminated as well
SELECT beds, COUNT(*)
FROM us_housing_e1
GROUP BY 1
ORDER BY 1;


SELECT baths, COUNT(*)
FROM us_housing_e1
GROUP BY 1
ORDER BY 1;


SET SQL_SAFE_UPDATES = 0;
DELETE
FROM us_housing_e1
WHERE beds > 8 OR baths > 8;
SET SQL_SAFE_UPDATES = 1;

# There are little more data makes no sense such as a 200 sqfeet room has 2 bathrooms, since we are dealing with craigslist posts rather than official housing data, we will leave them as how they are


# 4. Changing boolean values from numbers to text (Yes or No) for better understanding for the audience


ALTER TABLE `us_housing_e1` 
CHANGE COLUMN `cats_allowed` `cats_allowed` TEXT NULL DEFAULT NULL;

SET SQL_SAFE_UPDATES = 0;
UPDATE us_housing_e1
SET cats_allowed = CASE WHEN cats_allowed = 0 THEN 'No' ELSE 'Yes' END;
SET SQL_SAFE_UPDATES = 1;


ALTER TABLE `us_housing_e1` 
CHANGE COLUMN `dogs_allowed` `dogs_allowed` TEXT NULL DEFAULT NULL;

SET SQL_SAFE_UPDATES = 0;
UPDATE us_housing_e1
SET dogs_allowed = CASE WHEN dogs_allowed = 0 THEN 'No' ELSE 'Yes' END;
SET SQL_SAFE_UPDATES = 1;


ALTER TABLE `us_housing_e1` 
CHANGE COLUMN `smoking_allowed` `smoking_allowed` TEXT NULL DEFAULT NULL;

SET SQL_SAFE_UPDATES = 0;
UPDATE us_housing_e1
SET smoking_allowed = CASE WHEN smoking_allowed = 0 THEN 'No' ELSE 'Yes' END;
SET SQL_SAFE_UPDATES = 1;


ALTER TABLE `us_housing_e1` 
CHANGE COLUMN `wheelchair_access` `wheelchair_access` TEXT NULL DEFAULT NULL;

SET SQL_SAFE_UPDATES = 0;
UPDATE us_housing_e1
SET wheelchair_access = CASE WHEN wheelchair_access = 0 THEN 'No' ELSE 'Yes' END;
SET SQL_SAFE_UPDATES = 1;


ALTER TABLE `us_housing_e1` 
CHANGE COLUMN `electric_vehicle_charge` `electric_vehicle_charge` TEXT NULL DEFAULT NULL;

SET SQL_SAFE_UPDATES = 0;
UPDATE us_housing_e1
SET electric_vehicle_charge = CASE WHEN electric_vehicle_charge = 0 THEN 'No' ELSE 'Yes' END;
SET SQL_SAFE_UPDATES = 1;


ALTER TABLE `us_housing_e1` 
CHANGE COLUMN `comes_furnished` `comes_furnished` TEXT NULL DEFAULT NULL;

SET SQL_SAFE_UPDATES = 0;
UPDATE us_housing_e1
SET comes_furnished = CASE WHEN comes_furnished = 0 THEN 'No' ELSE 'Yes' END;
SET SQL_SAFE_UPDATES = 1;


# Now the data is ready for visualization, we export it to a CSV file and visualize with Tableau
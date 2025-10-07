CREATE TABLE raw.ad_data(
customer_id INTEGER,
bulkmail_ad INTEGER,
twitter_ad INTEGER,
instagram_ad INTEGER,
facebook_ad INTEGER,
brochure_ad INTEGER
);

SELECT *
FROM raw.ad_data

CREATE TABLE raw.marketing_data(
customer_id INTEGER,
year_birth DATE,
age INTEGER,
education VARCHAR(15),
marital_status VARCHAR(15),
income NUMERIC,
kidhome INTEGER,
teenhome INTEGER,
dt_customer DATE,
recency INTEGER,
amtliq NUMERIC,
amtvege NUMERIC,
amtnonveg NUMERIC,
amtpes NUMERIC,
amtchocolates NUMERIC,
amtcomm NUMERIC,
numdeals INTEGER,
numwebbuy INTEGER,
numwalkinpur INTEGER,
numvisits INTEGER,
response INTEGER,
complain INTEGER,
country VARCHAR(10),
count_success INTEGER
);

SELECT *
FROM raw.marketing_data


CREATE OR REPLACE VIEW staging.stg_ad_data as
SELECT
customer_id,
bulkmail_ad,
twitter_ad,
instagram_ad,
facebook_ad,
brochure_ad
from raw.ad_data

CREATE OR REPLACE VIEW staging.stg_marketing_data as
SELECT
customer_id,
year_birth,
age,
education,
marital_status,
income,
kidhome,
teenhome,
dt_customer,
recency,
amtliq,
amtvege,
amtnonveg,
amtpes,
amtchocolates,
amtcomm,
numdeals,
numwebbuy,
numwalkinpur,
numvisits,
response,
complain,
country,
count_success
FROM raw.marketing_data


-- total number of ad conversions per customer

ALTER TABLE raw.ad_data
ADD COLUMN total_ad integer GENERATED ALWAYS AS (bulkmail_ad + twitter_ad + instagram_ad + facebook_ad + brochure_ad) STORED;

-- total spend per country

ALTER TABLE raw.marketing_data
ADD COLUMN amttotal numeric GENERATED ALWAYS AS (amtliq + amtvege + amtnonveg + amtpes + amtchocolates + amtcomm) STORED;

SELECT country, SUM(amttotal)
FROM raw.marketing_data
GROUP BY country
ORDER BY SUM(amttotal) DESC;

-- total spend per product per country

SELECT country,
SUM(amtliq) AS total_alcohol,
SUM(amtvege) AS total_veg,
SUM(amtnonveg) AS total_meat,
SUM(amtpes) AS total_fish,
SUM(amtchocolates) AS total_chocolates,
SUM(amtcomm) AS total_commodities
FROM raw.marketing_data
GROUP BY country;

-- which products are the most popular in each country

SELECT country,
AVG(amtliq) AS average_alcohol,
AVG(amtvege) AS average_veg,
AVG(amtnonveg) AS average_meat,
AVG(amtpes) AS average_fish,
AVG(amtchocolates) AS average_chocolates,
AVG(amtcomm) AS average_commodities
FROM raw.marketing_data
GROUP BY country;

-- which products are the most popular based on marital status

SELECT marital_status,
AVG(amtliq) AS average_alcohol,
AVG(amtvege) AS average_veg,
AVG(amtnonveg) AS average_meat,
AVG(amtpes) AS average_fish,
AVG(amtchocolates) AS average_chocolates,
AVG(amtcomm) AS average_commodities
FROM raw.marketing_data
GROUP BY marital_status;

-- which products are most popular based on whether or not there are children or teens in the home

ALTER TABLE raw.marketing_data
ADD COLUMN total_children integer GENERATED ALWAYS AS (kidhome + teenhome) STORED;

SELECT 
    CASE 
        WHEN total_children = 0 THEN 'no_children'
        WHEN total_children > 0 THEN 'has_children'
    END AS children_group,
AVG(amtliq) AS average_alcohol,
AVG(amtvege) AS average_veg,
AVG(amtnonveg) AS average_meat,
AVG(amtpes) AS average_fish,
AVG(amtchocolates) AS average_chocolates,
AVG(amtcomm) AS average_commodities
FROM raw.marketing_data
GROUP BY 
    CASE 
        WHEN total_children = 0 THEN 'no_children'
        WHEN total_children > 0 THEN 'has_children' END
ORDER BY children_group DESC

-- join the two tables

CREATE TABLE raw.joined_table AS
SELECT *
FROM raw.marketing_data
JOIN raw.ad_data
USING(customer_id)

SELECT *
FROM raw.joined_table

-- which social media platform (Twitter, Instagram, or Facebook) is most effective method in each country

SELECT country, SUM(twitter_ad) AS twitter, SUM(instagram_ad) AS instagram, SUM(facebook_ad) AS facebook
FROM raw.joined_table
GROUP BY country
ORDER BY country ASC


SELECT country,
	CASE
		WHEN GREATEST (SUM(twitter_ad), SUM(instagram_ad), SUM(facebook_ad)) = 0 THEN 'none'
		WHEN GREATEST (SUM(twitter_ad), SUM(instagram_ad), SUM(facebook_ad)) = SUM(twitter_ad) THEN 'twitter'
		WHEN GREATEST (SUM(twitter_ad), SUM(instagram_ad), SUM(facebook_ad)) = SUM(instagram_ad) THEN 'instagram'
		WHEN GREATEST (SUM(twitter_ad), SUM(instagram_ad), SUM(facebook_ad)) = SUM(facebook_ad) THEN 'facebook'
	END AS most_effective
FROM raw.joined_table
GROUP BY country
ORDER BY country ASC

-- most effective social media by marital status?

SELECT marital_status, SUM(twitter_ad) AS twitter, SUM(instagram_ad) AS instagram, SUM(facebook_ad) AS facebook
FROM raw.joined_table
GROUP BY marital_status
ORDER BY marital_status ASC

SELECT marital_status,
	CASE
		WHEN GREATEST (SUM(twitter_ad), SUM(instagram_ad), SUM(facebook_ad)) = 0 THEN 'none'
		WHEN GREATEST (SUM(twitter_ad), SUM(instagram_ad), SUM(facebook_ad)) = SUM(twitter_ad) THEN 'twitter'
		WHEN GREATEST (SUM(twitter_ad), SUM(instagram_ad), SUM(facebook_ad)) = SUM(instagram_ad) THEN 'instagram'
		WHEN GREATEST (SUM(twitter_ad), SUM(instagram_ad), SUM(facebook_ad)) = SUM(facebook_ad) THEN 'facebook'
	END AS most_effective
FROM raw.joined_table
GROUP BY marital_status
ORDER BY marital_status ASC

-- which social media platform(s) seem(s) to be the most effective per country based on purchases?

SELECT country, SUM(amtliq) AS sum_alcohol, SUM(amtvege) AS sum_veg, SUM(amtnonveg) AS sum_meat,
SUM(amtpes) AS sum_fish, SUM(amtchocolates) AS sum_chocolates, SUM(amtcomm) AS sum_commodities,
SUM (amttotal) AS sum_total,
SUM(twitter_ad) AS twitter, SUM(instagram_ad) AS instagram, SUM(facebook_ad) AS facebook,
SUM(twitter_ad + instagram_ad + facebook_ad) AS sum_ads
FROM raw.joined_table
GROUP BY country
ORDER BY sum_total DESC
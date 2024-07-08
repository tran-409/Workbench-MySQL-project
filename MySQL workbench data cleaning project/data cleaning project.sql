use world_layoffs_project;

-- made a schema with the name world_layoffs_projects
-- I imported my layoff.csv file using Table Data Import Wizard

-- Tu Tran
-- 6/09/2024
-- Data cleaning project

-- Following steps for the project
-- 1. Will check for duplicates and remove if it has any
-- 2. standardize the data and fix the errors
-- 3. Look at all null values and blank values
-- 4. remove any columns and rows that are not necessary

-- Take a look at the raw table data.
SELECT * FROM layoffs;

-- Step 1). create a staging table so we don't ruin the actual raw data table.
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * FROM layoffs;

-- Identify duplicates in the staging table.

-- These are the duplcates
-- using a common table expression
WITH dupe_cte AS (
SELECT *, ROW_NUMBER() OVER(PARTITION BY 
company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging)
SELECT * FROM dupe_cte
WHERE row_num > 1;

-- take a look at the company casper to make sure it's a duplicate but must look at all the rows to make sure they are all dupplcates
SELECT * FROM layoffs_staging 
WHERE company = 'Casper';

-- create a new table with extra row named row_num so that we can delete all that has a 2 (duplicate)

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs_staging2;

-- insert data from layoffs_staging into layoffs_staging2
INSERT INTO layoffs_staging2
SELECT *, ROW_NUMBER() OVER(PARTITION BY 
company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- remove the duplicates by deleting
DELETE FROM layoffs_staging2
WHERE row_num > 1;

SELECT * FROM layoffs_staging2
WHERE row_num > 1;

-- Step 2). Stardardizing the data

SELECT company, (TRIM(company))
FROM layoffs_staging2;

-- trim the data from blank spaces in front.
UPDATE layoffs_staging2
SET company = TRIM(company);

-- I noticed there are 3 industry with similar names (Crypto) that need to be combined
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- taking a look at all names with Crypto
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- set all the Crypto names into one name.
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- let take a look at other columns for redundancies
SELECT DISTINCT location
FROM layoffs_staging2
ORDER by 1;

 -- We found United States with a period (.) at the end. We need to fix it.
SELECT DISTINCT country
FROM layoffs_staging2
ORDER by 1;

UPDATE layoffs_staging2
SET country = TRIM(Trailing '.' FROM country)
WHERE country LIKE 'United States%';

-- now we need to change the data format. 
SELECT `date`
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');

-- modify date from text to date
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- step 3). Now we work the areas where it has null values and empty rows.
SELECT *
FROM layoffs_staging2
WHERE total_laid_off is NULL
AND percentage_laid_off is NULL;

SELECT *
FROM layoffs_staging2
WHERE industry is NULL
or industry = '';

-- Take a look at Airbnb
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- I noticed there is a empty row in the industry column. I will populate the empty row
-- let check for other company with empty rows in the industry column
SELECT *
FROM layoffs_staging2 i1
JOIN layoffs_staging2 i2
	ON i1.company = i2.company
WHERE (i1.industry is NULL OR i1.industry = '')
AND i2.industry is NOT NULL;

-- change empty rows to null so i can populate the rows
UPDATE layoffs_staging2
SET industry = NULL
where industry = '';

-- I will do a join
UPDATE layoffs_staging2 i1
JOIN layoffs_staging2 i2
	ON i1.company = i2.company
SET i1.industry = i2.industry
WHERE i1.industry is NULL
AND i2.industry is NOT NULL;

-- step 4). Delete rows that isn't neccessary for this project.
Delete
FROM layoffs_staging2
WHERE total_laid_off is NULL
AND percentage_laid_off is NULL;

SELECT *
FROM layoffs_staging2;

-- delete the row_num column now since it's not needed anymore
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

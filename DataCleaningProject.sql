--Issues I encountered
--I could not connect my server in Microsoft SQL Server Management Studio
--I debugged and found out that the server used was not running
--Open Services (Win + R, type services.msc, press Enter).
--Look for SQL Server (SQLEXPRESS).
--If it's not running, right-click and select Start.

--I had issue updating the file because it was an excel file and Microsoft SQL Server Management Studio did not have my excel version
--I changed the file to a flat file

--I could not update the data type in SoldAsVacant and update the value
--I created a new column and set the data type to what was needed, then I deleted the SoldAsVacant column

-- Cleaning data with SQL

SELECT *
FROM NashvilleHousing


-- Update the Date Format

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

-- OR 

ALTER TABLE NashvilleHousing
ADD SaleDateConvert Date;

UPDATE NashvilleHousing
SET SaleDateConvert = CONVERT(Date, SaleDate)

-- Populate null Property Address Data

SELECT *
FROM NashvilleHousing a
WHERE PropertyAddress is NULL

--create a column with the right address for the null values in the address colummn
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL

--update the table with the values generate
--use the alias of the table not the act ual table name
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL

--Breaking the Address into Individual Columns (Address, City, State)
--property address
SELECT PropertyAddress
FROM NashvilleHousing

-- Address Line 1
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertyAddress1 VARCHAR(50);

UPDATE NashvilleHousing
SET PropertyAddress1 = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)
FROM NashvilleHousing

--City
SELECT SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertyCity VARCHAR(50);

UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))
FROM NashvilleHousing

--owner address
SELECT OwnerAddress
FROM NashvilleHousing

--Address Line 1
SELECT
PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
,PARSENAME(REPLACE(OwnerAddress, ',','.'),2)
,PARSENAME(REPLACE(OwnerAddress, ',','.'),3)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerAddress1 VARCHAR(50);

UPDATE NashvilleHousing
SET OwnerAddress1 = PARSENAME(REPLACE(OwnerAddress, ',','.'),3)
FROM NashvilleHousing

-- City
ALTER TABLE NashvilleHousing
ADD OwnerCity VARCHAR(50);

UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',','.'),2)
FROM NashvilleHousing

--State
ALTER TABLE NashvilleHousing
ADD OwnerState VARCHAR(50);

UPDATE NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
FROM NashvilleHousing

--Changing 1 and 0 in Column to Yes and No
SELECT Distinct(SoldAsVacant)
FROM NashvilleHousing

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 1 THEN 'Yes'
	WHEN SoldAsVacant = 0 THEN 'No'
	ELSE CAST(SoldAsVacant AS VARCHAR)
	END 
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SoldAsVacantText VARCHAR(5)

UPDATE NashvilleHousing
SET SoldAsVacantText = CASE WHEN SoldAsVacant = 1 THEN 'Yes'
	WHEN SoldAsVacant = 0 THEN 'No'
	ELSE CAST(SoldAsVacant AS VARCHAR)
	END 
FROM NashvilleHousing

--Remove Duplicates
select *
from (SELECT *,
ROW_NUMBER()OVER(
PARTITION BY UniqueID
order by UniqueID) rownum
FROM NashvilleHousing) a
WHERE rownum <> 1

-- This should be the right way to do it but it comes up empty because the uniqueID has no duplicate so lets try using other columns so we can actually drop something
WITH RowNumCTE AS(
SELECT *,
DENSE_RANK() OVER(
PARTITION BY ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			ORDER BY 
				UniqueID
				) rownum

FROM NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE rownum >1


--Now we get values and can delete this now
WITH RowNumCTE AS(
SELECT *,
DENSE_RANK() OVER(
PARTITION BY ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			ORDER BY 
				UniqueID
				) rownum

FROM NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE rownum >1

--Deleted over 100 rows

--Deleting Unused Columns
--Thid dhould not be done on the main db because you can lose data that may be useful in the future

SELECT *
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress, SoldAsVacant
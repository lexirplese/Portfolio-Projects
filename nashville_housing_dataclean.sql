SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

-- Standardize date format in SaleDate column

SELECT SaleDate
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

   -- Remove old SaleDate column

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate

   -- Rename SaleDateConverted to SaleDate using Object Explorer

-----------------------------------------------------------------------------------
-- Populate property address data (where there are currently NULL values) with a self join

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL

   -- Preliminary select statement

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
   ON a.ParcelID = b.ParcelID
   AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

   -- Update

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
   ON a.ParcelID = b.ParcelID
   AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

-----------------------------------------------------------------------------------
-- Separate property address data into 2 columns (address and city) using substrings

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing

   -- Preliminary select statement

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM PortfolioProject.dbo.NashvilleHousing

   -- Create 2 new columns for property address and city

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertyAddressSplit NVARCHAR(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertyAddressSplit = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertyCitySplit NVARCHAR(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertyCitySplit = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

   -- Remove old PropertyAddress column

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN PropertyAddress

   -- Rename new columns from PropertyAddressSplit to PropertyAddress and PropertyCitySplit to PropertyCity using Object Explorer


-----------------------------------------------------------------------------------
-- Separate owner address data into 3 columns (address, city, and state) using parsename

SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

   -- Preliminary select statement

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM PortfolioProject.dbo.NashvilleHousing

   -- Create 3 new columns for owner address, city, and state

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerAddress2 NVARCHAR(255)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerAddress2 = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerCity NVARCHAR(50)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerState NVARCHAR(50)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

   -- Delete old OwnerAddress column

SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress

   -- Rename OwnerAddress2 column to OwnerAddress using Object Explorer

-----------------------------------------------------------------------------------
-- Change Y and N to 'Yes' and 'No' in SoldAsVacant column

   -- Identify unique values & their quantities in SoldAsVacant column

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

   -- Preliminary select statement

SELECT SoldAsVacant,
CASE 
   WHEN SoldAsVacant = 'Y' THEN 'Yes'
   WHEN SoldAsVacant = 'N' THEN 'No'
   ELSE SoldAsVacant
END
FROM PortfolioProject.dbo.NashvilleHousing

   -- Update

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = 
CASE 
   WHEN SoldAsVacant = 'Y' THEN 'Yes'
   WHEN SoldAsVacant = 'N' THEN 'No'
   ELSE SoldAsVacant
END

-----------------------------------------------------------------------------------
-- Remove duplicates

   -- Preliminary SELECT

WITH RowNumCTE AS(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY 
   ParcelID, 
   PropertyAddress, 
   SalePrice, 
   SaleDate, 
   LegalReference
   ORDER BY 
      UniqueID
      ) row_num 
FROM PortfolioProject.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE

   -- Update

WITH RowNumCTE AS(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY 
   ParcelID, 
   PropertyAddress, 
   SalePrice, 
   SaleDate, 
   LegalReference
   ORDER BY 
      UniqueID
      ) row_num 
FROM PortfolioProject.dbo.NashvilleHousing
)
DELETE *
FROM RowNumCTE
WHERE row_num > 1

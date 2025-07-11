    
# Identify the most popular artists and genres for each country based on record sales,
# and flag countries where the top artist is not in the top genre.
# Create CTE's for ArtistSalesByCountry and GenreSalesByCountry
# 
WITH ArtistSalesByCountry AS (
    SELECT
        c.Country AS Country,
        a.Name AS ArtistName,
        g.Name AS GenreName, -- Include GenreName to link artist to their genre
        SUM(il.UnitPrice * il.Quantity) AS TotalSales
    FROM
        InvoiceLine il
    JOIN
        Track t ON il.TrackId = t.TrackId
    JOIN
        Album al ON t.AlbumId = al.AlbumId
    JOIN
        Artist a ON al.ArtistId = a.ArtistId
    JOIN
        Genre g ON t.GenreId = g.GenreId -- Join with Genre table
    JOIN
        Invoice i ON il.InvoiceId = i.InvoiceId
    JOIN
        Customer c ON i.CustomerId = c.CustomerId
    GROUP BY
        c.Country,
        a.Name,
        g.Name -- Group by genre as well
),
RankedArtistSales AS (
    SELECT
        Country,
        ArtistName,
        GenreName, -- Carry GenreName through
        TotalSales AS ArtistTotalSales,
        ROW_NUMBER() OVER (PARTITION BY Country ORDER BY TotalSales DESC) AS ArtistRank
    FROM
        ArtistSalesByCountry
),
GenreSalesByCountry AS (
    SELECT
        c.Country AS Country,
        g.Name AS GenreName,
        SUM(il.UnitPrice * il.Quantity) AS TotalSales
    FROM
        InvoiceLine il
    JOIN
        Track t ON il.TrackId = t.TrackId
    JOIN
        Genre g ON t.GenreId = g.GenreId
    JOIN
        Invoice i ON il.InvoiceId = i.InvoiceId
    JOIN
        Customer c ON i.CustomerId = c.CustomerId
    GROUP BY
        c.Country,
        g.Name
),
RankedGenreSales AS (
    SELECT
        Country,
        GenreName,
        TotalSales AS GenreTotalSales,
        ROW_NUMBER() OVER (PARTITION BY Country ORDER BY TotalSales DESC) AS GenreRank
    FROM
        GenreSalesByCountry
)
SELECT
    ras.Country,
    ras.ArtistName AS TopArtist,
    ras.ArtistTotalSales,
    ras.GenreName AS TopArtistGenre, -- Genre of the top artist
    rgs.GenreName AS TopSellingGenre,
    rgs.GenreTotalSales,
    CASE
        WHEN ras.GenreName = rgs.GenreName THEN ''
        ELSE 'yup'
    END AS BuckingTheTrend
FROM
    RankedArtistSales ras
JOIN
    RankedGenreSales rgs ON ras.Country = rgs.Country
WHERE
    ras.ArtistRank = 1 AND rgs.GenreRank = 1
ORDER BY
    ras.ArtistTotalSales DESC;


# Find the most popular track (by total quantity sold) and the email addresses of all customers who purchased it.
# Create a CTE that calculates the total quantity sold for each track
# Create a CTE to find the most popular 
WITH TrackSalesQuantity AS (
    SELECT
        t.TrackId,
        t.Name AS TrackName,
        SUM(il.Quantity) AS TotalQuantitySold
    FROM
        InvoiceLine il
    JOIN
        Track t ON il.TrackId = t.TrackId
    GROUP BY
        t.TrackId,
        t.Name
),
MostPopularTrack AS (
    -- Identify the single most popular track based on TotalQuantitySold
    SELECT
        TrackId,
        TrackName,
        TotalQuantitySold
    FROM
        TrackSalesQuantity
    ORDER BY
        TotalQuantitySold DESC
    LIMIT 1 -- Get only the top track
)
SELECT
    mpt.TrackName AS MostPopularTrack,
    mpt.TotalQuantitySold,
    c.Email AS CustomerEmail,
    c.FirstName,
    c.LastName
FROM
    MostPopularTrack mpt
JOIN
    InvoiceLine il ON mpt.TrackId = il.TrackId
JOIN
    Invoice i ON il.InvoiceId = i.InvoiceId
JOIN
    Customer c ON i.CustomerId = c.CustomerId
GROUP BY -- Use GROUP BY to get unique customer emails for the popular track
    mpt.TrackName,
    mpt.TotalQuantitySold,
    c.Email,
    c.FirstName,
    c.LastName
ORDER BY
    c.Email;

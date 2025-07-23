    
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



-- Find the artist that was responsible for the most tracks sold in the US
SELECT
    ar.name AS "Artist Name",
    SUM(il.quantity) AS "Total Tracks Sold"
FROM
    public.invoice AS i
INNER JOIN
    public.invoice_line AS il ON i.invoice_id = il.invoice_id
INNER JOIN
    public.track AS t ON il.track_id = t.track_id
INNER JOIN
    public.album AS al ON t.album_id = al.album_id
INNER JOIN
    public.artist AS ar ON al.artist_id = ar.artist_id
WHERE
    i.billing_country = 'USA'
GROUP BY
    ar.name
ORDER BY
    "Total Tracks Sold" DESC
LIMIT 1;


-- Check to see if NULL data exists in the join of invoice_line, track, and media type tables
SELECT *
FROM
    public.invoice_line AS il
LEFT JOIN
    public.track AS t ON il.track_id = t.track_id
LEFT JOIN
    public.media_type AS mt ON t.media_type_id = mt.media_type_id
WHERE il.invoice_line_id IS NULL
	OR il.invoice_id IS NULL
	OR il.track_id IS NULL
	OR il.unit_price IS NULL
	OR il.quantity IS NULL
	OR t.track_id IS NULL
	OR t.name IS NULL
	OR t.unit_price IS NULL
	OR t.media_type_id IS NULL
	OR mt.media_type_id IS NULL
	OR mt.name IS NULL;


-- Calculate the total units and sales for each media type and sort on units sold

SELECT
    mt.name AS "Media Type",
	SUM(il.quantity) AS "Units Sold",
    SUM(il.unit_price * il.quantity) AS "Total Sales"
FROM
    public.invoice_line AS il
LEFT JOIN
    public.track AS t ON il.track_id = t.track_id
LEFT JOIN
    public.media_type AS mt ON t.media_type_id = mt.media_type_id
GROUP BY
    mt.name
ORDER BY
    "Units Sold" DESC;




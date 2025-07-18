-- data table
TRUNCATE TABLE public.bch_price;

SET search_path TO bch_test;

-----------------------
-- Preview the raw data
-----------------------
SELECT *
FROM public.bch_test
LIMIT 100;


-----------------------
-- If a working copy of the table exists, delete it
-- Then create a new working copy
-----------------------
DROP TABLE IF EXISTS public.bch_data;
-- Create a working copy with renamed columns so I don't have to use quotes
CREATE TABLE public.bch_data AS
SELECT
    "Datetime" AS date_time,
    "Open" AS p_open,
    "High" AS p_high,
	"Low" AS p_low,
	"Close" AS p_close,
	"Volume" AS volume,
	"Dividends" AS dividends,
	"Stock Splits" AS splits
FROM
    public.bch_test;


-----------------------
-- Compare the incremental price to the day's average
-----------------------
SELECT
    to_char(date_time, 'yyyy:MM:dd - HH24:MI:SS') AS "Time",
    p_close,
    (SELECT AVG(p_close) FROM public.bch_data) AS average_close,
    p_close - (SELECT AVG(p_close) FROM public.bch_data) AS difference_from_average
FROM
    public.bch_data;

-----------------------
-- For each closing price entry, calculate the percentage increase or decrease
-- the very first entry in the dataset.

-- This version uses a subquery in the FROM clause to avoid potential execution issues with CTEs.

-- The main SELECT statement calculates the percentage change.
-- The formula is: ((Current Value - Initial Value) / Initial Value) * 100
-----------------------
SELECT
    pc.date_time,
    pc.p_close,
    pc.first_entry_price,
    -- Calculate the percentage difference
    ((pc.p_close - pc.first_entry_price) / pc.first_entry_price) * 100.0 AS percentage_change_from_first
FROM
    -- The subquery finds the 'p_close' for each row and adds a column
    -- containing the very first 'p_close' value from the dataset.
    (SELECT
        date_time,
        p_close,
        -- Get the very first 'p_close' value from the entire ordered set
		-- I should note that this is not the method that came to mind when
		-- putting this together. But I read this way is much more efficient
		-- than a subquery SELECT.
        FIRST_VALUE(p_close) OVER (ORDER BY date_time ASC) AS first_entry_price
    FROM
        public.bch_data
    ) AS pc
ORDER BY
    pc.date_time ASC;

	




-----------------------
-- Everything beyond this point is still a work in progress and should not be executed
-----------------------


-- Rolling weighted average
WITH weighted_sales AS (
  SELECT
    date,
    product_id,
    sales_volume,
    0.5 * sales_volume +
    0.3 * LAG(sales_volume, 1) OVER w +
    0.2 * LAG(sales_volume, 2) OVER w AS weighted_avg_sales,
    COUNT(*) OVER w AS num_days
  FROM sales
  WINDOW w AS (
    PARTITION BY product_id ORDER BY date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  )
)
SELECT
  date,
  product_id,
  weighted_avg_sales
FROM weighted_sales
WHERE num_days = 3;

---------------------------------------------
-- This script calculates a 5-period weighted moving average (WMA) for time-series data.
-- It assumes the data has been loaded into a table called 'bch_price_data'
-- with columns including 'Timestamp' and 'Close'.

-- First, we'll set up a Common Table Expression (CTE) to simulate the data table
-- and ensure the data is correctly ordered by timestamp.
WITH ordered_prices AS (
    SELECT
        "Timestamp",
        "Open",
        "High",
        "Low",
        "Close",
        "Volume"
    FROM
        public.bch_test -- Replace with your actual table name
    ORDER BY
        "Timestamp" ASC
),

-- Next, we use another CTE and the LAG() window function to access the 'Close' prices
-- from the four preceding rows. Each LAG corresponds to a previous time period.
price_lags AS (
    SELECT
        "Timestamp",
        "Close",
        -- Get the closing price from 1 period ago
        LAG("Close", 1) OVER (ORDER BY "Timestamp") AS prev_close_1,
        -- Get the closing price from 2 periods ago
        LAG("Close", 2) OVER (ORDER BY "Timestamp") AS prev_close_2,
        -- Get the closing price from 3 periods ago
        LAG("Close", 3) OVER (ORDER BY "Timestamp") AS prev_close_3,
        -- Get the closing price from 4 periods ago
        LAG("Close", 4) OVER (ORDER BY "Timestamp") AS prev_close_4
    FROM
        ordered_prices
)

-- Finally, we select all the original data and calculate the 5-period WMA.
-- The calculation is performed only if we have all 5 required data points (the current and 4 previous).
-- The weights are applied as specified: 5/15, 4/15, 3/15, 2/15, and 1/15.
SELECT
    op."Timestamp",
    op."Open",
    op."High",
    op."Low",
    op."Close",
    op."Volume",
    -- The CASE statement ensures we only calculate the WMA when we have enough historical data.
    CASE
        WHEN pl.prev_close_4 IS NOT NULL THEN
            (
                (pl."Close" * 5) +        -- Current price, weight 5
                (pl.prev_close_1 * 4) +   -- 1 period ago, weight 4
                (pl.prev_close_2 * 3) +   -- 2 periods ago, weight 3
                (pl.prev_close_3 * 2) +   -- 3 periods ago, weight 2
                (pl.prev_close_4 * 1)     -- 4 periods ago, weight 1
            ) / 15.0 -- The sum of the weights (5+4+3+2+1)
        ELSE
            NULL -- Output NULL if there isn't enough data for a full 5-period calculation
    END AS weighted_moving_average
FROM
    ordered_prices op
JOIN
    price_lags pl ON op."Timestamp" = pl."Timestamp"
ORDER BY
    op."Timestamp" ASC;

--------------------------------
SELECT "Price"
FROM public.bch_price
LIMIT 100;

SELECT
	to_char("Timestamp", 'yyyy:MM:dd - HH24:MI:SS') AS "Time",
    "Price",
    "Volume",
	price * volume AS "VWAP"
FROM
    bch_price;

-- data + VWAP
SELECT
    to_char("Timestamp", 'YYYY-MM-DD HH24:MI:SS') AS datetime,
    "Price",
    "Volume",
    CASE
        WHEN (SUM("Volume") OVER (ORDER BY "Timestamp")) > 0 THEN
            (SUM("Price" * "Volume") OVER (ORDER BY "Timestamp")) / (SUM("Volume") OVER (ORDER BY "Timestamp"))
        ELSE
            NULL
    END AS "VWAP"
FROM
    bch_price
ORDER BY
    "Timestamp" DESC;

-- Some attempted formatting
SELECT
    to_char("Timestamp", 'YYYY-MM-DD HH24:MI:SS') AS datetime,
    to_char("Price", '99.9999') AS "Price",
    "Volume",
    CASE
        WHEN (SUM("Volume") OVER (ORDER BY "Timestamp")) > 0 THEN
            to_char(
                (SUM("Price" * "Volume") OVER (ORDER BY "Timestamp")) / (SUM("Volume") OVER (ORDER BY "Timestamp")),
                '99.9999'
            )
        ELSE
            NULL
    END AS "VWAP"
FROM
    bch_price
ORDER BY
    "Timestamp" DESC;
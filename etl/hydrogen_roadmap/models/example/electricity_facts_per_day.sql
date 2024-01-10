WITH base AS(
    SELECT
        DATE :: TIMESTAMP + period * INTERVAL '15 minutes' AS adjusted,
        price_amount
    FROM
        hydrogen_roadmap_stag.electricity_prices
    WHERE
        resolution = 'PT15M'
)
SELECT
    date_trunc('day', adjusted) AS date,
    AVG(price_amount) AS price
FROM
    BASE
GROUP BY
    date
ORDER BY
    date
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
    adjusted as date,
    price_amount as price
FROM
    base

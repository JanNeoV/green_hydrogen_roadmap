WITH price_base AS(
    SELECT
        to_char(
            DATE :: TIMESTAMP,
            'YYYYMMDD'
        ) AS date_formatted,
        (
            price_amount / 1000
        ) AS price
    FROM
        hydrogen_roadmap_stag.electricity_prices
),
electricity_ref AS (
    SELECT
        'Mixed' AS technology,
        PERCENTILE_CONT(0.25) within GROUP (
            ORDER BY
                price
        ) AS price
    FROM
        price_base
    UNION ALL
    SELECT
        'Mixed' AS technology,
        PERCENTILE_CONT(0.5) within GROUP (
            ORDER BY
                price
        ) AS price
    FROM
        price_base
    UNION ALL
    SELECT
        'Mixed' AS technology,
        PERCENTILE_CONT(0.75) within GROUP (
            ORDER BY
                price
        ) AS price
    FROM
        price_base
    UNION ALL
    SELECT
        *
    FROM
        hydrogen_roadmap_stag.lcoe_table
)
SELECT * FROM electricity_ref
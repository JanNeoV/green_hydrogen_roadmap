WITH daterange AS (
    SELECT
        MIN(combined_date) :: TIMESTAMP AS min_date,
        MAX(combined_date) :: TIMESTAMP AS max_date
    FROM
        (
            SELECT
                DATE :: TIMESTAMP + period * INTERVAL '15 minutes' AS combined_date
            FROM
                hydrogen_roadmap_stag.electricity_prices
            UNION
            SELECT
                DATE :: TIMESTAMP + period * INTERVAL '15 minutes' AS combined_date
            FROM
                hydrogen_roadmap_stag.electricity_generation
        )
)
SELECT
    generate_series(
        min_date,
        max_date,
        INTERVAL '15 minutes'
    ) AS interval_date
FROM
    daterange

WITH base AS(
    SELECT
        to_char(
            DATE :: TIMESTAMP,
            'YYYY/MM/DD HH:MM:SS'
        ) AS date_formatted,
        DATE :: TIMESTAMP + period * INTERVAL '15 minutes' AS adjusted,
        quantity,
        mkt_psr_type
    FROM
        hydrogen_roadmap_stag.electricity_generation
)
SELECT
    DATE_TRUNC(
        'day',
        adjusted
    ) AS date,
    SUM(quantity) AS quantity,
    mkt_psr_type
FROM
    base
GROUP BY
    date,
    mkt_psr_type
ORDER BY
    date

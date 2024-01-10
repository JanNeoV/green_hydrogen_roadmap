WITH base AS(
    SELECT
        DATE :: TIMESTAMP + period * INTERVAL '15 minutes' AS date,
        quantity,
        mkt_psr_type
    FROM
        hydrogen_roadmap_stag.electricity_generation
)
SELECT
    quantity,
    mkt_psr_type,
    date
FROM
    base

SELECT
        DATE :: TIMESTAMP + period * INTERVAL '15 minutes' as combined_date
        
    FROM
        hydrogen_roadmap_stag.electricity_prices
            UNION
            SELECT
        DATE :: TIMESTAMP + period * INTERVAL '15 minutes' as combined_date
    FROM
        hydrogen_roadmap_stag.electricity_generation
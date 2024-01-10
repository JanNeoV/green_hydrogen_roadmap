WITH source AS (
    SELECT
        electrolysis_technology AS electrolyzer,
        capex_eur_kw :: numeric AS capex,
        electrolysis_energy_demand_kwh_kg :: numeric AS el_energy_demand,
        capacity_kw :: numeric AS capacity
    FROM
        hydrogen_roadmap_stag.lit_ref_table
),
prep AS(
    SELECT
        electrolyzer,
        '25th' AS quantile,
        PERCENTILE_CONT(0.25) within GROUP (
            ORDER BY
                capex
        ) AS capex,
        PERCENTILE_CONT(0.25) within GROUP (
            ORDER BY
                el_energy_demand
        ) AS el_energy_demand,
        PERCENTILE_CONT(0.25) within GROUP (
            ORDER BY
                capacity
        ) AS capacity
    FROM
        source
    GROUP BY
        electrolyzer
    UNION ALL
    SELECT
        electrolyzer,
        '50th' AS quantile,
        PERCENTILE_CONT(0.50) within GROUP (
            ORDER BY
                capex
        ) AS capex,
        PERCENTILE_CONT(0.50) within GROUP (
            ORDER BY
                el_energy_demand
        ) AS el_energy_demand,
        PERCENTILE_CONT(0.50) within GROUP (
            ORDER BY
                capacity
        ) AS capacity
    FROM
        source
    GROUP BY
        electrolyzer
    UNION ALL
    SELECT
        electrolyzer,
        '75th' AS quantile,
        PERCENTILE_CONT(0.75) within GROUP (
            ORDER BY
                capex
        ) AS capex,
        PERCENTILE_CONT(0.75) within GROUP (
            ORDER BY
                el_energy_demand
        ) AS el_energy_demand,
        PERCENTILE_CONT(0.75) within GROUP (
            ORDER BY
                capacity
        ) AS capacity
    FROM
        source
    GROUP BY
        electrolyzer
),
combined_invest_cost AS(
    SELECT
        b.electrolyzer,
        b.capex,
        C.el_energy_demand,
        d.capacity,
        b.capex * d.capacity AS invest
    FROM
        prep AS b
        CROSS JOIN prep AS C
        CROSS JOIN prep AS d
    WHERE
        b.electrolyzer = C.electrolyzer
        AND C.electrolyzer = d.electrolyzer
),
price_base AS(
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
),
combined_prices AS(
    SELECT
        A.electrolyzer,
        A.capex,
        A.el_energy_demand,
        A.capacity,
        A.invest,
        b.price
    FROM
        combined_invest_cost AS A
        CROSS JOIN electricity_ref AS b
),
combined_flh AS(
    SELECT
        A.electrolyzer,
        A.capex,
        A.el_energy_demand,
        A.capacity,
        A.invest,
        A.price,
        b.flh
    FROM
        combined_prices AS A
        CROSS JOIN hydrogen_roadmap_stag.flh_table AS b
),
lcoh_prep AS(
    SELECT
        electrolyzer,
        capex,
        el_energy_demand,
        capacity,
        invest,
        price,
        flh,
        (
            capacity * flh
        ) / el_energy_demand AS quantity_h2_kg,
        (
            capacity * flh * price
        ) AS opex
    FROM
        combined_flh
),
discounted_opex AS (
    SELECT
        electrolyzer,
        capex,
        el_energy_demand,
        capacity,
        invest,
        price,
        flh,
        quantity_h2_kg,
        opex,
        n AS year_n,
        (opex / (1.04) ^ n) AS discounted_opex_year_n
    FROM
        lcoh_prep,
        generate_series(
            1,
            20
        ) AS n
),
aggregated_opex AS (
    SELECT
        electrolyzer,
        capex,
        el_energy_demand,
        capacity,
        invest,
        price,
        flh,
        quantity_h2_kg,
        SUM(discounted_opex_year_n) AS total_discounted_opex
    FROM
        discounted_opex
    GROUP BY
        electrolyzer,
        capex,
        el_energy_demand,
        capacity,
        invest,
        price,
        flh,
        quantity_h2_kg
)
SELECT
    *,
    (
        invest + total_discounted_opex
    ) / (
        quantity_h2_kg * 20
    ) AS lcoh
FROM
    aggregated_opex

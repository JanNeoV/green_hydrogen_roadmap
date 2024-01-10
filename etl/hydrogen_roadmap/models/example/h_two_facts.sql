WITH source AS (
    SELECT
        storage_technology,
        storage_state,
        storage_cost_eur_kghtwo :: numeric AS storage_cost,
        conversion_input_state,
        conversion_technology,
        conversion_energy_demand_kwh_kghtwo :: numeric,
        conversion_output_state,
        transport_technology,
        transport_state,
        transport_cost_eur_tkm :: numeric
    FROM
        hydrogen_roadmap_stag.lit_ref_table
),
rep AS(
    SELECT
        electrolyzer,
        '25th' AS quantile,
        PERCENTILE_CONT(0.25) within GROUP (
            ORDER BY
                lcoh
        ) AS lcoh
    FROM
        {{ ref('LCOH_FACT') }}
    GROUP BY
        electrolyzer
    UNION ALL
    SELECT
        electrolyzer,
        '50th' AS quantile,
        PERCENTILE_CONT(0.5) within GROUP (
            ORDER BY
                lcoh
        ) AS lcoh
    FROM
        {{ ref('LCOH_FACT') }}
    GROUP BY
        electrolyzer
    UNION ALL
    SELECT
        electrolyzer,
        '75th' AS quantile,
        PERCENTILE_CONT(0.75) within GROUP (
            ORDER BY
                lcoh
        ) AS lcoh
    FROM
        {{ ref('LCOH_FACT') }}
    GROUP BY
        electrolyzer
),
storage_rep AS(
    SELECT
        storage_technology,
        storage_state,
        '25th' AS quantile,
        PERCENTILE_CONT(0.25) within GROUP (
            ORDER BY
                storage_cost
        ) AS storage_cost
    FROM
        source
    GROUP BY
        storage_technology,
        storage_state
    UNION ALL
    SELECT
        storage_technology,
        storage_state,
        '50th' AS quantile,
        PERCENTILE_CONT(0.5) within GROUP (
            ORDER BY
                storage_cost
        ) AS storage_cost
    FROM
        source
    GROUP BY
        storage_technology,
        storage_state
    UNION ALL
    SELECT
        storage_technology,
        storage_state,
        '75th' AS quantile,
        PERCENTILE_CONT(0.75) within GROUP (
            ORDER BY
                storage_cost
        ) AS storage_cost
    FROM
        source
    GROUP BY
        storage_technology,
        storage_state
),
storage_mid AS(
    SELECT
        A.storage_technology,
        A.storage_state,
        A.storage_cost,
        b.lcoh
    FROM
        storage_rep AS A
        CROSS JOIN rep AS b
    WHERE
        storage_cost IS NOT NULL
),
conversion_prep AS(
    SELECT
        conversion_input_state,
        conversion_technology,
        conversion_output_state,
        '25th' AS quantile,
        PERCENTILE_CONT(0.25) within GROUP (
            ORDER BY
                conversion_energy_demand_kwh_kghtwo
        ) AS conversion_energy_demand_kwh_kghtwo
    FROM
        source
    GROUP BY
        conversion_input_state,
        conversion_technology,
        conversion_output_state
    UNION ALL
    SELECT
        conversion_input_state,
        conversion_technology,
        conversion_output_state,
        '50th' AS quantile,
        PERCENTILE_CONT(0.5) within GROUP (
            ORDER BY
                conversion_energy_demand_kwh_kghtwo
        ) AS conversion_energy_demand_kwh_kghtwo
    FROM
        source
    GROUP BY
        conversion_input_state,
        conversion_technology,
        conversion_output_state
    UNION ALL
    SELECT
        conversion_input_state,
        conversion_technology,
        conversion_output_state,
        '75th' AS quantile,
        PERCENTILE_CONT(0.75) within GROUP (
            ORDER BY
                conversion_energy_demand_kwh_kghtwo
        ) AS conversion_energy_demand_kwh_kghtwo
    FROM
        source
    GROUP BY
        conversion_input_state,
        conversion_technology,
        conversion_output_state
),
conversion_mid AS (
    SELECT
        A.storage_technology,
        A.storage_state,
        A.storage_cost,
        A.lcoh,
        b.conversion_input_state,
        b.conversion_output_state,
        b.conversion_technology,
        b.conversion_energy_demand_kwh_kghtwo
    FROM
        storage_mid AS A
        CROSS JOIN conversion_prep AS b
    WHERE
        A.storage_state = b.conversion_input_state
),
transport_prep AS(
    SELECT
        transport_technology,
        transport_state,
        '25th' AS quantile,
        PERCENTILE_CONT(0.25) within GROUP (
            ORDER BY
                transport_cost_eur_tkm
        ) AS transport_cost_eur_tkm
    FROM
        source
    GROUP BY
        transport_technology,
        transport_state
    UNION ALL
    SELECT
        transport_technology,
        transport_state,
        '50th' AS quantile,
        PERCENTILE_CONT(0.5) within GROUP (
            ORDER BY
                transport_cost_eur_tkm
        ) AS transport_cost_eur_tkm
    FROM
        source
    GROUP BY
        transport_technology,
        transport_state
    UNION ALL
    SELECT
        transport_technology,
        transport_state,
        '75th' AS quantile,
        PERCENTILE_CONT(0.75) within GROUP (
            ORDER BY
                transport_cost_eur_tkm
        ) AS transport_cost_eur_tkm
    FROM
        source
    GROUP BY
        transport_technology,
        transport_state
),
combined_transport AS(
    SELECT
        A.transport_technology,
        A.transport_state,
        A.transport_cost_eur_tkm,
        b.distance_km
    FROM
        transport_prep AS A
        CROSS JOIN hydrogen_roadmap_stag.distance_table AS b
),
combined_conversion_transport AS(
    SELECT
        A.storage_technology,
        A.storage_state,
        A.storage_cost,
        A.lcoh,
        A.conversion_input_state,
        A.conversion_output_state,
        A.conversion_technology,
        A.conversion_energy_demand_kwh_kghtwo,
        b.transport_technology,
        b.transport_state,
        b.transport_cost_eur_tkm,
        b.distance_km
    FROM
        conversion_mid AS A
        CROSS JOIN combined_transport AS b
    WHERE
        A.conversion_output_state = b.transport_state
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
final_combination AS(
    SELECT
        A.storage_technology,
        A.storage_state,
        A.storage_cost,
        A.lcoh,
        A.conversion_input_state,
        A.conversion_output_state,
        A.conversion_technology,
        A.conversion_energy_demand_kwh_kghtwo,
        A.transport_technology,
        A.transport_state,
        A.transport_cost_eur_tkm,
        A.distance_km,
        b.price
    FROM
        combined_conversion_transport AS A
        CROSS JOIN electricity_ref AS b
),
total_cost AS(
    SELECT
        storage_technology,
        storage_state,
        storage_cost,
        lcoh,
        conversion_input_state,
        conversion_output_state,
        conversion_technology,
        conversion_energy_demand_kwh_kghtwo,
        transport_technology,
        transport_state,
        transport_cost_eur_tkm,
        distance_km,
        price,
        (
            conversion_energy_demand_kwh_kghtwo * price
        ) AS conversion_cost,
        (
            transport_cost_eur_tkm * distance_km / 1000
        ) AS transport_cost
    FROM
        final_combination
)
SELECT
    storage_technology,
    storage_state,
    storage_cost,
    lcoh,
    conversion_input_state,
    conversion_output_state,
    conversion_technology,
    conversion_energy_demand_kwh_kghtwo,
    transport_technology,
    transport_state,
    transport_cost_eur_tkm,
    distance_km,
    price,
    conversion_cost,
    transport_cost,
    storage_cost + conversion_cost + transport_cost + lcoh AS total_cost
FROM
    total_cost 


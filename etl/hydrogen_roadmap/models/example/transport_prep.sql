WITH source AS (
    SELECT
        storage_technology,
        storage_state,
        storage_cost_eur_kghtwo::NUMERIC as storage_cost,
        conversion_input_state,
        conversion_technology,
        conversion_energy_demand_kwh_kghtwo::NUMERIC,
        conversion_output_state,
        transport_technology,
        transport_state,
        transport_cost_eur_tkm::NUMERIC



    FROM
        hydrogen_roadmap_stag.lit_ref_table
) ,
transport_prep 
AS(
    SELECT
        transport_technology,
        transport_state,
        '25th' AS quantile,
        PERCENTILE_CONT(0.25) within GROUP (
            ORDER BY
                transport_cost_eur_tkm
        ) AS transport_cost_eur_tkm   FROM source
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
        ) AS transport_cost_eur_tkm  FROM source
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
        ) AS transport_cost_eur_tkm  FROM source
    GROUP BY
                transport_technology,
        transport_state),
         combined_transport AS(
SELECT a.transport_technology,a.transport_state,a.transport_cost_eur_tkm,b.distance_km FROM transport_prep AS a CROSS JOIN hydrogen_roadmap_stag.distance_table AS b)
SELECT * FROM combined_transport
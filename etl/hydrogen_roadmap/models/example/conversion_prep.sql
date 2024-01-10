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
conversion_prep
AS(
    SELECT
        conversion_input_state,
        conversion_technology,conversion_output_state,
        '25th' AS quantile,
        PERCENTILE_CONT(0.25) within GROUP (
            ORDER BY
                conversion_energy_demand_kwh_kghtwo
        ) AS conversion_energy_demand_kwh_kghtwo   FROM source
    GROUP BY
        conversion_input_state,
        conversion_technology,conversion_output_state
    UNION ALL
    SELECT
        conversion_input_state,
        conversion_technology,conversion_output_state,
        '50th' AS quantile,
        PERCENTILE_CONT(0.5) within GROUP (
            ORDER BY
                conversion_energy_demand_kwh_kghtwo 
        ) AS conversion_energy_demand_kwh_kghtwo  FROM source
    GROUP BY
        conversion_input_state,
        conversion_technology,conversion_output_state
    UNION ALL
    SELECT
        conversion_input_state,
        conversion_technology,conversion_output_state,
        '75th' AS quantile,
        PERCENTILE_CONT(0.75) within GROUP (
            ORDER BY
                conversion_energy_demand_kwh_kghtwo
        ) AS conversion_energy_demand_kwh_kghtwo  FROM source
    GROUP BY
        conversion_input_state,
        conversion_technology,conversion_output_state)
SELECT * FROM conversion_prep WHERE conversion_energy_demand_kwh_kghtwo IS NOT NULL
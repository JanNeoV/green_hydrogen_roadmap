WITH base AS (
    SELECT
        date,
        pngaseuusdm / 1.0703 AS ng_price_eur, -- Exchange rate conversion
        (pngaseuusdm / 1.0703) / 26.4 / 0.8 AS ng_price_eur_kg, -- Additional calculations
        0.15 / 1.0703 AS investment, -- Exchange rate conversion for investment
        0.81 * 0.249 / 1.0703 AS om -- Exchange rate conversion for OM
    FROM
        hydrogen_roadmap_stag.ngas_table
),
calculations AS (
    SELECT
        date,
        ng_price_eur,
        ng_price_eur_kg,
        investment,
        om,
        investment + om + ng_price_eur_kg * 3.2 AS raw,
        investment + om + ng_price_eur_kg * 3.2 + 8.5 * 50 / 1000 AS fif,
        investment + om + ng_price_eur_kg * 3.2 + 8.5 * 100 / 1000 AS hun,
        investment + om + ng_price_eur_kg * 3.2 + 8.5 * 150 / 1000 AS hunfif,
        investment + om + ng_price_eur_kg * 3.2 + 8.5 * 200 / 1000 AS two
    FROM
        base
)
SELECT
    *
FROM
    calculations

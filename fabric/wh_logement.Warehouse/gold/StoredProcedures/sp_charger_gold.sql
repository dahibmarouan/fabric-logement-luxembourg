CREATE   PROC [gold].[sp_charger_gold] AS BEGIN

    -- Dimension commune
    DROP TABLE IF EXISTS gold.dim_commune;

    CREATE TABLE gold.dim_commune AS
    WITH communes AS (
        SELECT DISTINCT commune
        FROM silver.prix_commune_annuel
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY commune) AS commune_id,
        commune
    FROM communes;

    -- Dimension année
    DROP TABLE IF EXISTS gold.dim_annee;

    CREATE TABLE gold.dim_annee AS
    WITH annees AS (
        SELECT DISTINCT annee
        FROM silver.prix_commune_annuel
    )
    SELECT
        annee,
        CASE
            WHEN annee BETWEEN 2016 AND 2019 THEN 'Avant Covid'
            WHEN annee = 2020                THEN 'Covid'
            WHEN annee BETWEEN 2021 AND 2022 THEN 'Boom post-Covid'
            WHEN annee BETWEEN 2023 AND 2025 THEN 'Hausse des taux'
        END AS periode
    FROM annees;

    -- Table de faits
    DROP TABLE IF EXISTS gold.fact_prix;

    CREATE TABLE gold.fact_prix AS
    SELECT
        g.commune_id,
        s.annee,
        s.type_bien,
        s.nb_ventes,
        s.prix_m2_affine,
        s.fourchette_min,
        s.fourchette_max,
        s.est_masque
    FROM silver.prix_commune_annuel AS s
    JOIN gold.dim_commune AS g
        ON s.commune = g.commune;

END;

GO
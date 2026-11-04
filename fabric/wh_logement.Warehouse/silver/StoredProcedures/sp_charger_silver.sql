CREATE   PROCEDURE silver.sp_charger_silver AS BEGIN 

DROP TABLE IF EXISTS silver.prix_commune_annuel;

CREATE TABLE silver.prix_commune_annuel AS

WITH existant AS (
    SELECT
        CAST(annee AS INT)                  AS annee,
        col_1                               AS commune,
        'existant'                          AS type_bien,
        TRY_CAST(col_2 AS INT)              AS nb_ventes,
        TRY_CAST(col_3 AS DECIMAL(10,3))    AS prix_m2_affine,
        CASE WHEN col_3 = '*' THEN 1 ELSE 0 END AS est_masque,
        CASE WHEN col_4 = '*' THEN NULL
             ELSE REPLACE(REPLACE(col_4, '€', ''), ' ', '')
        END                                 AS fourchette
    FROM lh_bronze.dbo.raw_prix_commune
    WHERE col_1 <> 'Total des transactions'
      AND TRY_CAST(col_2 AS INT) IS NOT NULL
),

vefa AS (
    SELECT
        CAST(annee AS INT)                  AS annee,
        col_1                               AS commune,
        'VEFA'                              AS type_bien,
        TRY_CAST(col_5 AS INT)              AS nb_ventes,
        TRY_CAST(col_6 AS DECIMAL(10,3))    AS prix_m2_affine,
        CASE WHEN col_6 = '*' THEN 1 ELSE 0 END AS est_masque,
        CASE WHEN col_7 = '*' THEN NULL
             ELSE REPLACE(REPLACE(col_7, '€', ''), ' ', '')
        END                                 AS fourchette
    FROM lh_bronze.dbo.raw_prix_commune
    WHERE col_1 <> 'Total des transactions'
      AND TRY_CAST(col_2 AS INT) IS NOT NULL
),

empile AS (
    SELECT * FROM existant
    UNION ALL
    SELECT * FROM vefa
),

avec_tiret AS (
    SELECT *, CHARINDEX('-', fourchette) AS tiret_posi
    FROM empile
)

SELECT
    annee,
    commune,
    type_bien,
    nb_ventes,
    prix_m2_affine,
    est_masque,
    TRY_CAST(LEFT(fourchette, tiret_posi - 1) AS INT)        AS fourchette_min,
    TRY_CAST(SUBSTRING(fourchette, tiret_posi + 1, 100) AS INT) AS fourchette_max
FROM avec_tiret
ORDER BY annee, commune, type_bien;

END

GO
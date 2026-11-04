CREATE TABLE [gold].[fact_prix] (
    [commune_id]     BIGINT          NULL,
    [annee]          INT             NULL,
    [type_bien]      VARCHAR (8)     NOT NULL,
    [nb_ventes]      INT             NULL,
    [prix_m2_affine] DECIMAL (10, 3) NULL,
    [fourchette_min] INT             NULL,
    [fourchette_max] INT             NULL,
    [est_masque]     INT             NOT NULL
);


GO
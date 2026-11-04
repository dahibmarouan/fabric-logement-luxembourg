CREATE TABLE [silver].[prix_commune_annuel] (
    [annee]          INT             NULL,
    [commune]        VARCHAR (8000)  NULL,
    [type_bien]      VARCHAR (8)     NOT NULL,
    [nb_ventes]      INT             NULL,
    [prix_m2_affine] DECIMAL (10, 3) NULL,
    [est_masque]     INT             NOT NULL,
    [fourchette_min] INT             NULL,
    [fourchette_max] INT             NULL
);


GO
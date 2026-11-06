# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "fe16c071-f247-4496-b303-fd91322cff77",
# META       "default_lakehouse_name": "lh_bronze",
# META       "default_lakehouse_workspace_id": "b83323f5-6981-47ac-8fa4-dc4e100a4e00",
# META       "known_lakehouses": [
# META         {
# META           "id": "fe16c071-f247-4496-b303-fd91322cff77"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

import requests, re, os, datetime

DATASET_API = "https://data.public.lu/api/1/datasets/57f268ff111e9b0c425f9bce/"
DOSSIER = "/lakehouse/default/Files/prix_commune"
ANNEE_MIN = 2016
ANNEE_MAX = datetime.date.today().year - 1   # uniquement des années civiles complètes

os.makedirs(DOSSIER, exist_ok=True)
ressources = requests.get(DATASET_API, timeout=30).json()["resources"]

telecharges = []
for r in ressources:
    m = re.search(r"par-commune-(\d{4})\.xls$", r["url"])
    if not m:
        continue   # ignore les fichiers trimestriels (ex. 2025t4) et les autres formats
    annee = int(m.group(1))
    if ANNEE_MIN <= annee <= ANNEE_MAX:
        contenu = requests.get(r["url"], timeout=60).content
        with open(f"{DOSSIER}/prix_affine_commune_{annee}.xls", "wb") as f:
            f.write(contenu)
        telecharges.append(annee)

print(f"{len(telecharges)} fichiers téléchargés : {sorted(telecharges)}")
assert len(telecharges) >= 10, "Moins de 10 années trouvées : vérifier la source"

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

import pandas as pd, glob, os, re
from pyspark.sql.types import StructType, StructField, StringType

frames = []
for path in sorted(glob.glob("/lakehouse/default/Files/prix_commune/*.xls")):
    nom = os.path.basename(path)
    annee = re.search(r"(\d{4})", nom).group(1)
    df = pd.read_excel(path, sheet_name=0, header=None, dtype=str)
    df.columns = [f"col_{i}" for i in range(df.shape[1])]
    df.insert(0, "num_ligne", range(1, len(df) + 1))
    df.insert(0, "annee", annee)
    df.insert(0, "fichier", nom)
    frames.append(df)

raw = pd.concat(frames, ignore_index=True)
raw = raw.astype(object).where(raw.notna(), None)
rows = [[None if v is None else str(v) for v in r] for r in raw.itertuples(index=False)]
schema = StructType([StructField(c, StringType(), True) for c in raw.columns])

spark.createDataFrame(rows, schema) \
     .write.mode("overwrite").format("delta") \
     .saveAsTable("raw_prix_commune")

print(f"{len(rows)} lignes chargées depuis {len(frames)} fichiers")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

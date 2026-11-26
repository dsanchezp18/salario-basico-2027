# ============================================================
# 02_ventas_sri.R
# Author: Daniel Sanchez
# Purpose: Ventas totales declaradas al SRI de enero a julio frente al salario
#          básico unificado (SBU), 2017 a 2025, en índice con 2017 = 100.
# Inputs:  data/raw/sri/ventas_enero_julio_2017_2025.csv
#          data/raw/sbu/sbu_ecuador_2007_2027.csv
# Outputs: outputs/tables/ventas_sri_vs_sbu.csv
# ============================================================

# 0. Setup ----

library(dplyr)
library(readr)

# 1. Read inputs ----

# Ventas de enero a julio de cada año, en millones de dólares, según el
# Ministerio de Economía y Finanzas con datos del SRI (publicadas por
# El Universo).
ventas <- read_csv(
  "data/raw/sri/ventas_enero_julio_2017_2025.csv",
  show_col_types = FALSE
)

sbu <- read_csv(
  "data/raw/sbu/sbu_ecuador_2007_2027.csv",
  show_col_types = FALSE
)

# 2. Prepare data ----

# La serie del SBU empieza en 2007 y llega a 2027: sus años sin ventas se
# descartan a propósito.
ventas_sbu <- ventas |>
  left_join(
    sbu,
    by = join_by(anio),
    relationship = "one-to-one"
  )

# 3. Calculate estimates ----

# Dividimos cada año para su valor de 2017: un índice de 148 significa que el
# valor es 48% mayor que en 2017.
ventas_sbu <- ventas_sbu |>
  mutate(
    indice_ventas = 100 * ventas_millones / ventas_millones[anio == 2017],
    indice_sbu = 100 * sbu / sbu[anio == 2017],
    across(c(indice_ventas, indice_sbu), \(x) round(x, 1))
  )

# 4. Write outputs ----

write_csv(ventas_sbu, "outputs/tables/ventas_sri_vs_sbu.csv")

# ============================================================
# 05_maquinaria_nacional.R
# Author: Daniel Sanchez
# Purpose: Compara cuánto subió en el último año el costo laboral de un
#          trabajador con salario básico unificado (SBU) y el precio de la
#          maquinaria producida en el país (INPP, sección 4 de la CPC:
#          productos metálicos, maquinaria y equipo).
# Inputs:  data/raw/inpp/inpp_seccion4_maquinaria_oct2026.csv
#          data/raw/sbu/sbu_ecuador_2007_2027.csv
# Outputs: outputs/tables/maquinaria_vs_costo_laboral.csv
# ============================================================

# 0. Setup ----

library(dplyr)
library(readr)

# 1. Read inputs ----

# Índice y variación anual de la sección 4 en octubre de 2026, tomados del
# boletín técnico del INPP de octubre de 2026.
maquinaria <- read_csv(
  "data/raw/inpp/inpp_seccion4_maquinaria_oct2026.csv",
  show_col_types = FALSE
)

sbu <- read_csv(
  "data/raw/sbu/sbu_ecuador_2007_2027.csv",
  show_col_types = FALSE
)

# 2. Calculate estimates ----

# El multiplicador de costo es fijo, así que el costo laboral crece igual que
# el SBU. El SBU fue de $470 en octubre de 2025 y de $482 en octubre de 2026.
sbu_2025 <- sbu$sbu[sbu$anio == 2025]
sbu_2026 <- sbu$sbu[sbu$anio == 2026]

comparacion <- tibble(
  periodo = "Octubre de 2025 a octubre de 2026",
  costo_laboral = 100 * (sbu_2026 / sbu_2025 - 1),
  maquinaria = maquinaria$variacion_anual
) |>
  mutate(across(c(costo_laboral, maquinaria), \(x) round(x, 2)))

# 3. Write outputs ----

write_csv(comparacion, "outputs/tables/maquinaria_vs_costo_laboral.csv")

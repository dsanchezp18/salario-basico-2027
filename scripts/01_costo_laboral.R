# ============================================================
# 01_costo_laboral.R
# Author: Daniel Sanchez
# Purpose: Costo mensual para el empleador de un trabajador con salario básico
#          unificado (SBU), 2026 y 2027. Es la Tabla 1 del artículo.
# Inputs:  Ninguno. Las tasas legales están escritas en el script.
# Outputs: outputs/tables/costo_laboral_sbu.csv
# ============================================================

# 0. Setup ----

library(dplyr)
library(readr)

sbu_2026 <- 482
sbu_2027 <- 500

# El décimo tercero, el décimo cuarto y los fondos de reserva equivalen cada
# uno a un doceavo del salario al año. El décimo cuarto es un SBU para todos,
# así que su doceavo coincide con el del salario solo cuando se gana el SBU.
doceavo <- 1 / 12

# Aporte patronal general al IESS: 11,15%. No se suma el 1% adicional al
# IECE y al SECAP. Las vacaciones tampoco se suman: ya se pagan dentro del
# salario.
aporte_patronal <- 0.1115

# 1. Calculate estimates ----

# Cada rubro por cada dólar de salario básico. El costo total es la suma de
# los rubros, sin redondear.
costo_laboral <- tibble(
  rubro = c(
    "Salario básico",
    "Décimo tercero (1/12 del salario)",
    "Décimo cuarto (1/12 de un SBU)",
    "Fondos de reserva (1/12 del salario)",
    "Aporte patronal al IESS (11,15%)"
  ),
  por_dolar = c(1, doceavo, doceavo, doceavo, aporte_patronal)
) |>
  add_row(
    rubro = "Costo total para el empleador",
    por_dolar = 1 + 3 * doceavo + aporte_patronal
  ) |>
  mutate(
    monto_2026 = round(sbu_2026 * por_dolar, 2),
    monto_2027 = round(sbu_2027 * por_dolar, 2),
    cambio_mensual = round(monto_2027 - monto_2026, 2),
    por_dolar = round(por_dolar, 4)
  )

# 2. Write outputs ----

write_csv(costo_laboral, "outputs/tables/costo_laboral_sbu.csv")

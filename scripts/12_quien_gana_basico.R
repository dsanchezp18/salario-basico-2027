# ============================================================
# 12_quien_gana_basico.R
# Author: Daniel Sanchez
# Purpose: Qué parte de las personas que trabajan gana menos, alrededor o más
#          que el salario básico, y cuántas de cada grupo tienen empleo
#          formal, enero a mayo de 2026.
# Inputs:  data/raw/enemdu/enemdu_persona_2026_l_trimestre.sav (enero a marzo)
#          data/raw/enemdu/enemdu_persona_2026_04.sav
#          data/raw/enemdu/enemdu_persona_2026_05.sav
# Outputs: outputs/tables/quien_gana_basico_resumen.csv
# ============================================================

# 0. Setup ----

library(dplyr)
library(haven)
library(readr)

# "Alrededor del básico" es entre 95% y 105% del SBU de $482: de $458 a $506.
limite_bajo <- 458
limite_alto <- 506

columnas <- c("secemp", "ingrl", "fexp")

# 1. Read inputs ----

primer_trimestre <- read_sav(
  "data/raw/enemdu/enemdu_persona_2026_l_trimestre.sav",
  encoding = "latin1",
  col_select = c(all_of(columnas), mes)
) |>
  zap_labels() |>
  mutate(mes = as.character(mes))

abril <- read_sav(
  "data/raw/enemdu/enemdu_persona_2026_04.sav",
  col_select = all_of(columnas)
) |>
  zap_labels() |>
  mutate(mes = "04")

mayo <- read_sav(
  "data/raw/enemdu/enemdu_persona_2026_05.sav",
  col_select = all_of(columnas)
) |>
  zap_labels() |>
  mutate(mes = "05")

# 2. Prepare data ----

# Cada mes pesa lo mismo: el factor de cada persona se divide para la suma del
# factor de su mes. Los factores faltantes se excluyen de la suma.
enemdu <- bind_rows(primer_trimestre, abril, mayo) |>
  mutate(across(c(secemp, ingrl, fexp), as.numeric)) |>
  mutate(peso = fexp / sum(fexp, na.rm = TRUE), .by = mes)

# Todas las personas que trabajan (secemp 1 a 4) con ingreso laboral conocido,
# incluidas las que no reciben pago. 999999 es "no informa". Empleo formal es
# secemp 1; el resto es informal, empleo doméstico o no clasificado.
ocupados <- enemdu |>
  filter(secemp %in% 1:4, !is.na(ingrl), ingrl < 999999, fexp > 0) |>
  mutate(
    empleo = if_else(secemp == 1, "Formal", "Informal y otros"),
    grupo = case_when(
      ingrl < limite_bajo ~ "Menos que el básico",
      ingrl <= limite_alto ~ "Alrededor del básico",
      .default = "Más que el básico"
    )
  )

# 3. Calculate estimates ----

peso_total <- sum(ocupados$peso, na.rm = TRUE)

# Porcentaje de todas las personas que trabajan en cada grupo y tipo de empleo,
# y qué parte de cada grupo tiene empleo formal.
resumen <- ocupados |>
  summarise(
    porcentaje = 100 * sum(peso, na.rm = TRUE) / peso_total,
    .by = c(grupo, empleo)
  ) |>
  mutate(
    porcentaje_grupo = sum(porcentaje),
    parte_del_grupo = 100 * porcentaje / porcentaje_grupo,
    .by = grupo
  ) |>
  arrange(grupo, empleo)

# 4. Write outputs ----

write_csv(resumen, "outputs/tables/quien_gana_basico_resumen.csv")

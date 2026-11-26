# ============================================================
# 06_ingreso_informales.R
# Author: Daniel Sanchez
# Purpose: Ingreso laboral mensual mediano de las personas que trabajan en el
#          sector formal y en el informal, enero a mayo de 2026.
# Inputs:  data/raw/enemdu/enemdu_persona_2026_l_trimestre.sav (enero a marzo)
#          data/raw/enemdu/enemdu_persona_2026_04.sav
#          data/raw/enemdu/enemdu_persona_2026_05.sav
# Outputs: outputs/tables/ingreso_formal_informal_2026.csv
# ============================================================

# 0. Setup ----

library(dplyr)
library(haven)
library(readr)

# Solo se leen el sector del empleo (secemp), el ingreso laboral (ingrl) y el
# factor de expansión (fexp).
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

# La base trimestral y las mensuales tienen factores de expansión en escalas
# distintas. Para que cada mes pese lo mismo, dividimos el factor de cada
# persona para la suma del factor de su mes. Los factores faltantes se
# excluyen de la suma.
enemdu <- bind_rows(primer_trimestre, abril, mayo) |>
  mutate(across(c(secemp, ingrl, fexp), as.numeric)) |>
  mutate(peso = fexp / sum(fexp, na.rm = TRUE), .by = mes)

# Personas ocupadas en el sector formal (secemp = 1) o informal (secemp = 2)
# con ingreso laboral positivo. 999999 es el código de "no informa".
ocupados <- enemdu |>
  filter(secemp %in% c(1, 2), ingrl > 0, ingrl < 999999, fexp > 0) |>
  mutate(sector = if_else(secemp == 1, "Formal", "Informal"))

# 3. Calculate estimates ----

# Mediana ponderada del ingreso laboral de cada sector.
ingreso_sector <- ocupados |>
  summarise(
    observaciones = n(),
    mediana = Hmisc::wtd.quantile(
      ingrl,
      weights = peso,
      probs = 0.5,
      normwt = TRUE
    ),
    .by = sector
  ) |>
  arrange(sector)

# 4. Write outputs ----

write_csv(ingreso_sector, "outputs/tables/ingreso_formal_informal_2026.csv")

# ============================================================
# 11_vab_por_trabajador_sector.R
# Author: Daniel Sanchez
# Purpose: Valor agregado por trabajador en 13 sectores, 2017 y 2025, frente
#          al salario básico unificado (SBU). Dibuja el Gráfico 2 del
#          artículo.
# Inputs:  data/raw/bce/iem_432_vab_corriente_2017_2025_todas.csv
#          data/raw/ilo/ilostat_empleo_seccion_2017_2025.csv
#          data/raw/sbu/sbu_ecuador_2007_2027.csv
# Outputs: outputs/tables/vab_por_trabajador_sector.csv
#          outputs/figures/grafico_2_vab_por_trabajador_sector.png
#          outputs/figures/grafico_2_vab_por_trabajador_sector.svg
# ============================================================

# 0. Setup ----

library(dplyr)
library(readr)
library(stringr)

source("scripts/00_common.R") # tema y colores; carga ggplot2

# 1. Read inputs ----

# Valor agregado bruto por industria, en millones de dólares corrientes.
# Banco Central del Ecuador, IEM 4.3.2 (boletín 2096, octubre de 2026).
vab <- read_csv(
  "data/raw/bce/iem_432_vab_corriente_2017_2025_todas.csv",
  show_col_types = FALSE
)

# Personas que trabajan por sección CIIU, en miles, formales e informales.
# OIT, ILOSTAT (EMP_TEMP_NB), con datos de la ENEMDU.
empleo <- read_csv(
  "data/raw/ilo/ilostat_empleo_seccion_2017_2025.csv",
  show_col_types = FALSE
)

sbu <- read_csv(
  "data/raw/sbu/sbu_ecuador_2007_2027.csv",
  show_col_types = FALSE
)

# 2. Prepare data ----

# El BCE agrupa algunas secciones de la CIIU. Manufactura va sin refinación de
# petróleo. Se dejan fuera minería, administración pública, actividades
# inmobiliarias (su valor agregado incluye el alquiler imputado de las
# viviendas propias) y hogares como empleadores.
industria_a_sector <- tribble(
  ~industria,                ~sector,
  "agricultura",             "Agricultura y pesca",
  "pesca",                   "Agricultura y pesca",
  "manuf_alimenticios",      "Manufactura",
  "manuf_no_alimenticios",   "Manufactura",
  "electricidad_agua",       "Electricidad y agua",
  "construccion",            "Construcción",
  "comercio",                "Comercio",
  "transporte",              "Transporte",
  "alojamiento",             "Alojamiento y comidas",
  "informacion",             "Información y comunicación",
  "financieras",             "Actividades financieras",
  "profesionales_tecnicas",  "Profesionales y administrativos",
  "ensenanza",               "Enseñanza",
  "salud",                   "Salud",
  "arte_otros_servicios",    "Arte y otros servicios"
)

seccion_a_sector <- tribble(
  ~seccion, ~sector,
  "A", "Agricultura y pesca",
  "C", "Manufactura",
  "D", "Electricidad y agua",
  "E", "Electricidad y agua",
  "F", "Construcción",
  "G", "Comercio",
  "H", "Transporte",
  "I", "Alojamiento y comidas",
  "J", "Información y comunicación",
  "K", "Actividades financieras",
  "M", "Profesionales y administrativos",
  "N", "Profesionales y administrativos",
  "P", "Enseñanza",
  "Q", "Salud",
  "R", "Arte y otros servicios",
  "S", "Arte y otros servicios"
)

# Las industrias y secciones que no están en las tablas de arriba se
# descartan a propósito.
vab_sector <- vab |>
  inner_join(
    industria_a_sector,
    by = join_by(industria),
    relationship = "many-to-one"
  ) |>
  summarise(
    vab_2017 = sum(vab_2017, na.rm = FALSE),
    vab_2025 = sum(vab_2025, na.rm = FALSE),
    .by = sector
  )

empleo_sector <- empleo |>
  inner_join(
    seccion_a_sector,
    by = join_by(seccion),
    relationship = "many-to-one"
  ) |>
  summarise(
    ocupados_2017 = sum(ocupados_miles_2017, na.rm = FALSE),
    ocupados_2025 = sum(ocupados_miles_2025, na.rm = FALSE),
    .by = sector
  )

# 3. Calculate estimates ----

cambio_sbu <- 100 * (sbu$sbu[sbu$anio == 2025] / sbu$sbu[sbu$anio == 2017] - 1)

# El valor agregado está en millones de dólares y los ocupados en miles, así
# que el cociente por 1000 da dólares por trabajador.
vab_por_trabajador <- vab_sector |>
  inner_join(
    empleo_sector,
    by = join_by(sector),
    relationship = "one-to-one"
  ) |>
  mutate(
    por_trabajador_2017 = vab_2017 * 1000 / ocupados_2017,
    por_trabajador_2025 = vab_2025 * 1000 / ocupados_2025,
    cambio = 100 * (por_trabajador_2025 / por_trabajador_2017 - 1),
    sobre_sbu = cambio > cambio_sbu
  ) |>
  arrange(desc(cambio))

# 4. Write outputs ----

write_csv(vab_por_trabajador, "outputs/tables/vab_por_trabajador_sector.csv")

# Los sectores van de mayor a menor cambio, de arriba hacia abajo. En azul,
# los sectores donde el valor agregado por trabajador creció menos que el
# salario básico.
grafico_2 <- vab_por_trabajador |>
  mutate(
    sector = factor(sector, levels = rev(sector)),
    etiqueta = sprintf("%+d%%", round(cambio))
  )

p_grafico_2 <- ggplot(
  grafico_2,
  aes(x = cambio, y = sector, fill = sobre_sbu)
) +
  geom_col(width = 0.65) +
  geom_vline(
    xintercept = cambio_sbu,
    colour = "grey20",
    linetype = "22",
    linewidth = 0.5
  ) +
  geom_text(
    aes(x = 70, label = etiqueta, colour = sobre_sbu),
    hjust = 1,
    size = 4,
    fontface = "bold"
  ) +
  annotate(
    "text",
    x = cambio_sbu + 1,
    y = nrow(grafico_2) + 0.9,
    label = paste0("Salario básico: +", round(cambio_sbu), "%"),
    hjust = 0,
    size = 4
  ) +
  scale_fill_manual(values = c("TRUE" = gris, "FALSE" = azul)) +
  scale_colour_manual(values = c("TRUE" = "grey20", "FALSE" = azul)) +
  scale_x_continuous(
    breaks = c(-20, 0, 20, 40, 60),
    labels = \(x) paste0(x, "%"),
    limits = c(-25, 70)
  ) +
  scale_y_discrete(
    labels = \(x) str_wrap(x, 22),
    expand = expansion(add = c(0.6, 1.5))
  ) +
  labs(x = "Variación entre 2017 y 2025", y = NULL) +
  theme_quantificador() +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank())

# Mismo formato que los gráficos del artículo de la ENIGHUR: 8 x 6,4 pulgadas,
# PNG a 300 ppp y SVG. El título y la fuente van en el texto del artículo.
ggsave(
  "outputs/figures/grafico_2_vab_por_trabajador_sector.png",
  plot = p_grafico_2,
  width = 8,
  height = 6.4,
  units = "in",
  dpi = 300,
  device = ragg::agg_png,
  bg = "white"
)

ggsave(
  "outputs/figures/grafico_2_vab_por_trabajador_sector.svg",
  plot = p_grafico_2,
  width = 8,
  height = 6.4,
  units = "in",
  device = grDevices::svg,
  bg = "white"
)

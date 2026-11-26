# ============================================================
# 04_precio_capital.R
# Author: Daniel Sanchez
# Purpose: Salario básico unificado (SBU) frente al precio de tres tipos de
#          capital: maquinaria industrial, computadoras y software, 2007 a
#          2026, en índice con 2007 = 100. Dibuja el Gráfico 3 del artículo.
# Inputs:  data/raw/fred/WPU11.csv
#          data/raw/fred/PCU334111334111.csv
#          data/raw/fred/PCU511210511210.csv
#          data/raw/sbu/sbu_ecuador_2007_2027.csv
# Outputs: outputs/tables/precio_capital_vs_sbu.csv
#          outputs/figures/grafico_3_sbu_precio_capital.png
#          outputs/figures/grafico_3_sbu_precio_capital.svg
# ============================================================

# 0. Setup ----

library(dplyr)
library(lubridate)
library(purrr)
library(readr)
library(stringr)

source("scripts/00_common.R") # tema y colores; carga ggplot2

# 1. Read inputs ----

# Índices de precios productor de Estados Unidos (BLS vía FRED), mensuales.
# Ecuador está dolarizado e importa buena parte de su equipo, así que estos
# precios en dólares sirven como referencia.
#   WPU11: maquinaria y equipo
#   PCU334111334111: fabricación de computadoras
#   PCU511210511210: editores de software
precios <- c(
  "Maquinaria industrial" = "data/raw/fred/WPU11.csv",
  "Computadoras" = "data/raw/fred/PCU334111334111.csv",
  "Software" = "data/raw/fred/PCU511210511210.csv"
) |>
  map(read_csv, show_col_types = FALSE) |>
  list_rbind(names_to = "serie")

sbu <- read_csv(
  "data/raw/sbu/sbu_ecuador_2007_2027.csv",
  show_col_types = FALSE
)

# 2. Prepare data ----

# 2026 es el promedio de enero a octubre, los meses publicados.
precios_anuales <- precios |>
  mutate(anio = year(fecha)) |>
  summarise(valor = mean(valor, na.rm = FALSE), .by = c(serie, anio))

sbu_anual <- sbu |>
  filter(anio <= 2026) |>
  transmute(serie = "Salario básico", anio, valor = sbu)

# 3. Calculate estimates ----

# Dividimos cada año para su valor de 2007: un índice de 150 significa que el
# valor es 50% mayor que en 2007 y uno de 50, que es la mitad.
precio_capital <- bind_rows(sbu_anual, precios_anuales) |>
  mutate(indice = round(100 * valor / valor[anio == 2007], 1), .by = serie)

# 4. Write outputs ----

write_csv(precio_capital, "outputs/tables/precio_capital_vs_sbu.csv")

# Cada serie se nombra al final de su línea, con su valor de 2026 y un
# decimal, como en la tabla.
etiquetas <- precio_capital |>
  filter(anio == 2026) |>
  mutate(
    etiqueta = str_wrap(
      paste0(serie, ": ", format(indice, nsmall = 1, decimal.mark = ",")),
      18
    )
  )

colores_serie <- c(
  "Salario básico" = azul,
  "Maquinaria industrial" = gris,
  "Software" = gris,
  "Computadoras" = gris
)

p_grafico_3 <- ggplot(
  precio_capital,
  aes(x = anio, y = indice, colour = serie, linewidth = serie)
) +
  annotate(
    "segment",
    x = 2007,
    xend = 2026,
    y = 100,
    yend = 100,
    colour = "grey70",
    linetype = "22",
    linewidth = 0.4
  ) +
  geom_line() +
  geom_text(
    data = etiquetas,
    aes(label = etiqueta),
    hjust = 0,
    nudge_x = 0.5,
    size = 4,
    lineheight = 0.95
  ) +
  scale_colour_manual(values = colores_serie) +
  scale_linewidth_manual(
    values = c(
      "Salario básico" = 1.3,
      "Maquinaria industrial" = 0.8,
      "Software" = 0.8,
      "Computadoras" = 0.8
    )
  ) +
  scale_x_continuous(
    breaks = c(2007, 2012, 2017, 2022, 2026),
    limits = c(2007, 2032)
  ) +
  scale_y_continuous(breaks = c(0, 100, 200, 300), limits = c(0, 300)) +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = "Índice (2007 = 100)") +
  theme_quantificador()

# Mismo formato que los gráficos del artículo de la ENIGHUR: 8 x 6,4 pulgadas,
# PNG a 300 ppp y SVG. El título y la fuente van en el texto del artículo.
ggsave(
  "outputs/figures/grafico_3_sbu_precio_capital.png",
  plot = p_grafico_3,
  width = 8,
  height = 6.4,
  units = "in",
  dpi = 300,
  device = ragg::agg_png,
  bg = "white"
)

ggsave(
  "outputs/figures/grafico_3_sbu_precio_capital.svg",
  plot = p_grafico_3,
  width = 8,
  height = 6.4,
  units = "in",
  device = grDevices::svg,
  bg = "white"
)

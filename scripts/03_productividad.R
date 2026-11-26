# ============================================================
# 03_productividad.R
# Author: Daniel Sanchez
# Purpose: Valor agregado fuera del petróleo y valor agregado por trabajador,
#          2007 a 2025. Dibuja el Gráfico 1 del artículo: valor agregado,
#          valor agregado por trabajador y salario básico unificado (SBU),
#          2017 a 2025, en índice con 2017 = 100. También calcula el
#          peso del petróleo y la minería (nota 4 del artículo).
# Inputs:  data/raw/bce/iem_432_vab_industria_2007_2025.csv
#          data/raw/ilo/ilostat_empleo_rama_ecuador.csv
#          data/raw/sbu/sbu_ecuador_2007_2027.csv
# Outputs: outputs/tables/productividad_no_petrolera_2007_2025.csv
#          outputs/tables/indice_vab_sbu_2017_2025.csv
#          outputs/figures/grafico_1_vab_sbu.png
#          outputs/figures/grafico_1_vab_sbu.svg
# ============================================================

# 0. Setup ----

library(dplyr)
library(readr)
library(stringr)
library(tidyr)

source("scripts/00_common.R") # tema y colores; carga ggplot2

# 1. Read inputs ----

# Valor agregado bruto por industria, en millones de dólares corrientes.
# Banco Central del Ecuador, IEM 4.3.2.
vab <- read_csv(
  "data/raw/bce/iem_432_vab_industria_2007_2025.csv",
  show_col_types = FALSE
)

# Ocupados por rama, en miles. OIT, ILOSTAT (EMP_TEMP_NB), con datos de la
# ENEMDU. B es minas y canteras y T es el total. Hasta 2012 la OIT usa la
# CIIU Rev. 3 y desde 2013 la Rev. 4.
ocupados <- read_csv(
  "data/raw/ilo/ilostat_empleo_rama_ecuador.csv",
  show_col_types = FALSE
) |>
  pivot_wider(
    names_from = rama,
    values_from = ocupados_miles,
    names_prefix = "ocupados_"
  )

sbu <- read_csv(
  "data/raw/sbu/sbu_ecuador_2007_2027.csv",
  show_col_types = FALSE
)

# 2. Prepare data ----

# El petróleo produce mucho con muy pocos trabajadores y movería el promedio
# con su precio. Quitamos minas y canteras y los refinados de petróleo del
# valor agregado, y a los ocupados en minas del empleo.
no_petrolero <- vab |>
  left_join(
    ocupados,
    by = join_by(anio),
    relationship = "one-to-one",
    unmatched = "error"
  ) |>
  transmute(
    anio,
    vab_no_petrolero = vab_corriente - minas_corriente - refin_corriente,
    ocupados_no_petroleros = (ocupados_T - ocupados_B) * 1000,
    petroleo_y_minas_en_vab = 100 * (minas_corriente + refin_corriente) /
      vab_corriente,
    minas_en_empleo = 100 * ocupados_B / ocupados_T
  )

# 3. Calculate estimates ----

# Lo que produce en promedio cada ocupado en un año, en dólares.
no_petrolero <- no_petrolero |>
  mutate(
    vab_por_trabajador = vab_no_petrolero * 1e6 / ocupados_no_petroleros
  )

# Dividimos cada año para su valor de 2017: un índice de 114 significa que el
# valor es 14% mayor que en 2017. La serie del SBU empieza en 2007 y llega a
# 2027: se usan solo los años de 2017 a 2025.
indices <- no_petrolero |>
  filter(anio >= 2017) |>
  mutate(
    indice_vab = 100 * vab_no_petrolero / vab_no_petrolero[anio == 2017],
    indice_vab_trabajador = 100 * vab_por_trabajador /
      vab_por_trabajador[anio == 2017]
  ) |>
  select(anio, indice_vab, indice_vab_trabajador) |>
  left_join(
    transmute(
      filter(sbu, anio %in% 2017:2025),
      anio,
      indice_sbu = 100 * sbu / sbu[anio == 2017]
    ),
    by = join_by(anio),
    relationship = "one-to-one",
    unmatched = "error"
  ) |>
  mutate(across(-anio, \(x) round(x, 1)))

# 4. Write outputs ----

write_csv(
  no_petrolero,
  "outputs/tables/productividad_no_petrolera_2007_2025.csv"
)
write_csv(indices, "outputs/tables/indice_vab_sbu_2017_2025.csv")

nombres_serie <- c(
  indice_sbu = "Salario básico",
  indice_vab = "Valor agregado",
  indice_vab_trabajador = "Valor agregado por trabajador"
)

grafico_1 <- indices |>
  pivot_longer(-anio, names_to = "serie", values_to = "indice") |>
  mutate(serie = unname(nombres_serie[serie]))

# Cada serie se nombra al final de su línea, con su valor de 2025.
etiquetas <- grafico_1 |>
  filter(anio == 2025) |>
  mutate(
    etiqueta = str_wrap(paste0(serie, ": ", round(indice)), 20)
  )

colores_serie <- c(
  "Valor agregado por trabajador" = azul,
  "Salario básico" = "grey20",
  "Valor agregado" = gris
)

p_grafico_1 <- ggplot(
  grafico_1,
  aes(x = anio, y = indice, colour = serie, linetype = serie, linewidth = serie)
) +
  annotate(
    "segment",
    x = 2017,
    xend = 2025,
    y = 100,
    yend = 100,
    colour = "grey70",
    linewidth = 0.4
  ) +
  geom_line() +
  geom_point(size = 2) +
  geom_text(
    data = etiquetas,
    aes(x = anio + 0.3, y = indice, label = etiqueta),
    hjust = 0,
    size = 4,
    lineheight = 0.95
  ) +
  scale_colour_manual(values = colores_serie) +
  scale_linetype_manual(
    values = c(
      "Valor agregado por trabajador" = "solid",
      "Salario básico" = "solid",
      "Valor agregado" = "solid"
    )
  ) +
  scale_linewidth_manual(
    values = c(
      "Valor agregado por trabajador" = 1.3,
      "Salario básico" = 0.8,
      "Valor agregado" = 0.8
    )
  ) +
  scale_x_continuous(breaks = 2017:2025, limits = c(2017, 2028.6)) +
  scale_y_continuous(breaks = seq(90, 130, 10), limits = c(90, 130)) +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = "Índice (2017 = 100)") +
  theme_quantificador()

# Mismo formato que los gráficos del artículo de la ENIGHUR: 8 x 6,4 pulgadas,
# PNG a 300 ppp y SVG. El título y la fuente van en el texto del artículo.
ggsave(
  "outputs/figures/grafico_1_vab_sbu.png",
  plot = p_grafico_1,
  width = 8,
  height = 6.4,
  units = "in",
  dpi = 300,
  device = ragg::agg_png,
  bg = "white"
)

ggsave(
  "outputs/figures/grafico_1_vab_sbu.svg",
  plot = p_grafico_1,
  width = 8,
  height = 6.4,
  units = "in",
  device = grDevices::svg,
  bg = "white"
)

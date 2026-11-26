# ============================================================
# 13_basico_por_rama.R
# Author: Daniel Sanchez
# Purpose: En qué ramas se gana el salario básico, enero a mayo de 2026:
#          porcentaje que gana menos de $482 y cuántas personas que ganan
#          menos no tienen empleo formal, por rama; y, por sector, qué parte
#          de los trabajadores formales gana hasta el básico. Dibuja los
#          Gráficos 3 y 5 del artículo. También calcula cuánto cambió el
#          número de afiliados del sector privado en la construcción, 2017 a 2025.
# Inputs:  data/raw/enemdu/enemdu_persona_2026_l_trimestre.sav (enero a marzo)
#          data/raw/enemdu/enemdu_persona_2026_04.sav
#          data/raw/enemdu/enemdu_persona_2026_05.sav
#          data/raw/reess/reess_privado_seccion_mensual.csv
#          data/raw/sbu/sbu_ecuador_2007_2027.csv
#          outputs/tables/vab_por_trabajador_sector.csv (de 11_...R)
# Outputs: outputs/tables/basico_por_rama_2026.csv
#          outputs/tables/gana_menos_del_basico_por_sector_2026.csv
#          outputs/tables/basico_por_sector_grupos_bce_2026.csv
#          outputs/tables/afiliados_construccion_2017_2025.csv
#          outputs/figures/grafico_3_gana_menos_del_basico_por_sector.png
#          outputs/figures/grafico_3_gana_menos_del_basico_por_sector.svg
#          outputs/figures/grafico_5_presion_y_exposicion_por_sector.png
#          outputs/figures/grafico_5_presion_y_exposicion_por_sector.svg
# ============================================================

# 0. Setup ----

library(dplyr)
library(haven)
library(purrr)
library(readr)
library(stringr)
library(tidyr)

source("scripts/00_common.R") # tema y colores; carga ggplot2

sbu_2026 <- 482

# "Alrededor del básico" es entre 95% y 105% del SBU de $482: de $458 a $506.
limite_bajo <- 458
limite_alto <- 506

columnas <- c("secemp", "ingrl", "fexp", "rama1")

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

# Empleo registrado del sector privado por sección CIIU y mes, del tabulado
# 1_2_1 del REESS (INEC, mayo de 2026). Los meses tienen formato "ene.-17".
reess <- read_csv(
  "data/raw/reess/reess_privado_seccion_mensual.csv",
  show_col_types = FALSE
)

sbu <- read_csv(
  "data/raw/sbu/sbu_ecuador_2007_2027.csv",
  show_col_types = FALSE
)

vab_por_trabajador <- read_csv(
  "outputs/tables/vab_por_trabajador_sector.csv",
  show_col_types = FALSE
)

# 2. Prepare data ----

# Cada mes pesa lo mismo: el factor de cada persona se divide para la suma del
# factor de su mes. Los factores faltantes se excluyen de la suma.
enemdu <- bind_rows(primer_trimestre, abril, mayo) |>
  mutate(across(c(secemp, ingrl, fexp, rama1), as.numeric)) |>
  mutate(peso = fexp / sum(fexp, na.rm = TRUE), .by = mes)

# Todas las personas que trabajan (secemp 1 a 4) con ingreso laboral conocido,
# incluidas las que no reciben pago. 999999 es "no informa". Empleo formal es
# secemp 1. rama1 va de 1 (sección A de la CIIU) a 21 (U); 22 es "no
# especificado".
ocupados <- enemdu |>
  filter(
    secemp %in% 1:4,
    !is.na(ingrl),
    ingrl < 999999,
    fexp > 0,
    rama1 %in% 1:21
  ) |>
  mutate(seccion = LETTERS[rama1])

# El Banco Central junta M con N y R con S, así que aquí también se juntan.
# Las demás secciones se descartan a propósito, como en el Gráfico 2.
grupos <- tribble(
  ~seccion, ~sector,
  "A", "Agricultura y pesca",
  "C", "Manufactura",
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

# 3. Calculate estimates ----

# Por rama: porcentaje que gana menos de $482 y, entre quienes ganan menos,
# porcentaje sin empleo formal.
basico_por_rama <- ocupados |>
  summarise(
    gana_menos_de_482 = 100 * sum(peso[ingrl < sbu_2026], na.rm = TRUE) /
      sum(peso, na.rm = TRUE),
    sin_empleo_formal_entre_quienes_ganan_menos = 100 *
      sum(peso[ingrl < sbu_2026 & secemp != 1], na.rm = TRUE) /
      sum(peso[ingrl < sbu_2026], na.rm = TRUE),
    .by = seccion
  ) |>
  arrange(seccion)

# Por sector: parte de quienes ganan alrededor del básico que trabaja en el
# sector (tamaño de los círculos) y porcentaje de los formales del sector que
# gana hasta el límite alto, $506 (altura de los círculos).
alrededor <- ocupados |>
  filter(ingrl >= limite_bajo, ingrl <= limite_alto)

peso_alrededor <- sum(alrededor$peso, na.rm = TRUE)

basico_por_sector <- ocupados |>
  inner_join(grupos, by = join_by(seccion), relationship = "many-to-one") |>
  summarise(
    parte_de_quienes_ganan_alrededor = 100 *
      sum(peso[ingrl >= limite_bajo & ingrl <= limite_alto], na.rm = TRUE) /
      peso_alrededor,
    formales_hasta_el_basico = 100 *
      sum(peso[secemp == 1 & ingrl <= limite_alto], na.rm = TRUE) /
      sum(peso[secemp == 1], na.rm = TRUE),
    .by = sector
  )

# Por sector (los 13 del Gráfico 2): porcentaje de quienes trabajan que gana
# menos de $482, separado entre quienes tienen y no tienen empleo formal.
grupos_13 <- bind_rows(
  grupos,
  tibble(seccion = c("D", "E"), sector = "Electricidad y agua")
)

gana_menos_por_sector <- ocupados |>
  inner_join(grupos_13, by = join_by(seccion), relationship = "many-to-one") |>
  summarise(
    con_empleo_formal = 100 *
      sum(peso[ingrl < sbu_2026 & secemp == 1], na.rm = TRUE) /
      sum(peso, na.rm = TRUE),
    sin_empleo_formal = 100 *
      sum(peso[ingrl < sbu_2026 & secemp != 1], na.rm = TRUE) /
      sum(peso, na.rm = TRUE),
    .by = sector
  ) |>
  mutate(gana_menos_de_482 = con_empleo_formal + sin_empleo_formal) |>
  arrange(desc(gana_menos_de_482))

# Promedio de todas las ramas.
formales <- filter(ocupados, secemp == 1)

formales_hasta_el_basico_total <- 100 *
  sum(formales$peso[formales$ingrl <= limite_alto], na.rm = TRUE) /
  sum(formales$peso, na.rm = TRUE)

cambio_sbu <- 100 * (sbu$sbu[sbu$anio == 2025] / sbu$sbu[sbu$anio == 2017] - 1)

# Un sector sufre más presión si lo que crea cada trabajador creció menos que
# el básico y una parte mayor que el promedio de sus formales gana el básico.
# El sector de electricidad y agua no está en el Gráfico 4 y se descarta.
grafico_4 <- basico_por_sector |>
  inner_join(
    select(vab_por_trabajador, sector, cambio_vab_trabajador = cambio),
    by = join_by(sector),
    relationship = "one-to-one"
  ) |>
  mutate(
    mas_presion = cambio_vab_trabajador < cambio_sbu &
      formales_hasta_el_basico > formales_hasta_el_basico_total
  )

# Afiliados del sector privado en la construcción (sección F): promedio de los
# doce meses de 2017 y de 2025.
afiliados_construccion <- reess |>
  filter(seccion == "F") |>
  mutate(anio = 2000 + as.integer(str_sub(mes, -2))) |>
  filter(anio %in% c(2017, 2025)) |>
  summarise(afiliados = mean(afiliados, na.rm = FALSE), .by = anio) |>
  arrange(anio) |>
  mutate(cambio = 100 * (afiliados / afiliados[anio == 2017] - 1))

# 4. Write outputs ----

write_csv(basico_por_rama, "outputs/tables/basico_por_rama_2026.csv")
write_csv(
  gana_menos_por_sector,
  "outputs/tables/gana_menos_del_basico_por_sector_2026.csv"
)
write_csv(grafico_4, "outputs/tables/basico_por_sector_grupos_bce_2026.csv")
write_csv(
  afiliados_construccion,
  "outputs/tables/afiliados_construccion_2017_2025.csv"
)

# Dónde va el nombre de cada sector, en las unidades de los ejes; cómo se
# alinea con respecto a ese punto (0 a la izquierda, 0,5 centrado, 1 a la
# derecha); y cuántos caracteres caben por línea. Se fijan a mano para que
# ningún nombre tape un círculo.
posicion_nombre <- tribble(
  ~sector,                           ~x_nombre, ~y_nombre, ~alineacion, ~ancho,
  "Comercio",                        41.4,      58.3,      0.5,         18,
  "Manufactura",                     31.0,      33.3,      0,           18,
  "Construcción",                    -23.5,     30.0,      0,           18,
  "Agricultura y pesca",             27.5,      43.5,      0,           18,
  "Alojamiento y comidas",           16.9,      53.8,      0,           12,
  "Profesionales y administrativos", -6.1,      47.2,      0.5,         18,
  "Transporte",                      -1.1,      33.5,      0.5,         18,
  "Arte y otros servicios",          5.9,       60.3,      0.5,         18,
  "Información y comunicación",      12.5,      28.5,      0.5,         18,
  "Salud",                           34.0,      21.2,      0,           18,
  "Enseñanza",                       19.5,      12.5,      1,           18,
  "Actividades financieras",         59.5,      14.5,      1,           18
)

p_grafico_4 <- ggplot(
  grafico_4,
  aes(x = cambio_vab_trabajador, y = formales_hasta_el_basico)
) +
  annotate(
    "rect",
    xmin = -25,
    xmax = cambio_sbu,
    ymin = formales_hasta_el_basico_total,
    ymax = 65,
    fill = azul,
    alpha = 0.08
  ) +
  # La línea vertical se corta entre 50,8% y 56,8% para dejar espacio al
  # nombre de alojamiento y comidas.
  annotate(
    "segment",
    x = cambio_sbu,
    xend = cambio_sbu,
    y = c(0, 56.8),
    yend = c(50.8, 65),
    colour = "grey20",
    linetype = "22",
    linewidth = 0.3
  ) +
  geom_hline(
    yintercept = formales_hasta_el_basico_total,
    colour = "grey20",
    linetype = "22",
    linewidth = 0.3
  ) +
  geom_point(
    aes(size = parte_de_quienes_ganan_alrededor, colour = mas_presion),
    alpha = 0.85
  ) +
  geom_text(
    data = left_join(
      grafico_4,
      posicion_nombre,
      by = join_by(sector),
      relationship = "one-to-one"
    ),
    aes(
      x = x_nombre,
      y = y_nombre,
      label = map2_chr(sector, ancho, str_wrap),
      hjust = alineacion,
      colour = mas_presion
    ),
    size = 3.8,
    lineheight = 0.9
  ) +
  annotate(
    "text",
    x = cambio_sbu - 1,
    y = 1.5,
    label = paste0("El básico creció ", round(cambio_sbu), "%"),
    hjust = 1,
    size = 3.8
  ) +
  annotate(
    "text",
    x = 60,
    y = formales_hasta_el_basico_total + 2,
    label = paste0("Promedio: ", round(formales_hasta_el_basico_total), "%"),
    hjust = 1,
    size = 3.8
  ) +
  scale_size_area(max_size = 18) +
  scale_colour_manual(values = c("TRUE" = azul, "FALSE" = gris)) +
  scale_x_continuous(
    limits = c(-25, 60),
    breaks = c(-20, 0, 20, 40, 60),
    labels = \(x) paste0(x, "%")
  ) +
  scale_y_continuous(
    limits = c(0, 65),
    breaks = c(0, 20, 40, 60),
    labels = \(x) paste0(x, "%")
  ) +
  labs(
    x = "Variación del valor agregado por trabajador, 2017-2025 →",
    y = "↑ Formales que ganan hasta el básico, 2026"
  ) +
  theme_quantificador()

# Mismo formato que los gráficos del artículo de la ENIGHUR: 8 x 6,4 pulgadas,
# PNG a 300 ppp y SVG. El título y la fuente van en el texto del artículo.
ggsave(
  "outputs/figures/grafico_5_presion_y_exposicion_por_sector.png",
  plot = p_grafico_4,
  width = 8,
  height = 6.4,
  units = "in",
  dpi = 300,
  device = ragg::agg_png,
  bg = "white"
)

ggsave(
  "outputs/figures/grafico_5_presion_y_exposicion_por_sector.svg",
  plot = p_grafico_4,
  width = 8,
  height = 6.4,
  units = "in",
  device = grDevices::svg,
  bg = "white"
)

# Gráfico 3: de arriba hacia abajo, de más a menos personas que ganan menos de
# $482. En azul, la parte sin empleo formal.
grafico_3 <- gana_menos_por_sector |>
  mutate(sector = factor(sector, levels = rev(sector))) |>
  pivot_longer(
    c(sin_empleo_formal, con_empleo_formal),
    names_to = "empleo",
    values_to = "porcentaje"
  ) |>
  mutate(
    empleo = factor(
      empleo,
      levels = c("con_empleo_formal", "sin_empleo_formal"),
      labels = c("Con empleo formal", "Sin empleo formal")
    )
  )

totales_3 <- gana_menos_por_sector |>
  mutate(sector = factor(sector, levels = rev(sector)))

p_grafico_3 <- ggplot(
  grafico_3,
  aes(x = porcentaje, y = sector, fill = empleo)
) +
  geom_col(width = 0.65) +
  geom_text(
    data = totales_3,
    aes(
      x = gana_menos_de_482 + 1.5,
      y = sector,
      label = paste0(round(gana_menos_de_482), "%")
    ),
    inherit.aes = FALSE,
    hjust = 0,
    size = 4,
    fontface = "bold"
  ) +
  scale_fill_manual(
    values = c("Con empleo formal" = gris, "Sin empleo formal" = azul)
  ) +
  scale_x_continuous(
    breaks = c(0, 25, 50, 75),
    labels = \(x) paste0(x, "%"),
    limits = c(0, 95)
  ) +
  scale_y_discrete(labels = \(x) str_wrap(x, 22)) +
  labs(x = "Personas que trabajan y ganan menos de $482", y = NULL) +
  theme_quantificador() +
  theme(
    axis.line.y = element_blank(),
    axis.ticks.y = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank(),
    legend.text = element_text(size = 12, colour = "grey20")
  )

ggsave(
  "outputs/figures/grafico_3_gana_menos_del_basico_por_sector.png",
  plot = p_grafico_3,
  width = 8,
  height = 6.4,
  units = "in",
  dpi = 300,
  device = ragg::agg_png,
  bg = "white"
)

ggsave(
  "outputs/figures/grafico_3_gana_menos_del_basico_por_sector.svg",
  plot = p_grafico_3,
  width = 8,
  height = 6.4,
  units = "in",
  device = grDevices::svg,
  bg = "white"
)

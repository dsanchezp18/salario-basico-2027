# ============================================================
# 00_common.R
# Author: Daniel Sanchez
# Purpose: Tema y colores de los gráficos del artículo. Siguen el formato de
#          los gráficos del artículo de la ENIGHUR de El Quantificador: la
#          imagen no lleva título, subtítulo, fuente ni logo, porque el
#          artículo los pone en el texto. El tema es una copia de
#          theme_quantificador() de scripts/utils.R del repositorio
#          enighur-quantificador, para que este repositorio corra solo. Lo
#          cargan con source() los scripts que dibujan un gráfico.
# Inputs:  Ninguno.
# Outputs: Ninguno. Define el tema y los colores.
# ============================================================

# 0. Setup ----

library(ggplot2)

azul <- "#2D7DB3"
gris <- "grey45"

# 1. Tema ----

theme_quantificador <- function() {
  theme_classic(base_size = 12) +
    theme(
      axis.text = element_text(colour = "grey20", size = 12),
      axis.title.x = element_text(
        size = 12,
        margin = margin(t = 8),
        hjust = 0.5
      ),
      axis.title.y = element_text(
        size = 12,
        margin = margin(r = 8),
        hjust = 0.5
      ),
      axis.line = element_line(colour = "grey60"),
      legend.position = "none",
      panel.grid = element_blank(),
      plot.margin = margin(8, 16, 8, 12)
    )
}

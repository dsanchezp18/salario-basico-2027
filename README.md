# Con el salario básico de $500, ¿nos reemplazarán las máquinas?

Este repositorio tiene los datos y el código de R del artículo de El Quantificador «Con el salario básico de $500, ¿nos reemplazarán las máquinas?», de Daniel Sánchez. El código calcula las cifras de la Tabla 1, dibuja los cuatro gráficos y produce los números que el texto cita.

## La pregunta

El salario básico unificado (SBU) sube de $482 a $500 en 2027. Si contratar con salario básico se encarece, ¿le conviene a una empresa comprar una máquina en lugar de contratar?

Para responder, el código hace cuatro comparaciones:

1. Cuánto cuesta en total un trabajador con salario básico para el empleador (script 01).
2. Cuánto creció el SBU frente a lo que venden las empresas y frente a lo que produce cada trabajador (scripts 02, 03 y 11).
3. Cuánto cambió el precio de la maquinaria, las computadoras y el software frente al SBU (scripts 04 y 05).
4. Quiénes ganan alrededor del básico y en qué sectores trabajan (scripts 06, 12 y 13).

## Cómo correr los scripts

Necesitas R 4.1 o más reciente y estos paquetes: `dplyr` (1.1 o más reciente), `readr`, `tidyr`, `purrr` (1.0 o más reciente), `lubridate`, `haven`, `Hmisc`, `ggplot2`, `stringr` y `ragg`.

Los scripts 06, 12 y 13 leen microdatos de la ENEMDU, que no están en el repositorio por su tamaño. Descarga las bases de enero a mayo de 2026 en formato SPSS desde https://www.ecuadorencifras.gob.ec/empleo-desempleo-y-subempleo/ y guárdalas con estos nombres:

- `data/raw/enemdu/enemdu_persona_2026_l_trimestre.sav` (enero a marzo)
- `data/raw/enemdu/enemdu_persona_2026_04.sav`
- `data/raw/enemdu/enemdu_persona_2026_05.sav`

Corre los scripts desde la raíz del proyecto, en este orden:

```
Rscript scripts/01_costo_laboral.R
Rscript scripts/02_ventas_sri.R
Rscript scripts/03_productividad.R
Rscript scripts/04_precio_capital.R
Rscript scripts/05_maquinaria_nacional.R
Rscript scripts/06_ingreso_informales.R
Rscript scripts/11_vab_por_trabajador_sector.R
Rscript scripts/12_quien_gana_basico.R
Rscript scripts/13_basico_por_rama.R
```

El orden importa en dos casos. El script 03 lee una tabla que escribe el 02, y el 13 lee una tabla que escribe el 11. La numeración salta del 06 al 11 y no falta ningún script.

Carpetas:

```
scripts/           un script por cálculo; 00_common.R tiene el estilo de los gráficos
data/raw/<fuente>/ datos de origen, sin modificar
outputs/tables/    tablas en CSV, con punto decimal
outputs/figures/   los cuatro gráficos, en PNG y SVG
```

## Datos

| Archivo | Fuente | Qué contiene |
| --- | --- | --- |
| `sbu/sbu_ecuador_2007_2027.csv` | Acuerdos ministeriales del Ministerio del Trabajo; 2027 según el Decreto Ejecutivo 538 | SBU mensual de cada año, en dólares |
| `sri/ventas_enero_julio_2017_2025.csv` | Ministerio de Economía y Finanzas con datos del SRI, publicado por [El Universo](https://www.eluniverso.com/noticias/economia/ecuador-ventas-totales-crecimiento-anual-ministerio-economia-nota/) | Ventas totales declaradas de enero a julio, en millones de dólares |
| `bce/iem_432_vab_industria_2007_2025.csv` | Banco Central del Ecuador, Información Estadística Mensual 2096, cuadro 4.3.2 ([IEM-432-e.xlsx](https://contenido.bce.fin.ec/documentos/PublicacionesNotas/Catalogo/IEMensual/m2096/IEM-432-e.xlsx)) | Valor agregado bruto (VAB) por industria, 2007 a 2025, en millones de dólares corrientes y de 2018 |
| `bce/iem_432_vab_corriente_2017_2025_todas.csv` | La misma tabla del Banco Central | VAB corriente de cada industria en 2017 y 2025 |
| `ilo/ilostat_empleo_rama_ecuador.csv` | OIT, ILOSTAT, `EMP_TEMP_NB`, con datos de la ENEMDU | Ocupados por rama, en miles. Hasta 2012 usa la CIIU Rev. 3 y desde 2013 la Rev. 4 |
| `ilo/ilostat_empleo_seccion_2017_2025.csv` | OIT, ILOSTAT, `EMP_TEMP_NB`, con datos de la ENEMDU | Ocupados por sección CIIU en 2017 y 2025, en miles |
| `fred/WPU11.csv`, `fred/PCU334111334111.csv`, `fred/PCU511210511210.csv` | Bureau of Labor Statistics de Estados Unidos, vía FRED | Índices de precios productor mensuales de maquinaria y equipo, computadoras y software |
| `inpp/inpp_seccion4_maquinaria_oct2026.csv` | INEC, boletín técnico del Índice Nacional de Precios Productor de octubre de 2026 | Índice y variación anual de la sección 4 de la CPC (productos metálicos, maquinaria y equipo) |
| `reess/reess_privado_seccion_mensual.csv` | INEC, Registro Estadístico de Empleo en la Seguridad Social, tabulado 1_2_1 de mayo de 2026 | Afiliados del sector privado por sección CIIU y mes |
| `enemdu/*.sav` | INEC, ENEMDU de enero a mayo de 2026 | Microdatos de personas (no están en el repositorio) |

## Qué hace cada script

### 01_costo_laboral.R: Tabla 1

El costo mensual de un trabajador con SBU para el empleador es:

```
costo = SBU × (1 + 3/12 + 0,1115)
```

Aquí, `SBU` es el salario básico del mes. El `3/12` suma tres rubros que valen un doceavo del salario cada uno: décimo tercero, décimo cuarto y fondos de reserva. El `0,1115` es el aporte patronal general al IESS.

Con el SBU de 2027: 500 × 1,3615 = $680,75. Con el de 2026: 482 × 1,3615 = $656,24. El aumento del costo es $24,51 al mes, frente a los $18 del salario.

El décimo cuarto es un SBU entero al año para todos, así que su doceavo coincide con el del salario solo cuando se gana el SBU. No se suma el 1% adicional del IECE y el SECAP. Las vacaciones tampoco, porque ya se pagan dentro del salario. No se incluyen la participación de utilidades ni el costo de un despido.

Escribe `costo_laboral_sbu.csv`, con una fila por rubro: `por_dolar` (cuánto cuesta cada dólar de salario), `monto_2026`, `monto_2027` y `cambio_mensual`. La última fila es el costo total.

### 02_ventas_sri.R: ventas frente al SBU

Para comparar series con unidades distintas, cada una se divide para su valor de 2017:

```
índice del año t = 100 × valor en t / valor en 2017
```

Un índice de 148 significa que el valor es 48% mayor que en 2017. Con las ventas de enero a julio: 100 × 144.711 / 97.617 = 148,2. Con el SBU: 100 × 470 / 375 = 125,3.

Lee las ventas y el SBU. Escribe `ventas_sri_vs_sbu.csv` con los valores y los dos índices.

### 03_productividad.R: Gráfico 1

Mide cuánto produce en promedio cada persona que trabaja, sin el petróleo:

```
VAB por trabajador = (VAB − VAB minas − VAB refinación) × 1.000.000 / ((T − B) × 1.000)
```

Aquí, `VAB` es el valor agregado bruto total en millones de dólares corrientes; `VAB minas` y `VAB refinación` son el de explotación de minas y canteras y el de refinación de petróleo; `T` es el total de ocupados y `B` los ocupados en minas, ambos en miles.

Con 2025: el VAB sin petróleo es 110.640,5 millones y hay 8.288.630 ocupados sin minas, así que cada trabajador produce 110.640,5 × 1.000.000 / 8.288.630 = $13.348. En 2017 fueron $11.721. El cociente es 1,139, así que el índice de 2025 es 113,9.

Se quita el petróleo porque produce mucho con muy pocos trabajadores y movería el promedio con el precio del crudo. Las minas empleaban cerca de 0,5% de los ocupados, pero la minería y la refinación generaron 23% del VAB en 2008 y 7% en 2016. Esos pesos están en las columnas `petroleo_y_minas_en_vab` y `minas_en_empleo`.

El promedio incluye a trabajadores formales e informales. No mide lo que produce quien gana el básico.

Lee el VAB, los ocupados y la tabla del script 02. Escribe:

- `productividad_no_petrolera_2007_2025.csv`: VAB sin petróleo, ocupados, VAB por trabajador y los dos pesos.
- `indice_ventas_vab_sbu_2017_2025.csv`: los cuatro índices del Gráfico 1, con 2017 = 100.
- `grafico_1_ventas_vab_sbu.png` y `grafico_1_ventas_vab_sbu.svg`.

### 04_precio_capital.R: Gráfico 3

Los índices de precio de Estados Unidos son mensuales. Primero se promedian por año y después se divide cada año para 2007:

```
índice del año t = 100 × promedio anual en t / promedio anual en 2007
```

Con las computadoras: el promedio de 2026 (enero a octubre) es 101,48 y el de 2007 es 218,36. El índice es 46,5, es decir, el precio de la misma capacidad bajó a menos de la mitad. Con el SBU: 482 / 170 da 283,5.

Se usan precios de Estados Unidos porque Ecuador está dolarizado y compra en el exterior buena parte de sus equipos. Los índices de computadoras y software ya se ajustan por calidad: miden cuánto cuesta la misma capacidad.

Escribe `precio_capital_vs_sbu.csv` (`serie`, `anio`, `valor`, `indice`), `grafico_3_sbu_precio_capital.png` y `grafico_3_sbu_precio_capital.svg`.

### 05_maquinaria_nacional.R: maquinaria producida en el país

El INPP mide el precio de la maquinaria producida en Ecuador. El script compara su variación entre octubre de 2025 y octubre de 2026 con la del costo laboral. El multiplicador de costo es fijo, así que el costo laboral crece igual que el SBU: 100 × (482 / 470 − 1) = 2,55%. La maquinaria subió 2,84%.

El INPP no mide software ni inteligencia artificial, y no existe un índice de precios para ellos en Ecuador.

Escribe `maquinaria_vs_costo_laboral.csv`.

### 06_ingreso_informales.R: ingreso del sector informal

Calcula la mediana ponderada del ingreso laboral mensual (`ingrl`) de las personas ocupadas en el sector formal (`secemp` = 1) y en el informal (`secemp` = 2), de enero a mayo de 2026. Solo cuentan quienes tienen ingreso positivo; el código 999999 significa «no informa» y se excluye.

La base trimestral y las mensuales tienen factores de expansión (`fexp`) en escalas distintas. Para que cada mes pese lo mismo, cada persona recibe un peso:

```
peso = fexp / suma de fexp del mes de esa persona
```

La mediana del sector informal es $220 y la del formal, $600. Los $220 equivalen a cerca de un tercio de los $656,24 que cuesta un trabajador formal con SBU en 2026.

Escribe `ingreso_formal_informal_2026.csv` (`sector`, `observaciones`, `mediana`).

### 11_vab_por_trabajador_sector.R: Gráfico 2

Calcula el VAB por trabajador de 13 sectores. El Banco Central agrupa las industrias de una forma y la OIT agrupa las ocupaciones por sección CIIU de otra, así que dos tablas dentro del script (`industria_a_sector` y `seccion_a_sector`) las llevan a los mismos 13 sectores. Después:

```
VAB por trabajador = VAB × 1.000 / ocupados
cambio = 100 × (VAB por trabajador en 2025 / VAB por trabajador en 2017 − 1)
```

Aquí, el VAB está en millones de dólares y los ocupados en miles, por eso se multiplica por 1.000. Un sector queda «sobre el SBU» si su cambio supera el del SBU entre 2017 y 2025, que es 25,3%.

Con comercio: $10.044 por trabajador en 2017 y $14.203 en 2025. El cambio es +41,4%, mayor que 25,3%. Con construcción: $12.777 y $10.321, un cambio de −19,2%.

Quedan fuera la minería, la administración pública, las actividades inmobiliarias (su VAB incluye el alquiler imputado de las viviendas propias) y los hogares como empleadores. La manufactura va sin refinación de petróleo.

Escribe `vab_por_trabajador_sector.csv`, `grafico_2_vab_por_trabajador_sector.png` y `grafico_2_vab_por_trabajador_sector.svg`.

### 12_quien_gana_basico.R: quién gana alrededor del básico

Reparte a todas las personas que trabajan (`secemp` de 1 a 4, incluidas las que no reciben pago) en tres grupos según su ingreso laboral:

| Grupo | Ingreso mensual |
| --- | --- |
| Menos que el básico | menos de $458 |
| Alrededor del básico | de $458 a $506 (entre 95% y 105% de $482) |
| Más que el básico | más de $506 |

Para cada grupo calcula qué porcentaje de todas las personas que trabajan representa, y qué parte de ese grupo tiene empleo formal (`secemp` = 1). Con los mismos pesos del script 06: 10,4% gana alrededor del básico, y 65% de ellas tiene empleo formal; 55% de todas las personas que trabajan gana menos.

Escribe `quien_gana_basico_resumen.csv` (`grupo`, `empleo`, `porcentaje`, `porcentaje_grupo`, `parte_del_grupo`).

### 13_basico_por_rama.R: Gráfico 4

Usa las mismas personas y los mismos pesos del script 12, y la rama de actividad (`rama1`, secciones A a U de la CIIU). Calcula, por sección:

```
gana_menos_de_482 = 100 × suma de pesos con ingreso < 482 / suma de pesos de la sección
```

En agricultura y pesca, 83,7% de quienes trabajan gana menos de $482. Entre ellos, 93,6% no tiene empleo formal (`sin_empleo_formal_entre_quienes_ganan_menos`).

Para el Gráfico 4 junta M con N y R con S, como el Banco Central, y calcula por sector:

- `formales_hasta_el_basico`: el porcentaje de los trabajadores formales del sector que gana $506 o menos (altura de cada círculo). El promedio de todas las ramas es 36%.
- `parte_de_quienes_ganan_alrededor`: qué parte de las personas que ganan de $458 a $506 trabaja en el sector (tamaño del círculo).
- `cambio_vab_trabajador`: el cambio del script 11 (posición horizontal).

Un sector sufre más presión (`mas_presion`) si su cambio es menor que el del SBU (25,3%) y su `formales_hasta_el_basico` supera el promedio. Son los círculos azules dentro de la zona sombreada.

El script también calcula los afiliados del sector privado en la construcción (sección F del REESS), como promedio de los doce meses: 111.614 en 2017 y 87.668 en 2025, un cambio de −21,5%.

Escribe `basico_por_rama_2026.csv`, `basico_por_sector_grupos_bce_2026.csv`, `afiliados_construccion_2017_2025.csv`, `grafico_4_presion_y_exposicion_por_sector.png` y `grafico_4_presion_y_exposicion_por_sector.svg`.

## Los gráficos

Los gráficos siguen el formato de los del artículo de la ENIGHUR de El Quantificador. Miden 8 × 6,4 pulgadas, y cada uno se guarda en PNG a 300 puntos por pulgada y en SVG. La imagen no lleva título, fuente ni logo, porque el artículo los pone en el texto, arriba y abajo del gráfico. `scripts/00_common.R` es una copia de `theme_quantificador()` del archivo `scripts/utils.R` del repositorio `enighur-quantificador`, y define los dos colores de los gráficos. Los scripts 03, 04, 11 y 13 lo cargan con `source()`.

En el Gráfico 4, el nombre de cada sector se coloca a mano, en la tabla `posicion_nombre` del script 13, para que ningún nombre tape un círculo. Si cambian los datos, revisa el PNG y mueve los nombres que se superpongan.

## Uso de inteligencia artificial

La imagen de portada del artículo se generó con inteligencia artificial. También se usó inteligencia artificial para consultar datos con [EcuData MCP](https://github.com/DweskZ/EcuDataMCP), un servidor de datos abiertos de Ecuador.

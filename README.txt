============================================================================================================
MATERIAL SUPLEMENTARIO Y CÓDIGO FUENTE - TFM
Análisis del perfil transcriptómico de Bacillus velezensis en su interacción con Colletotrichum gloeosporioides
============================================================================================================

1. REQUISITOS DE ENTORNO Y REPRODUCIBILIDAD
-------------------------------------------------------------------------------
- Entorno Conda/Mamba: Gestor de paquetes:
    Miniconda (v26.1.1) o Mamba equivalente.

- Entorno Conda/Mamba integrado (Bash + R):
    Se adjunta el archivo 'environment.yml' con la suite bioinformática completa empleada en este TFT

- Permisos de sistema:
    Se requieren permisos de lectura y escritura en la raíz del directorio del proyecto
    para la creación automática de subcarpetas (data/, reports/, results/). Se recomienda
    asignar permisos totales para la correcta reproducción de este entorno (chmod +x Anexos_TFM/).

- Entorno Rstudio (R Project):
    Se incluye 'tfm_bacillus_velezensis.Rproj'. Abierto desde RStudio, el paquete 'here' detecta la raíz
    del proyecto.

2. ESTRUCTURA DE DIRECTORIOS DEL Y ARCHIVOS
-------------------------------------------------------------------------------
.
├── environment.yml                          # Especificación del entorno Conda
├── README.txt                               # Guía de reproducción y documentación (Este archivo)
├── tfm_bacillus_velezensis.Rproj            # Archivo de proyecto RStudio
├── analisis_transcriptomico_master.Rmd      # Script Rmd para el análisis downstream
│
├── scripts/                                 # Pipeline de procesamiento (Bash)
│   ├── 01_download_and_QC.sh
│   ├── 02_trimming_and_postQC.sh
│   ├── 03_alignment.sh
│   ├── 04_quantification.sh
│   └── 05_buil_annotation.sh
│
├── data/                                    # Estructura de datos de entrada e intermedios
│   ├── metadata/
│   │   └── metadata.tsv                     # [Requerido] Tabla de metadatos de las 12 muestras
│   ├── raw/
│   │   └── reference_strain_83/
│   └── processed/                           # Archivos procesados e intermedios de bajo peso
│       ├── annotation/
│       │   └── query.emapper.annotations    # [Incluido] Anotación funcional EggNOG-mapper (vía Web)
│       └── counts/
│           └── gene_counts_clean.tsv        # [Incluido] Matriz de conteos limpia por gen para DESeq2
│
├── reports/                                 # Logs de ejecución del pipeline y métricas QC
│   ├── *.log
│   └── sequencing_report_table.md
│
└── results/                                 # Entregables finales y tablas suplementarias
    ├── annotation/                          # [Autogenerado] Archivos de anotación funcional
    ├── figures/                             # [Autogenerado] Gráficos exportados
    ├── S1_anexo_tabla_maestra_anotacion.csv # Tabla Suplementaria S1 (Máster Anotación/DEGs)
    ├── S2_anexo_gsea_results_all_8h_13h.csv # Tabla Suplementaria S2 (Resultados GSEA)
    ├── S3_anexo_BGC_genes_master_table.csv  # Tabla Suplementaria S3 (Detalle gen a gen BGCs)
    ├── Tabla_QC_Summary_Formatted.docx
    ├── Tabla_BGC_Dynamics_Formatted.docx
    ├── Tabla_ORA_Summary_Formatted.docx
    └── Tabla_GSEA_Summary_Formatted.docx

NOTAS:
---------
Por limitación de tamaño de archivo, las subcarpetas dentro de '/data/raw' y '/data/processed' han sido reducidas a aquellas indispensables para reproducibilidad, como metadata.tsv.

Algunos scripts (03.sh y 05.sh) asumen la presencia del genoma de referencia, ensamblado NCBI RefSeq GCF_004101805.1 (ASM410180v1) contenido en 'data/raw/reference_strain_83/'.


3. ORDEN DE EJECUCIÓN DEL PIPELINE
-------------------------------------------------------------------------------
FASE 1: Procesamiento inicial (Shell Scripts)

Ejecutar en orden secuencial desde la carpeta del proyecto:
  1. bash 01_scripts_bash/01_download_and_QC.sh --> Descarga/verificación de lecturas crudas y FastQC inicial.
  2. bash 01_scripts_bash/02_trimming_and_postQC.sh --> Filtrado de calidad/adaptadores y verificación post-trimming.
  3. bash 01_scripts_bash/03_alignment.sh --> Mapeo de lecturas contra el genoma de referencia de B. velezensis.
  4. bash 01_scripts_bash/04_quantification.sh --> Cuantificación de lecturas por gen (matriz de conteos).
  5. bash 01_scripts_bash/05_buil_annotation.sh --> Consolidación de la anotación funcional de referencia.

FASE 2: Análisis downstream y generación de resultados (RMarkdown)

Abrir y ejecutar '02_scripts_R/analisis_transcriptomico_master.Rmd' en RStudio.
El script realiza:
    - Filtrado y modelado estadístico con DESeq2 (8h y 13h).
    - Análisis de enriquecimiento funcional ORA y GSEA (clusterProfiler).
    - Integración de la expresión en regiones de metabolitos secundarios (antiSMASH).
    - Exportación de tablas maquetadas (.docx) y suplementarias (.csv).

4. DESCRIPCIÓN DE TABLAS SUPLEMENTARIAS
-------------------------------------------------------------------------------
- Tabla_S1 (Tabla_S1_anexo_tabla_maestra_anotacion.csv):
  Consolidado de anotación funcional, estado de
  regulación (8h y 13h) y patrón temporal asignado a cada gen.

- Tabla_S2 (Tabla_S2_anexo_BGC_genes_master_table.csv):
  Detalle gen a gen de las regiones biosintéticas de metabolitos secundarios (BGCs)
  identificadas por antiSMASH y sus métricas de expresión.

- Tabla_S3 (Tabla_S3_gsea_results_all_8h_13h.csv):
  Resultados completos del análisis de enriquecimiento de conjuntos de genes (GSEA)
  para los puntos temporales de 8h y 13h.
-------------------------------------------------------------------------------

#!/usr/bin/env bash
set -euo pipefail

#Establecimiento de la raíz del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

#Establecimiento variables
RAW_DIR="data/raw/fastq"
PRE_QC_DIR="data/processed/qc/pre_trimming"
REPORTS_DIR="reports"

mkdir -p "$RAW_DIR" "$PRE_QC_DIR" "$REPORTS_DIR"

SRRS=(
  SRR19176864 SRR19176863 SRR19176862
  SRR19176861 SRR19176860 SRR19176859
  SRR19176858 SRR19176857 SRR19176856
  SRR19176855 SRR19176854 SRR19176853
)

#Descarga de datos. Prefetch + fasterq-dump 
echo "=== 1/3. Descargando muestras con prefetch y fasterq-dump ===" | tee -a "$REPORTS_DIR/download.log"

for srr in "${SRRS[@]}"; do
    if [ -f "$RAW_DIR/${srr}_1.fastq.gz" ] && [ -f "$RAW_DIR/${srr}_2.fastq.gz" ]; then
        echo "Muestra $srr ya existe en $RAW_DIR. Omitiendo..."
        continue
    fi

    echo "Procesando $srr..."
    prefetch "$srr" --output-directory "$RAW_DIR"
    fasterq-dump "$RAW_DIR/$srr/$srr.sra" \
        --outdir "$RAW_DIR" \
        --threads 14 \
        --split-files \
        --progress

    #Compresión multi-hilo
    pigz -p 14 "$RAW_DIR/${srr}_1.fastq" "$RAW_DIR/${srr}_2.fastq"
    rm -rf "$RAW_DIR/$srr"
done

#Control de Calidad Pre-Trimming
echo "=== 2/3. Ejecutando FastQC ===" | tee -a "$REPORTS_DIR/download.log"
fastqc -t 14 "$RAW_DIR"/*.fastq.gz -o "$PRE_QC_DIR"

echo "=== 3/3. Generando MultiQC ===" | tee -a "$REPORTS_DIR/download.log"
multiqc "$PRE_QC_DIR" -o "$PRE_QC_DIR"

echo "=== Script 01 finalizado. Reporte listo en: $PRE_QC_DIR/multiqc_report.html ==="

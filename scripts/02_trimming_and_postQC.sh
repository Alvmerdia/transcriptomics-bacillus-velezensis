#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

#Establecimiento de variables
RAW_DIR="data/raw/fastq"
TRIMMED_DIR="data/processed/trimmed"
POST_QC_DIR="data/processed/qc/post_trimming"
REPORTS_DIR="reports"

mkdir -p "$TRIMMED_DIR" "$POST_QC_DIR" "$REPORTS_DIR"

SRRS=(
  SRR19176864 SRR19176863 SRR19176862
  SRR19176861 SRR19176860 SRR19176859
  SRR19176858 SRR19176857 SRR19176856
  SRR19176855 SRR19176854 SRR19176853
)

#Trimming
echo "=== 1/3. Ejecutando Trimming con fastp ===" | tee -a "$REPORTS_DIR/trimming.log"

for srr in "${SRRS[@]}"; do
    if [ -f "$TRIMMED_DIR/${srr}_1.trimmed.fastq.gz" ] && [ -f "$TRIMMED_DIR/${srr}_2.trimmed.fastq.gz" ]; then
        echo "La muestra $srr ya ha sido procesada. Omitiendo..."
        continue
    fi

    echo "Procesando $srr..."
    fastp \
        --in1 "$RAW_DIR/${srr}_1.fastq.gz" \
        --in2 "$RAW_DIR/${srr}_2.fastq.gz" \
        --out1 "$TRIMMED_DIR/${srr}_1.trimmed.fastq.gz" \
        --out2 "$TRIMMED_DIR/${srr}_2.trimmed.fastq.gz" \
        --detect_adapter_for_pe \
        --trim_poly_g \
        --length_required 35 \
        --thread 14 \
        --json "$POST_QC_DIR/${srr}_fastp.json" \
        --html "$POST_QC_DIR/${srr}_fastp.html" 2>&1 | tee -a "$REPORTS_DIR/trimming.log"
done

echo "=== 2/3. Generando FastQC POST-trimming ===" | tee -a "$REPORTS_DIR/trimming.log"
fastqc -t 14 "$TRIMMED_DIR"/*.trimmed.fastq.gz -o "$POST_QC_DIR"

echo "=== 3/3. Generando MultiQC POST-trimming ===" | tee -a "$REPORTS_DIR/trimming.log"
multiqc "$POST_QC_DIR" -o "$POST_QC_DIR"

echo "=== Script 02 finalizado. Reporte listo en: $POST_QC_DIR/multiqc_report.html ==="

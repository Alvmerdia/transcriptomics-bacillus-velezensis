#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Configuración de rutas
REF_FASTA="data/raw/reference_strain_83/GCF_004101805.1_ASM410180v1_genomic.fna"

INDEX_DIR="data/processed/reference_index/bowtie2"
INDEX_PREFIX="$INDEX_DIR/b_velezensis_83"

TRIMMED_DIR="data/processed/trimmed"
ALIGN_DIR="data/processed/aligned"
QC_DIR="data/processed/qc/alignment_qc"
REPORTS_DIR="reports"

mkdir -p "$INDEX_DIR" "$ALIGN_DIR" "$QC_DIR" "$REPORTS_DIR"

# Muestras
SRRS=(
  SRR19176864 SRR19176863 SRR19176862
  SRR19176861 SRR19176860 SRR19176859
  SRR19176858 SRR19176857 SRR19176856
  SRR19176855 SRR19176854 SRR19176853
)

# 1. Indexado del genoma
if [ ! -f "$INDEX_PREFIX.1.bt2" ]; then
    echo "=== 1/3. Generando índice de Bowtie2 ===" | tee -a "$REPORTS_DIR/alignment.log"
    bowtie2-build "$REF_FASTA" "$INDEX_PREFIX" --threads 12
else
    echo "=== Índice de Bowtie2 detectado. Omitiendo indexado... ==="
fi

# 2. Alineamiento + Ordenado + Indexado BAM
echo "=== 2/3. Alineando muestras con Bowtie2 ===" | tee -a "$REPORTS_DIR/alignment.log"

for srr in "${SRRS[@]}"; do
    if [ -f "$ALIGN_DIR/${srr}.bam" ]; then
        echo "Muestra $srr ya procesada. Omitiendo..."
        continue
    fi

    echo "Alineando $srr..."
    bowtie2 \
        -x "$INDEX_PREFIX" \
        -1 "$TRIMMED_DIR/${srr}_1.trimmed.fastq.gz" \
        -2 "$TRIMMED_DIR/${srr}_2.trimmed.fastq.gz" \
        --threads 12 \
        --no-unal \
        2> "$QC_DIR/${srr}_bowtie2.log" | \
    samtools view -@ 4 -b -q 30 - | \
    samtools sort -@ 4 -o "$ALIGN_DIR/${srr}.bam" -

    samtools index "$ALIGN_DIR/${srr}.bam"
done

# 3. Reporte de alineamiento con MultiQC
echo "=== 3/3. Generando reporte MultiQC para alineamiento ===" | tee -a "$REPORTS_DIR/alignment.log"
multiqc "$QC_DIR" -o "$QC_DIR"

echo "=== Fase de alineamiento completada exitosamente ==="

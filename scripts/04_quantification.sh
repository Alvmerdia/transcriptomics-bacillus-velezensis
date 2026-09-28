#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Configuración de rutas
GFF_FILE="data/raw/reference_strain_83/genomic.gff"
ALIGN_DIR="data/processed/aligned"
COUNTS_DIR="data/processed/counts"
REPORTS_DIR="reports"

mkdir -p "$COUNTS_DIR" "$REPORTS_DIR"

OUTPUT_FILE="$COUNTS_DIR/gene_counts.txt"
LOG_FILE="$REPORTS_DIR/quantification.log"

echo "=== Iniciando cuantificación con featureCounts (Stranded: Reverse, -s 2) ===" | tee "$LOG_FILE"

# Recopilación de los archivos BAM
BAM_FILES=("$ALIGN_DIR"/*.bam)

# Cuantificación con featureCounts | Se establece previamente que el protocolo es -s 2 (reverse-stranded)
featureCounts \
    -p -B -C \
    -s 2 \
    -F GTF \
    -t CDS \
    -g Parent \
    -T 12 \
    -a "$GFF_FILE" \
    -o "$OUTPUT_FILE" \
    "${BAM_FILES[@]}" \
    2>&1 | tee -a "$LOG_FILE"

echo "=== Generando matriz simplificada de conteos ===" | tee -a "$LOG_FILE"

# Extraemos únicamente el ID del gen y las columnas de conteos
# y eliminamos el prefijo "gene-" de los IDs
cut -f 1,7- "$OUTPUT_FILE" |
    grep -v '^#' |
    sed 's/^gene-//' \
    > "$COUNTS_DIR/gene_counts_clean.tsv"

echo "=== Cuantificación completada exitosamente ===" | tee -a "$LOG_FILE"

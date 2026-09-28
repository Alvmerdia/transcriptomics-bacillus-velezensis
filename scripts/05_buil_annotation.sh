#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Configuración de rutas
GFF="data/raw/reference_strain_83/genomic.gff"
COUNTS="data/processed/counts/gene_counts_clean.tsv"

ANNOTATION_DIR="results/annotation"
ANNOTATION_FILE="$ANNOTATION_DIR/CP034203_annotation.tsv"

mkdir -p "$ANNOTATION_DIR"

echo "=== Construcción de la tabla de anotación de CP034203 ==="

# Comprobar archivos de entrada
if [ ! -f "$GFF" ]; then
    echo "ERROR: No se encuentra el archivo GFF:"
    echo "$GFF"
    exit 1
fi

if [ ! -f "$COUNTS" ]; then
    echo "ERROR: No se encuentra la matriz de counts:"
    echo "$COUNTS"
    exit 1
fi

# Evitar sobrescribir accidentalmente un resultado existente
if [ -f "$ANNOTATION_FILE" ]; then
    echo "=== Tabla de anotación ya existente. Omitiendo generación... ==="
    exit 0
fi

# Extracción de anotación desde CDS
echo "=== Extrayendo anotación de CDS desde el GFF ==="

TMP_ANNOTATION=$(mktemp)

awk -F'\t' '
BEGIN {
    OFS="\t"
}

$3 == "CDS" {

    locus=""
    gene=""
    old=""
    protein=""
    product=""
    go=""

    if (match($9,/locus_tag=[^;]+/))
        locus=substr($9,RSTART+10,RLENGTH-10)

    if (match($9,/gene=[^;]+/))
        gene=substr($9,RSTART+5,RLENGTH-5)

    if (match($9,/old_locus_tag=[^;]+/))
        old=substr($9,RSTART+15,RLENGTH-15)

    if (match($9,/protein_id=[^;]+/))
        protein=substr($9,RSTART+11,RLENGTH-11)

    if (match($9,/product=[^;]+/))
        product=substr($9,RSTART+8,RLENGTH-8)

    if (match($9,/Ontology_term=[^;]+/))
        go=substr($9,RSTART+14,RLENGTH-14)

    if (locus != "")
        print locus, gene, old, protein, product, go
}
' "$GFF" > "$TMP_ANNOTATION"

# Una única fila por locus_tag
{
    printf "locus_tag\tgene\told_locus_tag\tprotein_id\tproduct\tGO\n"
    sort -t $'\t' -k1,1 "$TMP_ANNOTATION" | \
        awk -F'\t' '!seen[$1]++'
} > "$ANNOTATION_FILE"

rm -f "$TMP_ANNOTATION"

# Comprobación del num loci
N_ANNOTATION=$(tail -n +2 "$ANNOTATION_FILE" | cut -f1 | sort -u | wc -l)

echo "=== Anotación generada ==="
echo "Locus_tag únicos: $N_ANNOTATION"

if [ "$N_ANNOTATION" -ne 3825 ]; then
    echo "ERROR: Se esperaban 3825 locus_tag únicos."
    exit 1
fi

# Validación frente a la matriz de conteos
echo "=== Validando correspondencia con la matriz de conteos ==="

cut -f1 "$COUNTS" | tail -n +2 | sort -u > /tmp/count_ids.txt
tail -n +2 "$ANNOTATION_FILE" | cut -f1 | sort -u > /tmp/annotation_ids.txt

MISSING_COUNTS=$(comm -23 /tmp/count_ids.txt /tmp/annotation_ids.txt | wc -l)
MISSING_ANNOTATION=$(comm -13 /tmp/count_ids.txt /tmp/annotation_ids.txt | wc -l)

echo "Genes en counts sin anotación: $MISSING_COUNTS"
echo "Genes anotados sin counts: $MISSING_ANNOTATION"

rm -f /tmp/count_ids.txt /tmp/annotation_ids.txt

if [ "$MISSING_COUNTS" -ne 0 ] || [ "$MISSING_ANNOTATION" -ne 0 ]; then
    echo "ERROR: La correspondencia entre counts y anotación no es completa."
    exit 1
fi

echo "=== Correspondencia counts ↔ anotación: OK ==="
echo "=== Fase de anotación completada exitosamente ==="

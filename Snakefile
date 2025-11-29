from snakemake.utils import min_version
min_version("6.0")

DATA_DIR = 'data'
QUERIES_DIR = f"{DATA_DIR}/queries"
TARGET_PROTEINS = ["srpx2", "foxp1", "foxp2", "slitrk6", "dcdc2", "avpr1a", "cntp2"]
QUERY_FILES = expand("{q_dir}/{target}.fasta", q_dir=QUERIES_DIR, target=TARGET_PROTEINS)

rule all:
    input:
        expand("output/alignments/{gene}.afa", gene=TARGET_PROTEINS),
        expand("output/trimmed_alignments/{gene}.clipkit.afa", gene=TARGET_PROTEINS),
        expand(
            "output/{dirs}/{gene}.html",
            gene=TARGET_PROTEINS,
            dirs=['alignments_html', 'trimmed_alignments_html']
        )

module blast:
    snakefile: "workflows/rules/blast.smk"
use rule * from blast

module db:
    snakefile: "workflows/rules/db.smk"
use rule * from db as set_*

module fasta_manipulations:
    snakefile: "workflows/rules/fasta_mainpulations.smk"
use rule * from fasta_manipulations

module mafft_alignments:
    snakefile: "workflows/rules/mafft_alignments.smk"
use rule * from mafft_alignments
from snakemake.utils import min_version
min_version("6.0")

configfile: "config.yaml"

def get_path(BASE, key):
    return f"{BASE['base_root']}/{BASE['dirs'][key]}"

OUTPUT = config["output"]
SUFFIX = config["suffix"]

ALIGNMENT_DIR = get_path(OUTPUT, "alignments")
TRIMMED_ALIGNMENT_DIR = get_path(OUTPUT, "trimmed_alignments")
ALIGNMENT_REPORTS_DIR = get_path(OUTPUT, "alignments_reports")
TRIMMED_ALIGNMENT_REPORTS_DIR = get_path(OUTPUT, "trimmed_alignments_reports")
TREE_DIR = get_path(OUTPUT, "trees")

TARGETS = sorted(config['targets'].keys())
rule all:
    input:
        # output/alignments/{gene}.afa
        expand(
            "{align_dir}/{gene}.{ext}",
            align_dir=ALIGNMENT_DIR,
            gene=TARGETS,
            ext=SUFFIX["alignment"],
        ),
        # output/trimmed_alignments/{gene}.clipkit.afa
        expand(
            "{trim_dir}/{gene}.{ext}",
            trim_dir=TRIMMED_ALIGNMENT_DIR,
            gene=TARGETS,
            ext=SUFFIX["trimmed_alignment"],
        ),
        # output/html_reports_dir|trimmed_html_reports_dir/{gene}.html
        expand(
            "{dir}/{gene}.html",
            dir=[
                ALIGNMENT_REPORTS_DIR,
                TRIMMED_ALIGNMENT_REPORTS_DIR,
            ],
            gene=TARGETS,
        ),
        expand(
            "{dir}/{gene}.treefile",
            dir=TREE_DIR,
            gene=TARGETS,
        )

WORKFLOW = config['workflow']
RULES_DIR = get_path(WORKFLOW, "rules")

module blast:
    snakefile: f"{RULES_DIR}/blast.smk"
    config: config
use rule * from blast

module db:
    snakefile: f"{RULES_DIR}/db.smk"
    config: config
use rule * from db as set_*

module fasta_manipulations:
    snakefile: f"{RULES_DIR}/fasta_manipulations.smk"
    config: config
use rule * from fasta_manipulations

module mafft_alignments:
    snakefile: f"{RULES_DIR}/mafft_alignments.smk"
    config: config
use rule * from mafft_alignments

module taxonomy:
    snakefile: f"{RULES_DIR}/taxonomy.smk"
    config: config
use rule * from taxonomy

module phylogeny:
    snakefile: f"{RULES_DIR}/phylogeny.smk"
    config: config
use rule * from phylogeny
def get_path(BASE, key):
    return f"{BASE['base_root']}/{BASE['dirs'][key]}"

DATA = config['data']
FASTA_MODIFIED_DIR = get_path(DATA, 'fasta_modified')
OUTPUT = config['output']
ALIGNMENT_DIR = get_path(OUTPUT, "alignments")
TRIMMED_ALIGNMENT_DIR = get_path(OUTPUT, "trimmed_alignments")
ALIGNMENT_REPORTS_DIR = get_path(OUTPUT, "alignments_reports")
TRIMMED_ALIGNMENT_REPORTS_DIR = get_path(OUTPUT, "trimmed_alignments_reports")

SUFFIX = config['suffix']
FASTA_SUFFIX = SUFFIX['fasta']
ALIGNMENT_SUFFIX = SUFFIX['alignment']
TRIMMED_ALIGNMENT_SUFFIX = SUFFIX['trimmed_alignment']

MAFFT_PARAMS = config['mafft']
CLIPKIT_PARAMS = config['clipkit']

rule mafft_align:
    input:
        f"{FASTA_MODIFIED_DIR}/{{gene}}.{FASTA_SUFFIX}"
    output:
        f"{ALIGNMENT_DIR}/{{gene}}.{ALIGNMENT_SUFFIX}"
    params:
        mode=MAFFT_PARAMS['mode'],
        max_iter=MAFFT_PARAMS['max_iter'],
        thread=MAFFT_PARAMS['threads']
    shell:
        """
        mafft {params.mode} --maxiterate {params.max_iter} --thread {params.thread} {input} > {output}
        """

rule afa_to_html:
    input:
        rules.mafft_align.output
    output:
        f"{ALIGNMENT_REPORTS_DIR}/{{gene}}.html"
    shell:
        """
        mview -in fasta -label2 -ruler on -html head -css on -coloring any {input} > {output}
        """

rule trim_afa:
    input:
        rules.mafft_align.output
    output:
        f"{TRIMMED_ALIGNMENT_DIR}/{{gene}}.{TRIMMED_ALIGNMENT_SUFFIX}"
    log:
        "logs/clipkit/{gene}.log"
    params:
        mode=CLIPKIT_PARAMS['mode']
    shell:
        """
        clipkit {input} -m {params.mode} -o {output} >{log} 2>&1
        """

rule trimmed_afa_to_html:
    input:
        rules.trim_afa.output
    output:
        f"{TRIMMED_ALIGNMENT_REPORTS_DIR}/{{gene}}.html"
    shell:
        """
        mview -in fasta -label2 -ruler on -html head -css on -coloring any {input} > {output}
        """
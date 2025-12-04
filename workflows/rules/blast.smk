def get_path(BASE, key):
    return f"{BASE['base_root']}/{BASE['dirs'][key]}"

DATA = config["data"]
QUERIES_DIR = get_path(DATA, 'queries')

DATA_BASE = config["db"]['base_root']
DB_NAME = f"{DATA_BASE}/{config['db']['name']}"

BLAST_OUT_DIR = get_path(DATA, 'blast')
FILTERED_HITS_DIR = get_path(DATA, 'filtered_hits')

WORKFLOW = config['workflow']
SCRIPTS = get_path(WORKFLOW, 'scripts')
QC_SCRIPT = f"{SCRIPTS}/hit_qc.py"

BLAST_PARAMS = config['blast']

SUFFIX = config['suffix']
FASTA_SUFFIX = SUFFIX['fasta']

rule run_blastp:
    input:
        fasta = f"{QUERIES_DIR}/{{gene}}.{FASTA_SUFFIX}",
        taxdb_btd=f"{DATA_BASE}/taxdb.btd",
        taxdb_bti=f"{DATA_BASE}/taxdb.bti",
        seq_db = f"{DATA_BASE}/.ready"
    output:
        tsv=f"{BLAST_OUT_DIR}/{{gene}}.tsv"
    params:
        db=DB_NAME,
        tax_db=DATA_BASE,
        e_value=BLAST_PARAMS['evalue'],
        max_seq=BLAST_PARAMS['max_target_seqs'],
        qcov =BLAST_PARAMS['qcov'],
        outfmt=BLAST_PARAMS['outfmt']
    log:
        "logs/blast/{gene}.log"
    shell:
        r"""
        echo "BLASTp for {wildcards.gene}" > {log}
        export BLASTDB={params.tax_db}
        blastp \
            -query {input.fasta} \
            -db {params.db} \
            -evalue {params.e_value} \
            -qcov_hsp_perc {params.qcov} \
            -max_target_seqs {params.max_seq} \
            -out {output.tsv} \
            -outfmt "{params.outfmt}" \
            2>> {log}
        """

rule blast_results_QC:
    input:
        rules.run_blastp.output
    output:
        f"{FILTERED_HITS_DIR}/{{gene}}.tsv"
    params:
        script=QC_SCRIPT,
        filters=config['filters'],
        title_meta=lambda wc: config["targets"][wc.gene]["meta"]
    shell:
        r"""
        python3 {params.script} \
          -i {input} \
          -o {output} \
          --drop_duplicates \
          --s_filters "{params.filters}" \
          --title_meta "{params.title_meta}"
        """
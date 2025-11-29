DATA_DIR = 'data'
QUERIES_DIR = f"{DATA_DIR}/queries"
TAX_DB = 'tax_db'
TARGET_PROTEINS = ["srpx2", "foxp1", "foxp2", "slitrk6", "dcdc2", "avpr1a", "cntp2"]
QUERY_FILES = expand("{q_dir}/{target}.fasta", q_dir=QUERIES_DIR, target=TARGET_PROTEINS)

QC_SCRIPT = "workflows/scripts/hit_qc.py"

rule run_blastp:
    input:
        fasta="data/queries/{gene}.fasta",
        taxdb_btd=f"{TAX_DB}/taxdb.btd",
        taxdb_bti=f"{TAX_DB}/taxdb.bti"
    output:
        tsv="data/blast/{gene}.tsv"
    params:
        db="tax_db/refseq_primates",
        tax="txid9443[orgn]",
        tax_db=TAX_DB
    log:
        "logs/blast/{gene}.log"
    shell:
        r"""
        echo "BLASTp for {wildcards.gene}" > {log}
        export BLASTDB={params.tax_db}
        blastp \
            -query {input.fasta} \
            -db {params.db} \
            -evalue 1e-10 \
            -qcov_hsp_perc 50 \
            -max_target_seqs 500 \
            -out {output.tsv} \
            -outfmt "6 sseqid length pident qcovs evalue bitscore stitle" \
            2>> {log}
        """

rule blast_results_QC:
    input:
        "data/blast/{gene}.tsv"
    output:
        "data/filtered_hits/{gene}.tsv"
    params:
        script=QC_SCRIPT
    shell:
        """
        python3 {params.script} -i {input} -o {output} --drop_duplicates
        """
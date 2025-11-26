DATA_DIR = 'data'
QUERIES_DIR = f"{DATA_DIR}/queries"
TAX_DB = 'tax_db'
TARGET_PROTEINS = ["srpx2", "foxp1", "foxp2", "slitrk6", "dcdc2"]
QUERY_FILES = expand("{q_dir}/{target}.fasta", q_dir=QUERIES_DIR, target=TARGET_PROTEINS)

QC_SCRIPT = "workflows/scripts/hit_qc.py"
FIND_SHARED_ID = "workflows/scripts/find_shared_tax.py"
FETCH_FASTA_SCRIPT = "workflows/scripts/fetch_fasta.py"
rule all:
    input:
        expand(
            "data/blast/{gene}.tsv", gene=TARGET_PROTEINS
        ),
        expand(
            "data/filtered_hits/{gene}.tsv", gene=TARGET_PROTEINS
        ),
        expand(
            "data/shared_taxa_hits/{gene}.tsv", gene=TARGET_PROTEINS
        ),
        expand(
            "data/fasta/{gene}.fasta", gene=TARGET_PROTEINS
        )

rule set_taxdb:
    output:
        f"{TAX_DB}/taxdb.btd",
        f"{TAX_DB}/taxdb.bti"
    params:
        tax_db=TAX_DB
    shell:
        r"""
        wget -O {params.tax_db}/taxdb.tar.gz ftp://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz
        tar -xvzf {params.tax_db}/taxdb.tar.gz -C {params.tax_db}
        """
        

rule run_blastp:
    input:
        fasta="data/queries/{gene}.fasta",
        taxdb_btd=f"{TAX_DB}/taxdb.btd",
        taxdb_bti=f"{TAX_DB}/taxdb.bti"
    output:
        tsv="data/blast/{gene}.tsv"
    params:
        db="refseq_protein",
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
            -remote \
            -entrez_query "{params.tax}" \
            -evalue 1e-10 \
            -qcov_hsp_perc 50 \
            -max_target_seqs 500 \
            -out {output.tsv} \
            -outfmt "6 sseqid sscinames pident qcovs evalue bitscore stitle" \
            2>> {log}
        """

rule blast_results_QC:
    input:
        "data/blast/{gene}.tsv"
    output:
        "data/filtered_hits/{gene}.tsv"
    params:
        qc_script=QC_SCRIPT
    shell:
        """
        python3 {params.qc_script} -i {input} -o {output} --drop_duplicates
        """

rule find_shared_ids:
    input:
        rules.blast_results_QC.output
    output:
        "data/shared_taxa_hits/{gene}.tsv"
    params:
        script=FIND_SHARED_ID,
        input_dir = subpath(rules.blast_results_QC.output[0], parent=True),
        output_dir = "data/shared_taxa_hits"
    shell:
        """
        python3 {params.script} -d {params.input_dir} -o {params.output_dir}
        """

rule fetch_fasta:
    input:
        "data/shared_taxa_hits/{gene}.tsv"
    output:
        "data/fasta/{gene}.fasta"
    params:
        script=FETCH_FASTA_SCRIPT,
        db="protein"
    shell:
        """
        python3 {params.script} -i {input} -o {output} -db {params.db}
        """
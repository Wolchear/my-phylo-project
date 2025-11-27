DATA_DIR = 'data'
QUERIES_DIR = f"{DATA_DIR}/queries"
TAX_DB = 'tax_db'
TARGET_PROTEINS = ["srpx2", "foxp1", "foxp2", "slitrk6", "dcdc2", "avpr1a", "cntp2"]
QUERY_FILES = expand("{q_dir}/{target}.fasta", q_dir=QUERIES_DIR, target=TARGET_PROTEINS)

QC_SCRIPT = "workflows/scripts/hit_qc.py"
MODIFY_IDS_SCRIPT = "workflows/scripts/modify_ids.py"
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
            "data/fasta/{gene}.fasta", gene=TARGET_PROTEINS
        ),
        expand(
            "data/fasta_modified/{gene}.fasta", gene=TARGET_PROTEINS
        ),
        expand(
            "output/alignments/{gene}.afa", gene=TARGET_PROTEINS,
        ),
        expand(
            "output/alignments_html/{gene}.html", gene=TARGET_PROTEINS
        ),
        expand(
            "output/trimmed_alignments/{gene}.clipkit.afa", gene=TARGET_PROTEINS
        ),
        expand(
            "output/trimmed_alignments_html/{gene}.html", gene=TARGET_PROTEINS
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

rule fetch_fasta:
    input:
        rules.blast_results_QC.output
    output:
        "data/fasta/{gene}.fasta"
    params:
        script=FETCH_FASTA_SCRIPT,
        db="protein"
    shell:
        """
        python3 {params.script} -i {input} -o {output} -db {params.db} --local
        """

rule modify_ids:
    input:
        rules.fetch_fasta.output
    output:
        "data/fasta_modified/{gene}.fasta"
    params:
        script=MODIFY_IDS_SCRIPT
    shell:
        """
         python3 {params.script} -i {input} -o {output}
        """

rule mafft_align:
    input:
        rules.modify_ids.output
    output:
        "output/alignments/{gene}.afa"
    shell:
        """
        mafft --localpair --maxiterate 1000 --thread 5 {input} > {output}
        """

rule afa_to_html:
    input:
        rules.mafft_align.output
    output:
        "output/alignments_html/{gene}.html"
    shell:
        """
        mview -in fasta -label2 -ruler on -html head -css on -coloring any {input} > {output}
        """

rule trim_afa:
    input:
        rules.mafft_align.output
    output:
        "output/trimmed_alignments/{gene}.clipkit.afa"
    log:
        "logs/clipkit/{gene}.log"
    shell:
        """
        clipkit {input} -m kpic-smart-gap -o {output} >{log} 2>&1
        """

rule trimmed_afa_to_html:
    input:
        rules.trim_afa.output
    output:
        "output/trimmed_alignments_html/{gene}.html"
    shell:
        """
        mview -in fasta -label2 -ruler on -html head -css on -coloring any {input} > {output}
        """
MODIFY_IDS_SCRIPT = "workflows/scripts/modify_ids.py"
FETCH_FASTA_SCRIPT = "workflows/scripts/fetch_fasta.py"


rule fetch_fasta:
    input:
        "data/filtered_hits/{gene}.tsv"
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
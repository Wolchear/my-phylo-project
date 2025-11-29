
rule mafft_align:
    input:
        "data/fasta_modified/{gene}.fasta"
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
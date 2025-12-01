def get_path(BASE, key):
    return f"{BASE['base_root']}/{BASE['dirs'][key]}"

DATA = config['data']
FILTERED_HITS_DIR = get_path(DATA, 'filtered_hits')
FASTA_DIR = get_path(DATA, 'fasta')
FASTA_MODIFIED_DIR = get_path(DATA, 'fasta_modified')

WORKFLOW = config['workflow']
SCRIPTS = get_path(WORKFLOW, 'scripts')
MODIFY_IDS_SCRIPT = f"{SCRIPTS}/modify_ids.py"
FETCH_FASTA_SCRIPT = f"{SCRIPTS}/fetch_fasta.py"

SUFFIX = config['suffix']
FASTA_SUFFIX = SUFFIX['fasta']
rule fetch_fasta:
    input:
        f"{FILTERED_HITS_DIR}/{{gene}}.tsv"
    output:
        f"{FASTA_DIR}/{{gene}}.{FASTA_SUFFIX}"
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
        f"{FASTA_MODIFIED_DIR}/{{gene}}.{FASTA_SUFFIX}"
    params:
        script=MODIFY_IDS_SCRIPT
    shell:
        """
        python3 {params.script} -i {input} -o {output}
        """
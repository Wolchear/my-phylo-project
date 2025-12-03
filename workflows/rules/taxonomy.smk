def get_path(BASE, key):
    return f"{BASE['base_root']}/{BASE['dirs'][key]}"

OUTPUT = config['output']
ALIGNMENT_DIR = get_path(OUTPUT, "alignments")
TAXONOMY_DIR = get_path(OUTPUT, "taxonomy_tables")

SUFFIX = config['suffix']
ALIGNMENT_SUFFIX = SUFFIX['alignment']

WORKFLOW = config['workflow']
SCRIPTS = get_path(WORKFLOW, 'scripts')
TAX_SCRIPT = f"{SCRIPTS}/get_species.py"

rule generate_tables:
    input:
        f"{ALIGNMENT_DIR}/{{gene}}.{ALIGNMENT_SUFFIX}"
    output:
        f"{TAXONOMY_DIR}/{{gene}}.tsv"
    params:
        script=TAX_SCRIPT
    shell:
        """
        python3 {params.script} -i {input} -o {output}
        """
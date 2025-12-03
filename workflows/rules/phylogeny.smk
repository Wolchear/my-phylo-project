def get_path(BASE, key):
    return f"{BASE['base_root']}/{BASE['dirs'][key]}"

def get_species(file: str):
    OUTGROUP = config["outgroup"]
    group_idx = OUTGROUP["group_by_idx"]          # 2
    group_value = OUTGROUP["group_by_value"]      # "Lemuriformes"
    species_column = OUTGROUP["species_column"]   # 0
    species = []

    with open(file, 'r') as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            cols = line.split("\t")
            if cols[group_idx] == group_value:
                species_name = cols[species_column]
                species.append(species_name)

    return ",".join(sorted(set(species)))

OUTPUT = config['output']
TAXONOMY_DIR = get_path(OUTPUT, "taxonomy_tables")
TAXONOMY_DIR = get_path(OUTPUT, "taxonomy_tables")
TREE_DIR = get_path(OUTPUT, "trees")
TRIMMED_ALIGNMENT_DIR = get_path(OUTPUT, "trimmed_alignments")
SUFFIX = config['suffix']
TRIMMED_ALIGNMENT_SUFFIX = SUFFIX['trimmed_alignment']

rule iqtree:
    input:
        aln = f"{TRIMMED_ALIGNMENT_DIR}/{{gene}}.{TRIMMED_ALIGNMENT_SUFFIX}",
        tax = f"{TAXONOMY_DIR}/{{gene}}.tsv"
    threads: 4
    params:
        prefix   = f"{TREE_DIR}/{{gene}}",
        outgroup = lambda wildcards, input: get_species(input.tax)  # waiting, untild {gene} wildcard is defined
    output:                                                         # calling fucntion to get outgroup species names for every
        f"{TREE_DIR}/{{gene}}.treefile"
    shell:
        r"""
        iqtree \
            -s {input.aln} \
            -m MFP \
            -bb 1000 \
            -nt {threads} \
            -keep-ident \
            -o "{params.outgroup}" \
            -pre {params.prefix}
        """
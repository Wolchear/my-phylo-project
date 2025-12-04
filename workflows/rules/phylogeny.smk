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
SPECIES_TREES_DIR = get_path(OUTPUT, "species_trees")

SUFFIX = config['suffix']
TRIMMED_ALIGNMENT_SUFFIX = SUFFIX['trimmed_alignment']

IQTREE_PARAMS = config['iqtree']
ASTRAL_PARAMS = config['astral']

TARGETS = sorted(config['targets'].keys())

ALL_GENES_FILES = expand(
            f"{TREE_DIR}/{{gene}}.treefile",
            gene=TARGETS
        )
INCLUDED_GENES_FILES = expand(
    f"{TREE_DIR}/{{gene}}.treefile",
    gene=[g for g in TARGETS if g not in ASTRAL_PARAMS['exclude']]
)
rule iqtree:
    input:
        aln = f"{TRIMMED_ALIGNMENT_DIR}/{{gene}}.{TRIMMED_ALIGNMENT_SUFFIX}",
        tax = f"{TAXONOMY_DIR}/{{gene}}.tsv"
    threads: IQTREE_PARAMS['threads']
    params:
        keep_ident = "-keep-ident" if IQTREE_PARAMS.get("keep_ident", False) else "",
        bb_iter=IQTREE_PARAMS['bb_iter'],
        mode=IQTREE_PARAMS['mode'],
        prefix= f"{TREE_DIR}/{{gene}}",
        outgroup= lambda wildcards, input: get_species(input.tax)  # waiting, untild {gene} wildcard is defined
    output:                                                         # calling fucntion to get outgroup species names for every
        f"{TREE_DIR}/{{gene}}.treefile"
    shell:
        r"""
        iqtree \
            -s {input.aln} \
            -m {params.mode} \
            -bb {params.bb_iter} \
            -nt {threads} \
            -o "{params.outgroup}" \
            -pre {params.prefix} \
            -redo \
            {params.keep_ident}
        """

rule concat_astral_all:
    input:
        ALL_GENES_FILES
    output:
        temp(f"{SPECIES_TREES_DIR}/all_gene_trees.tre")
    shell:
        r"""
        cat {input} > {output}
        """

rule astral_tree:
    input:
        rules.concat_astral_all.output
    output:
        f"{SPECIES_TREES_DIR}/all_species_tree.treefile"
    params:
        seed = ASTRAL_PARAMS['seed']
    shell:
        r"""
        astral \
            -i {input} \
            -o {output} \
            -s {params.seed}
        """

rule concat_astral_excluded:
    input:
        INCLUDED_GENES_FILES
    output:
        temp(f"{SPECIES_TREES_DIR}/all_gene_trees.excluded.tre")
    shell:
        r"""
        cat {input} > {output}
        """

rule astral_tree_exclude:
    input:
        rules.concat_astral_excluded.output
    output:
        f"{SPECIES_TREES_DIR}/all_species_tree.excluded.treefile"
    params:
        seed = ASTRAL_PARAMS['seed']
    shell:
        r"""
        astral \
            -i {input} \
            -o {output} \
            -s {params.seed}
        """
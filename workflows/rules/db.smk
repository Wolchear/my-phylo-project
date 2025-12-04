DATA_BASE = config['db']
DATA_BASE_DIR = DATA_BASE['base_root']
DB_NAME = DATA_BASE['name']

rule get_data:
    output:
        temp(f"{DATA_BASE_DIR}/{DB_NAME}.zip")
    params:
        taxon=DATA_BASE['taxon'],
        db_type=DATA_BASE['db_type']
    shell:
        r"""
        datasets download genome taxon {params.taxon} \
            --include {params.db_type} \
            --assembly-source refseq \
            --filename {output}
        """
rule fetch_data:
    input:
        rules.get_data.output
    output:
        f"{DATA_BASE['base_root']}/{DB_NAME}.faa"
    params:
        tmp_dir = temp(directory(f"{DATA_BASE_DIR}/tmp_dir")),
        db_type=DATA_BASE['db_type']
    shell:
        r"""
        unzip -o {input} -d {params.tmp_dir}
        find {params.tmp_dir} -name "{params.db_type}.faa" -exec cat {{}} + > {output}
        """

rule set_db:
    input:
        rules.fetch_data.output
    output:
        f"{DATA_BASE_DIR}/.ready"
    params:
        db_type='prot' if DATA_BASE['db_type'] == "protein" else "nucl",
        db_dir=DATA_BASE_DIR,
        db_name=DB_NAME
    shell:
        """
        makeblastdb -in {input} -dbtype {params.db_type} -out "{params.db_dir}/{params.db_name}"
        touch {output}
        """

rule taxdb:
    input:
        rules.get_data.output
    output:
        f"{DATA_BASE_DIR}/taxdb.btd",
        f"{DATA_BASE_DIR}/taxdb.bti"
    params:
        tax_db=DATA_BASE_DIR
    shell:
        r"""
        wget -O {params.tax_db}/taxdb.tar.gz ftp://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz
        tar -xvzf {params.tax_db}/taxdb.tar.gz -C {params.tax_db}
        """
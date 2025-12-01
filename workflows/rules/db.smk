DATA_BASE = config['db']
DATA_BASE_DIR = DATA_BASE['base_root']

rule taxdb:
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
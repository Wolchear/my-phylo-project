TAX_DB = 'tax_db'

rule taxdb:
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
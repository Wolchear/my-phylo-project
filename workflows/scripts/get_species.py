import argparse
import re

from ete3 import NCBITaxa

ncbi = NCBITaxa()

def classify_species(tax_name: str):
    canonical = tax_name.replace("_", " ").strip()
    print(canonical)
    try:
        taxid = ncbi.get_name_translator([canonical])[canonical][0]
    except KeyError:
        return None, None, None

    lineage = ncbi.get_lineage(taxid)
    ranks = ncbi.get_rank(lineage)
    names = ncbi.get_taxid_translator(lineage)

    infraorder = next((names[t] for t in lineage if ranks[t] == "infraorder"), None)
    superfamily = next((names[t] for t in lineage if ranks[t] == "superfamily"), None)
    family = next((names[t] for t in lineage if ranks[t] == "family"), None)

    return infraorder, superfamily, family


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="..."
    )
    
    parser.add_argument(
        "--input", "-i",
        type=str,
        required=True,
        help="Input BLAST table (tsv)"
    )
    
    parser.add_argument(
        "--output", "-o",
        type=str,
        required=True,
        help="Output filtered BLAST table (tsv)"
    )
    
    return parser.parse_args()

def main() -> None:
    args = parse_args()
    rows = []
    with open(args.input, 'r') as fh:
        for line in fh:
            if line.startswith('>'):
                content = line.split(" ")
                specie_name = content[0][1:]
                seq_acc = content[1]
                infraorder, superfamily, family = classify_species(specie_name)
                rows.append((specie_name, seq_acc, infraorder, superfamily, family))
    
    rows.sort(key=lambda x: x[0].lower())

    with open(args.output, "w") as fout:
        for species, acc, infraorder, superfamily, family in rows:
            fout.write(f"{species}\t{acc}\t{infraorder}\t{superfamily}\t{family}\n")
    
if __name__ == "__main__":
    main()
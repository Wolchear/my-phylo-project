import argparse
from pathlib import Path

import pandas as pd

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="BLAST hits shared taxa sort script!"
    )
    
    parser.add_argument(
        "--dir", "-d",
        type=str,
        required=True,
        help="Speciefy dir with hit files"
    )
    
    parser.add_argument(
        "--output", "-o",
        type=str,
        required=True,
        help="Speciefy dir to store sorted tables (TSV)"
    )
    
    parser.add_argument(
        "--id-col", "-c",
        type=str,
        default="tax_name",
        help="Column name to use as ID for intersection (default: tax_name)"
    )

    
    return parser.parse_args()

def main() -> None:
    args = parse_args()
    in_dir = Path(args.dir)
    out_dir = Path(args.output)
    out_dir.mkdir(parents=True, exist_ok=True)
    
    id_col = args.id_col

    tsv_files = sorted(in_dir.glob("*.tsv"))
    if not tsv_files:
        raise SystemExit(f"No .tsv files found in {in_dir}")
    
    dfs = {}
    id_sets = []
    
    cols = ["sseqid", "sscinames", "pident", "qcovs", "evalue", "bitscore", "stitle", "tax_name"]
    
    for f in tsv_files:
        df = pd.read_csv(f, sep="\t", header=None, names=cols)

        dfs[f.name] = df
        id_set = set(df[id_col].dropna().unique())
        id_sets.append(id_set)

    common_ids = set.intersection(*id_sets)

    for fname, df in dfs.items():
        filtered = df[df[id_col].isin(common_ids)].copy()
        out_path = out_dir / fname
        filtered.to_csv(out_path, sep="\t", header=False, index=False)


if __name__ == "__main__":
    main()
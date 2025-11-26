import argparse
import sys

import pandas as pd

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="BLAST sequences filtering script!"
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

    parser.add_argument(
        "--min_cov",
        type=float,
        default=70.0,
        help="Minimum query coverage (default: 70)"
    )

    parser.add_argument(
        "--e_value",
        type=float,
        default=1e-20,
        help="Set E-value threshold (default: 1e-20)"
    )
    
    parser.add_argument(
        "--drop_duplicates",
        action="store_true",
        help="Include only one best sequence for each unique taxa (default: False)"
    )
    
    return parser.parse_args()

def main() -> None:
    args = parse_args()

    cols = ["sseqid", "sscinames", "pident", "qcovs", "evalue", "bitscore", "stitle"]

    df = pd.read_csv(args.input, sep="\t", header=None, names=cols)
    df['tax_name'] = df['stitle'].str.extract(r'\[([^\]]+)\]')
    df_filt = df[
        (df["qcovs"] >= args.min_cov) &
        (df["evalue"] <= args.e_value)
    ].copy()

    if df_filt.empty:
        df_filt.to_csv(args.output, sep="\t", header=False, index=False)
        sys.exit(0)

    if args.drop_duplicates:
        df_filt.sort_values(
            by=["bitscore"],
            ascending=False,
            inplace=True
        )

        df_filt = df_filt.drop_duplicates(subset="tax_name", keep="first")

    df_filt.to_csv(args.output, sep="\t", header=False, index=False)
    
if __name__ == "__main__":
    main()
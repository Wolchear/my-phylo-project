import argparse
import subprocess
from pathlib import Path
import re
from typing import Iterator

import pandas as pd

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sequences fetch script!"
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
        "--batch",
        type=int,
        default=100,
        help='Specify number of seq per batch (default: 100)'
    )
    
    parser.add_argument(
        "--data_base", "-db",
        type=str,
        required=True,
        help="Specify database to fetch from"
    )
    
    return parser.parse_args()

def batched(seq, n) -> Iterator: 
    for i in range(0, len(seq), n):
        yield seq[i:i+n]

def extract_accession(id: str) -> str:
    if "|" in id:
        match = re.search(r"\|([^|]+)\|", id)
        return match.group(1).strip()
    return id

def main() -> None:
    args = parse_args()
    
    cols = ["sseqid", "sscinames", "pident", "qcovs", "evalue", "bitscore", "stitle", "tax_name"]
    
    df = pd.read_csv(args.input, sep="\t", header=None, names=cols)
    ids = (
        df['sseqid']
        .map(extract_accession)
        .tolist()
    )
    
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)

    with out.open("w", encoding="utf-8") as fh:
        for chunk in batched(ids, args.batch):
            cmd = ["efetch", "-db", args.data_base, "-id", ",".join(chunk), "-format", "fasta"]
            res = subprocess.run(cmd, check=True, capture_output=True, text=True)
            fh.write(res.stdout)


if __name__ == '__main__':
    main()
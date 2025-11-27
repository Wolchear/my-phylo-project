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
    
    parser.add_argument(
        "--local",
        action="store_true",
        help="Set flag if using local db"
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

def extract_accession_local(id: str) -> str:
    return id.split()[0].strip()

def main() -> None:
    args = parse_args()
    
    cols = ["sseqid", "length", "pident", "qcovs", "evalue", "bitscore", "stitle", "tax_name"]
  
    df = pd.read_csv(args.input, sep="\t", header=None, names=cols)
    df["sseqid"] = df["sseqid"].astype(str)
    # If we are using local db, then out ACC will look like >ACC insted >ref|ACC| with remote
    # In this way, we have to parce id a little in other way
    extractor = extract_accession_local if args.local else extract_accession
    ids = (
        df['sseqid']
        .map(extractor)
        .tolist()
    ) # Get ACC from seqid
    
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    # Just batch download with efetch
    with out.open("w", encoding="utf-8") as fh:
        for chunk in batched(ids, args.batch):
            cmd = ["efetch", "-db", args.data_base, "-id", ",".join(chunk), "-format", "fasta"]
            res = subprocess.run(cmd, check=True, capture_output=True, text=True)
            fh.write(res.stdout)


if __name__ == '__main__':
    main()
import argparse
import re

def parse_args() -> argparse.Namespace:
    """
    Just function to parce arguments..
    """
    parser = argparse.ArgumentParser(
        description="Add taxa name before accession"
    )
    
    parser.add_argument(
        "--input", "-i",
        type=str,
        required=True,
        help="Specify fasta file to modify headers"
    )
    
    parser.add_argument(
        "--output", "-o",
        type=str,
        required=True,
        help="Specify out fasta file"
    )
    
    return parser.parse_args()

def process_header(line: str) -> str:
    """
    Function for header modification.
    
    We are looking for headers with fomat like:
    >acc *something*+ [tax_id]
    
    As an output we will return:
    >tax_id|acc *something*+
    """
    header = line.strip()[1:]

    m = re.search(r"\[([^\]]+)\]\s*$", header)
    if not m:
        return line # if header do not contains taxa name, return as it is

    tax_name = m.group(1).strip()
    tax_name = re.sub(r"\s+", "_", tax_name.strip()) # Replacing space with _ to print it properly with mview
    header_wo_tax = header[:m.start()].rstrip() # Removing [] from tax_id

    parts = header_wo_tax.split(maxsplit=1)
    acc = parts[0]
    rest = parts[1] if len(parts) > 1 else " "

    new_header = f">{tax_name}|{acc} {rest}\n"

    return new_header

def main() -> None:
    args = parse_args()

    # Reading input fasta and in the same moment filling out fasta with data
    with open(args.input, "r") as fh_in, open(args.output, "w") as fh_out:
        for line in fh_in:
            if line.startswith(">"):
                fh_out.write(process_header(line))
            else:
                fh_out.write(line)
    
    
if __name__ == "__main__":
    main()
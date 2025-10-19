#!/usr/bin/env python3

import pandas as pd
import argparse
import sys

def split_csv(input_file, output_prefix, max_records, key):
    """
    Splits a CSV into multiple files based on a grouping key and a maximum record count per file.
    """
    try:
        df = pd.read_csv(input_file)
    except Exception as e:
        print(f"Error reading CSV file: {e}", file=sys.stderr)
        sys.exit(1)

    key = None if key is None else key.split(',')

    if key is not None and not set( df.columns ).issuperset( key ):
        print(f"Error: Column(s) '{key}' not found in input file.", file=sys.stderr)
        sys.exit(1)

    # Produce one group per record when key is None.
    grouped = list(df.groupby( key if key is None else df.index ))

    file_index = 1
    current_chunk = []
    current_count = 0

    i = 0
    while i < len(grouped):
        group_key, group = grouped[i]
        group_size = len(group)

        if group_size > max_records:
            # Oversized group — write separately
            output_file = f"{output_prefix}_{file_index}.csv"
            group.to_csv(output_file, index=False)
            print(f"Wrote {output_file} with {group_size} records (oversized group: {group_key})")
            file_index += 1
            i += 1
        elif current_count + group_size <= max_records:
            current_chunk.append(group)
            current_count += group_size
            i += 1
        else:
            if current_chunk:
                output_file = f"{output_prefix}_{file_index}.csv"
                pd.concat(current_chunk).to_csv(output_file, index=False)
                print(f"Wrote {output_file} with {current_count} records")
                file_index += 1
                current_chunk = []
                current_count = 0

    if current_chunk:
        output_file = f"{output_prefix}_{file_index}.csv"
        pd.concat(current_chunk).to_csv(output_file, index=False)
        print(f"Wrote {output_file} with {current_count} records")


def main():
    parser = argparse.ArgumentParser(description="Split a CSV file by a grouping key, limiting rows per output file.")
    parser.add_argument('--input', required=True, help='Path to input CSV file')
    parser.add_argument('--output-prefix', required=True, help='Prefix for output CSV files')
    parser.add_argument('--max-records', type=int, required=True, help='Maximum number of records per output file')
    parser.add_argument('--key', type=str, required=False, const=None, help='Column name(s) to group by (e.g., id)')

    args = parser.parse_args()

    split_csv(
        input_file=args.input,
        output_prefix=args.output_prefix,
        max_records=args.max_records,
        key=args.key
    )

if __name__ == "__main__":
    main()

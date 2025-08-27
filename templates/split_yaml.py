#!/usr/bin/env python3

import sys
import yaml
import os

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <input_yaml_file>")
        sys.exit(1)

    input_file = sys.argv[1]

    if not os.path.isfile(input_file):
        print(f"Error: File '{input_file}' not found.")
        sys.exit(1)

    with open(input_file, 'r') as f:
        try:
            data = yaml.load(f, Loader=yaml.FullLoader)
        except yaml.YAMLError as e:
            print(f"YAML parsing error: {e}")
            sys.exit(1)

    if not isinstance(data, list):
        print("YAML file does not contain a list at the top level.")
        sys.exit(1)

    count = 1
    for item in data:
        if not isinstance(item, dict) or 'nested' not in item:
            print(f"Skipping item {count}: missing or invalid 'nested' key.")
            continue

        nested_data = item['nested']
        out_file = f"params_{count}.yaml"
        with open(out_file, "w") as out_f:
            yaml.dump(nested_data, out_f, sort_keys=False)
        print(f"Written: {out_file}")
        count += 1

if __name__ == "__main__":
    main()

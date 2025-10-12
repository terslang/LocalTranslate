#!/usr/bin/env python3
import os
import shutil
import json
import gzip
from typing import List
import argparse

MODELS_DIR = "models"
OUT_DIR = "flattened-models"
models_data = {}

def make_out_dir():
    """Create the output directory for flattened models."""
    if os.path.exists(OUT_DIR):
        shutil.rmtree(OUT_DIR)
    
    os.makedirs(OUT_DIR)

def process_models(base_first: bool = False):
    """Process the Firefox translations models and flatten their structure."""
    TINY_MODELS_DIR = f"{MODELS_DIR}/tiny"
    BASE_MEMORY_DIR = f"{MODELS_DIR}/base-memory"
    BASE_DIR = f"{MODELS_DIR}/base"

    models_order = [TINY_MODELS_DIR, BASE_MEMORY_DIR, BASE_DIR] if not base_first else [BASE_DIR, BASE_MEMORY_DIR, TINY_MODELS_DIR]

    for dir in models_order:
        first = True
        for root, _, files in os.walk(dir):
            if first:
                first = False
                continue

            copy_model_files(root, files)

def copy_model_files(dir_path: str, model_files: List[str]):
    """Process the model files in a given directory and store their metadata."""
    lang_code = dir_path.split("/")[-1]
    if lang_code not in models_data:
        models_data[lang_code] = {}

        for file in model_files:
            for prefix in ["model", "lex", "vocab", "srcvocab", "trgvocab"]:
                if file.startswith(prefix):
                    file_path = os.path.join(dir_path, file)
                    
                    # Check if the file is gzipped and decompress it if necessary
                    if file.endswith(".gz"):
                        with gzip.open(file_path, 'rb') as f_in:
                            file_path = f"{file_path[:-3]}"
                            with open(file_path, 'wb') as f_out:
                                shutil.copyfileobj(f_in, f_out)

                        size = os.path.getsize(file_path)
                        shutil.copy(file_path, OUT_DIR)
                        models_data[lang_code][prefix] = {"name": file[:-3], "size": size}
                        
                        if not args.silent:
                            print(f"processed {file}")

def write_to_registry_file():
    """Write the models data to a registry file."""
    with open(os.path.join(OUT_DIR, "registry.json"), "w") as f:
        json.dump(dict(sorted(models_data.items())), f, indent=4)

def copy_license_file():
    """Copy the license file to the output directory."""
    LICENSE_FILE = "LICENSE"
    if os.path.exists(LICENSE_FILE):
        shutil.copy(LICENSE_FILE, OUT_DIR)
        if not args.silent:
            print(f"Copied {LICENSE_FILE} to {OUT_DIR}.")
    else:
        print(f"Warning: {license_file} not found, skipping copy.")

def main(args):
    make_out_dir()
    process_models(args.base_first)
    write_to_registry_file()
    copy_license_file()
    print("Done processing models.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Process Firefox translation models.")
    parser.add_argument(
        "-bf",
        "--base-first",
        default=False,
        action="store_true",
        help="Process base models first. Default behavior is to process tiny models first.")
    parser.add_argument(
        "-s",
        "--silent",
        default=False,
        action="store_true",
        help="Suppress output messages.")

    args = parser.parse_args()
    main(args)

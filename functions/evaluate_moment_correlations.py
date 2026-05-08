#!/usr/bin/env python3

"""
Batch evaluation of spatial correlations between subject-specific and
normative MPmoments.

Automatically detects all subject MPmoments files in a directory and
computes spatial Pearson correlations for matching moment rows.

Expected filename pattern:
    sub-XXX_space-fsaverage5_desc-MPmoments.csv

Normative file example:
    grp-MICs_space-fsaverage5_desc-MPmoments.csv
"""

import os
import argparse
import pandas as pd
import numpy as np
from scipy.stats import pearsonr
import re


def load_csv(path):
    """Load MPmoments CSV with first column as row index."""
    return pd.read_csv(path, index_col=0)


def compute_spatial_correlations(subject_df, normative_df):
    """
    Compute Pearson correlations between matching moment rows.
    Returns dictionary {moment: r}.
    """
    correlations = {}

    common_moments = subject_df.index.intersection(normative_df.index)
    if len(common_moments) == 0:
        raise ValueError("No matching moment rows found.")

    for moment in common_moments:
        subj_values = subject_df.loc[moment].values.astype(float)
        norm_values = normative_df.loc[moment].values.astype(float)

        if subj_values.shape != norm_values.shape:
            raise ValueError(f"Shape mismatch for moment {moment}")

        r, _ = pearsonr(subj_values, norm_values)
        correlations[moment] = r

    return correlations


def find_subject_files(mp_dir):
    """
    Identify all subject MPmoments files in directory.
    """
    pattern = re.compile(r"(sub-[^_]+)_space-fsaverage5_desc-MPmoments\.csv$")
    subject_files = {}

    for fname in os.listdir(mp_dir):
        match = pattern.match(fname)
        if match:
            subject_id = match.group(1)
            subject_files[subject_id] = os.path.join(mp_dir, fname)

    return subject_files


def main():
    parser = argparse.ArgumentParser(
        description="Batch compute spatial correlations of MPmoments against normative reference."
    )
    parser.add_argument("--mp-dir", required=True,
                        help="Directory containing subject MPmoments CSV files.")
    parser.add_argument("--normative-file", required=True,
                        help="Path to normative MPmoments CSV.")
    parser.add_argument("--output-dir", required=True,
                        help="Directory to store correlation results.")

    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    print("Loading normative reference...")
    normative_df = load_csv(args.normative_file)

    subject_files = find_subject_files(args.mp_dir)

    if len(subject_files) == 0:
        raise ValueError("No subject MPmoments files found in directory.")

    print(f"Found {len(subject_files)} subjects.")

    all_results = []

    for subject_id, subject_path in sorted(subject_files.items()):
        print(f"Processing {subject_id}...")

        subject_df = load_csv(subject_path)
        correlations = compute_spatial_correlations(subject_df, normative_df)

        subj_df = pd.DataFrame.from_dict(
            correlations, orient="index", columns=["pearson_r"]
        )
        subj_df.index.name = "moment"
        subj_df["subject"] = subject_id

        # Store for group summary
        for moment, r in correlations.items():
            all_results.append({
                "subject": subject_id,
                "moment": moment,
                "pearson_r": r
            })

    # Group summary table
    group_df = pd.DataFrame(all_results)
    group_out = os.path.join(
        args.output_dir,
        "group_desc-MPmoments_spatialcorrelations.csv"
    )
    group_df.to_csv(group_out, index=False)

    print("Done.")
    print(f"Group summary saved to: {group_out}")


if __name__ == "__main__":
    main()
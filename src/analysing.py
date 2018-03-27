# -*- coding: utf-8 -*-
# Copyright: Johanna de Vos (2018)

import argparse
import os

import pandas as pd

import preprocessing as prep


def create_pandas_df(lca_results_dir, filename):
    """A function that reads the LCA results (per exam) from a CSV file into
    a pandas DataFrame."""
    
    # NB: Make sure that the text file is encoded in UTF-8    
    df = pd.read_csv(os.path.join(lca_results_dir, filename), sep = ",")
    df.set_index('subjectcode', inplace = True) # Set subject code as index
    
    # Check whether all subject codes are unique
    if len(set(list(df.index))) != len(df):
        print("WARNING: Some subject codes occur more than once.")
        
    return df


def filter_df(df, measures):
    """A function that subsets only those columns (i.e., LCA measures) we are
    interested in, and in addition only includes writing samples with fifty
    words or more.""" 
    
    # Only use selected measures
    df = df.loc[: , measures]
    
    # Remove empty entries
    #df = df[df.wordtokens != 0]
    
    return df


def merge_df(exam, subject_info):
    pass


def diff_same_lang(df1, df2, measures):
    """A function that creates a new pandas DataFrame which contains the
    difference on the selected LCA measures between two exams."""
    
    # Create list of subject codes that are present in both datasets
    subs = [index for index in list(df1.index) if index in 
        list(df2.index)]
    
    # Create empty dataframe
    df_diff = pd.DataFrame(index=subs, columns = measures)
    
    for subj in df_diff.index:
        for col in df_diff.columns:
            diff = df2.loc[subj, col] - df1.loc[subj, col]     
            df_diff.at[subj, col] = diff
    
    print(df_diff[measures].mean())
    
    return df_diff


def diff_other_lang(df1, df2, measures):
    """A function that calculates the mean on all measures for both exams, 
    and then calculates the difference between the means."""
    
    means1 = df1[measures].mean()
    means2 = df2[measures].mean()
    
    diff_means = means2 - means1
    print(diff_means)

#pd.set_option('display.max_columns', None)
#pd.set_option('display.max_rows', None)


### --------
### RUN CODE
### --------

#def main():
#if __name__ == "__main__":
    
# Parse arguments
parser = argparse.ArgumentParser()
parser.add_argument("exam1", help = "The first exam in the comparison.")
parser.add_argument("exam2", help = "The second exam in the comparison.")
parser.add_argument("--truncation", help = "Should the LCA be performed on samples \
                    that were truncated at the same length?", choices = 
                    ["yes", "no"], default = "yes")
parser.add_argument("--nationality", help = "For which nationality do you \
                    want to perform the analysis?", choices = ["DU", "NL"], 
                    default = "NL")

args = parser.parse_args()
name_exam1 = args.exam1
name_exam2 = args.exam2
trunc = args.truncation
natio = args.nationality
    
# Define directories
src_dir = os.path.dirname(os.path.abspath(__file__))
data_dir = os.path.join(src_dir, '..', 'data')
results_dir = os.path.join(src_dir, '..', 'results')

if trunc == "yes":
    lca_results_dir = os.path.join(results_dir, 'lca_truncated')
elif trunc == "no":
    lca_results_dir = os.path.join(results_dir, 'lca_untruncated')

# Create dataframes with LCA results for the two exams
exam1 = create_pandas_df(lca_results_dir, name_exam1)
exam2 = create_pandas_df(lca_results_dir, name_exam2)

# Establish the language each exam was written in
if "EN" in name_exam1:
    lang1 = "EN"
elif "NL" in name_exam1:
    lang1 = "NL"

if "EN" in name_exam2:
    lang2 = "EN"
elif "NL" in name_exam2:
    lang2 = "NL"

# Read in subject info
subject_info = prep.read_subject_info(data_dir)

# Define required measures
sel_measures = ['ld', 'ls2', 'vs2', 'ndwesz', 'cttr', 'svv1']
all_measures = list(exam1.columns)

# Optionally, apply filters
filtered_exam1 = filter_df(exam1, sel_measures)
filtered_exam2 = filter_df(exam2, sel_measures)

# Join dataframes
data1 = exam1.join(subject_info)
data2 = exam2.join(subject_info)

# Compare the two exams
print("Calculating:", name_exam2[:-4], "minus", name_exam1[:-4], "\n")

if lang1 == lang2:
    diff_same_lang(data1, data2, all_measures)
    #diff_same_lang(exam1, exam2, all_measures)
elif lang1 != lang2:
    diff_other_lang(data1, data2, sel_measures)
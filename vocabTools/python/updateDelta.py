import os
import sys

# Check if pandas is installed
try:
    import pandas as pd
except ImportError:
    sys.exit("Error: The 'pandas' library is not installed. Please install it using 'pip install pandas'.")

# Get the directory where the script is located
script_dir = os.path.dirname(os.path.abspath(__file__))

# Define the file paths for your CSV files relative to the script's location
delta_concept_path = os.path.join(script_dir, "../output/deltaConcept.csv")
delta_concept_relationship_path = os.path.join(script_dir, "../output/deltaConceptRelationship.csv")

concept_dir = os.path.join(script_dir, "../concept") 
concept_relationship_dir = os.path.join(script_dir, "../concept_relationship") 

# Initialize an empty DataFrame to store the merged data
merged_concept = pd.DataFrame()
merged_concept_relationship = pd.DataFrame()

# List all CSV files in the directory
concept_files = [file for file in os.listdir(concept_dir) if file.endswith(".csv")]
concept_relationship_files = [file for file in os.listdir(concept_relationship_dir) if file.endswith(".csv")]

# Loop through each CSV file and merge it into the merged_df
for csv_file in concept_files:
    csv_path = os.path.join(concept_dir, csv_file)
    df = pd.read_csv(csv_path)
    merged_concept = pd.concat([merged_concept, df], ignore_index=True)

# Loop through each CSV file and merge it into the merged_df
for csv_file in concept_relationship_files:
    csv_path = os.path.join(concept_relationship_dir, csv_file)
    df = pd.read_csv(csv_path)
    merged_concept_relationship = pd.concat([merged_concept_relationship, df], ignore_index=True)

# Continue with the rest of your script
# ...

# Read and merge CSV files using the full paths
delta_concept = pd.read_csv(delta_concept_path)
delta_concept_relationship = pd.read_csv(delta_concept_relationship_path)

merged_concept = pd.concat([delta_concept, merged_concept], ignore_index=True)
merged_concept_relationship = pd.concat([delta_concept_relationship, merged_concept_relationship], ignore_index=True)

# Remove exact duplicates
merged_concept.drop_duplicates(inplace=True)
merged_concept_relationship.drop_duplicates(inplace=True)

# TODO are there other validation tests to add at this point?
# These would be specific to the data being merged (e.g. contradicting relationships, etc.)

# Save the final merged data to a CSV file
merged_concept_path = os.path.join(script_dir, "../output/deltaConcept.csv")
merged_concept_relationship_path = os.path.join(script_dir, "../output/deltaConceptRelationship.csv")

merged_concept.to_csv(merged_concept_path, index=False)
merged_concept_relationship.to_csv(merged_concept_relationship_path, index=False)

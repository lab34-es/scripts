#!/bin/bash

# --- Configuration ---
# Search terms are now passed as command-line arguments
# Example Usage: ./script_name.sh term1 term2 term3
# --- End Configuration ---

# Exit script on error
set -e
# Ensure pipelines report failure status
set -o pipefail

# --- Argument Handling ---
if [ "$#" -eq 0 ]; then
    # Print usage instructions to standard error
    echo "Usage: $0 <search_term1> [search_term2] ..." >&2
    echo "Error: Please provide at least one search term argument." >&2
    echo "       The script will find Lambda functions containing ALL provided terms in their name." >&2
    exit 1
fi

# Store all command-line arguments in an array
search_terms=("$@")
# Inform the user which terms are being searched for
echo "Searching for Lambda functions containing ALL terms: ${search_terms[*]}" >&2
# --- End Argument Handling ---


# --- Dependency Checks ---
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI not found. Please install and configure it." >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq not found. Please install jq (e.g., 'sudo apt-get install jq' or 'brew install jq')." >&2
    exit 1
fi
# --- End Dependency Checks ---


# --- Build JMESPath Query Dynamically ---
# Initialize an empty string to build the filter conditions
filter_conditions=""
# Loop through each search term provided as an argument
is_first_term=true
for term in "${search_terms[@]}"; do
    # Basic sanitization: escape single quotes within the term for safe use in JMESPath query
    # Replaces ' with '\'' within the string
    safe_term=$(echo "$term" | sed "s/'/'\\\\''/g")

    # Construct the 'contains' clause for the current term
    current_clause="contains(FunctionName, '$safe_term')"

    if [ "$is_first_term" = true ]; then
        # For the first term, just assign the clause
        filter_conditions="$current_clause"
        is_first_term=false
    else
        # For subsequent terms, prepend " && "
        filter_conditions="$filter_conditions && $current_clause"
    fi
done

# Construct the final AWS CLI --query argument string
aws_query="Functions[?$filter_conditions].{Name:FunctionName, Runtime:Runtime, Role:Role}"
# --- End Query Building ---


# Get the list of functions using the dynamically built query
echo "Executing AWS CLI command..." >&2
functions_json=$(aws lambda list-functions \
    --query "$aws_query" \
    --output json)

# Check if any functions were found (check before sorting)
# Use the arguments array in the message
if [[ -z "$functions_json" || "$functions_json" == "[]" ]]; then
    echo "No Lambda functions found containing ALL terms: ${search_terms[*]}" >&2
    exit 0
fi

# Sort the functions alphabetically by name using jq
echo "Sorting functions alphabetically..." >&2
sorted_functions_json=$(echo "$functions_json" | jq 'sort_by(.Name)')

echo "Outputting in nested list format..." >&2
# --- No Table Header Needed ---

# Process each function found using the SORTED JSON
echo "$sorted_functions_json" | jq -c '.[]' | while IFS= read -r line; do
    func_name=$(echo "$line" | jq -r '.Name')
    runtime=$(echo "$line" | jq -r '.Runtime')
    role_arn=$(echo "$line" | jq -r '.Role')
    role_name=${role_arn##*/} # Extract role name from ARN

    # Check if it's a NodeJS runtime before proceeding
    if [[ "$runtime" == nodejs* ]]; then

        # Print function details in the specified list format
        printf -- "- %s\n" "$func_name"
        printf "  - node: %s\n" "$runtime"
        printf "  - role: %s\n" "$role_name"
        printf "  - env vars:\n"

        # Get environment variables for the specific function
        env_vars_json=$(aws lambda get-function-configuration \
            --function-name "$func_name" \
            --query "Environment.Variables" \
            --output json 2>/dev/null || echo "null")

        # Start the Markdown code block (indented)
        printf "    \`\`\`\n"

        # Check if env_vars_json is not null, not empty, and not an empty object {}
        if [[ -n "$env_vars_json" && "$env_vars_json" != "null" && "$env_vars_json" != "{}" ]]; then
            # Sort env vars by key and print inside the block
            echo "$env_vars_json" | jq -r 'to_entries | sort_by(.key)[] | "\(.key)=\(.value)"' | sed 's/^/    /'
        else
            # If no env vars exist, print "None" inside the block
            printf "    None\n"
        fi

        # End the Markdown code block
        printf "    \`\`\`\n"
        printf "\n" # Optional blank line

    fi # End NodeJS check
done # End function loop

echo "Script finished." >&2

# AWS Lambda NodeJS Function Lister

## Description

This script queries AWS Lambda to find functions based on fragments of their names, specifically filtering for those using a NodeJS runtime. It then outputs details for each matching function, including its full name, NodeJS runtime version, execution role name, and environment variables.

The script requires functions to contain **all** specified search terms (provided as command-line arguments) in their names to be included in the results. The output is formatted as a nested Markdown list for easy readability and is sorted alphabetically by function name. Environment variables are also sorted alphabetically by key within their respective code blocks.

This script is designed to output Markdown formatted text directly to standard output. To create an actual Markdown file, redirect the script's output.

## Prerequisites

Before running this script, ensure you have the following installed and configured:

1.  **AWS CLI:** The AWS Command Line Interface must be installed and configured with valid credentials and a default region. You can configure it by running `aws configure`.
    * [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2.  **jq:** A lightweight command-line JSON processor. This script uses `jq` for parsing and sorting the JSON responses from the AWS CLI.
    * Install on Debian/Ubuntu: `sudo apt-get update && sudo apt-get install jq`
    * Install on macOS (using Homebrew): `brew install jq`
    * [Other jq Installation Methods](https://stedolan.github.io/jq/download/)

## Required AWS Permissions

The AWS credentials used by the script need permissions for the following IAM actions:

* `lambda:ListFunctions`
* `lambda:GetFunctionConfiguration`

Attach a policy with these permissions to the relevant IAM user or role.

## Usage

1.  Save the script to a file (e.g., `list_lambdas.sh`).
2.  Make the script executable: `chmod +x list_lambdas.sh`.
3.  Run the script, providing one or more search terms as command-line arguments. The script will find functions whose names contain *all* the provided terms.
4.  **Important:** Redirect the output to a file to create the Markdown document.

**Command Format:**

```bash
./list_lambdas.sh <search_term1> [search_term2] ... > output_report.md
```

## Example output

```
- **function-alpha-term1-term2**
  - nodejs18.x
  - my-lambda-role-alpha
  - ```
    API_ENDPOINT=https://api.example.com/alpha
    DATABASE_TABLE=alpha_table
    LOG_LEVEL=INFO
    ```

- **function-beta-term1-term2**
  - nodejs20.x
  - my-lambda-role-beta
  - ```
    API_ENDPOINT=https://api.example.com/beta
    DATABASE_TABLE=beta_table
    LOG_LEVEL=WARN
    NEW_FEATURE_FLAG=true
    ```

- **function-gamma-term1-term2-no-vars**
  - nodejs18.x
  - my-lambda-role-gamma
  - ```
    None
    ```
```
```

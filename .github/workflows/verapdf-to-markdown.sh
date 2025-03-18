#!/bin/bash

search_dir=$1
pdf_files=$(find $search_dir -maxdepth 1 -type f -name "*.pdf")

# global counters
total_files=0
non_compliant_files=0
total_checks=0
failed_checks=0

get_markdown_from_jsonresult() {
    local json_file=$1
    local f_name=$(jq -r '.report.jobs[].itemDetails.name' $json_file)
    local f_size=$(jq -r '.report.jobs[].itemDetails.size' $json_file)
    local f_passed_rules=$(jq -r '.report.jobs[].validationResult.details.passedRules' $json_file)
    local f_failed_rules=$(jq -r '.report.jobs[].validationResult.details.failedRules' $json_file)
    local f_passed_checks=$(jq -r '.report.jobs[].validationResult.details.passedChecks' $json_file)
    local f_failed_checks=$(jq -r '.report.jobs[].validationResult.details.failedChecks' $json_file)
    local f_statement=$(jq -r '.report.jobs[].validationResult.statement' $json_file)
    local f_compliant=$(jq -r '.report.jobs[].validationResult.compliant' $json_file)
    echo "## $f_name"
    echo "$f_statement"
    echo "| Name | Value |"
    echo "| --- | --- |"
    echo "| Size | $f_size |"
    echo "| Passed Rules | $f_passed_rules |"
    echo "| Failed Rules | $f_failed_rules |"
    echo "| Passed Checks | $f_passed_checks |"
    echo "| Failed Checks | $f_failed_checks |"

    # update global counters
    total_files=$((total_files + 1))
    total_checks=$((total_checks + f_passed_checks + f_failed_checks))
    failed_checks=$((failed_checks + f_failed_checks))
    if [ "$f_compliant" == "false" ]; then
        non_compliant_files=$((non_compliant_files + 1))
    fi
}

print_total_results() {
    echo "## Summary"
    echo "| Name | Value |"
    echo "| --- | --- |"
    echo "| Total Files | $total_files |"
    echo "| Total Checks | $total_checks |"
    echo "| Failed Checks | $failed_checks |"
    echo "| Non-compliant Files | $non_compliant_files |"
    if [ $non_compliant_files -gt 0 ]; then
        echo "### :x: The repository contains non-compliant PDF files"
    else
        echo "### :white_check_mark: The repository contains only compliant PDF files"
    fi
}

echo "# Verapdf Compliance Report"

for pdf_file in $pdf_files; do
    jsonname="${pdf_file%.pdf}.pdfa-2b-complience.json"
    verapdf --format json -f 2b "$pdf_file" >$jsonname 2>/dev/null
    get_markdown_from_jsonresult $jsonname
done

if ((total_files == 0)); then
    echo "No PDF files found in the output directory"
    exit 0
fi

if ((total_files > 0)); then
    print_total_results
fi

if ((non_compliant_files > 0)); then
    exit 1
fi

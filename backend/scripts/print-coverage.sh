#!/bin/sh
# Print JaCoCo coverage summary to console

JACOCO_CSV="target/site/jacoco/jacoco.csv"

if [ ! -f "$JACOCO_CSV" ]; then
    echo "⚠️  Coverage report not found at $JACOCO_CSV"
    exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 CODE COVERAGE REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Parse CSV and calculate totals (skip header and last line which is the total)
INSTRUCTION_MISSED=0
INSTRUCTION_COVERED=0
BRANCH_MISSED=0
BRANCH_COVERED=0
LINE_MISSED=0
LINE_COVERED=0
METHOD_MISSED=0
METHOD_COVERED=0

# Read CSV, skip header (line 1) and process data lines
tail -n +2 "$JACOCO_CSV" | while IFS=, read -r GROUP PACKAGE CLASS INSTRUCTION_MISSED INSTRUCTION_COVERED BRANCH_MISSED BRANCH_COVERED LINE_MISSED LINE_COVERED COMPLEXITY_MISSED COMPLEXITY_COVERED METHOD_MISSED METHOD_COVERED; do
    # Accumulate totals (this is done in the subshell, so we'll use a different approach)
    :
done

# Better approach: use awk to sum the columns
TOTALS=$(awk -F, 'NR>1 {
    inst_miss+=$4; inst_cov+=$5;
    branch_miss+=$6; branch_cov+=$7;
    line_miss+=$8; line_cov+=$9;
    method_miss+=$12; method_cov+=$13
}
END {
    print inst_miss, inst_cov, branch_miss, branch_cov, line_miss, line_cov, method_miss, method_cov
}' "$JACOCO_CSV")

read INSTRUCTION_MISSED INSTRUCTION_COVERED BRANCH_MISSED BRANCH_COVERED LINE_MISSED LINE_COVERED METHOD_MISSED METHOD_COVERED <<EOF
$TOTALS
EOF

# Calculate totals and percentages
INSTRUCTION_TOTAL=$((INSTRUCTION_MISSED + INSTRUCTION_COVERED))
BRANCH_TOTAL=$((BRANCH_MISSED + BRANCH_COVERED))
LINE_TOTAL=$((LINE_MISSED + LINE_COVERED))
METHOD_TOTAL=$((METHOD_MISSED + METHOD_COVERED))

# Calculate percentages (avoid division by zero)
if [ "$INSTRUCTION_TOTAL" -gt 0 ]; then
    INSTRUCTION_PCT=$((INSTRUCTION_COVERED * 100 / INSTRUCTION_TOTAL))
else
    INSTRUCTION_PCT=0
fi

if [ "$BRANCH_TOTAL" -gt 0 ]; then
    BRANCH_PCT=$((BRANCH_COVERED * 100 / BRANCH_TOTAL))
else
    BRANCH_PCT=100
fi

if [ "$LINE_TOTAL" -gt 0 ]; then
    LINE_PCT=$((LINE_COVERED * 100 / LINE_TOTAL))
else
    LINE_PCT=0
fi

if [ "$METHOD_TOTAL" -gt 0 ]; then
    METHOD_PCT=$((METHOD_COVERED * 100 / METHOD_TOTAL))
else
    METHOD_PCT=0
fi

# Print table
printf "  %-20s %10s %10s %10s\n" "Metric" "Covered" "Total" "Coverage"
echo "  ────────────────────────────────────────────────────────────────"
printf "  %-20s %10s %10s %9s%%\n" "Instructions" "$INSTRUCTION_COVERED" "$INSTRUCTION_TOTAL" "$INSTRUCTION_PCT"
printf "  %-20s %10s %10s %9s%%\n" "Branches" "$BRANCH_COVERED" "$BRANCH_TOTAL" "$BRANCH_PCT"
printf "  %-20s %10s %10s %9s%%\n" "Lines" "$LINE_COVERED" "$LINE_TOTAL" "$LINE_PCT"
printf "  %-20s %10s %10s %9s%%\n" "Methods" "$METHOD_COVERED" "$METHOD_TOTAL" "$METHOD_PCT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if coverage is 100%
if [ "$INSTRUCTION_PCT" -eq 100 ] && [ "$BRANCH_PCT" -eq 100 ] && [ "$LINE_PCT" -eq 100 ] && [ "$METHOD_PCT" -eq 100 ]; then
    echo "✅ Excellent! 100% code coverage maintained!"
else
    echo "⚠️  Coverage below 100% - consider adding more tests"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📄 Full report: target/site/jacoco/index.html"
echo ""

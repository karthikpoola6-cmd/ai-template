#!/bin/bash
set -e

# Colors
CYAN='\033[36m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# Create tmp directory for reports
mkdir -p tmp/reports

REPORT_FILE="tmp/reports/test-report.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
FAILED=0

# Start report
cat > "$REPORT_FILE" << EOF
# Test Report

**Generated:** $TIMESTAMP

---

EOF

echo -e "${CYAN}Running all tests...${RESET}"

# Test Go packages
echo "## Go Tests" >> "$REPORT_FILE"
if find . -name "go.mod" -type f -not -path "./v0/*" -not -path "./.template/*" | grep -q .; then
    echo -e "${CYAN}Testing Go packages...${RESET}"
    if go test ./... -v 2>&1 | tee /tmp/go-test.log; then
        echo "✅ **PASSED**" >> "$REPORT_FILE"
        echo -e "${GREEN}✓${RESET} Go tests passed"
    else
        echo "❌ **FAILED**" >> "$REPORT_FILE"
        echo -e "${RED}✗${RESET} Go tests failed"
        FAILED=1
    fi
else
    echo "_No Go packages found_" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Test Python packages
echo "## Python Tests" >> "$REPORT_FILE"
PYTHON_TESTED=false

# Check for pytest
if command -v pytest &> /dev/null; then
    # Test root pyproject.toml
    if [ -f "pyproject.toml" ]; then
        PYTHON_TESTED=true
        echo -e "${CYAN}Testing Python packages...${RESET}"
        if pytest -v --tb=short 2>&1 | tee /tmp/python-test.log; then
            echo "✅ **PASSED**" >> "$REPORT_FILE"
            echo -e "${GREEN}✓${RESET} Python tests passed"
        else
            echo "❌ **FAILED**" >> "$REPORT_FILE"
            echo -e "${RED}✗${RESET} Python tests failed"
            FAILED=1
        fi
    fi

    # Test service-specific packages
    for dir in $(find pkg/python services/python -name "pyproject.toml" 2>/dev/null | xargs -r dirname | sort -u); do
        if [ -d "$dir" ]; then
            PYTHON_TESTED=true
            echo "### $(basename $dir)" >> "$REPORT_FILE"
            if (cd "$dir" && pytest -v --tb=short 2>&1); then
                echo "✅ Passed" >> "$REPORT_FILE"
            else
                echo "❌ Failed" >> "$REPORT_FILE"
                FAILED=1
            fi
        fi
    done
fi

if [ "$PYTHON_TESTED" = false ]; then
    echo "_No Python test packages found_" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Summary
echo "---" >> "$REPORT_FILE"
if [ $FAILED -eq 0 ]; then
    echo "## ✅ Result: PASSED" >> "$REPORT_FILE"
    echo -e "${GREEN}✅ All tests passed${RESET}"
else
    echo "## ❌ Result: FAILED" >> "$REPORT_FILE"
    echo -e "${RED}❌ Tests failed${RESET}"
fi

echo -e "${CYAN}📊 Report: $REPORT_FILE${RESET}"

exit $FAILED

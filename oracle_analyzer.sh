#!/usr/bin/env bash
# Adam OS Project Oracle - v1.2
# Full project tomography and analysis system

set -eo pipefail

# Configuration
OUTPUT_FILE="${OUTPUT_FILE:-oracle_report.json}"
TEMP_DIR=$(mktemp -d -t adam-oracle-XXXXXX)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Dependency checks
check_deps() {
    local missing=()
    for dep in tree cloc jq git grep find; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing dependencies: ${missing[*]}"
        echo "Install with:"
        echo "  Debian/Ubuntu: sudo apt-get install -y tree cloc jq git grep findutils"
        echo "  macOS: brew install tree cloc jq git grep findutils"
        exit 1
    fi
}

# Main analysis functions
analyze_filesystem() {
    echo "📂 Analyzing file structure..."
    tree -a -I '.git|node_modules|venv|.venv|__pycache__' -L 3 -J 2>/dev/null > "$TEMP_DIR/file_tree.json"
}

analyze_codebase() {
    echo "📊 Calculating code metrics..."
    cloc --quiet --json . 2>/dev/null > "$TEMP_DIR/cloc.json"
}

analyze_dependencies() {
    echo "🧩 Identifying dependencies..."
    
    # Node.js
    if [ -f "package.json" ]; then
        jq '{dependencies: .dependencies, devDependencies: .devDependencies}' package.json > "$TEMP_DIR/node_deps.json"
    fi

    # Python
    if [ -f "requirements.txt" ]; then
        pip freeze --local | awk -F= '{print $1}' > "$TEMP_DIR/python_deps.txt"
    fi
}

analyze_environment() {
    echo "🔧 Detecting environment configuration..."
    {
        grep -rhE '^export [A-Z_]' .env* 2>/dev/null || true
        find . -type f \( -name '*docker*' -o -name '*compose*' \) -exec grep -hiE 'ENV [A-Z_]+' {} + 2>/dev/null || true
    } | sort -u > "$TEMP_DIR/env_vars.txt"
}

analyze_architecture() {
    echo "🏗 Inferring system architecture..."
    {
        # Docker analysis
        find . -type f \( -name 'Dockerfile*' -o -name '*compose*.yml' \) -exec grep -hiE 'FROM|image:' {} +
        
        # Service endpoints
        find . -type f \( -name '*.js' -o -name '*.py' -o -name '*.yaml' \) -exec grep -hiE 'http(s)?://[^"'\'' ]+' {} +
    } 2>/dev/null | sort -u > "$TEMP_DIR/architecture.txt"
}

analyze_git() {
    if [ -d ".git" ]; then
        echo "🔄 Analyzing repository history..."
        {
            echo "## Branches ##"
            git branch -av
            
            echo "## Recent Commits ##"
            git log --oneline -n 5
            
            echo "## Status ##"
            git status -s
        } > "$TEMP_DIR/git_state.txt"
    fi
}

generate_report() {
    echo "📦 Synthesizing final report..."
    python3 - <<EOF
import json, os, sys

def load_file(path):
    if not os.path.exists(path): return None
    with open(path) as f:
        return f.read() if path.endswith('.txt') else json.load(f)

report = {
    "filesystem": load_file("$TEMP_DIR/file_tree.json"),
    "code_metrics": load_file("$TEMP_DIR/cloc.json"),
    "dependencies": {
        "node": load_file("$TEMP_DIR/node_deps.json"),
        "python": load_file("$TEMP_DIR/python_deps.txt")
    },
    "environment": load_file("$TEMP_DIR/env_vars.txt"),
    "architecture": load_file("$TEMP_DIR/architecture.txt"),
    "git_state": load_file("$TEMP_DIR/git_state.txt"),
    "system": {
        "cwd": os.getcwd(),
        "user": os.getenv("USER"),
        "timestamp": $(date +%s)
    }
}

with open("$OUTPUT_FILE", "w") as f:
    json.dump(report, f, indent=2)
EOF
}

# Main execution flow
main() {
    check_deps
    
    echo "🔍 Adam Oracle Analysis Started"
    echo "📁 Project Directory: $(pwd)"
    echo "📄 Output File: $OUTPUT_FILE"
    
    analyze_filesystem
    analyze_codebase
    analyze_dependencies
    analyze_environment
    analyze_architecture
    analyze_git
    
    generate_report
    
    echo "✅ Analysis Complete! Report saved to $OUTPUT_FILE"
}

# Handle help/usage
if [[ "$1" =~ ^-h|--help ]]; then
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo "Options:"
    echo "  -o FILE    Output file (default: oracle_report.json)"
    echo "  -h         Show this help"
    exit 0
fi

# Run with user confirmation
read -rp "🔒 This will analyze the current directory. Continue? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    main
else
    echo "❌ Analysis cancelled"
    exit 1
fi

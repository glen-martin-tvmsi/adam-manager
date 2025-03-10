#!/usr/bin/env bash
# Adam OS Project Oracle - v1.2
# Full project tomography and analysis system

set -eo pipefail

# Configuration
OUTPUT_FILE="./oracle_report.json"
TEMP_DIR="/tmp/adam-oracle"  # Consistent temporary directory path
trap 'rm -rf "$TEMP_DIR"' EXIT

# Ensure the temporary directory exists and is clean
prepare_temp_dir() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    mkdir -p "$TEMP_DIR"
}

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

analyze_filesystem() {
    echo "📂 Analyzing file structure..."
    tree -a -I '.git|node_modules|venv|__pycache__' -L 3 > "$TEMP_DIR/file_tree.txt"
    cat "$TEMP_DIR/file_tree.txt" # Debugging output
}


analyze_codebase() {
    echo "📊 Calculating code metrics..."
    cloc --quiet --json . > "$TEMP_DIR/cloc.json"
    
    # File type breakdown (debugging)
    find . -type f | awk -F. '{print $NF}' | sort | uniq -c > "$TEMP_DIR/file_types.txt"
}


analyze_dependencies() {
    echo "🧩 Identifying dependencies..."
    
    # Node.js dependencies
    if [ -f "package.json" ]; then
        jq '.dependencies' package.json > "$TEMP_DIR/node_deps.json"
        echo "Node.js dependencies detected."
    else
        echo "No package.json found."
    fi

    # Python dependencies
    if [ -f "requirements.txt" ]; then
        pip freeze > "$TEMP_DIR/python_deps.txt"
        echo "Python dependencies detected."
    else
        echo "No requirements.txt found."
    fi
}



analyze_environment() {
    echo "🔧 Detecting environment configuration..."
    {
        find . -type f \( -name "*.env" \) -exec cat {} + || true
        env | grep -E '^[A-Z_]+=' || true
    } > "$TEMP_DIR/env_vars.txt"
}


analyze_architecture() {
    echo "🏗 Inferring system architecture..."
    {
        find . -type f \( -name "Dockerfile*" -o -name "*.yml" \) \
            -exec grep -hiE 'FROM|image:' {} + || true
    } > "$TEMP_DIR/architecture.txt"
}


generate_knowledge_graph() {
    echo "🧠 Generating knowledge graph..."
    
    # Call the Python script and save its output to a temporary file.
    python3 codebase_knowledge_graph.py --input "$TEMP_DIR/file_tree.json" \
                                        --output "$TEMP_DIR/knowledge_graph.json"
}

analyze_git() {
    if [ -d ".git" ]; then
        git branch > "$TEMP_DIR/git_branches.txt"
        git log --oneline > "$TEMP_DIR/git_commits.txt"
        git status --short > "$TEMP_DIR/git_status.txt"
        git diff --cached > "$TEMP_DIR/git_staged_diff.txt"
    else
        echo "No Git repository found."
    fi
}


generate_report() {
    echo "📦 Synthesizing final report..."
    python3 - <<EOF
import json, os

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
    "knowledge_graph": load_file("$TEMP_DIR/knowledge_graph.json"),
}

with open("$OUTPUT_FILE", "w") as f:
    json.dump(report, f, indent=2)

print(f"Report written to: {os.path.abspath('$OUTPUT_FILE')}")
EOF
}

# Main execution flow
main() {
    check_deps
    prepare_temp_dir  # Ensure consistent temp directory setup
    
    echo "🔍 Adam Oracle Analysis Started"
    echo "📁 Project Directory: $(pwd)"
    echo "📄 Output File: $OUTPUT_FILE"
    
    analyze_filesystem
    analyze_codebase
    analyze_dependencies
    analyze_environment
    analyze_architecture
    analyze_git
    generate_knowledge_graph  
    
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

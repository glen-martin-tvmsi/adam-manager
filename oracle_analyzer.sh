#!/usr/bin/env bash
# Adam OS Project Oracle - v1.8

set -eo pipefail

# Configuration
OUTPUT_FILE="./oracle_report.json"
TEMP_DIR="/tmp/adam-oracle"  # Consistent temporary directory path

# Ensure the temporary directory exists and is clean
prepare_temp_dir() {
    echo "🛠 Preparing temporary directory at $TEMP_DIR..."
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    mkdir -p "$TEMP_DIR"
    echo "✅ Temporary directory prepared."
}

# Dependency checks
check_deps() {
    local missing=()
    for dep in tree cloc jq git python3; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "❌ Missing dependencies: ${missing[*]}"
        echo "Install with:"
        echo "  Debian/Ubuntu: sudo apt-get install -y tree cloc jq git python3"
        echo "  macOS: brew install tree cloc jq git python"
        exit 1
    fi
}

# Main analysis functions
analyze_filesystem() {
    echo "📂 Analyzing file structure..."
    tree -a -I '.git|node_modules|venv|__pycache__' -L 3 -J > "$TEMP_DIR/file_tree.json"
    
    if [ ! -f "$TEMP_DIR/file_tree.json" ]; then
        echo "❌ Failed to create file_tree.json! Debugging output:"
        ls -lh "$TEMP_DIR"
        exit 1
    fi
    
    echo "✅ File structure analysis complete. Output saved to $TEMP_DIR/file_tree.json."
}

analyze_codebase() {
    echo "📊 Calculating code metrics..."
    cloc --quiet --json . > "$TEMP_DIR/cloc.json"
    
    if [ ! -f "$TEMP_DIR/cloc.json" ]; then
        echo "❌ Failed to create cloc.json!"
        exit 1
    fi
    
    echo "✅ Code metrics analysis complete. Output saved to $TEMP_DIR/cloc.json."
}

analyze_dependencies() {
    echo "🧩 Identifying dependencies..."
    
    # Node.js dependencies
    if [ -f "package.json" ]; then
        jq '.dependencies' package.json > "$TEMP_DIR/node_deps.json"
        echo "✅ Node.js dependencies detected."
    else
        echo "No package.json found."
    fi

    # Python dependencies
    if [ -f "requirements.txt" ]; then
        pip freeze > "$TEMP_DIR/python_deps.txt"
        echo "✅ Python dependencies detected."
    else
        echo "No requirements.txt found."
    fi
    
    echo "✅ Dependencies analysis complete."
}

analyze_environment() {
    echo "🔧 Detecting environment configuration..."
    {
        # Capture environment variables but exclude sensitive ones
        env | grep -E '^[A-Z_]+=' | grep -vE '_TOKEN|_KEY|PASSWORD|SECRET' || true
    } > "$TEMP_DIR/env_vars.txt"
    
    if [ ! -f "$TEMP_DIR/env_vars.txt" ]; then
        echo "❌ Failed to create env_vars.txt!"
        exit 1
    fi
    
    echo "✅ Environment configuration analysis complete. Output saved to $TEMP_DIR/env_vars.txt."
}


analyze_architecture() {
    echo "🏗 Inferring system architecture..."
    find . -type f \( -name 'Dockerfile*' -o -name '*.yml' \) \
        -exec grep -hiE 'FROM|image:' {} + > "$TEMP_DIR/architecture.txt"
    
    if [ ! -f "$TEMP_DIR/architecture.txt" ]; then
        echo "❌ Failed to create architecture.txt!"
        exit 1
    fi
    
    echo "✅ Architecture inference complete. Output saved to $TEMP_DIR/architecture.txt."
}

generate_knowledge_graph() {
    echo "🧠 Generating knowledge graph..."
    
    python3 codebase_knowledge_graph.py --input "$TEMP_DIR/file_tree.json" \
                                        --output "$TEMP_DIR/knowledge_graph.json"
    
    if [ ! -f "$TEMP_DIR/knowledge_graph.json" ]; then
        echo "❌ Failed to create knowledge_graph.json! Debugging output:"
        ls -lh "$TEMP_DIR"
        exit 1
    fi
    
    echo "✅ Knowledge graph generation complete. Output saved to $TEMP_DIR/knowledge_graph.json."
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
}

with open("$OUTPUT_FILE", "w") as f:
    json.dump(report, f, indent=2)

print(f"Report written to: {os.path.abspath('$OUTPUT_FILE')}")
EOF

if [ ! -f "$OUTPUT_FILE" ]; then
    echo "❌ Failed to create oracle_report.json!"
else
    echo "✅ Final report created successfully at $OUTPUT_FILE."
fi
}

main() {
    check_deps
    
    prepare_temp_dir  # Ensure consistent temp directory setup
    
    echo "🔍 Adam Oracle Analysis Started"
    
    analyze_filesystem
    analyze_codebase
    analyze_dependencies
    analyze_environment
    analyze_architecture
    
    generate_knowledge_graph
    
    generate_report
    
    echo "✅ Analysis complete!"
}

main "$@"

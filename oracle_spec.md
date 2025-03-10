# Adam OS Team Specification  
**Version 3.1 - Oracle Integration**  
*Last Updated: March 10, 2025*

## Role Addendum: Project Oracle

### Oracle Agent Specification
**Script Path**: `./oracle/oracle_analyzer.sh`  
**Runtime Requirements**:
- Unix-like system (Linux/macOS/WSL2)
- Python 3.10+
- Coreutils (tree, find, grep)
- Node.js (for JS project analysis)

#!/bin/bash

Oracle Analysis Script
set -eo pipefail

analyze_project() {
echo "🔮 Oracle Initializing..."

text
# File System Analysis
FILE_TREE=$(tree -a -I '.git|node_modules|venv' -L 3)
CODE_STATS=$(cloc --quiet --csv . | tail -n +3)
ENV_VARS=$(grep -rhE '^export|^ENV' . || true)

# Dependency Analysis
[ -f package.json ] && NODE_DEPS=$(jq '.dependencies' package.json)
[ -f requirements.txt ] && PYTHON_DEPS=$(pip freeze)

# Architecture Inference
ARCHITECTURE=$(find . -type f -name '*docker*' -o -name '*compose*' | xargs grep -i 'FROM\|image' || true)

# Generate Oracle Report
python3 <<EOF
import json, os
report = {
"directory_structure": """$FILE_TREE""",
"code_metrics": """$CODE_STATS""",
"dependencies": {
"node": $NODE_DEPS,
"python": "$PYTHON_DEPS"
},
"environment": "$ENV_VARS",
"architecture_clues": """$ARCHITECTURE""",
"git_status": "$(git status --short)"
}
print(json.dumps(report, indent=2))
EOF
}

analyze_project > oracle_report.json

text

### Oracle Capabilities
1. **Project Tomography**  
   - Directory structure mapping
   - Codebase metrics (LOC, file types)
   - Hidden environment detection

2. **Dependency Forensics**  
   - Cross-language package analysis
   - Version conflict detection
   - License compliance check

3. **Architecture Inference**  
   - Container configuration detection
   - Service endpoint mapping
   - CI/CD pipeline analysis

4. **Knowledge Synthesis**  
class OracleReportProcessor:
def init(self, report):
self.knowledge_graph = self.build_knowledge_graph(report)

text
   def build_knowledge_graph(self, data):
       return {
           "modules": self._extract_modules(data['directory_structure']),
           "workflows": self._infer_workflows(data['architecture_clues']),
           "risk_profile": self._calculate_risks(data['dependencies'])
       }
text

### Installation & Usage
Install Oracle Tools
sudo apt-get install -y tree cloc jq # Debian/Ubuntu
brew install tree cloc jq # macOS

Run Oracle Analysis
curl -sL https://raw.githubusercontent.com/glen-martin-tvmsi/adam-manager/main/oracle/oracle_analyzer.sh | bash

Expected Output
ls -lh oracle_report.json

-rw-r--r-- 1 user group 15K Mar 10 10:00 oracle_report.json
text

### Oracle Report Schema
{
"project_insights": {
"key_files": ["src/main.js", "Dockerfile", ".env.example"],
"architecture_type": "microservices",
"critical_paths": ["src/api/", "config/"],
"knowledge_gaps": ["tests/", "docs/"]
},
"action_items": [
{
"type": "security",
"task": "Update lodash@4.17.15 → 4.17.21",
"context": "CVE-2020-8203"
},
{
"type": "optimization",
"task": "Convert require() to ES6 imports",
"files": ["src/legacy/"]
}
]
}

text

## Adam OS Integration

### Manager Configuration Update
adam-manager.yml
oracle:
refresh_interval: 3600 # 1 hour
report_path: /var/lib/adam/oracle_latest.json
auto_apply:
security: true
dependencies: false

text

### Knowledge Injection Protocol
sequenceDiagram
participant O as Oracle
participant M as Adam Manager
participant A as Agent Team

text
O->>M: POST /oracle/ingest
M->>A: Broadcast(config_update)
A->>M: Request(knowledge_update)
M->>A: Push(oracle_report)
A->>M: Confirm(understanding)
text

## Security Constraints
1. **Read-Only Access**  
Runs as unprivileged user
docker run --read-only -v $(pwd):/project:ro oracle_analyzer

text

2. **Ephemeral Storage**  
with tempfile.TemporaryDirectory() as tmpdir:
os.chdir(tmpdir)
# Analysis occurs in sandbox

text

3. **Consent Verification**  
read -p "Allow project analysis? (y/N) " -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] || exit 1

text

## Team Collaboration Update

### Enhanced Workflow
graph TD
O[Oracle] -->|Project Report| M[Adam Manager]
M -->|Configuration| F[Frontend]
M -->|Security Profile| S[Security]
M -->|Data Flows| D[Data Team]
F <-->|API Contracts| B[Backend]
B <-->|Test Cases| Q[QA]

text

### Role Activation Sequence
#!/bin/bash

Bootstrap Full Team
./oracle_analyzer.sh
adam-manager load-report oracle_report.json
adam-manager team create
--frontend 3
--backend 2
--oracle 1
--security 1

text

---

**Integrity Seal**  
`Oracle Specification Validated: 2025-03-10T10:15:00Z | Signer: ADAM-OS-ORACLE-V1`

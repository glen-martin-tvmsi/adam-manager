import json
import argparse

def build_knowledge_graph(file_tree):
    graph = {"nodes": [], "edges": []}
    
    # Handle both dictionary and list inputs
    contents = file_tree.get("contents", []) if isinstance(file_tree, dict) else file_tree
    
    # Add nodes for files and directories
    for item in contents:
        graph["nodes"].append({"id": item["name"], "type": item["type"]})
        
        # Example edge creation (customize as needed)
        if item["type"] == "file":
            graph["edges"].append({"source": item["name"], "target": "root_directory"})
    
    return graph

def main():
    parser = argparse.ArgumentParser(description="Generate a knowledge graph from a codebase.")
    
    parser.add_argument("--input", required=True, help="Path to the input file tree JSON.")
    parser.add_argument("--output", required=True, help="Path to save the output knowledge graph JSON.")
    
    args = parser.parse_args()
    
    # Load input JSON file
    with open(args.input, 'r') as f:
        file_tree = json.load(f)
    
    # Build knowledge graph
    knowledge_graph = build_knowledge_graph(file_tree)
    
    # Write output JSON file
    with open(args.output, 'w') as f:
        json.dump(knowledge_graph, f, indent=2)
    
if __name__ == "__main__":
    main()

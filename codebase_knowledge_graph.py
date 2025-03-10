import json
import argparse


def sanitize_environment(env_data):
    """Remove sensitive information from environment data."""
    sanitized_env = []
    for line in env_data.splitlines():
        if not any(keyword in line for keyword in ["_TOKEN", "_KEY", "PASSWORD", "SECRET"]):
            sanitized_env.append(line)
    return "\n".join(sanitized_env)


def build_knowledge_graph(file_tree):
    """Build a knowledge graph from the file tree."""
    graph = {"nodes": [], "edges": []}

    # Extract the dictionary with "type": "directory" from the root list
    directory_entry = next((entry for entry in file_tree if entry.get("type") == "directory"), None)

    if not directory_entry or "contents" not in directory_entry:
        raise ValueError("Input JSON must contain a 'directory' entry with a 'contents' key.")

    contents = directory_entry["contents"]

    # Add nodes for files and directories
    for item in contents:
        name = item.get("name", "unknown")
        type_ = item.get("type", "unknown")

        graph["nodes"].append({"id": name, "type": type_})

        # Example edge creation (customize as needed)
        if type_ == "file":
            graph["edges"].append({"source": name, "target": "root_directory"})

    return graph


def main():
    parser = argparse.ArgumentParser(description="Generate a knowledge graph from a codebase.")

    parser.add_argument("--input", required=True, help="Path to the input file tree JSON.")
    parser.add_argument("--output", required=True, help="Path to save the output knowledge graph JSON.")

    args = parser.parse_args()

    # Load input JSON file
    with open(args.input, 'r') as f:
        file_tree = json.load(f)

    # Ensure input is a list
    if not isinstance(file_tree, list):
        raise ValueError("Input JSON must be a list containing a 'directory' entry.")

    # Build knowledge graph
    knowledge_graph = build_knowledge_graph(file_tree)

    # Write output JSON file
    with open(args.output, 'w') as f:
        json.dump(knowledge_graph, f, indent=2)


if __name__ == "__main__":
    main()

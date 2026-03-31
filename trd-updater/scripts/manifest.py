#!/usr/bin/env python3
"""Update manifest.json after an incremental TRD update run.

Usage:
    python3 manifest.py <project_root> '<module_map_json>'

Args:
    project_root: Absolute path to the project root directory.
    module_map_json: JSON object mapping module names to directory paths.
        Example: '{"chain_apis":"chain/apis/","center":"center/"}'
        If directory structure did not change, pass the same map from the old manifest.

Reads existing manifest.json, increments version, updates commit/timestamp/file lists.

Output (stdout): JSON with status, path, old_version, new_version, commits, modules, total_files.
"""

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def get_git_head(project_root):
    result = subprocess.run(
        ["git", "-C", str(project_root), "rev-parse", "HEAD"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def get_tracked_files(project_root, path):
    result = subprocess.run(
        ["git", "-C", str(project_root), "ls-files", "--", path],
        capture_output=True, text=True,
    )
    return [f for f in result.stdout.strip().split("\n") if f]


def main():
    if len(sys.argv) < 3:
        print(json.dumps({"error": "Usage: manifest.py <project_root> '<module_map_json>'"}))
        sys.exit(1)

    project_root = Path(sys.argv[1]).resolve()
    trd_work = project_root / "trd_work"
    manifest_path = trd_work / "manifest.json"

    if not manifest_path.exists():
        print(json.dumps({"error": f"No existing manifest: {manifest_path}. Run trd-writer first."}))
        sys.exit(1)

    with open(manifest_path, encoding="utf-8") as f:
        old_manifest = json.load(f)

    try:
        module_paths = json.loads(sys.argv[2])
    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"Invalid module_map JSON: {e}"}))
        sys.exit(1)

    commit = get_git_head(project_root)
    if not commit:
        print(json.dumps({"error": "Not a git repository or git not available"}))
        sys.exit(1)

    old_version = old_manifest.get("version", 0)
    new_version = old_version + 1

    module_file_map = {}
    for name, path in module_paths.items():
        module_file_map[name] = get_tracked_files(project_root, path)

    manifest = {
        "version": new_version,
        "last_commit": commit,
        "last_run": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "module_file_map": module_file_map,
    }

    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")

    print(json.dumps({
        "status": "ok",
        "path": str(manifest_path),
        "old_version": old_version,
        "new_version": new_version,
        "old_commit": old_manifest.get("last_commit", "")[:12],
        "new_commit": commit[:12],
        "modules": len(module_file_map),
        "total_files": sum(len(v) for v in module_file_map.values()),
    }))


if __name__ == "__main__":
    main()

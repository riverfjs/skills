#!/usr/bin/env python3
"""Generate manifest.json for TRD work.

Usage:
    python3 manifest.py <project_root>
    python3 manifest.py <project_root> '<file_list_json>'

Args:
    project_root: Absolute path to the project root directory.
    file_list_json: Optional JSON array of files to record.
        If not provided, uses `git ls-files` to get all tracked files.

Output (stdout): JSON with status, path, version, commit, total_files.
Writes: {project_root}/trd_work/manifest.json
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


def get_all_tracked_files(project_root):
    result = subprocess.run(
        ["git", "-C", str(project_root), "ls-files"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return []
    return [f for f in result.stdout.strip().split("\n") if f]


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: manifest.py <project_root> [file_list_json]"}))
        sys.exit(1)

    project_root = Path(sys.argv[1]).resolve()
    
    # Get file list from argument or git
    if len(sys.argv) >= 3:
        try:
            files = json.loads(sys.argv[2])
        except json.JSONDecodeError as e:
            print(json.dumps({"error": f"Invalid file_list JSON: {e}"}))
            sys.exit(1)
    else:
        files = get_all_tracked_files(project_root)

    commit = get_git_head(project_root)
    if not commit:
        print(json.dumps({"error": "Not a git repository or git not available"}))
        sys.exit(1)

    manifest = {
        "version": 1,
        "last_commit": commit,
        "last_run": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "files": files,
    }

    trd_work = project_root / "trd_work"
    trd_work.mkdir(parents=True, exist_ok=True)
    manifest_path = trd_work / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")

    print(json.dumps({
        "status": "ok",
        "path": str(manifest_path),
        "version": 1,
        "commit": commit[:12],
        "total_files": len(files),
    }))


if __name__ == "__main__":
    main()

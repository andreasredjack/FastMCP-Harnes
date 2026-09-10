"""Read-only validation harness for the FastMCP workspace."""

from __future__ import annotations

import argparse
import ast
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

import yaml


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_TIMEOUT = 120
OUTPUT_LIMIT = 4000
TRIVY_CACHE_DIR = os.getenv("TRIVY_CACHE_DIR", "/tmp/trivy-cache")
TRIVY_SKIP_DIRS = [".git", ".venv", "__pycache__", ".mypy_cache", ".pytest_cache"]
REQUIRED_POLICY_FILES = [
    ".github/copilot-instructions.md",
    "Policies-Readme.md",
    "instructions/architecture.instructions.md",
    "harness/profiles/reviewer.md",
]
PYTHON_SUFFIXES = {".py"}
YAML_SUFFIXES = {".yaml", ".yml"}


def run_command(command: list[str], timeout: int = DEFAULT_TIMEOUT) -> dict[str, Any]:
    try:
        completed = subprocess.run(
            command,
            cwd=REPOSITORY_ROOT,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        return {
            "command": command,
            "exit_code": None,
            "ok": False,
            "output": str(error),
        }

    output = "\n".join(part for part in (completed.stdout, completed.stderr) if part)
    truncated = len(output) > OUTPUT_LIMIT
    return {
        "command": command,
        "exit_code": completed.returncode,
        "ok": completed.returncode == 0,
        "output": output[:OUTPUT_LIMIT].strip(),
        "output_truncated": truncated,
    }


def changed_files() -> list[str]:
    result = run_command(["git", "status", "--short"])
    if not result["ok"]:
        return []
    files = []
    for line in result["output"].splitlines():
        if len(line) > 3:
            files.append(line[3:].strip())
    return files


def repository_files() -> list[Path]:
    excluded = {".git", ".venv", "__pycache__", ".mypy_cache", ".pytest_cache"}
    return sorted(
        path
        for path in REPOSITORY_ROOT.rglob("*")
        if path.is_file() and not excluded.intersection(path.parts)
    )


def check_python(path: Path) -> dict[str, Any]:
    try:
        ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        return {"file": str(path.relative_to(REPOSITORY_ROOT)), "ok": True}
    except (OSError, SyntaxError, UnicodeError) as error:
        return {
            "file": str(path.relative_to(REPOSITORY_ROOT)),
            "ok": False,
            "error": str(error),
        }


def check_yaml(path: Path) -> dict[str, Any]:
    try:
        yaml.safe_load(path.read_text(encoding="utf-8"))
        return {"file": str(path.relative_to(REPOSITORY_ROOT)), "ok": True}
    except (OSError, yaml.YAMLError, UnicodeError) as error:
        return {
            "file": str(path.relative_to(REPOSITORY_ROOT)),
            "ok": False,
            "error": str(error),
        }


def check_policy_files() -> dict[str, Any]:
    missing = [
        relative_path
        for relative_path in REQUIRED_POLICY_FILES
        if not (REPOSITORY_ROOT / relative_path).is_file()
    ]
    return {
        "required": REQUIRED_POLICY_FILES,
        "missing": missing,
        "ok": not missing,
    }


def run_harness() -> dict[str, Any]:
    files = repository_files()
    python_checks = [
        check_python(path) for path in files if path.suffix in PYTHON_SUFFIXES
    ]
    yaml_checks = [check_yaml(path) for path in files if path.suffix in YAML_SUFFIXES]
    checks = {
        "mandatory_policy_files": check_policy_files(),
        "git_status": run_command(["git", "status", "--short", "--branch"]),
        "git_diff_check": run_command(
            ["git", "-c", "core.whitespace=cr-at-eol", "diff", "--check"]
        ),
        "python_syntax": python_checks,
        "yaml_syntax": yaml_checks,
        "trivy_fs": run_command(
            [
                "trivy",
                "fs",
                "--scanners",
                "vuln,secret",
                "--format",
                "json",
                "--quiet",
                "--cache-dir",
                TRIVY_CACHE_DIR,
                *sum((["--skip-dirs", directory] for directory in TRIVY_SKIP_DIRS), []),
                ".",
            ],
            timeout=300,
        ),
        "trivy_config": run_command(
            [
                "trivy",
                "config",
                "--format",
                "json",
                "--quiet",
                "--cache-dir",
                TRIVY_CACHE_DIR,
                *sum((["--skip-dirs", directory] for directory in TRIVY_SKIP_DIRS), []),
                ".",
            ],
            timeout=300,
        ),
    }
    failures = []
    for name, result in checks.items():
        if isinstance(result, list):
            failures.extend(item["file"] for item in result if not item["ok"])
        elif not result["ok"]:
            failures.append(name)
    return {
        "harness": "fastmcp-read-only-reviewer",
        "repository": str(REPOSITORY_ROOT),
        "changed_files": changed_files(),
        "checks": checks,
        "ok": not failures,
        "failures": failures,
        "mutations_performed": False,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="Emit JSON only.")
    args = parser.parse_args()
    report = run_harness()
    print(json.dumps(report, ensure_ascii=True, indent=2))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
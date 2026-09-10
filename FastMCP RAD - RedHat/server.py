"""Policy-gated read-only FastMCP server for the Red-Hat build harness."""

from __future__ import annotations

import asyncio
import json
import os
from pathlib import Path

from mcp.server.fastmcp import FastMCP

from harness.build_llm import model_status, review_build

ROOT = Path(__file__).resolve().parent
mcp = FastMCP(
    "FastMCP RAG Build Review",
    host=os.getenv("MCP_HOST", "0.0.0.0"),
    port=int(os.getenv("MCP_PORT", "8000")),
)


@mcp.tool()
async def build_llm_status() -> str:
    """Prüft Modell, LM-Studio-Erreichbarkeit und verbindlichen Policy-Hash."""
    return json.dumps(await model_status(), ensure_ascii=True, indent=2)


@mcp.tool()
async def review_build_request(request: str, context: str = "") -> str:
    """Bewertet einen Build read-only nach dem verbindlichen BSI-Regelwerk."""
    return await review_build(request, context)


@mcp.tool()
async def run_deterministic_harness() -> str:
    """Führt nur die vorhandene read-only Harness aus; kein Apply oder Deployment."""
    process = await asyncio.create_subprocess_exec(
        "python",
        "harness/coding_harness.py",
        "--json",
        cwd=ROOT,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT,
    )
    output, _ = await process.communicate()
    return output.decode("utf-8", errors="replace")


if __name__ == "__main__":
    mcp.run(transport="streamable-http")

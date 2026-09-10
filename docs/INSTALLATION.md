# Installation FastMCP-Harness

## Zweck

Dieses Projekt ist eine getrennte Test- und Governance-Umgebung für den
FastMCP-Server. Das laufende Originalsystem unter `FastMCP RAG` wird nicht
verändert.

## Voraussetzungen

- AlmaLinux 9 unter WSL;
- Python 3.11;
- LM Studio auf Windows mit OpenAI-kompatibler API;
- Trivy für die Harness-Scans;
- keine produktiven Secrets in der Testkopie.

## Virtuelle Umgebung

```bash
cd "/mnt/h/VS Code Arbeitsbereiche/FastMCP-Harness"
/usr/bin/python3.11 -m venv "$HOME/.venvs/fastmcp-governance-test"
source "$HOME/.venvs/fastmcp-governance-test/bin/activate"
python -m pip install --upgrade pip setuptools
python -m pip install -r requirements.txt
```

## Governance-Dateien

Die Dateien unter `governance/` bilden die technische Eingabe für die
Fail-Closed-Prüfung:

- KI-System-Inventar;
- Risikoanalyse;
- EU-AI-Act-Bewertung;
- DSGVO-Datenverarbeitung;
- menschliche Aufsicht;
- Modellevaluation;
- Aufbewahrung und Löschung;
- Incident Response.

`TBD`, `pending` und `assessment_required` sind absichtliche Sperrwerte. Sie
müssen vor einer Freigabe durch belastbare Angaben und Nachweise ersetzt werden.

## Harness prüfen

```bash
python -m py_compile server.py harness/coding_harness.py
python harness/coding_harness.py --json
```

Ein Fehlschlag ist erwartbar, solange Governance-Verantwortliche,
Rechtsbewertung, Retention und Evaluation noch offen sind.

## Testserver starten

Der Testserver verwendet einen eigenen Port:

```bash
MCP_PORT=8100 python server.py
```

MCP-Endpunkt:

```text
http://127.0.0.1:8100/mcp
```

Die Originalserver auf den Ports `8000` und `8001` dürfen nicht gestoppt,
überschrieben oder neu gestartet werden.

## Verbindung testen

```bash
python - <<'PY'
import asyncio
from fastmcp import Client

async def main():
    async with Client("http://127.0.0.1:8100/mcp") as client:
        print([tool.name for tool in await client.list_tools()])
        print(await client.call_tool("lm_studio_status", {}))

asyncio.run(main())
PY
```

## Freigabegrenze

Die Testkopie darf erst als betriebsbereit bezeichnet werden, wenn Harness,
Governance-Prüfungen, PII-/Secret-Scans, Evaluation und menschliche Freigaben
erfolgreich nachgewiesen sind. Sie ist kein Deployment-Runner.

## ToDo: Zielarchitektur

- produktive TLS-Zertifikate und Nginx-Authentifizierung freigeben;
- LiteLLM-API-Keys, ACLs, Tokenlimits und Retention festlegen;
- getrennte Ollama-RAG-/Coding-Backends mit eigenen Volumes und Netzwerken bereitstellen;
- GPU-/ROCm-Unterstützung auf dem Zielsystem nachweisen;
- Gateway-End-to-End-Test mit freigegebenen Modellaliasen durchführen;
- Governance-Owner, Rechtsprüfung, DPIA-/DSGVO-Status und Evidence-Aufbewahrung eintragen.

## Testmodell und Abnahmegrenze

Die Installation umfasst derzeit den Harness-Orchestrator und die LLM-/Gateway-
Anbindung. Eine vollständige Abnahme benötigt zusätzlich eine versionierte
Datensatz-Pipeline, erwartete Ergebnisse, unabhängige Evaluation/Grader und ein
Evidence Bundle. Diese Komponenten müssen vor einer Zielarchitektur-Freigabe
installiert und getestet werden.

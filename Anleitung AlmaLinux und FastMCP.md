# ToDo: Zielarchitektur

- Nginx-/LiteLLM-Gateway mit TLS, ACLs und Rate Limiting end-to-end testen;
- getrennte Ollama-RAG-/Coding-Backends auf dem Zielsystem bereitstellen;
- GPU-/ROCm-Unterstützung oder CPU-Betriebsprofil dokumentieren;
- FastMCP ausschließlich über das Gateway betreiben;
- Harness-Gateway- und Governance-Gates vor jeder Freigabe ausführen.

# Anleitung: AlmaLinux 9 und FastMCP unter WSL

AlmaLinux 9 ist die lokale RHEL-nahe WSL-Umgebung fuer FastMCP. Ubuntu bleibt
als Rueckfallebene installiert. Die produktive Freigabe erfolgt weiterhin ueber
den Red-Hat-Container oder den Cluster-GitOps-Prozess.

## WSL-Status

```powershell
wsl --list --verbose
wsl --set-default AlmaLinux-9
```

Die erwartete Konfiguration ist:

```text
AlmaLinux-9       Running oder Stopped    2    Standard
Ubuntu            Stopped                2    Rueckfallebene
```

Ubuntu wird nicht geloescht, bevor die AlmaLinux-Migration fachlich und
technisch abgenommen wurde.

## AlmaLinux-Basis

In AlmaLinux als Administrator aktualisieren und Werkzeuge installieren:

```bash
sudo dnf update -y
sudo dnf install -y python3.11 python3.11-pip python3.11-devel \
  gcc git ca-certificates curl tar gzip
```

FastMCP benoetigt eine Python-Version ab 3.10. Die Standard-Python-Version
3.9 von AlmaLinux 9 wird deshalb fuer dieses Projekt nicht verwendet.

## FastMCP-venv

```bash
cd "/mnt/h/VS Code Arbeitsbereiche/FastMCP RAG"
python3.11 -m venv "$HOME/.venvs/fastmcp-rag"
source "$HOME/.venvs/fastmcp-rag/bin/activate"
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python --version
```

Die venv muss Python 3.11 melden. Die Abhaengigkeiten werden anschliessend
kontrolliert importiert:

```bash
python -c "import fastmcp, openai, yaml; print('FAST_MCP_DEPS=ok')"
```

Der freigegebene Dependency-Stand ist:

```text
fastmcp==3.2.0
setuptools>=78.1.1
```

## Trivy installieren

Die Version und das Release-Archiv muessen aus einer freigegebenen Quelle
stammen. Das Archiv wird vor der Installation mit der offiziellen SHA-256-
Pruefsumme verglichen:

```bash
curl --fail --show-error --location \
  https://github.com/aquasecurity/trivy/releases/download/v0.74.0/trivy_0.74.0_Linux-64bit.tar.gz \
  --output /tmp/trivy.tar.gz
curl --fail --show-error --location \
  https://github.com/aquasecurity/trivy/releases/download/v0.74.0/trivy_0.74.0_checksums.txt \
  --output /tmp/trivy_checksums.txt
grep 'trivy_0.74.0_Linux-64bit.tar.gz' /tmp/trivy_checksums.txt
sha256sum /tmp/trivy.tar.gz
sudo tar -xzf /tmp/trivy.tar.gz -C /usr/local/bin trivy
sudo chmod 0755 /usr/local/bin/trivy
trivy --version
```

Die ausgegebene Archivpruefsumme muss mit der offiziellen Checksums-Datei
uebereinstimmen. Die Trivy-Datenbank wird separat aktualisiert:

```bash
trivy fs --download-db-only --cache-dir /tmp/trivy-cache
```

## FastMCP starten

```bash
cd "/mnt/h/VS Code Arbeitsbereiche/FastMCP RAG"
source "$HOME/.venvs/fastmcp-rag/bin/activate"
python server.py
```

Der MCP-Endpunkt bleibt unveraendert:

```text
http://127.0.0.1:8000/mcp
```

## Harness pruefen

Die verbindliche Red-Hat-Harness liegt unter
`FastMCP RAD - RedHat/`. Der lokale AlmaLinux-Lauf ist eine Vorpruefung:

```bash
cd "/mnt/h/VS Code Arbeitsbereiche/FastMCP RAG/FastMCP RAD - RedHat"
/root/.venvs/fastmcp-rag/bin/python -m py_compile harness/coding_harness.py
/root/.venvs/fastmcp-rag/bin/python harness/coding_harness.py --json
```

Erwartet werden erfolgreiche Gates fuer:

- Pflicht-Policy-Dateien;
- Python-Syntax;
- YAML-Validierung;
- `git diff --check`;
- Trivy-FS-Scan fuer Vulnerabilities und Secrets;
- Trivy-Config-Scan;
- keine durch die Harness ausgefuehrten Mutationen.

## Sicherheitsgrenzen

- AlmaLinux-WSL darf keine produktiven Cluster direkt veraendern.
- Kein `terraform apply`, `kubectl apply`, Loeschen oder Skalieren aus der
  Harness.
- Policies und Security-Regeln bleiben identisch zur Cluster- und
  Container-Variante.
- Das LLM laeuft lokal beziehungsweise im freigegebenen Cluster-Endpoint.
- Harness- und LLM-Endpunkte haben keinen direkten Internetzugang waehrend
  des Scans.
- Externe Downloads wie die Trivy-Datenbank sind separate, kontrollierte
  Vorbereitungsschritte.
- Die verbindliche Freigabe erfolgt ueber Container/CI/CD, Vier-Augen-Prinzip
  und GitOps.

## Upgrade- und CVE-Pruefung

Nach einem Dependency-Upgrade muessen mindestens folgende Tests erfolgreich
sein:

```bash
python -m py_compile server.py
python -c "import fastmcp, setuptools; print(fastmcp.__version__, setuptools.__version__)"
python harness/coding_harness.py --json
```

Nach FastMCP `3.2.0` wurden MCP-Handshake, `lm_studio_status`, `ask_llm`,
`review_code_security`, `trivy_scan` und `trivy_update` erfolgreich gegen LM
Studio beziehungsweise Trivy getestet. Der finale CVE-Stand ist:

- kritisch: `0`;
- hoch: `0`;
- mittel: `1` (`CVE-2025-69872` in `diskcache 5.6.3`, derzeit ohne bekannte
  Fix-Version).
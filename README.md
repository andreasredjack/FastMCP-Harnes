# FastMCP-Harness

Eigenständiges, read-only Governance- und Security-Harness-Projekt für den
lokalen FastMCP-Server unter AlmaLinux 9 in WSL. Dieses Projekt ist aus einer
isolierten Testkopie entstanden und wird getrennt vom laufenden Originalsystem
auf Port `8100` getestet.

Das Harness prüft technische, sicherheitsbezogene und Governance-Kontrollen.
Es führt keine Commits, Pushes, Deployments, `kubectl apply`, `helm upgrade`,
`terraform apply` oder sonstige Produktionsmutationen aus.

Die aktiven Originalserver auf den Ports `8000` und `8001` gehören nicht zu
diesem Projekt und werden nicht verändert.

## Dokumentation

- `docs/INSTALLATION.md` – Installation und Testkopie;
- `docs/BETRIEB.md` – read-only Betrieb und Testablauf;
- `docs/GOVERNANCE.md` – ISO/IEC 42001, EU AI Act und DSGVO-Kontrollen;
- `docs/TESTPROTOKOLL.md` – isolierter Teststand;
- `Harness.md` – technische Harness- und Containerbeschreibung;
- `governance/` – versionierte Governance-Eingaben.

## LM Studio vorbereiten

1. In LM Studio ein Modell laden, zum Beispiel das vorhandene Ollama-Modell.
2. Den lokalen Server starten und den Port `1234` verwenden.
3. Den Server so konfigurieren, dass Verbindungen aus WSL erlaubt sind.
4. Fuer Sicherheitspruefungen ein Security-orientiertes Modell laden und dessen
	exakte Modell-ID in `config.yaml` unter `lm_studio.security_model` eintragen.

LM Studio verwendet eine OpenAI-kompatible API. Der Server benoetigt daher
keine separate Ollama-Verbindung.

## Isolierter Harness-Test

Das Projekt wird ausschließlich als Testkopie betrieben:

```bash
cd "/mnt/h/VS Code Arbeitsbereiche/FastMCP-Harness"
source "$HOME/.venvs/fastmcp-governance-test/bin/activate"
MCP_PORT=8100 python server.py
```

Der Testserver verwendet den MCP-Endpunkt `http://127.0.0.1:8100/mcp`.
Die Originalserver auf Port 8000 und 8001 werden nicht angefasst.

Die Governance-Prüfung läuft mit:

```bash
python -m py_compile server.py harness/coding_harness.py
python harness/coding_harness.py --json
```

## AlmaLinux/WSL einrichten

```bash
/usr/bin/python3.11 -m venv "$HOME/.venvs/fastmcp-governance-test"
source "$HOME/.venvs/fastmcp-governance-test/bin/activate"
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Die aktuelle Laufzeit verwendet FastMCP `3.2.0` und `setuptools` mindestens
`78.1.1`. Fuer AlmaLinux 9 ist Python `3.11` erforderlich, weil die
Systemversion Python 3.9 fuer FastMCP 3.2.0 nicht ausreicht.

Die anpassbaren Werte stehen in `config.yaml`. Jede relevante Zeile ist dort
mit einem Kommentar `ANPASSEN` versehen. Umgebungsvariablen wie `LM_STUDIO_HOST`
und `MCP_PORT` haben weiterhin Vorrang vor den Werten aus dieser Datei.

Die Regeln fuer die Codepruefung stehen zusaetzlich in
`security-review.yaml`. Dort werden Security-Modell, Temperatur, maximale
Codegroesse und die Review-Anweisung angepasst.

Das verbindliche, BSI-orientierte Regelwerk liegt im Verzeichnis
`security-rules/`. Der Server laedt beim Start alle Markdown-Dateien dieses
Verzeichnisses und beruecksichtigt sie automatisch bei jedem
`review_code_security`-Aufruf. Neue oder geaenderte Regeldateien werden nach
einem Neustart wirksam.

Das Reviewer-Profil liegt unter `instructions/architecture.instructions.md`.
Es wird ebenfalls bei jedem Security-Review geladen und legt nur den Zeitpunkt,
die Reihenfolge und das Ausgabeformat der Regelpruefung fest. Dadurch gilt es
unabhaengig vom konkret in LM Studio ausgewaehlten Security-LLM.

## Code-Sicherheitsprüfung

Das MCP-Tool `review_code_security` sendet Code an das konfigurierte lokale
Security-Modell. Der Code wird vom Server nicht ausgefuehrt. Die Antwort enthaelt
Schweregrad, moegliche CWE-/OWASP-Zuordnung, Fundstelle, Risiko und konkrete
Korrekturvorschlaege.

Wenn `security-review.yaml` unter `model` leer bleibt, wird ersatzweise
`config.yaml` unter `lm_studio.security_model` oder das allgemeine `model`-Feld
verwendet. Fuer belastbare Security-Reviews sollte ein speziell dafuer trainiertes
oder ausgerichtetes Modell geladen und explizit eingetragen werden.

Beispiel fuer einen Aufruf ueber einen MCP-Client:

```text
review_code_security(
	code="...",
	language="python",
	context="FastMCP-Tool fuer interne Codeanalyse"
)
```

Falls die automatische Host-Erkennung nicht funktioniert, die Windows-Host-IP
ermitteln und in `.env` setzen:

```bash
grep nameserver /etc/resolv.conf
```

Danach `LM_STUDIO_HOST=<IP-aus-der-Ausgabe>` in `.env` eintragen.

## Server starten

```bash
python server.py
```

Der MCP-Endpunkt ist anschließend unter `http://127.0.0.1:8000/mcp` erreichbar.
Zum Testen der Verbindung zu LM Studio kann das MCP-Tool `lm_studio_status`
aufgerufen werden.

## Trivy-Scan-Engine

Trivy wird in Ubuntu/WSL installiert und über das offizielle Aqua-Security-
Repository aktualisiert:

```bash
sudo apt-get update
sudo apt-get install -y wget apt-transport-https gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
	| gpg --dearmor \
	| sudo tee /usr/share/keyrings/trivy.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
	| sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy
```

Das MCP-Tool `trivy_update` lädt die Vulnerability-Datenbank aus dem Internet.
Der Server verwendet dafuer den Trivy-Aufruf `trivy fs --download-db-only`.
`trivy_scan` unterstützt die Scan-Typen `fs`, `image`, `rootfs` und `config`.
Beispiel: `trivy_scan(target=".", scan_type="fs")`. Die Timeout- und Binary-
Einstellungen stehen im Abschnitt `trivy` in `config.yaml`.

## CVE-Status

Nach dem Upgrade auf FastMCP `3.2.0` sind die kritischen und hohen CVEs
behoben. Der aktuelle Trivy-SBOM-Scan weist noch ein Medium-Finding aus:
`CVE-2025-69872` in `diskcache 5.6.3`. Trivy meldet dafuer derzeit keine
verfuegbare Fix-Version. Der vollstaendige Bericht liegt unter
`CVE-Berichte/`.

## AlmaLinux 9 unter WSL

Für eine RHEL-nahe lokale Entwicklungsumgebung steht AlmaLinux 9 als zweite
WSL-Distribution zur Verfügung. Die Einrichtung, Python-3.11-venv, Trivy-
Installation und der Harness-Lauf sind in
`Anleitung AlmaLinux und FastMCP.md` dokumentiert. Ubuntu bleibt als
Rückfallebene installiert.

## ToDo: Zielarchitektur

- Nginx mit produktivem TLS 1.3, Authentifizierung und freigegebenem Rate Limit betreiben;
- LiteLLM-ACLs, Token-Tracking und produktive Modellfreigaben definieren;
- getrennte Ollama-RAG-/Coding-Backends mit eigenen Volumes und Netzwerken umsetzen;
- GPU-/ROCm-Konfiguration auf dem Zielsystem validieren;
- FastMCP ausschließlich über das Gateway routen und den direkten Fallback entfernen;
- PII-/Secret-Scan, Evaluation, Evidence Bundle und menschliche Freigaben vervollständigen;
- offene Governance-Werte in `governance/` durch verantwortete Nachweise ersetzen.

## Technisches Testmodell

Die aktuelle Architektur entspricht dem folgenden Modell nur teilweise:

```text
Datensatz-Pipeline -> Harness-Orchestrator -> LLM / Applikation
									  -> Evaluation-Suite / Richter
```

Vorhanden sind Harness-Orchestrator, FastMCP-Anwendung, Gateway-Konfiguration
und deterministische Gates. Noch aufzubauen sind versionierte Datensätze,
erwartete Ergebnisse, unabhängige Evaluation/Grader und ein vollständiges
Evidence Bundle.

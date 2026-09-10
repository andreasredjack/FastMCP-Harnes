# FastMCP Coding Harness fuer Ubuntu/WSL

Die Harness ist eine bewusst kleine, read-only Kontrollschicht fuer den
FastMCP-Workspace. Sie setzt die Empfehlungen aus dem Artikel zu Agent
Harnesses um: enger Scope, spezialisierte Reviewer-Rolle, explizite
Pruefreihenfolge, deterministische Rueckmeldungen und unabhaengige Sicherheits-
Gates.

## Sicherheitsmodell

Der Reviewer veraendert keine Dateien und fuehrt den FastMCP-Server nicht aus.
Er verwendet nur:

- Git-Status und `git diff --check`;
- Python-AST-Syntaxpruefung;
- `yaml.safe_load` fuer YAML-Dateien;
- Trivy-Dateisystem- und Konfigurationsscans.

Der Trivy-Cache wird standardmaessig unter `/tmp/trivy-cache` verwendet. Ein
anderer Pfad kann mit `TRIVY_CACHE_DIR` gesetzt werden. Die Git-Pruefung
beruecksichtigt mit `core.whitespace=cr-at-eol` die Windows-Zeilenenden der
Arbeitskopie unter WSL. Trivy ueberspringt `.git`, `.venv` und Python-Cache-
Verzeichnisse, damit der Scan auf dem kontrollierten Repository-Scope bleibt.

Die Datei `profiles/reviewer.md` ist die versionierte Rollenbeschreibung. Sie
trennt Rolle, Arbeitsreihenfolge, Toolgrenzen, Abbruchbedingungen und Ausgabe.

## Einrichtung in Ubuntu/WSL

```bash
cd "/mnt/h/VS Code Arbeitsbereiche/FastMCP RAG"
source "$HOME/.venvs/fastmcp-rag/bin/activate"
python -m pip install -r requirements.txt
```

Trivy muss im PATH vorhanden sein:

```bash
trivy --version
```

## Ausfuehrung

```bash
python harness/coding_harness.py --json
```

Exit-Code `0` bedeutet, dass alle deterministischen Pruefungen erfolgreich
waren. Exit-Code `1` bedeutet, dass mindestens ein Gate fehlgeschlagen ist.
Der Bericht enthaelt keinen Schreibschritt und weist mit
`mutations_performed: false` aus, dass die Harness nichts veraendert hat.

## Ablauf fuer echte Aenderungen

1. Auftrag mit Ziel, Scope, Abbruchbedingungen und Abnahmekriterien formulieren.
2. Harness read-only ausfuehren.
3. Befunde durch einen Menschen bestaetigen lassen.
4. Aenderungen in einem separaten, freigegebenen Arbeitsschritt umsetzen.
5. Harness erneut ausfuehren.
6. Security-Review, Tests, Merge Request und Cluster-GitOps-Prozess anwenden.

## ToDo: Zielarchitektur

- Gateway-Konfiguration als verpflichtenden Harness-Scope prüfen;
- Nginx-TLS und Rate Limiting statisch und integrativ testen;
- LiteLLM-ACLs und RAG-/Coding-Modellgruppen gegen Allowlist prüfen;
- Evidence Bundle, PII-Scan und Prompt-Injection-Suite ergänzen.

Die Harness ist kein Deployment-Runner. `terraform apply`, `kubectl apply`,
Produktionsaenderungen und Jira-/Confluence-Freigaben bleiben ausserhalb und
benoetigen eigene Berechtigungen und menschliche Freigaben.

## Technisches Testmodell

Die Harness ist der Orchestrator, nicht der Richter. Testdaten, erwartete
Ergebnisse und unabhängige Evaluation müssen als getrennte Komponenten ergänzt
werden. Erst die Kombination aus Harness, Datensatz-Pipeline, LLM/Applikation
und Evaluation-Suite bildet den vollständigen Nachweisprozess.
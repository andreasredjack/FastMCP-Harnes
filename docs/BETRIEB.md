## ToDo: Zielarchitektur

- externe Gateway-Erreichbarkeit über TLS 1.3 und Portbindung prüfen;
- Nginx-Rate-Limit und LiteLLM-ACLs mit Testkonten verifizieren;
- getrennte Ollama-Backends und Modellrouting vollständig end-to-end testen;
- GPU-/ROCm-Betrieb oder verbindliche CPU-Betriebsgrenzen dokumentieren;
- PII-/Secret-Scans und Evaluation-Suite als verpflichtende CI-Gates aktivieren;
- Evidence Bundle und menschliche Produktionsfreigabe organisatorisch verankern.
# Betrieb FastMCP-Harness

## Betriebsmodell

Die Harness ist eine read-only Kontrollschicht. Sie prüft Repository, Policies,
Governance, Python/YAML, Trivy und Konfigurationssicherheit. Sie verändert keine
Dateien, committet nichts und führt keine Produktionsaktionen aus.

## Fester Ablauf

1. Auftrag, Scope, Datenarten und Abbruchbedingungen dokumentieren.
2. Policies und Governance-Dateien laden.
3. Repository-Status und Testport prüfen.
4. Harness im JSON-Modus ausführen.
5. Befunde in technische Findings und offene Governance-Fragen trennen.
6. Menschliche Freigabe einholen.
7. Änderungen ausschließlich in einem separaten Arbeitsschritt umsetzen.
8. Harness erneut ausführen und Evidence Bundle archivieren.

## Testserver

```bash
MCP_PORT=8100 python server.py
```

Der Server der Testkopie darf nur gegen das lokale LM Studio verwendet werden.
Tools wie `ask_llm`, `review_code_security` und `lm_studio_status` erzeugen
keine produktiven Änderungen.

## Gateway-Teststack

Die lokale Gateway-Architektur liegt unter `gateway/` und besteht aus Nginx,
LiteLLM sowie getrennten RAG-/Coding-Backendgrenzen. Der CPU-Teststack wird
separat vom FastMCP-Server gestartet:

```powershell
Set-Location "H:\VS Code Arbeitsbereiche\FastMCP-Harness\gateway"
Copy-Item .env.example .env
docker compose config
docker compose up -d litellm nginx
```

Die Ollama-Backends werden nur bei Bedarf mit `--profile backends` gestartet.
Die Harness kontrolliert die Gateway-Dateien vor einer Freigabe.

## Governance-Gates

Die Harness blockiert, wenn:

- Pflichtdateien fehlen;
- Owner oder Risiko-Verantwortliche fehlen;
- EU-AI-Act-Bewertung offen ist;
- DSGVO-Datenverarbeitung nicht bewertet ist;
- menschliche Aufsicht nicht verpflichtend ist;
- Modellevaluation oder Incident-Prozess offen ist;
- Aufbewahrungsfristen nicht festgelegt sind;
- ein Secret- oder Trivy-Gate fehlschlägt.

## Datenschutzbetrieb

- Roh-Prompts und Roh-Antworten werden nicht dauerhaft gespeichert;
- Testdaten bleiben synthetisch oder werden vor Nutzung redigiert;
- Secret- und PII-Scans laufen vor Evidence-Erzeugung;
- Berichte dürfen keine Tokens, Passwörter oder personenbezogenen Rohdaten enthalten;
- Löschfristen und Verantwortliche stehen in `governance/retention-policy.yaml`.

## ISO/IEC 42001

Der Betrieb muss Zweck, Owner, Risiko, menschliche Aufsicht, Evaluation,
Monitoring, Vorfallbehandlung und kontinuierliche Verbesserung nachweisen.
Ein positives Harness-Ergebnis ersetzt kein KI-Managementsystem.

## EU AI Act

Die Risikokategorie wird je Anwendungsfall bewertet. Transparenz,
Protokollierung, Genauigkeit, Robustheit, Cybersicherheit und menschliche
Aufsicht sind vor einer Freigabe zu dokumentieren.

## Freigabe und Handoff

Ein Harness-Report mit Exit-Code 0 ist ein technischer Nachweis, keine
Produktionsfreigabe. Jede weitere Aktion benötigt den zuständigen menschlichen
Owner und den dokumentierten Übergang zu CI/GitOps.

## Abschalten

Zum Beenden ausschließlich den Prozess der Testkopie auf Port 8100 stoppen.
Die Prozesse auf Ports 8000 und 8001 gehören zum Originalsystem und bleiben
unangetastet.

## Testmodell im Betrieb

Der aktuelle Betrieb deckt Harness-Orchestrator und LLM-/Gateway-Aufruf ab.
Für belastbare Qualitäts- und Sicherheitsnachweise fehlen noch die getrennte
Datensatz-Pipeline, erwartete Referenzergebnisse, unabhängige Grader sowie ein
revisionssicheres Evidence Bundle. Diese Lücke blockiert eine vollständige
Produktionsfreigabe.

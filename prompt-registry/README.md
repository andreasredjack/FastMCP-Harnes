# PostgreSQL-Referenzschema

Dieses Schema ist für den ersten isolierten FastMCP-Harness-Probelauf gedacht.
Es enthält keine Secrets und keine produktiven Nutzdaten.

## Abgedeckte Bereiche

- KI-System-Inventar und Verantwortlichkeiten
- Modellprovenienz und Modellgruppen
- versionierte Prompt-Templates
- Datensätze und Dataset-Versionen
- Evaluation-Suites und Testfälle
- unabhängige Evaluationsergebnisse
- menschliche Freigaben
- Evidence Bundles
- Audit-Ereignisse
- Retention-Metadaten

## Testdatenbank starten

```powershell
Set-Location "H:\VS Code Arbeitsbereiche\FastMCP-Harness\prompt-registry"
docker run --name fastmcp-harness-postgres `
  -e POSTGRES_USER=harness `
  -e POSTGRES_PASSWORD=change-me-test-only `
  -e POSTGRES_DB=harness `
  -p 127.0.0.1:55432:5432 `
  -v fastmcp-harness-postgres:/var/lib/postgresql/data `
  -d postgres:16-alpine
```

Schema einspielen:

```powershell
Get-Content .\schema.sql | docker exec -i fastmcp-harness-postgres `
  psql -U harness -d harness
```

Für einen produktiven Einsatz müssen Passwort, TLS, Rollen, Backup, Restore,
Monitoring und Retention freigegeben werden. `change-me-test-only` darf niemals
produktiv verwendet werden.

## Betriebsgrenzen

- Der FastMCP-Server erhält nur die minimal benötigten Datenbankrechte.
- Das LLM erhält keinen direkten Datenbankzugriff.
- Freigegebene Prompt-Versionen sind unveränderlich.
- Roh-Prompts und Roh-Antworten werden nicht automatisch gespeichert.
- PII- und Secret-Scans laufen vor Evidence-Erzeugung.
- Evaluationsergebnisse referenzieren Modell-, Prompt- und Dataset-Versionen.
- Die Datenbank ersetzt keine rechtliche Prüfung nach DSGVO oder EU AI Act.

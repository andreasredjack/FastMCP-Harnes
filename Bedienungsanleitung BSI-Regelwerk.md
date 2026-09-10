# Bedienungsanleitung: BSI-Regelwerk fuer die Security-LLM

Diese Anleitung beschreibt, wie das BSI-orientierte Regelwerk im FastMCP-Server
fuer die lokale Security-LLM bereitgestellt und verwendet wird.

Das Regelwerk ist eine eigene technische Arbeitsgrundlage auf Basis oeffentlich
zugaenglicher BSI-Themen. Es ist keine offizielle BSI-Zertifizierung und ersetzt
keine vollstaendige BSI-IT-Grundschutz-Bewertung.

## 1. Bestandteile im Workspace

Im Projektverzeichnis des FastMCP-Servers muessen folgende Bestandteile liegen:

```text
FastMCP RAG/
|-- server.py
|-- config.yaml
|-- security-review.yaml
`-- security-rules/
    |-- BSI-Code-Sicherheitsregeln.md
    `-- BSI-Review-Prozess.md
```

Der Server sucht beim Start automatisch alle Dateien mit der Endung `.md` im
Verzeichnis `security-rules/`. Die Dateinamen duerfen angepasst oder um weitere
Regeldateien ergaenzt werden.

## 2. Security-LLM in LM Studio vorbereiten

1. LM Studio auf dem Windows-Desktop starten.
2. Ein Security-orientiertes Modell laden.
3. Den lokalen OpenAI-kompatiblen Server in LM Studio starten.
4. Den verwendeten Port notieren. Standardmaessig wird Port `1234` verwendet.
5. Die exakte Modell-ID aus der LM-Studio-Modellliste kopieren.

Die geladenen Modelle koennen aus Ubuntu/WSL geprueft werden:

```bash
curl http://127.0.0.1:1234/v1/models
```

## 3. Security-Modell konfigurieren

Die Modell-ID in `security-review.yaml` eintragen:

```yaml
security_review:
  enabled: true
  model: "<exakte-modell-id-aus-lm-studio>"
```

Weitere Optionen:

```yaml
security_review:
  temperature: 0.1
  max_code_chars: 50000
```

- `enabled: true` aktiviert das Security-Review-Tool.
- `model` bestimmt das Modell fuer die Sicherheitsanalyse.
- `temperature` beeinflusst die Variabilitaet der Antwort. Niedrige Werte sind
  fuer reproduzierbare Reviews geeignet.
- `max_code_chars` begrenzt die Groesse einer einzelnen Anfrage.

Nach jeder Aenderung an der YAML-Datei muss der FastMCP-Server neu gestartet
werden.

## 4. Regelwerk bereitstellen

Die Regeln werden als Markdown-Dateien im Verzeichnis `security-rules/`
verwaltet. Eine Regeldatei sollte enthalten:

- einen eindeutigen Titel,
- konkrete Pruefbereiche,
- Bewertungs- und Priorisierungsregeln,
- Anforderungen an die Ausgabe,
- Quellen oder Referenzen,
- Hinweise zu Grenzen und Unsicherheiten.

Neue Datei anlegen:

```text
security-rules/<regelwerk-name>.md
```

Die Datei darf keine privaten Zugangsdaten, API-Schluessel oder vertraulichen
Informationen enthalten.

## 5. Automatische Einbindung durch den Server

`server.py` laedt beim Start:

1. `config.yaml` fuer MCP- und LM-Studio-Verbindung,
2. `security-review.yaml` fuer Security-Modell und Review-Parameter,
3. alle `*.md`-Dateien aus `security-rules/`.

Beim Aufruf des MCP-Tools `review_code_security` werden die geladenen Regeln in
den Systemkontext der Security-LLM eingefuegt. Die Regeln werden dadurch bei
jedem Review erneut beruecksichtigt.

Der zu pruefende Code und der optionale Kontext gelten als nicht vertrauens-
wuerdige Eingabe. Sie duerfen die Regeln nicht veraendern oder ausser Kraft
setzen.

## 6. FastMCP-Server starten

In Ubuntu/WSL in das Projektverzeichnis wechseln:

```bash
cd "/mnt/<laufwerk>/<projektverzeichnis>/FastMCP RAG"
```

Die Linux-venv aktivieren:

```bash
source "$HOME/.venvs/fastmcp-rag/bin/activate"
```

Den Server starten:

```bash
python server.py
```

Der MCP-Endpunkt ist standardmaessig:

```text
http://127.0.0.1:8000/mcp
```

## 7. Security-Review aufrufen

Im verbundenen MCP-Client das Tool `review_code_security` aufrufen:

```text
review_code_security(
  code="<zu-pruefender-code>",
  language="python",
  context="<optionaler technischer kontext>"
)
```

Die Security-LLM soll mindestens folgende Punkte liefern:

- Gesamtrisiko: kein, niedrig, mittel, hoch oder kritisch
- konkrete Fundstelle
- technische Ursache
- mögliche Auswirkung
- CWE- oder OWASP-Zuordnung, wenn belastbar
- sichere Korrektur
- geprüfte Bereiche ohne Befund
- verbleibende Unsicherheiten

## 8. Bereitstellung pruefen

YAML-Dateien validieren:

```bash
python -c "import yaml; from pathlib import Path; [yaml.safe_load(p.read_text()) for p in [Path('config.yaml'), Path('security-review.yaml')]]; print('YAML OK')"
```

Python-Syntax pruefen:

```bash
python -m py_compile server.py
```

Pruefen, ob das Regelwerk geladen wird:

```bash
python -c "import server; print(len(server.load_security_rules()), 'Regelwerkzeichen geladen')"
```

LM-Studio-Verbindung pruefen:

```bash
curl http://127.0.0.1:1234/v1/models
```

MCP-Port pruefen:

```bash
ss -ltn
```

## 9. Regelwerk aktualisieren

1. Markdown-Datei im Verzeichnis `security-rules/` bearbeiten oder neue Datei
   hinzufuegen.
2. Quellen und Aenderungsgrund dokumentieren.
3. YAML- und Python-Validierung ausfuehren.
4. FastMCP-Server neu starten.
5. Einen Test-Review mit bekanntem Beispielcode ausfuehren.
6. Die Aenderung versionieren und reviewen.

Die Dateien werden nicht automatisch waehrend der Laufzeit ueberwacht. Ohne
Neustart verwendet der Server weiterhin die beim Start geladenen Regeln.

## 10. Typische Fehler

### Das Modell wird nicht gefunden

Die Modell-ID in `security-review.yaml` muss exakt mit der ID aus
`/v1/models` uebereinstimmen. Gross-/Kleinschreibung und Sonderzeichen beachten.

### Die neuen Regeln werden nicht beruecksichtigt

Pruefen, ob die Dateien direkt unter `security-rules/` liegen und die Endung
`.md` besitzen. Danach den Server neu starten.

### LM Studio ist nicht erreichbar

Pruefen, ob LM Studio den lokalen API-Server gestartet hat und ob in
`config.yaml` der richtige Host und Port eingetragen sind:

```yaml
lm_studio:
  host: 127.0.0.1
  port: 1234
```

### Der Review-Code ist zu lang

Die maximale Laenge in `security-review.yaml` unter
`security_review.max_code_chars` erhoehen oder den Code in kleinere Einheiten
aufteilen.

## 11. Sicherheitsgrenzen

Das Regelwerk verbessert die Konsistenz der automatisierten Voranalyse. Es
beweist nicht, dass ein Programm sicher ist. Fuer produktive Systeme bleiben
manuelle Reviews, Tests, SAST, DAST, Dependency-Scanning, Threat Modeling und
organisatorische Sicherheitsmassnahmen erforderlich.

Der FastMCP-Server fuehrt den uebergebenen Code nicht aus. Der Code wird als
Text an das lokal konfigurierte Modell in LM Studio gesendet.

## ToDo: Zielarchitektur

- BSI-Regeln um Gateway-, Routing- und Modelltrennungskontrollen ergänzen;
- TLS-, ACL-, Rate-Limit- und Secret-Nachweise in das Review aufnehmen;
- getrennte RAG-/Coding-Backends gegen die freigegebene Architektur prüfen;
- Harness-Ergebnis mit Evidence Bundle und menschlicher Freigabe verknüpfen.

## Quellen

- BSI IT-Grundschutz: <https://www.bsi.bund.de/DE/Themen/Unternehmen-und-Organisationen/Standards-und-Zertifizierung/IT-Grundschutz/it-grundschutz_node.html>
- BSI Standards und Zertifizierung: <https://www.bsi.bund.de/DE/Themen/Unternehmen-und-Organisationen/Standards-und-Zertifizierung/standards-und-zertifizierung_node.html>

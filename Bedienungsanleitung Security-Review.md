# Bedienungsanleitung: Lokale Code-Sicherheitsprüfung

Diese Anleitung beschreibt die Sicherheitsprüfung von Code mit dem lokalen
Security-Modell in LM Studio und dem FastMCP-Server unter Ubuntu/WSL.

## Voraussetzungen

- Ubuntu unter WSL 2 ist gestartet.
- LM Studio laeuft auf dem Windows-Desktop.
- In LM Studio ist ein Security-orientiertes Modell geladen.
- Der OpenAI-kompatible LM-Studio-Server laeuft auf dem konfigurierten Port.
- Die FastMCP-Abhaengigkeiten sind in der Ubuntu-venv installiert.

## 1. Security-Modell in LM Studio laden

1. Ein Modell auswaehlen, das fuer Codeanalyse oder Application Security
ausgerichtet ist.
2. Das Modell in LM Studio laden.
3. Den exakten Modellnamen aus der LM-Studio-Modellliste kopieren.
4. Sicherstellen, dass der lokale OpenAI-kompatible Server aktiv ist.

Der Modellname muss exakt der von LM Studio gemeldeten ID entsprechen.

## 2. Security-YAML konfigurieren

Die zentrale Datei ist:

```text
security-review.yaml
```

Dort die Modell-ID eintragen:

```yaml
security_review:
  enabled: true
  model: "<modell-id-aus-lm-studio>"
```

Weitere Einstellungen:

- `enabled`: aktiviert oder deaktiviert das Review-Tool.
- `temperature`: niedrige Werte erzeugen reproduzierbarere Antworten.
- `max_code_chars`: begrenzt die Menge Code pro Anfrage.
- `system_prompt`: beschreibt die Regeln und das Ausgabeformat der Prüfung.

Die Datei `config.yaml` bleibt für die allgemeine Verbindung zu LM Studio und
den MCP-Port zuständig.

## 3. FastMCP-Server starten

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

Der MCP-Endpunkt lautet standardmaessig:

```text
http://127.0.0.1:8000/mcp
```

Nach jeder Aenderung an einer YAML-Datei muss der Server neu gestartet werden.

## 4. Verbindung pruefen

LM-Studio-Modelle aus Ubuntu pruefen:

```bash
curl http://127.0.0.1:1234/v1/models
```

Den MCP-Port pruefen:

```bash
ss -ltn
```

Eine erfolgreiche Verbindung zu LM Studio bedeutet, dass eine Antwort mit einer
Liste geladener Modelle zurueckkommt.

## 5. Security-Review ausfuehren

Im verbundenen MCP-Client das Tool `review_code_security` auswaehlen und diese
Argumente uebergeben:

```text
code: Der zu pruefende Quellcode
language: Die Programmiersprache, zum Beispiel python, javascript oder bash
context: Optionaler technischer Kontext zum Code
```

Beispiel:

```text
review_code_security(
  code="password = input()",
  language="python",
  context="Kleine Eingaberoutine fuer ein internes Tool"
)
```

Die Antwort enthaelt:

1. ein Kurzfazit mit Risikostufe,
2. Findings mit Schweregrad,
3. CWE- oder OWASP-Zuordnung, wenn eindeutig,
4. Fundstelle und technische Begruendung,
5. Auswirkung,
6. konkrete Korrekturvorschlaege,
7. gepruefte Bereiche ohne Befund,
8. offene Unsicherheiten.

## 6. Sicherheitsgrenzen

Das Tool ist eine Unterstuetzung fuer Code-Reviews und ersetzt keine manuelle
Pruefung, Tests oder spezialisierten SAST-/DAST-Werkzeuge.

Der FastMCP-Server fuehrt den uebergebenen Code nicht aus. Der Code wird als
Text an LM Studio gesendet. Trotzdem sollte kein vertraulicher Quellcode an ein
Modell gesendet werden, wenn dessen lokale Datenverarbeitung nicht gewuenscht
oder nicht geklaert ist.

Ein negatives Review-Ergebnis beweist nicht, dass der Code sicher ist. Besonders
wichtig bleiben Abhaengigkeitspruefungen, Geheimnisschutz, Berechtigungen,
Netzwerkgrenzen, Eingabevalidierung und Tests.

## 7. Typische Probleme

### Das Security-Modell wird nicht gefunden

Die Modell-ID in `security-review.yaml` muss exakt mit der LM-Studio-Modell-ID
uebereinstimmen. Die IDs koennen mit diesem Befehl angezeigt werden:

```bash
curl http://127.0.0.1:1234/v1/models
```

### Das Tool verwendet das falsche Modell

Pruefen, ob `security_review.model` gesetzt ist. Danach den FastMCP-Server neu
starten. Die Prioritaet lautet:

1. Umgebungsvariable `SECURITY_MODEL`,
2. `security-review.yaml` unter `security_review.model`,
3. `config.yaml` unter `lm_studio.security_model`,
4. allgemeines LM-Studio-Modell.

### LM Studio ist nicht erreichbar

Pruefen, ob LM Studio den lokalen Server gestartet hat und ob Port und Host in
`config.yaml` stimmen. In der beschriebenen WSL-Umgebung ist der Standard:

```yaml
lm_studio:
  host: 127.0.0.1
  port: 1234
```

### Der Server verwendet alte Einstellungen

Den laufenden FastMCP-Prozess beenden und mit `python server.py` neu starten.
YAML-Aenderungen werden nicht waehrend der Laufzeit automatisch eingelesen.

### Der Code ist zu lang

Die maximale Groesse wird in `security-review.yaml` unter
`security_review.max_code_chars` eingestellt. Fuer grosse Projekte den Code in
kleinere, fachlich zusammengehoerige Einheiten aufteilen.

# Governance-Modell FastMCP-Harness

## Zweck

Das Projekt verbindet technische Harness-Gates mit Governance-Anforderungen für
ISO/IEC 42001, den EU AI Act und DSGVO/BDSG. Die Dateien sind versionierte
Kontrollinputs, keine automatische Rechtsbewertung.

## ISO/IEC 42001

Nachzuweisen sind:

- KI-System-Inventar mit Zweck, Modell, Owner und Risiko-Owner;
- Risiko- und Auswirkungsbewertung;
- Modell- und Prompt-Provenienz;
- Evaluation für Prompt-Injection, Halluzination, Redaction und Tool-Missbrauch;
- menschliche Aufsicht vor Sicherheitsentscheidungen und externen Ausgaben;
- Incident-, Abschalt- und Verbesserungsprozess;
- Evidence Bundle mit Policy- und Konfigurationshashes.

## EU AI Act

Die konkrete Einstufung erfolgt anwendungsbezogen. Das Harness erzwingt daher:

- dokumentierten Zweck;
- Prüfung verbotener Praktiken;
- dokumentierte Risikokategorie;
- Transparenzhinweis;
- menschliche Aufsicht;
- Protokollierung und Evaluation;
- Robustheits- und Cybersicherheitsprüfung;
- benannten rechtlichen und betrieblichen Verantwortlichen.

`assessment_required` und `pending` blockieren die technische Freigabe.

## DSGVO/BDSG

Der lokale Betrieb von LM Studio beseitigt Datenschutzpflichten nicht.
Entscheidend sind Datenart, Zweck und Verarbeitungsszenario. Zu prüfen sind:

- personenbezogene und besondere Kategorien;
- Rechtsgrundlage und Zweckbindung;
- Datenminimierung;
- Prompt-/Response-Logging;
- Aufbewahrung und Löschung;
- Zugriff und Rollen;
- DPIA-/Verarbeitungsverzeichnis-Status;
- mögliche Drittlandübermittlung.

Rohdaten werden im Evidence Bundle nicht gespeichert.

## Fail-Closed-Prinzip

Die Harness beendet die Prüfung mit Fehler, wenn Pflichtdateien fehlen oder
Governance-Werte offen sind. Das verhindert, dass ein technisch grüner Lauf als
rechtliche oder organisatorische Freigabe missverstanden wird.

## Aussagegrenze

Das Projekt ist eine technische Kontroll- und Testumgebung. Es stellt keine
ISO-42001-Zertifizierung, EU-AI-Act-Konformität, DSGVO-Bewertung oder formale
BSI-/C5-Testierung dar. Diese Aussagen erfordern zuständige Rollen,
Dokumentprüfung und gegebenenfalls unabhängige Bewertung.

## ToDo: Zielarchitektur

- verantwortliche Rollen und Freigabematrix benennen;
- EU-AI-Act-Risikoklassifikation und rechtliche Prüfung abschließen;
- DSGVO-Rechtsgrundlage, DPIA-Entscheidung und Löschfristen festlegen;
- ISO-42001-Risikoregister, Evaluation und Verbesserungsprozess nachweisen;
- PII-/Secret-Scan, Modellprovenienz und Evidence Bundle implementieren;
- Gateway-ACLs, menschliche Aufsicht und Incident-Prozess freigeben.

## Prompt-Registry

Das Schema `prompt-registry/schema.sql` verbindet Prompt-, Modell-, Dataset- und
Evaluation-Versionen mit Freigaben und Audit-Ereignissen. Es unterstützt
ISO-42001-Provenienz, EU-AI-Act-Evaluation und DSGVO-Retention, ersetzt aber
keine rechtliche Bewertung. Genehmigte Prompt-Versionen bleiben unveränderlich.

## Testmodell und Nachweisgrenze

Ein Harness-Ergebnis bewertet derzeit technische Gates und Governance-Eingaben.
Es ersetzt keine unabhängige Evaluation der LLM-Ausgaben. Für ISO-42001-,
EU-AI-Act- und DSGVO-relevante Nachweise müssen Testdatensätze, Grader,
Referenzergebnisse, Modellprovenienz und Evidence Bundle getrennt versioniert
werden.

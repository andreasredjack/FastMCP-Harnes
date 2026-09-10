# BSI-orientierte Regeln fuer sichere Codepruefung

Dieses Dokument ist eine eigene, technische Arbeitsgrundlage fuer Code-Reviews.
Es ist eine Zusammenfassung und Operationalisierung oeffentlich zugaenglicher
BSI-Themen, keine offizielle BSI-Zertifizierung und kein Ersatz fuer eine
Risikoanalyse nach BSI IT-Grundschutz.

## Verbindliche Pruefbereiche

### 1. Schutzbedarf und Sicherheitsziele

- Erkenne schutzbeduerftige Daten, insbesondere Zugangsdaten, personenbezogene
  Daten, Gesundheitsdaten, Finanzdaten und interne Geheimnisse.
- Pruefe Vertraulichkeit, Integritaet, Verfuegbarkeit und Nachvollziehbarkeit.
- Bewerte die Auswirkung eines Missbrauchs getrennt von der Wahrscheinlichkeit.
- Fordere fehlenden Kontext an, statt eine niedrige Gefaehrdung zu behaupten.

### 2. Eingaben und Ausgaben

- Behandle jede externe Eingabe als nicht vertrauenswuerdig.
- Pruefe Typ, Format, Laenge, Wertebereich und Zeichencodierung.
- Suche nach Injection-Risiken in SQL, Shell, Template-, LDAP-, XPath-,
  NoSQL- und Prompt-Kontexten.
- Pruefe Ausgaben auf kontextgerechte Kodierung und unbeabsichtigte
  Informationspreisgabe.

### 3. Identitaet, Authentisierung und Berechtigungen

- Pruefe sichere Passwortverarbeitung, Session-Schutz und Tokenlebensdauer.
- Pruefe Least Privilege, serverseitige Autorisierung und Trennung von Rollen.
- Suche nach IDOR/BOLA, fehlenden Zugriffskontrollen und Privilege Escalation.
- Geheimnisse duerfen nicht im Quelltext, in Logs oder Fehlermeldungen stehen.

### 4. Kryptografie und sichere Kommunikation

- Verwende etablierte Bibliotheken und sichere Standardverfahren.
- Suche nach selbst implementierter Kryptografie, schwachen Algorithmen,
  hartcodierten Schluesseln und unsicherer Zufallszahlenerzeugung.
- Pruefe TLS-/Zertifikatsvalidierung und den Schutz von Schluesseln im Betrieb.
- Bewerte Schluesselrotation, Ablauf und sichere Speicherung.

### 5. Fehlerbehandlung, Protokollierung und Monitoring

- Fehlermeldungen duerfen keine Geheimnisse, Tokens, Stacktraces oder internen
  Pfade an unberechtigte Empfaenger ausgeben.
- Sicherheitsrelevante Ereignisse muessen nachvollziehbar, aber datensparsam
  protokolliert werden.
- Pruefe Log Injection, fehlende Ereigniszeit, fehlende Korrelation und
  manipulierbare Protokolle.
- Sicherheitsfehler duerfen nicht stillschweigend ignoriert werden.

### 6. Abhaengigkeiten und Lieferkette

- Pruefe ungepinnt oder unkontrolliert bezogene Abhaengigkeiten.
- Suche nach unsicheren Standardkonfigurationen, veralteten Bibliotheken und
  fehlender Integritaetspruefung.
- Pruefe, ob Build-, Installations- und Laufzeitrechte minimiert sind.
- Beruecksichtige Secrets und sensible Artefakte in CI/CD-Konfigurationen.

### 7. Ressourcen und Verfuegbarkeit

- Suche nach fehlenden Limits fuer Eingaben, Dateien, Rekursion, Threads,
  Speicher, Laufzeit und externe Aufrufe.
- Pruefe Denial-of-Service-Risiken, ungebremste Wiederholungen und fehlende
  Timeouts.
- Bewerte sichere Abbruch- und Wiederanlaufverhalten.

### 8. Datenschutz und Datenminimierung

- Verarbeite nur Daten, die fuer den Zweck erforderlich sind.
- Pruefe Speicherung, Weitergabe, Aufbewahrung und Loeschung sensibler Daten.
- Weise darauf hin, wenn Code Daten an externe Dienste oder Modelle sendet.

## Bewertungsregeln

1. Trenne bestaetigte Befunde, plausible Risiken und offene Fragen.
2. Nenne die konkrete Fundstelle und die ausnutzbare Ursache.
3. Ordne nur dann CWE oder OWASP zu, wenn die Zuordnung belastbar ist.
4. Priorisiere nach Auswirkung und Ausnutzbarkeit, nicht nach der Anzahl der
   Findings.
5. Liefere immer eine konkrete, sichere Korrektur und moegliche Folgerisiken.

## Referenzen

- BSI, IT-Grundschutz: <https://www.bsi.bund.de/DE/Themen/Unternehmen-und-Organisationen/Standards-und-Zertifizierung/IT-Grundschutz/it-grundschutz_node.html>
- BSI, Standards und Zertifizierung: <https://www.bsi.bund.de/DE/Themen/Unternehmen-und-Organisationen/Standards-und-Zertifizierung/standards-und-zertifizierung_node.html>
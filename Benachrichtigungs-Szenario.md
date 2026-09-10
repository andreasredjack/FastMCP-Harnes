# Benachrichtigungs-Szenario fuer Policy-Aenderungen

Dieses Szenario beschreibt, wie Servicepersonal ueber Jira-Tickets ueber
Aenderungen, Pruefungen und Stoerungen im Policy-Regelwerk informiert wird.

Confluence oder Git bleibt die technische Quelle der Policies. Jira verwaltet
Aufgaben, Zuständigkeiten, Freigaben, Eskalationen und Nachweise. Das LLM darf
keine Freigabe simulieren und kein Jira-Ticket eigenstaendig schliessen.

## Ziel

Jede relevante Policy-Aenderung soll:

- einer verantwortlichen Person zugewiesen werden;
- fachlich und technisch geprueft werden;
- nachvollziehbar freigegeben werden;
- kontrolliert im Cluster ausgerollt werden;
- fuer Servicepersonal und Betreiber sichtbar sein;
- bei Fehlern oder Fristueberschreitungen eskaliert werden.

## Standardablauf

```text
Policy-Entwurf in Confluence oder Git
  -> Jira-Ticket wird erstellt oder aktualisiert
  -> Servicepersonal wird zugewiesen
  -> fachliche Pruefung
  -> technische Pruefung und Security-Review
  -> Freigabe durch mindestens zwei berechtigte Personen
  -> Policy wird veroeffentlicht
  -> FastMCP uebernimmt die neue Version
  -> Aktivierung im Cluster wird verifiziert
  -> Jira-Ticket wird dokumentiert und geschlossen
```

Eine Aenderung darf nicht allein deshalb als erfolgreich gelten, weil das LLM
einen positiven Text erzeugt hat. Entscheidend sind die technischen Nachweise
und die menschlichen Freigaben.

## Jira-Tickettypen

### Policy Change

Wird bei einer neuen oder geaenderten Policy angelegt.

### Policy Review

Wird fuer eine regelmaessige Wiedervorlage und Aktualitaetspruefung angelegt.

### Policy Incident

Wird bei einer Regelverletzung, einem fehlenden Policy-Stand oder einer
fehlerhaften Aktivierung angelegt.

### Policy Exception

Dokumentiert eine zeitlich und sachlich begrenzte Ausnahme. Eine Ausnahme muss
eine Begruendung, einen Ablaufzeitpunkt, einen Scope und eine verantwortliche
Freigabe enthalten.

### Policy Retirement

Dokumentiert die kontrollierte Ausserkraftsetzung einer Policy.

## Pflichtfelder

Jedes Ticket muss mindestens folgende Angaben enthalten:

- Policy-ID und Titel;
- Confluence-Seitenlink oder Git-Commit;
- bisherige und neue Version;
- Aenderungstyp;
- Aenderungsbegruendung;
- betroffene Cluster, LLMs und MCP-Tools;
- betroffener Repository-, Pfad- und Ressourcenscope;
- Schutzbedarf und Risikoeinschaetzung;
- Policy-Hash, falls die Version freigegeben ist;
- erforderliche Pruefungen;
- verantwortliche Person und Stellvertretung;
- Frist und Eskalationsstufe;
- Status der menschlichen Freigaben.

Secrets, API-Tokens, Passwoerter und private Schluessel duerfen nicht in Jira-
Feldern, Kommentaren oder Anhängen gespeichert werden.

## Statusworkflow

```text
Entwurf
  -> Pruefung erforderlich
  -> Technische Pruefung
  -> Security-Review
  -> Freigabe ausstehend
  -> Freigegeben
  -> Ausgerollt
  -> Verifiziert
  -> Geschlossen
```

Zulaessige Rueckspruenge sind:

```text
Pruefung erforderlich -> Aenderungen notwendig
Technische Pruefung -> Fehler
Ausgerollt -> Rollback erforderlich
```

Die Statuswechsel `Freigegeben`, `Ausgerollt`, `Verifiziert` und `Geschlossen`
muessen entweder durch berechtigte Personen oder durch nachweisbare technische
Pruefungen erfolgen.

## Benachrichtigungen

Das Servicepersonal kann ueber folgende Kanaele informiert werden:

- Jira-In-App-Benachrichtigung;
- E-Mail an die zustaendige Gruppe;
- Microsoft Teams oder Slack;
- taegliche Zusammenfassung offener Policy-Tickets;
- sofortige Eskalation bei kritischen Ereignissen;
- Erinnerung vor Ablauf einer Pruefungs- oder Ausnahmefrist.

Die Benachrichtigung soll immer die Jira-Ticketnummer, Prioritaet, Policy-ID,
betroffene Umgebung, erforderliche Aktion und Frist enthalten.

## Sofort zu meldende Ereignisse

Eine sofortige Benachrichtigung mit hoher oder kritischer Prioritaet ist
erforderlich, wenn:

- der Policy-Hash nicht stimmt;
- eine freigegebene Policy nicht erreichbar ist;
- eine Policy ohne erwartete Freigabe geaendert wurde;
- ein Trivy- oder Secret-Scan fehlschlaegt;
- ein LLM eine veraltete Policy verwendet;
- ein Cluster vom freigegebenen Policy-Stand abweicht;
- eine Policy ungueltig, abgelaufen oder nicht mehr freigegeben ist;
- ein Rollback notwendig wird;
- eine nicht erlaubte Schreibaktion erkannt wird.

Bei einem solchen Ereignis muss der betroffene Freigabe- oder Rollout-Prozess
angehalten werden. Das System darf nicht automatisch auf eine unbekannte Policy
ausweichen.

## Automatisierung

Eine Confluence- oder Git-Aenderung kann ueber einen Webhook, eine CI/CD-
Pipeline oder eine geplante Abfrage die Jira-REST-API ausloesen. Dabei wird ein
Ticket mit dem Status `Pruefung erforderlich` angelegt oder aktualisiert.

Der FastMCP-Server kann nach einer erfolgreichen technischen Pruefung einen
Kommentar in Jira schreiben:

```text
Policy core-policy erfolgreich aktiviert.

Version: 12
Quelle: Confluence
Page-ID: 123456
SHA-256: <hash>
Betroffene Umgebung: production-01
Verwendete LLMs: <modell-ids>
Zeitpunkt: <timestamp>
Trivy-Ergebnis: bestanden
Security-Review: bestanden
```

Vor dem Statuswechsel auf `Verifiziert` müssen Policy-Version, Hash,
betroffene Umgebung und technische Prüfergebnisse dokumentiert sein.

Webhooks dürfen nicht blind vertraut werden. Nach einem Änderungsereignis muss
der FastMCP-Server die Policy erneut laden und Version, Status, Scope und Hash
prüfen.

## Rollen und Verantwortlichkeiten

### Policy Owner

Verantwortet Inhalt, Zweck, Geltungsbereich und fachliche Aktualität der
Policy.

### Servicepersonal

Überwacht offene Tickets, prüft Betriebsfolgen, koordiniert die Bearbeitung und
eskaliert Fristüberschreitungen oder kritische Abweichungen.

### Security Reviewer

Bewertet Sicherheitsauswirkungen, Trivy-/Secret-Scan-Ergebnisse und die
Einhaltung des Security-Regelwerks.

### Plattform- oder Clusterverantwortliche

Prüfen Plan und Diff, kontrollieren den Rollout und bestätigen die technische
Verifikation im Cluster.

### LLM

Erstellt Analysen, Änderungsvorschläge, Zusammenfassungen und Prüfhilfen. Das
LLM besitzt keine alleinige Freigabekompetenz und darf keine produktiven
Änderungen direkt anwenden.

## Nachweise und Audit

Für jedes Ticket sind mindestens zu dokumentieren:

- Zeitstempel und aufrufender Client;
- Policy-ID, Quelle und Version;
- Policy-Hash;
- betroffener Repository-, Cluster- und Pfad-Scope;
- verwendetes Modell und Modell-ID;
- Trivy-Version und Scan-Ergebnis;
- Security-Review-Ergebnis;
- Plan- oder Diff-Ergebnis;
- menschliche Freigaben;
- Rollout- und Verifikationsergebnis;
- gegebenenfalls Rollback und Ursache.

Die eigentlichen Secrets und nicht erforderliche vertrauliche Inhalte werden
nicht protokolliert.

## Eskalationsmodell

| Stufe | Beispiel | Reaktion |
| --- | --- | --- |
| Niedrig | Regelmaessige Policy-Review faellig | Erinnerung an Policy Owner |
| Mittel | Technische Pruefung oder Frist ueberfaellig | Benachrichtigung an Servicepersonal und Stellvertretung |
| Hoch | Scan fehlgeschlagen oder Policy-Stand abweichend | Rollout stoppen und Plattformverantwortliche informieren |
| Kritisch | Unautorisierte Aenderung, Hash-Konflikt oder Produktionsrisiko | Sofortige Eskalation, Prozess sperren, Incident bearbeiten |

## Grundregeln fuer Jira-Automatisierung

- Jira enthaelt Nachweise, aber nicht die alleinige technische Policy-Quelle.
- Ein LLM darf kein Ticket als `Freigegeben` oder `Geschlossen` markieren.
- Freigaben muessen einer berechtigten Person oder einem eindeutig
  nachvollziehbaren technischen Gate zugeordnet sein.
- Automationen muessen idempotent sein und dürfen keine Ticketflut durch
  wiederholte Webhook-Zustellung erzeugen.
- Jede Automation braucht einen definierten Service-Account und minimale
  Rechte.
- Kommentare und Benachrichtigungen werden auf notwendige Informationen
  begrenzt.
- Kritische Tickets duerfen nicht automatisch unterdrueckt, zusammengefuehrt
  oder geschlossen werden.
- Nach einem Rollback wird ein neues Folge-Ticket oder ein dokumentierter
  Incident-Nachweis erstellt.

## Ergebnis

Das Servicepersonal erhält über Jira eine priorisierte, zugewiesene und
nachvollziehbare Aufgabenliste. Confluence oder Git bleibt die kontrollierte
Policy-Quelle. FastMCP validiert die Policy und liefert technische Nachweise.
Jira verbindet diese Nachweise mit Verantwortlichen, Freigaben,
Benachrichtigungen und Eskalationen.
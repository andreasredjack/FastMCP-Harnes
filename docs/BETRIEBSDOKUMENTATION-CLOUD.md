# Betriebsdokumentation FastMCP-Harness in einer Cloudinfrastruktur

**Dokumenttyp:** verbindliche technische Betriebsdokumentation
**System:** FastMCP-Harness mit Nginx, LiteLLM, PostgreSQL-Prompt-Registry und getrennten Modellgruppen
**Zielumgebung:** Cloudinfrastruktur mit containerisiertem bzw. Kubernetes-basiertem Betrieb
**Status:** Referenz für Aufbau, Betrieb und Freigabe; keine formale Zertifizierung
**Version:** 1.0

## 1. Zweck und Geltungsbereich

Diese Betriebsdokumentation beschreibt den sicheren Betrieb des FastMCP-Harness-
Systems in einer Cloudinfrastruktur. Sie umfasst den Edge-Zugriff, das Gateway,
die FastMCP-Anwendung, die Prompt-Registry, Modellgruppen, Evaluation, Governance,
Monitoring, Backup, Incident Response und die kontrollierte Freigabe.

Das System verarbeitet KI-Anfragen und Security-Review-Aufträge. Es darf keine
unbeaufsichtigten Produktionsmutationen ausführen. Insbesondere sind Commits,
Pushes, Deployments, `kubectl apply`, `helm upgrade`, `terraform apply` und
`terraform destroy` nicht Teil des FastMCP-Harness-Betriebs.

## 2. Verbindliche Aussagegrenze

Das System ist technisch an ISO/IEC 42001, EU AI Act, DSGVO/BDSG und BSI-/C5-
Kontrollzielen ausgerichtet. Daraus folgt keine automatische Zertifizierung,
Rechtskonformität oder unabhängige Prüfung.

Die zuständigen Rollen müssen je Einsatzfall bewerten:

- EU-AI-Act-Risikokategorie und Betreiberpflichten;
- DSGVO-Rechtsgrundlage, Zweckbindung und DPIA-Erfordernis;
- Datenklassifikation und Drittlandübermittlung;
- Aufbewahrung und Löschung;
- Verantwortlichkeiten und menschliche Aufsicht;
- Cloud-Provider-, Vertrags- und Auditnachweise.

## 3. Cloud-Zielarchitektur

```text
Benutzer / Entwickler
        |
        | TLS 1.3, Authentifizierung, Rate Limiting
        v
Nginx / Edge Proxy
        |
        | ACL, Token-Tracking, Modellalias
        v
LiteLLM Gateway
        |
        +--> Ollama RAG Backend
        |      RAG-Modelle, eigenes Netzwerk/Volume
        |
        +--> Ollama Coding Backend
               Coding-Modelle, eigenes Netzwerk/Volume

FastMCP-Harness
        |
        +--> LiteLLM Gateway
        +--> PostgreSQL Prompt Registry
        +--> Datensatz-/Evaluation-Suite
        +--> Evidence Bundle
```

### 3.1 Cloud-Komponenten

| Komponente | Betriebsfunktion | Mindestkontrolle |
|---|---|---|
| Nginx | TLS-Termination, Rate Limit, Header | TLS 1.3, Zertifikatsrotation, kein direkter Backendzugriff |
| LiteLLM | Routing, ACLs, Token-Tracking | API-Keys, Modell-Allowlist, Auditlogs |
| FastMCP | Tools, Orchestrierung, Security Review | read-only, Tool-Allowlist, Human Oversight |
| Ollama RAG | RAG-Modelle | eigenes Netzwerk, Volume und Ressourcenlimit |
| Ollama Coding | Coding-Modelle | eigenes Netzwerk, Volume und Ressourcenlimit |
| PostgreSQL | Prompt-/Evaluation-/Evidence-Metadaten | TLS, Rollen, Backup, Restore, Retention |
| Evaluation-Suite | unabhängige Bewertung | getrenntes Bewertungssystem, reproduzierbare Grader |

## 4. Mandanten-, Netzwerk- und Zugriffsmodell

Die Cloudumgebung wird logisch in mindestens folgende Zonen getrennt:

1. Edge-Zone für Nginx;
2. Gateway-Zone für LiteLLM;
3. Application-Zone für FastMCP;
4. RAG-Backend-Zone;
5. Coding-Backend-Zone;
6. Datenzone für PostgreSQL und Evidence Storage;
7. Monitoring-/Audit-Zone.

Verbindliche Regeln:

- Ollama ist niemals öffentlich erreichbar;
- LiteLLM ist der einzige Modellgateway;
- FastMCP verwendet bevorzugt ausschließlich LiteLLM;
- RAG- und Coding-Backends besitzen getrennte Netzwerkregeln;
- PostgreSQL ist nur aus dem autorisierten Application-Scope erreichbar;
- Datenbankzugriff erfolgt mit minimalen Rollen;
- Cloud- und Kubernetes-ServiceAccounts werden nicht gemeinsam genutzt;
- Adminzugriffe erfolgen über einen kontrollierten Bastion-/Identity-Prozess;
- alle externen Zugriffe werden authentifiziert, autorisiert und protokolliert.

## 5. TLS, Identität und Secrets

### 5.1 TLS

- öffentlich erreichbare Schnittstellen verwenden TLS 1.3;
- Zertifikate stammen aus der freigegebenen ACME-/PKI-Infrastruktur;
- private Schlüssel werden ausschließlich über Secret-/Key-Management bezogen;
- Zertifikatsablauf und Revocation werden überwacht;
- interne TLS-Anforderungen werden je Daten- und Risikoklasse festgelegt;
- veraltete Protokolle und schwache Cipher werden deaktiviert.

### 5.2 Identität

- zentrale Identität über den freigegebenen Identity Provider;
- MFA für Benutzer und privilegierte Rollen;
- getrennte Rollen für Betrieb, Security, Datenschutz, Audit und Entwicklung;
- kurzlebige Tokens und kontrollierte Refresh-Tokens;
- regelmäßige Rezertifizierung und Deprovisionierung;
- ServiceAccounts je Umgebung und Komponente.

### 5.3 Secrets

Secrets dürfen nicht in Git, Images, Logs, Prompts, Reports oder Terraform-Plans
erscheinen. Das gilt insbesondere für:

- LiteLLM-API-Keys;
- PostgreSQL-Passwörter;
- Cloud-Credentials;
- Registry-Token;
- Zertifikatsschlüssel;
- Modell- oder Provider-Schlüssel.

## 6. FastMCP-Betrieb

FastMCP läuft als unprivilegierter Service mit:

- read-only Repository-Mounts, sofern ein Repository geprüft wird;
- keiner Docker-/Kubernetes-Socket-Einbindung;
- keiner Shell-Ausführung aus LLM-Tools;
- keiner direkten Deploymentberechtigung;
- maximaler Prompt- und Codegröße;
- Request-Timeouts und Rate Limits;
- Tool-Allowlist und deny-by-default;
- expliziter Kennzeichnung `human_review_required`;
- strukturierten, redigierten Ergebnissen.

Die Produktionskonfiguration darf keinen direkten LM-Studio- oder Ollama-Fallback
verwenden. Der Gateway-Endpunkt und der Modellalias werden kontrolliert aus
Secret-/Konfigurationsquellen bezogen.

## 7. Prompt-Registry und PostgreSQL

Die PostgreSQL-Registry liegt im Projekt unter `prompt-registry/schema.sql`.
Sie umfasst:

- `ai_systems` für Zweck, Owner und Risikoverantwortung;
- `models` für Provider, Modellgruppe und Freigabe;
- `prompt_templates` und `prompt_versions`;
- `datasets` und `dataset_versions`;
- `evaluation_suites`, `evaluation_cases` und `evaluation_runs`;
- `evaluation_results` mit unabhängiger Richterkennung;
- `approvals` für menschliche Freigaben;
- `evidence_bundles`;
- `audit_events`.

### 7.1 Betriebsregeln

- das LLM erhält keinen Datenbankzugriff;
- der FastMCP-Service verwendet eine minimale Datenbankrolle;
- genehmigte Prompt-Versionen sind unveränderlich;
- Änderungen erzeugen neue Versionen;
- Roh-Prompts und Roh-Antworten werden nicht automatisch gespeichert;
- PII-/Secret-Scan erfolgt vor Evidence-Erzeugung;
- PostgreSQL wird mit TLS, Backup, Restore, Monitoring und Retention betrieben;
- Schemaänderungen erfolgen über versionierte Migrationen;
- Datenbankzugriffe werden auditierbar protokolliert.

## 8. Datensatz-Pipeline und Evaluation

Der vollständige Testprozess besteht aus:

```text
Datensatz-Pipeline
        -> Harness-Orchestrator
        -> LLM / Applikation
        -> unabhängige Evaluation-Suite / Richter
        -> Evidence Bundle
        -> menschliche Freigabe
```

### 8.1 Datensätze

Datensätze müssen:

- versioniert und reproduzierbar sein;
- eine Datenklassifikation besitzen;
- PII-bereinigt oder pseudonymisiert sein;
- erwartete Ergebnisse und Akzeptanzkriterien enthalten;
- Prompt-Injection-, Secret-, Halluzinations- und No-Mutation-Fälle enthalten;
- einen Owner und eine Retention besitzen.

### 8.2 Richter

Der Richter darf nicht identisch mit dem bewerteten LLM sein, wenn dadurch eine
unabhängige Bewertung verhindert wird. Ergebnisse enthalten mindestens:

- Suite- und Dataset-Version;
- Prompt-Version;
- Modellalias und Provenienz;
- Gradername und Grader-Version;
- Score und Status;
- redigierte Notizen;
- Evidence-Hash.

## 9. ISO/IEC 42001-Betrieb

Der Betreiber führt ein KI-System-Inventar und ein Risikoregister. Für jede
wesentliche Änderung werden Zweck, Modell, Daten, Risiken, Owner, menschliche
Aufsicht und Evaluation dokumentiert.

Betriebskontrollen:

- Modell- und Prompt-Provenienz;
- Risiko- und Auswirkungsbewertung;
- menschliche Aufsicht vor sicherheitsrelevanten Entscheidungen;
- Monitoring von Qualität, Robustheit und Fehlverhalten;
- Incident- und Abschaltprozess;
- kontinuierliche Verbesserung;
- interne Kontrollen und Managementreview.

## 10. EU AI Act und DSGVO/BDSG

Die EU-AI-Act-Einstufung erfolgt für den konkreten Zweck, nicht nur für die
Technologie. Zu prüfen sind Transparenz, Protokollierung, menschliche Aufsicht,
Robustheit, Cybersicherheit und gegebenenfalls technische Dokumentation.

Bei personenbezogenen Daten sind insbesondere Zweckbindung, Datenminimierung,
Rechtsgrundlage, Betroffenenrechte, Aufbewahrung, Löschung, Zugriffsschutz und
Drittlandtransfer zu prüfen. Eine lokale Modellinstanz beseitigt diese Pflichten
nicht.

## 11. Monitoring und Audit

Zu überwachen sind:

- Nginx-TLS-, Authentifizierungs- und Rate-Limit-Ereignisse;
- LiteLLM-Modellrouting, ACL-Verstöße und Tokenverbrauch;
- FastMCP-Toolaufrufe, Fehler und Laufzeiten;
- PostgreSQL-Verbindungen, Migrationen und Rollenänderungen;
- Ollama-Verfügbarkeit, Ressourcen und Modellfehler;
- Evaluationsergebnisse und Governance-Gate-Fehler;
- Backup-, Restore- und Evidence-Bundle-Ergebnisse.

Auditlogs müssen Zeitquelle, Umgebung, Korrelation-ID, Actor, Aktion, Ergebnis
und redigierte Metadaten enthalten. Rohdaten werden nicht unkontrolliert in Logs
übernommen.

## 12. Backup, Restore und Notfallbetrieb

### Backup

- PostgreSQL täglich und vor Migrationen sichern;
- Prompt-Registry, Evidence-Referenzen und Auditdaten getrennt sichern;
- Konfigurationen und Gateway-Policies versionieren;
- Schlüssel getrennt vom Backup-Datenbestand verwalten;
- Backups verschlüsseln und unveränderlich aufbewahren.

### Restore

1. Incident eröffnen und Schreibzugriffe stoppen;
2. Scope und Datenverlust feststellen;
3. Backup-Prüfsumme verifizieren;
4. Restore in isolierter Umgebung durchführen;
5. Schema, Prompt-Versionen und Evidence-Referenzen prüfen;
6. RPO/RTO messen;
7. Wiederfreigabe durch Betrieb und Security dokumentieren.

## 13. Release- und Change-Prozess

1. Änderung in Git vorbereiten;
2. Harness-Orchestrator und technische Gates ausführen;
3. Datensatz-/Evaluation-Suite ausführen;
4. Trivy-, Secret- und PII-Scans prüfen;
5. Evidence Bundle erzeugen;
6. Security-, Datenschutz- und Fachfreigabe einholen;
7. CI/GitOps-Promotion ausführen;
8. Cloud-Rollout überwachen;
9. Betriebsnachweis und Lessons Learned archivieren.

Ein positives Harness-Ergebnis ist keine automatische Produktionsfreigabe.

## 14. Service-Level und Abbruchbedingungen

Für jede Cloudumgebung müssen Verfügbarkeit, RPO, RTO, Retention und Support-
zeiten verbindlich festgelegt werden. Der Betrieb wird blockiert bei:

- fehlender TLS-/Auth-Konfiguration;
- unbekanntem Modell oder nicht freigegebenem Prompt;
- fehlendem Backup oder Restore-Nachweis;
- kritischem Security-/PII-Fund;
- fehlendem Evidence Bundle;
- offener Governance-Bewertung;
- fehlender menschlicher Freigabe;
- direktem Versuch einer Produktionsmutation.

## 15. Aussagegrenze

Dieses Dokument ist eine technische Cloud-Betriebsreferenz. Es ersetzt keine
Cloud-Provider-Verträge, keine ISO-42001-Zertifizierung, keine EU-AI-Act-
Rechtsprüfung, keine DSGVO-Bewertung, keine BSI-/C5-Testierung und keine
unabhängige Auditierung.

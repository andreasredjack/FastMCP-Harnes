## ToDo: Zielarchitektur

- Host-Portfreigabe von Docker Desktop für Nginx auf dem Zielsystem beheben;
- produktive TLS-Zertifikate, Authentifizierung und echte Rate-Limit-Werte einsetzen;
- LiteLLM-ACLs mit realen Rollen und kurzlebigen API-Keys konfigurieren;
- Ollama-RAG und Ollama-Coding mit realen Modellvolumes starten;
- GPU-/ROCm-Zuweisung beziehungsweise CPU-Betriebsgrenze nachweisen;
- FastMCP-Testserver ausschließlich über das Gateway testen;
- Gateway-, Routing- und Backend-Gates mit Integrationstests automatisieren.

## Prompt-Registry und Gateway

LiteLLM verwaltet Modellrouting und ACLs; die PostgreSQL-Prompt-Registry
verwaltet Prompt-Versionen, Evaluation und Freigaben. FastMCP verbindet die
freigegebene Prompt-Version mit einem Gateway-Modellalias. Die Datenbank ist
kein Modellendpunkt und wird nicht vom LLM beschrieben.
# Lokale Gateway-Architektur

## Ziel

Die Testkopie verwendet folgende Kette:

```text
Client -> Nginx -> LiteLLM -> Ollama-RAG oder Ollama-Coding
                         ^
                         |
                  FastMCP-Harness
```

Die Umsetzung ist CPU-fähig. GPU-Zuweisungen sind in der Architekturdatei als
`disabled` dokumentiert, weil die aktuelle WSL-Umgebung keinen nutzbaren
NVIDIA-/ROCm-Pfad nachweist.

## Komponenten

- Nginx: lokaler Edge-Proxy, TLS-1.3-Konfiguration für den Zielbetrieb,
  Testkonfiguration ohne Zertifikatsabhängigkeit, Rate Limiting und Header;
- LiteLLM: Modellaliasse, Gateway-ACLs, Token-Tracking und einheitlicher
  OpenAI-kompatibler Endpunkt;
- `ollama-rag`: getrennte Netzwerkgrenze und Modellvolume für RAG;
- `ollama-coding`: getrennte Netzwerkgrenze und Modellvolume für Coding;
- FastMCP: bevorzugt Gateway-Endpunkt, keine direkten Backend-URLs.

## Start des CPU-Teststacks

```powershell
Set-Location "H:\VS Code Arbeitsbereiche\FastMCP-Harness\gateway"
Copy-Item .env.example .env
$env:LITELLM_MASTER_KEY = "sk-test-change-me"
docker compose config
docker compose up -d litellm nginx
```

Die Ollama-Backends werden separat mit dem Profil `backends` gestartet:

```powershell
docker compose --profile backends up -d
```

Für produktionsnahe Nutzung müssen Testschlüssel, Images, TLS-Zertifikate,
ACLs, Datenbank, Retention und Modellfreigaben ersetzt werden.

## Routing

Die stabilen Modellaliasse sind:

- `rag-gpt-oss`
- `rag-embedding`
- `coding-qwen`
- `coding-qwen-small`
- `coding-gemma`

Der FastMCP-Server nutzt in dieser Kopie `MODEL_GATEWAY_BASE_URL` und
`MODEL_GATEWAY_MODEL`. Direkte LM-Studio-Nutzung ist nur noch der explizite
Fallback für lokale Basistests.

## Harness-Gate

Die Harness prüft zwingend:

- Nginx als Edge-Proxy;
- TLS 1.3 in der Produktionskonfiguration;
- Rate Limiting;
- LiteLLM als Gateway;
- getrennte RAG-/Coding-Backends;
- getrennte Docker-Netzwerke und Modellvolumes;
- Modellrouting und Gateway-Dateien;
- keine automatische Mutation.

Ein erfolgreicher Architekturcheck ist ein technischer Nachweis, keine
Produktionsfreigabe.

## Beziehung zum Testmodell

Das Gateway stellt die LLM-/Applikationsschicht bereit. Die Harness orchestriert
Aufträge und technische Gates. Eine Datensatz-Pipeline und eine unabhängige
Evaluation-Suite mit Richterfunktion sind noch separate offene Komponenten.

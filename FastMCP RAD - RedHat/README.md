# FastMCP Coding-Harness auf Red-Hat-Basis

Dieser Workspace ist die Red-Hat-basierte Variante der FastMCP-Coding-Harness.
Er ist fuer Linux-Container auf Basis von Red Hat Universal Base Image 9
(UBI 9) vorgesehen. Die bestehende Ubuntu-/WSL-Variante bleibt unveraendert.

## Inhalt

- `Containerfile`: UBI-9-/Python-3.12-Basis fuer Docker oder Podman;
- `harness/coding_harness.py`: read-only Orchestrator;
- `harness/profiles/reviewer.md`: verbindliches Reviewer-Profil;
- `.github/copilot-instructions.md`: projektweite Agentenregeln;
- `Policies-Readme.md`: verbindliche Policy-Grundlage;
- `security-rules/`: fachliche Sicherheitsregeln;
- `instructions/`: Security-Review-Anweisungen.
- `build-llm.yaml`: verbindliche Qwen3.0-Build-LLM-Konfiguration;
- `server.py`: read-only FastMCP-Server mit Policy-Gates;
- `security-rules/BSI-Build-LLM-Regeln.md`: unveränderliches Build-Regelwerk.

Der validierte Runtime-Stand ist FastMCP `3.2.0` mit `setuptools` mindestens
`78.1.1`. Python 3.11 ist fuer die lokale AlmaLinux-9-Ausfuehrung erforderlich.

## Red-Hat-Betrieb

Der Repository-Mount ist read-only. Der einzige beschreibbare Bereich ist der
separate Trivy-Cache. Der Container laeuft ohne zusaetzliche Capabilities,
ohne Docker- oder Kubernetes-Socket und ohne direkten Netzwerkzugriff waehrend
des Scans.

```bash
podman build --file Containerfile --tag fastmcp-harness-redhat:local .
podman volume create fastmcp-redhat-trivy-cache
podman run --rm --user 0:0 \
  -v fastmcp-redhat-trivy-cache:/var/cache/trivy \
  fastmcp-harness-redhat:local \
  trivy fs --download-db-only --cache-dir /var/cache/trivy
podman run --rm --read-only --cap-drop=ALL \
  --security-opt=no-new-privileges:true --network=none \
  -v "$PWD:/workspace/repository:ro" \
  -v fastmcp-redhat-trivy-cache:/var/cache/trivy \
  -e TRIVY_CACHE_DIR=/var/cache/trivy \
  fastmcp-harness-redhat:local --json
```

Der Trivy-Download ist ein separater, kontrollierter Vorbereitungsschritt. Der
MCP-Aufruf `trivy_update` verwendet `trivy fs --download-db-only`.
Sein Datenbankstand muss zusammen mit dem JSON-Bericht dokumentiert werden.

## Build-LLM Qwen3.0

Der FastMCP-Server verwendet für Build-Reviews die in LM Studio geladene
Modell-ID `qwen3.0`. Die Modell-ID muss exakt vorhanden sein; wenn LM Studio
das Modell nicht meldet, bricht `build_llm_status` beziehungsweise
`review_build_request` aus Sicherheitsgründen ab.

Start in AlmaLinux/WSL:

```bash
cd "/mnt/h/VS Code Arbeitsbereiche/FastMCP RAG/FastMCP RAD - RedHat"
source "$HOME/.venvs/fastmcp-rag/bin/activate"
python server.py
```

Die Tools sind read-only. `review_build_request` lädt bei jedem Aufruf das
versionierte Regelwerk, berechnet den SHA-256-Hash und sendet Policy plus
Auftrag an LM Studio. Apply, Push, Merge, Deployment und freie Shell-
Ausführung sind technisch nicht erlaubt. Das Regelwerk ist in
`security-rules/BSI-Build-LLM-Regeln.md` dokumentiert; eine menschliche
Freigabe und die deterministische Harness bleiben Pflicht.

## Freigaberegeln

Ein erfolgreicher Harness-Lauf ist nur ein technischer Nachweis. Er ersetzt
weder Security-Review noch Plan/Diff, Vier-Augen-Freigabe, Jira-Nachweis oder
den GitOps-/CI/CD-Prozess. Das LLM darf keinen produktiven Apply ausfuehren.

Vor einem Release muessen Policy-Dateien, Python-/YAML-Validierung, Trivy-FS,
Trivy-Config, vorhandene Tests und menschliche Freigaben erfolgreich sein.

Nach dem FastMCP-3.2.0-Upgrade bleiben im finalen CVE-Scan keine kritischen
oder hohen Findings. Offen bleibt ein mittleres Finding in `diskcache 5.6.3`
(`CVE-2025-69872`), fuer das Trivy derzeit keine Fix-Version meldet.
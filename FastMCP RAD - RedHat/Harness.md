# Red-Hat-Coding-Harness

## Ziel

Diese Variante fuehrt dieselbe verbindliche Policy- und Kontrolllogik wie die
Ubuntu-/WSL-Harness aus, verwendet aber ein Red-Hat-kompatibles UBI-9-Image.
Die LLMs bleiben lokal beziehungsweise im freigegebenen Cluster. Der
Harness-Container besitzt keinen direkten Internetzugang waehrend des Scans.
Der validierte Dependency-Stand ist FastMCP `3.2.0` und `setuptools` `84.0.0`.
Der MCP-Server wurde unter AlmaLinux 9 mit LM Studio, Trivy und dem read-only
Harness-Ablauf erfolgreich getestet.

## Verbindlicher Ablauf

1. Auftrag, Repository, Branch, Pfad-Scope, Datenarten und Abnahmekriterien
   bestimmen.
2. `.github/copilot-instructions.md`, `Policies-Readme.md`,
   `security-rules/*.md`, `instructions/architecture.instructions.md` und
   `harness/profiles/reviewer.md` laden und validieren.
3. Lokale Hypothese, kontrollierenden Codepfad und Gegencheck festhalten.
4. Read-only-Gates ausfuehren: Git, Python, YAML, Trivy-FS und Trivy-Config.
5. Bestaetigte Befunde, plausible Risiken und offene Fragen trennen.
6. Plan/Diff, Scan-Ergebnisse und Handoff zur menschlichen Freigabe vorlegen.
7. Erst nach Freigabe eine Aenderung im bestaetigten Scope umsetzen.
8. Nach dem Edit denselben engsten Check erneut ausfuehren.
9. Ergebnis, Policy-Version, Hash, Risiken und veraenderte Dateien auditierbar
   dokumentieren.

Fehlt eine Policy, ein Scan, eine Berechtigung oder ein belastbarer Nachweis,
bricht der Agent ab. Es gilt `fail closed`.

## Systemtrennung

```text
Lokales oder Cluster-LLM
  -> erstellt Vorschlag
  -> Red-Hat-Harness im UBI-Container
  -> Policy-, Scope-, Syntax- und Trivy-Gates
  -> JSON-Bericht
  -> menschliches Vier-Augen-Prinzip
  -> GitOps / CI/CD / ArgoCD / Kyverno
```

Das LLM erhält keine Produktionsrechte. Der Harness-Container erhält keinen
Schreibzugriff auf das Repository und keine Cluster-, Docker- oder Kubernetes-
Sockets.

## Red-Hat-Laufzeit

Die Basis ist `registry.access.redhat.com/ubi9/python-312`. Abhaengigkeiten
und Trivy muessen aus freigegebenen, nachvollziehbaren Quellen stammen. Das
Containerfile verlangt deshalb einen expliziten Trivy-Hash, bevor ein Binary
installiert wird. Ein internes, signiertes Mirror-Artefakt ist zu bevorzugen.

## Lokale Entwicklung

Die Red-Hat-Variante wird bevorzugt mit Podman ausgefuehrt. Eine lokale WSL-
Ausfuehrung bleibt nur eine optionale Vorpruefung. Die verbindliche Freigabe
erfolgt im reproduzierbaren Red-Hat-Container oder in CI/CD.
Der finale CVE-Scan weist `0` kritische, `0` hohe und `1` mittlere Schwachstelle
aus: `CVE-2025-69872` in `diskcache 5.6.3` ohne derzeit bekannte Fix-Version.
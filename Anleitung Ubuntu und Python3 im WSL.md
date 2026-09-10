# ToDo: Zielarchitektur

- Ubuntu/AlmaLinux-Testprofile an die Gateway-Testkonfiguration angleichen;
- LiteLLM-Aliasse, ACLs und Tokenlimits mit Testkonten verifizieren;
- getrennte Ollama-Netzwerke und Modellvolumes testen;
- PII-/Secret-Scan und Prompt-Injection-Evaluation ergänzen;
- offene Governance-Owner und rechtliche Bewertungen eintragen.

# Anleitung: Ubuntu LTS und Python 3 im WSL

Diese Anleitung beschreibt die Einrichtung einer Ubuntu-LTS-Distribution mit
Python 3 unter Windows Subsystem for Linux (WSL 2). Alle Pfade und Namen sind
Platzhalter und muessen an die jeweilige Umgebung angepasst werden.

## Voraussetzungen

- Windows 10 Version 2004 oder neuer beziehungsweise Windows 11
- Administratorrechte fuer die Installation von WSL
- Eine aktive Internetverbindung fuer den Download der Distribution und der
  Ubuntu-Pakete
- Virtualisierung im UEFI/BIOS und die erforderlichen Windows-Komponenten fuer
  WSL 2

## 1. WSL installieren

PowerShell als Administrator oeffnen und WSL installieren:

```powershell
wsl --install
```

Danach Windows neu starten, falls dies verlangt wird. Die installierten
Distributionen koennen mit folgendem Befehl angezeigt werden:

```powershell
wsl --list --online
```

## 2. Ubuntu LTS installieren

Eine Ubuntu-LTS-Distribution gezielt installieren. `<Ubuntu-Distribution>` ist
mit dem Namen aus `wsl --list --online` zu ersetzen, zum Beispiel `Ubuntu`:

```powershell
wsl --install --distribution <Ubuntu-Distribution>
```

Bereits installierte Distributionen anzeigen:

```powershell
wsl --list --verbose
```

Die Ausgabe sollte fuer die gewuenschte Ubuntu-Distribution Version `2`
zeigen. Falls erforderlich, WSL 2 als Standard setzen:

```powershell
wsl --set-default-version 2
```

Eine vorhandene Distribution auf WSL 2 umstellen:

```powershell
wsl --set-version <Ubuntu-Distribution> 2
```

Beim ersten Start von Ubuntu werden ein Linux-Benutzername und ein Passwort
angelegt. Diese Zugangsdaten gelten nur innerhalb dieser Ubuntu-Distribution.

Ubuntu gezielt starten:

```powershell
wsl --distribution <Ubuntu-Distribution>
```

## 3. Ubuntu aktualisieren

Die folgenden Befehle innerhalb der Ubuntu-Shell ausfuehren:

```bash
sudo apt update
sudo apt full-upgrade -y
```

## 4. Python 3 und Entwicklungswerkzeuge installieren

Python 3, pip, virtuelle Umgebungen und die fuer Python-Pakete haeufig
benoetigten Entwicklungswerkzeuge installieren:

```bash
sudo apt install -y python3 python3-pip python3-venv python3-dev build-essential
```

Installation pruefen:

```bash
python3 --version
python3 -m pip --version
python3 -m venv --help
```

Erwartet wird eine Python-3-Version, die von der verwendeten Ubuntu-LTS-Version
bereitgestellt wird.

## 5. Virtuelle Umgebung fuer ein Projekt erstellen

In das Projektverzeichnis wechseln. Der Beispielpfad ist neutral und muss an
den Speicherort des Projekts angepasst werden:

```bash
cd "/mnt/<laufwerk>/<projektverzeichnis>"
```

Virtuelle Umgebung erstellen und aktivieren:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
```

Das verwendete Python und pip pruefen:

```bash
which python
python --version
python -m pip --version
```

Die virtuelle Umgebung verlassen:

```bash
deactivate
```

## 6. Projektabhaengigkeiten installieren

Falls das Projekt eine `requirements.txt` besitzt:

```bash
python -m pip install -r requirements.txt
```

Ein einzelnes Paket installieren:

```bash
python -m pip install <paketname>
```

Fuer den FastMCP-Server dieses Projekts kann die Installation beispielsweise
so erfolgen:

```bash
python -m pip install -r requirements.txt
```

## 7. WSL-Netzwerk und Windows-Dienste

Ein Dienst, der auf Windows laeuft und aus Ubuntu/WSL erreichbar sein soll,
kann je nach WSL-Netzwerkmodus ueber die Windows-Host-IP angesprochen werden.
Die DNS-Konfiguration der Ubuntu-Distribution kann diese IP enthalten:

```bash
grep nameserver /etc/resolv.conf
```

Die ausgegebene IP ist nur dann als Dienstadresse zu verwenden, wenn der
Windows-Dienst Verbindungen aus WSL erlaubt. Bei einer abweichenden
Netzwerkkonfiguration muss die Host-IP manuell in der Projektkonfiguration
eingetragen werden.

## 8. Ubuntu als Standarddistribution setzen

Wenn mehrere WSL-Distributionen installiert sind, sollte Ubuntu explizit als
Standarddistribution gesetzt werden:

```powershell
wsl --set-default <Ubuntu-Distribution>
```

Die Distributionen vorher kontrollieren:

```powershell
wsl --list --verbose
```

Eine andere WSL-Distribution, zum Beispiel eine von einem Desktop- oder
Virtualisierungswerkzeug verwaltete Distribution, sollte nicht veraendert
werden. Befehle wie `wsl --set-version` immer nur auf den Namen der eigenen
Ubuntu-Distribution anwenden.

## 9. Fehlerbehebung

### Ubuntu startet nicht oder ist nicht vorhanden

Die Distributionen anzeigen:

```powershell
wsl --list --verbose
```

Falls Ubuntu fehlt, den verfuegbaren Namen pruefen und danach installieren:

```powershell
wsl --list --online
wsl --install --distribution <Ubuntu-Distribution>
```

### WSL-Version ist nicht 2

Die Distribution gezielt auf WSL 2 umstellen:

```powershell
wsl --set-version <Ubuntu-Distribution> 2
```

### Paketquellen koennen nicht aufgeloest werden

In Ubuntu testen:

```bash
getent hosts archive.ubuntu.com
cat /etc/resolv.conf
```

Wenn die Namensaufloesung fehlschlaegt, WSL aus PowerShell neu starten:

```powershell
wsl --shutdown
wsl --distribution <Ubuntu-Distribution>
```

Danach den Test wiederholen. Dauerhafte Aenderungen an `/etc/resolv.conf`
sollten nur vorgenommen werden, wenn die WSL-Netzwerkkonfiguration bewusst
angepasst wird.

### `python3` ist vorhanden, aber `pip` fehlt

Das Paket `python3-pip` installieren:

```bash
sudo apt update
sudo apt install -y python3-pip
```

### `python3 -m venv` funktioniert nicht

Das passende Paket installieren:

```bash
sudo apt install -y python3-venv
```

Danach die virtuelle Umgebung erneut erstellen.

### Paketinstallation bricht wegen fehlender Compiler ab

Entwicklungswerkzeuge und Python-Header installieren:

```bash
sudo apt install -y python3-dev build-essential
```

## FAQ: Dokumentierte Fehler und Loesungen

### Warum wurde eine andere Linux-Distribution als Ubuntu erkannt?

**Ursache:** WSL kann mehrere Distributionen enthalten. Eine Distribution kann
von einem Desktop- oder Virtualisierungswerkzeug verwaltet werden und ist nicht
die gewuenschte Ubuntu-Umgebung.

**Loesung:** Mit `wsl --list --verbose` die Distributionsnamen pruefen und
Befehle immer mit `wsl --distribution <Ubuntu-Distribution>` gezielt an Ubuntu
richten. Die fremde Distribution nicht veraendern.

### Warum wurde Python in Ubuntu gefunden, aber pip fehlte?

**Ursache:** Python 3 und pip werden in Ubuntu als getrennte Pakete verwaltet.
Eine vorhandene Python-Installation bedeutet daher nicht automatisch, dass pip
installiert ist.

**Loesung:** `sudo apt install -y python3-pip` ausfuehren und anschliessend
`python3 -m pip --version` pruefen.

### Warum fehlten `venv` oder `ensurepip`?

**Ursache:** Das Modul fuer virtuelle Umgebungen wird in Ubuntu ueber ein
separates Paket bereitgestellt. `ensurepip` ist nicht zwingend Bestandteil der
minimalen Python-Installation.

**Loesung:** `sudo apt install -y python3-venv` installieren und virtuelle
Umgebungen mit `python3 -m venv .venv` erstellen.

### Warum schlug `apt update` mit "Temporary failure resolving" fehl?

**Ursache:** Der in WSL eingetragene DNS-Server war aus der Ubuntu-Distribution
nicht erreichbar. Dadurch konnten Hostnamen wie `archive.ubuntu.com` nicht
aufgeloest werden.

**Loesung:** Zuerst `wsl --shutdown` aus PowerShell ausfuehren und Ubuntu neu
starten. Danach mit `getent hosts archive.ubuntu.com` testen. Falls das Problem
bleibt, die WSL-DNS-Konfiguration beziehungsweise das lokale Netzwerk pruefen.
Eine temporaere DNS-Anpassung darf nur kontrolliert erfolgen und sollte danach
wiederhergestellt werden.

### Warum schlug `python3 -m ensurepip` fehl?

**Ursache:** Ubuntu stellt pip normalerweise ueber das Paket `python3-pip`
bereit; `ensurepip` ist in der Systeminstallation nicht unbedingt enthalten.

**Loesung:** `sudo apt install -y python3-pip` verwenden, nicht `ensurepip` als
primaeren Installationsweg voraussetzen.

### Warum wird ein Windows-Pfad in Ubuntu nicht direkt akzeptiert?

**Ursache:** Ubuntu unter WSL verwendet Linux-Pfade. Windows-Laufwerke werden
in der Regel unter `/mnt/<laufwerk>/` eingebunden.

**Loesung:** Einen neutralen WSL-Pfad wie `/mnt/<laufwerk>/<projektverzeichnis>`
verwenden und den Platzhalter anpassen. Pfade mit Leerzeichen in Anfuehrungszeichen
setzen.

### Warum kann ein Windows-Dienst aus WSL nicht erreicht werden?

**Ursache:** Der Dienst lauscht moeglicherweise nur auf `127.0.0.1`, verwendet
einen anderen Port oder blockiert Verbindungen durch die Windows-Firewall.

**Loesung:** Host-IP und Port pruefen, den Dienst fuer Verbindungen aus WSL
freigeben und die Verbindung aus Ubuntu testen. Keine private IP-Adresse fest
in eine portable Anleitung eintragen.

### Wie verhindere ich, dass Podman oder eine andere WSL-Distribution veraendert wird?

**Ursache:** Befehle ohne `--distribution` verwenden die Standarddistribution.
Diese kann eine verwaltete Umgebung und nicht Ubuntu sein.

**Loesung:** In PowerShell die Ubuntu-Distribution immer explizit angeben:

```powershell
wsl --distribution <Ubuntu-Distribution> -- bash -lc "python3 --version"
```

Vor administrativen Aenderungen den Distributionsnamen mit
`wsl --list --verbose` kontrollieren.

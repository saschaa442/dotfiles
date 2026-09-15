# dotfiles

Persönliche macOS-Konfiguration, die schrittweise wächst. Die Dateien unter
[`home/`](home/) spiegeln ihre Zielpfade im Home-Verzeichnis: Aus
`home/.config/zsh/.zshrc` wird beim Installieren `~/.config/zsh/.zshrc`.

## Erster Einsatz auf einem neuen Mac

1. Einmalig die Apple Command Line Tools installieren und anschließend das
   Repository klonen:

   ```sh
   xcode-select --install
   git clone git@github.com:saschaa442/dotfiles.git ~/.dotfiles
   ```

2. Den kompletten Bootstrap ausführen:

   ```sh
   cd ~/.dotfiles
   ./bootstrap.sh
   ```

`bootstrap.sh` installiert Homebrew bei Bedarf und führt anschließend das
[`Brewfile`](Brewfile) aus. `install.sh` legt ausschließlich die Symlinks an.
Beide Skripte überschreiben keine vorhandene
Konfiguration: Falls eine Zieldatei bereits existiert, wird sie zuerst in
`~/.dotfiles-backup/<Zeitstempel>/` gesichert. Bereits korrekte Symlinks werden
übersprungen.

Ausnahme: Dateien, die direkt von `launchd` gelesen oder ausgeführt werden,
installiert `install.sh` als echte Dateien. Das ist nötig, weil aktuelle
macOS-Versionen LaunchAgent-Plists als Symlink ablehnen und Hintergrundprozesse
Symlink-Ziele im geschützten Ordner `Documents` nicht öffnen dürfen.

## Entwicklungsumgebung

Das Brewfile installiert das aktuelle .NET SDK sowie `mise`. Die globale
[`mise`-Konfiguration](home/.config/mise/config.toml) verwendet die aktuelle
Node.js-LTS-Version; `bootstrap.sh` installiert sie direkt mit `mise install`.
Die zsh-Konfiguration aktiviert mise für jede interaktive Shell. Einzelne
Projekte können die globale Node-Version mit einer lokalen `mise.toml`
überschreiben.

Zum Prüfen ohne Änderungen:

```sh
./install.sh --dry-run
```

## Ghostty

Ghostty verwendet **FiraCode Nerd Font Mono Bold** in 16 pt. Die Schrift wird
über `font-fira-code-nerd-font` im Brewfile beim Bootstrap installiert.
Die [Ghostty-Konfiguration](home/.config/ghostty/config) wird durch `install.sh`
verlinkt und verwendet den nativen Bold-Schnitt ohne zusätzliche Verdickung.
Nach Änderungen die Konfiguration in Ghostty mit `Cmd+Shift+,` neu laden.

## eza statt ls

`eza` wird über das Brewfile installiert. Die zsh-Aliase bieten `ls` mit Icons
und Ordnern zuerst, `ll` mit Details und Git-Status, `la` zusätzlich mit
versteckten Dateien sowie `lt` als Baum mit zwei Ebenen. Das klassische
macOS-ls bleibt über `/bin/ls` erreichbar.

Das [Catppuccin-Mocha-Theme mit Mauve-Akzent](https://github.com/catppuccin/eza)
liegt in `home/.config/eza/theme.yml` und wird nach `~/.config/eza/theme.yml`
verlinkt. Es passt zu Ghostty und gilt auch für die eza-Vorschau in fzf-tab.
Nach Änderungen eine neue Shell öffnen oder `exec zsh` ausführen.

## Neue Konfiguration hinzufügen

Lege die Datei unter `home/` an, genau so wie sie später unter `~` liegen soll,
und führe das Install-Skript erneut aus. Beispiel:

```sh
mkdir -p home/.config/git
touch home/.config/git/config
./install.sh
```

Die Datei nicht direkt unter `~` bearbeiten, sondern über ihren Pfad im
Repository. Der Symlink sorgt dafür, dass Änderungen sofort wirksam sind.

## Struktur

```text
home/          # Inhalt, der nach ~ verlinkt wird
install.sh     # idempotenter Symlink-Installer
bootstrap.sh   # Homebrew installieren und das Brewfile anwenden
macos.sh        # reproduzierbare macOS-Systemeinstellungen
Brewfile       # deklarative Liste von CLI-Tools und Apps
preferences/   # wiederherstellbare Einstellungen einzelner Apps
```

`macos.sh` aktiviert unter anderem „Zum Klicken tippen“, die Batterieanzeige
mit Prozentwert und verhindert `.DS_Store` auf Netzwerk- sowie USB-Laufwerken.

## SSH über Bitwarden

SSH verwendet den Agent der Bitwarden-Desktop-App unter
`~/.bitwarden-ssh-agent.sock`. Bitwarden muss dafür laufen und entsperrt sein;
gegebenenfalls die Schlüsselnutzung in Bitwarden bestätigen.

Der private Devbox-Schlüssel liegt im persönlichen Tresor als `nas-devbox`.
`nas-codex` (LAN) und `nas-codex-remote` (über den VPS) wählen ihn mit
`IdentityFile ~/.ssh/id_ed25519_nas_codex_devbox.pub` und `IdentitiesOnly yes`
aus. Die lokale Datei enthält ausschließlich den öffentlichen Schlüssel;
die Anmeldung signiert Bitwarden. Auf einem neuen Mac den öffentlichen
Schlüssel aus diesem Tresoreintrag unter diesem Pfad speichern und den
SSH-Agent in Bitwarden aktivieren.

## Netzwerkfreigaben

Der LaunchAgent `de.sascha.mount-network-shares` verbindet die SMB-Freigaben
`sascha` und `media` von `192.168.2.237` über die in Finder/Schlüsselbund
gespeicherten Zugangsdaten. Die stabilen Zugriffspfade sind
`~/mounts/personal` (Freigabe `sascha`) und `~/mounts/media`.

Vor jedem Verbindungsversuch wird SMB-Port 445 mit einem kurzen Timeout
geprüft. Ist der NAS nicht erreichbar, beendet sich der Versuch still, ohne
NetFS aufzurufen oder einen macOS-Fehlerdialog auszulösen.

Der Agent läuft beim Login und versucht die Verbindung danach alle 30 Sekunden
erneut. Ein nicht erreichbarer Server erzeugt deshalb keine Meldung; nach einem
Reboot, dem Aufwachen oder einem späteren Netzwerkwechsel werden die Freigaben
automatisch wieder verbunden.

## SSH-Server: ausschließlich Homelab

Die Server-Konfiguration liegt in `ssh/000-homelab.conf`, der öffentliche
Homelab-Schlüssel in `ssh/homelab.pub`. Erwarteter Fingerprint:
`SHA256:DtD2i2zUTf5xmvTp2KxZpNbDuA4gfrmUy52f7AQOslA` (RSA 4096).
Der private Schlüssel bleibt in Bitwarden bzw. auf dem verbindenden Client.

Bewusst separat vom normalen Bootstrap aktivieren:

```sh
cd /Users/sascha/Documents/ChatGPT/.dotfiles
./setup-ssh.sh
```

Der Installer benötigt Administratorrechte. Er prüft den Public Key vor jeder
Änderung, sichert die bestehende SSH-Konfiguration und die bisherigen öffentlichen
Schlüssel unter `/var/backups/dotfiles-ssh.XXXXXXXX/` (nur root zugänglich),
installiert ausschließlich Homelab in `~/.ssh/authorized_keys` und setzt
`~/.ssh` auf 700, `authorized_keys` und `homelab.pub` auf 600.
Vorhandene andere autorisierte Schlüssel werden gesichert und ersetzt.
Bei einem Schlüsselwechsel Public Key und Fingerprint im Installer gemeinsam ändern.

Systemdateien werden als echte Dateien installiert, nicht nach Documents
verlinkt: `/etc/ssh/sshd_config.d/000-homelab.conf` gehört root:wheel (644).
Auch `authorized_keys` bleibt eine echte Datei, damit sshd nicht auf den
macOS-geschützten Documents-Ordner zugreifen muss. `@USER@` wird beim Installieren
durch den aufrufenden Benutzer ersetzt. Der bestehende Apple-Include bleibt
unverändert. Nach Änderungen den Installer erneut ausführen.

Der Installer erzeugt fehlende SSH-Hostschlüssel lokal, validiert mit `sshd -t`
und prüft die wirksamen Einstellungen mit `sshd -T`. Nur Public-Key-Anmeldung
ist erlaubt; Passwort, Keyboard Interactive und Root-Login sind ausgeschaltet.
`AllowUsers` enthält ausschließlich den ausgewählten Benutzer. Die vorhandene
macOS-SSH-Zugriffsgruppe wird bei Bedarf um diesen Benutzer ergänzt.

Remote Login ist ein Systemdienst und nicht symlinkbar: Aktivierung über
`systemsetup -setremotelogin on`, bei fehlendem Festplattenvollzugriff über
`launchctl load -w /System/Library/LaunchDaemons/ssh.plist`. Letzteres aktiviert
denselben Apple-Dienst dauerhaft. SSH lauscht auf Port 22; es wird keine
Router-Portfreigabe eingerichtet. Diese Konfiguration erzwingt keine
Beschränkung auf ein bestimmtes IP-Subnetz.

Vom anderen Rechner im LAN testen:

```sh
ssh -i ~/.ssh/homelab sascha@MacBook-Pro-von-Sascha.local
```

Mit Bitwarden-Agent und ausschließlich lokal gespeichertem Public Key:

```sh
ssh -o IdentityAgent=~/.bitwarden-ssh-agent.sock -o IdentitiesOnly=yes -i ~/.ssh/homelab.pub sascha@MacBook-Pro-von-Sascha.local
```

Wiederherstellung: Den gewünschten Sicherungsordner mit Administratorrechten
öffnen. Seine `sshd_config` und `sshd_config.d` enthalten den vorherigen Stand;
die von diesem Installer neu hinzugefügte `000-homelab.conf` entfernen, falls sie
in der Sicherung fehlt, ansonsten die gesicherte Version zurückkopieren.
`authorized_keys` und `homelab.pub` aus der Sicherung wiederherstellen (auch
Symlinks sind gesichert); bei zugehöriger `.absent`-Datei das neu angelegte Ziel
entfernen. `.contents` enthält zusätzlich den dereferenzierten Dateiinhalt.
Anschließend Eigentümer/Berechtigungen prüfen und `sudo /usr/sbin/sshd -t` ausführen.
Der vorherige Dienst- und Gruppenstatus liegt ebenfalls im Sicherungsordner.
War Remote Login zuvor aus, lässt er sich über Systemeinstellungen → Allgemein →
Teilen → Entfernte Anmeldung wieder abschalten. Hostschlüssel werden beim
Rückbau nicht gelöscht.

Das Repository ist `git@github.com:saschaa442/dotfiles.git`. Am 15.09.2026
wurde auf Wunsch ein neuer Anfangsstand ohne die bisherige Historie erstellt.

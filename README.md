# Projekt Modul 346 – Nextcloud

## Team
- Eymen – Webserver & Nextcloud
- Jayden – Datenbankserver
- Julian – IaC & Dokumentation

# Inhaltsverzeichnis

1. [Einleitung](#1-einleitung)
   - [Ziel des Projekts](#ziel-des-projekts)
   - [Kurzbeschreibung von Nextcloud](#kurzbeschreibung-von-nextcloud)
   - [Team & Rollen](#team--rollen)

2. [Architektur](#2-architektur)
   - [Beschreibung: Webserver + DB-Server](#beschreibung-webserver--db-server)

3. [Anleitung Installation](#3-Anleitung-Installation)
   - [Voraussetzungen](#voraussetzungen)
   - [Schritt für Schritt Anleitung](#Schritt-für-Schritt-Anleitung)

4. [Tests](#4-tests)
   - [Testfälle](#testfälle)
   - [Screenshots](#screenshots)

5. [Zusammenarbeit & Git](#5-zusammenarbeit--git)
   - [Commit-Strategie](#commit-strategie)
   - [Beschreibung der Zusammenarbeit](#kurze-beschreibung-der-zusammenarbeit)
  
6. [Schwierigkeiten](#6-Schwierigkeiten)

7. [Reflexion](#6-reflexion)
   - [Eymen](#Eymen)
   - [Jayden](#Jayden)
   - [Julian](#Julian)

# Nextcloud-Projekt – Modul 346

## 1. Einleitung

### Ziel des Projekts
Das Ziel dieses Projekts war es, Nextcloud auf einer AWS-Infrastruktur bereitzustellen, wobei Webserver und Datenbankserver getrennt voneinander laufen. Dies sollte eine hohe Verfügbarkeit und Skalierbarkeit der Anwendung gewährleisten.

### Kurzbeschreibung von Nextcloud
Nextcloud ist eine Open-Source-Plattform für Cloud-Speicher und Dateisynchronisation, die es Nutzern ermöglicht, ihre Daten in einer sicheren Umgebung zu speichern und über verschiedene Geräte zu synchronisieren. Es bietet eine Weboberfläche, mobile Apps und eine starke Integration von Kollaborationswerkzeugen, die es Nutzern ermöglichen, Dokumente zu bearbeiten, Dateien zu teilen und gemeinsam zu arbeiten.

### Team & Rollen
Das Projekt wurde im Team durchgeführt. Die Aufgaben wurden wie folgt verteilt:
- **Eymen**: Architekturplanung, Webserver-Implementierung und Nextcloud-Konfiguration
- **Jayden**: Implementierung der Datenbankinfrastruktur und Skripte für die Datenbankbereitstellung
- **Julian**: Dokumentation des Projekts, Tests und Unterstützung beim Skript

## 2. Architektur

### Beschreibung: Webserver + DB-Server
Die Architektur des Projekts umfasst zwei Hauptkomponenten:
- **Webserver**: Der Webserver hostet die Nextcloud-Anwendung und ermöglicht Nutzern den Zugriff auf ihre Dateien und Daten. Er wird über Apache und PHP betrieben, mit einer Datenbankverbindung zu MariaDB.
- **Datenbankserver**: Der DB-Server speichert alle Daten von Nextcloud, einschliesslich Benutzerinformationen und Datei-Metadaten. Er wird mit MariaDB betrieben und ist über eine private IP-Adresse mit dem Webserver verbunden, um die Sicherheit der Kommunikation zu gewährleisten.

Die Kommunikation zwischen dem Webserver und dem Datenbankserver erfolgt über interne Netzwerke innerhalb der AWS-Infrastruktur. Der Webserver ist öffentlich zugänglich, während der Datenbankserver in einer privaten Subnetz-Konfiguration betrieben wird, um die Sicherheit zu erhöhen.

## 3. Installation / Inbetriebnahme
### Voraussetzungen
| Anforderung | Zweck Installation / Download |
|-------------|-------------------------------|
| AWS-Konto	Erforderlich, um die Cloud-Ressourcen zu erstellen. |	Auf der AWS-Website registrieren: https://www.awsacademy.com/login?ec=302&startURL=%2F |
| AWS CLI Das Befehlszeilentool, das es dem Skript ermöglicht, mit Ihrem AWS-Konto zu kommunizieren und Ressourcen zu erstellen. | Über den offiziellen AWS-Installer installieren: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html |
| Terminal-Umgebung (Git Bash) Erforderlich, um das .sh-Shell-Skript auf Windows auszuführen. Linux- und macOS-Nutzer können das Standard-Terminal verwenden.| Windows-Nutzer Git Bash herunterladen und installieren: https://git-scm.com/install/windows |

### Schritt für Schritt Anleitung

### 🔧 Schritt 1: Tools installieren und konfigurieren
#### 1.1 Git Bash installieren (Nur Windows)
Führen Sie den Installer aus und folgen Sie den Anweisungen. Die Standardeinstellungen sind in der Regel ausreichend.
<img width="1122" height="216" alt="image" src="https://github.com/user-attachments/assets/24d3a6d8-be6c-41cd-b5cc-71936894698d" />
Nach der Installation können Sie mit Git Bish in windows Suche eingeben es öffnen
<img width="775" height="728" alt="image" src="https://github.com/user-attachments/assets/4e6e136d-f8da-409d-8d72-3d0985541dcd" />

Terminal Sieht dann etwa so aus:

<img width="574" height="366" alt="image" src="https://github.com/user-attachments/assets/a76ca031-9abd-4652-88dc-fc445d891b95" />

#### 1.2 AWS CLI installieren und konfigurieren
Installieren Sie die AWS CLI für Ihr Betriebssystem (Windows, macOS, Linux) per die anleitung.
<img width="1542" height="823" alt="image" src="https://github.com/user-attachments/assets/98c6b101-f724-4658-a046-b5b969e018b1" />

Öffnen Sie Ihr Terminal (Git Bash, macOS/Linux Terminal).
Prüfen Sie, ob die AWS CLI korrekt installiert wurde:

Version Finden:
aws --version

<img width="675" height="125" alt="image" src="https://github.com/user-attachments/assets/0e564674-87e0-4d0f-a43e-51b8e1e05cd6" />

Aws Verbindung konfigurieren:
aws configure

<img width="1882" height="223" alt="image" src="https://github.com/user-attachments/assets/560d5809-fd72-4958-9077-f9f04868f06d" />

AWS Access Key ID: Geben Sie Ihre AWS Access Key ID ein 

AWS Secret Access Key: Geben Sie Ihren Secret Access Key ein.

Default region name: Geben Sie die AWS-Region ein, in der die Server erstellt werden sollen (z.B. eu-central-1 für Frankfurt).

Default output format: Geben Sie json ein.

Die Infos findet man unter AWS details: <img width="1839" height="998" alt="image" src="https://github.com/user-attachments/assets/b0b02169-a50c-46db-b0f1-6c3c6d8d1ba6" /> 

### 📂 Schritt 2: Dateien vorbereiten
Speichern Sie alle drei Skripte im selben Ordner auf Ihrem lokalen Computer, z.B. in einem neuen Ordner namens nextcloud-deployment.

Die Skripts Findet sie unter ["/M346-projekt/Skripts"](/Skripts)

deploy_aws.sh

install_db.sh

install_web.sh

<img width="1917" height="357" alt="image" src="https://github.com/user-attachments/assets/df462d00-6bbb-41f3-bfd2-5cc1adff1307" />


### ⚙️ Schritt 3: Skript ausführbar machen und starten
Öffnen Sie Ihr Terminal (oder Git Bash auf Windows).

Navigieren Sie zu dem Ordner, in dem Sie die Skripte gespeichert haben:

cd /pfad/zu/ihrem/nextcloud-deployment Zum Beispiel ~/Downloads/Projekt

<img width="589" height="289" alt="image" src="https://github.com/user-attachments/assets/38b2da11-f64a-4f81-a7fe-3154a438af39" />

Recht zum Haupt-Deployment-Skript zum Ausführen geben mit:

chmod +x deploy_aws.sh Zum Beispiel 

<img width="589" height="289" alt="image" src="https://github.com/user-attachments/assets/3b338f76-51c8-44af-83ef-54a4380a78ae" />


Starten Sie das Deployment:./deploy_aws2.sh 

<img width="800" height="210" alt="image" src="https://github.com/user-attachments/assets/14844bbf-f327-4562-bb58-d16c1478a620" />

### 👁️ Schritt 4: Deployment beobachten
Das Skript führt nun folgende Aktionen in AWS aus:

Erstellung eines SSH-Schlüsselpaares (NextcloudProjectKey.pem).


Erstellung von Sicherheitsgruppen (Nextcloud-Web-SG, Nextcloud-DB-SG). Die Datenbank-SG lässt nur Verbindungen vom Webserver auf Port 3306 (MySQL) zu.

<img width="793" height="117" alt="image" src="https://github.com/user-attachments/assets/d887eb75-4efa-4504-8854-2aa65838f862" />

Start des Datenbank-Servers (Nextcloud-DB) und Ermittlung seiner privaten IP-Adresse.

<img width="793" height="149" alt="image" src="https://github.com/user-attachments/assets/3cdfdcdd-a7fa-450d-a1ec-639fc7b4e397" />

Injektion der Datenbank-IP in das Konfigurationsskript des Webservers.

<img width="793" height="125" alt="image" src="https://github.com/user-attachments/assets/8edc1cf8-35f2-4e73-9305-653d5376bbf5" />

Start des Web-Servers (Nextcloud-Web).

<img width="793" height="128" alt="image" src="https://github.com/user-attachments/assets/95e7c77d-9bca-49b6-9ded-41e673951b3e" />

Warten Sie, bis die öffentliche IP-Adresse am Ende angezeigt wird.

<img width="793" height="107" alt="image" src="https://github.com/user-attachments/assets/0ba57469-ec84-4cdc-a77b-b6bf27d31170" />

### 🌐 Schritt 5: Nextcloud-Installation abschliessen
Wartezeit: Warten Sie nach der Ausgabe der öffentlichen IP-Adresse noch etwa 2-3 Minuten, damit die automatischen Installationsskripte auf den Servern (MariaDB und Nextcloud) vollständig durchlaufen.

Im Browser öffnen: Kopieren Sie die am Ende der Skriptausgabe angezeigte Webserver Public IP und geben Sie sie in Ihren Browser ein: http://[Ihre_Webserver_Public_IP]

<img width="1040" height="225" alt="image" src="https://github.com/user-attachments/assets/dab6934d-28a7-4148-b167-2bf581813beb" />

### Schritt 6: Auf Nextcloud zugreifen
Sie sollten nun die Ersteinrichtungsseite von Nextcloud sehen.

Administratorkonto erstellen: Geben Sie auf der Nextcloud-Seite den gewünschten Administrator-Benutzernamen und ein Passwort ein.

Datenbank-Details eingeben: Wenn Nextcloud nach den Datenbankinformationen fragt, verwenden Sie die im Skript festgelegten Standardwerte:

Datenbank-Benutzer: nextcloud_user

Datenbank-Passwort: SecurePass2025!

Datenbank-Name: nextcloud_db

Der Datenbank-Host (die private IP-Adresse von Database) wird automatisch vom Skript bereitgestellt.

Nachdem Sie die Daten eingegeben und auf „Installation abschliessen“ geklickt haben, sollte Ihre Nextcloud-Instanz einsatzbereit sein!

## 4. Tests
### Testfälle
| Test-ID | Beschreibung                     | Erwartung                               | Ergebnis | Datum | Tester |
|---------|----------------------------------|-------------------------------------------|----------|-------|--------|
| T1      | "deploy_aws.sh" ausführen        | DB + Instanz + PW werden erstellt            | OK       | 14.12   | Jayden / Eymen     |
| T2      | "EC2 Instanz wird erstellt       | EC2 Instanz wird erstellt                  | OK       | 14.12  | Eymen/Jayden  |
| T3      | Nextcloud Seite erscheint        | Nextcloud ladet               | OK       | 14.12  | Eymen/ Julian    |
| T4      | Login mit Datenbank              | Dashboard lädt                            | OK       | 14.12 | Eymen/ Julian   |
| T5      | Security Groups erstellt         | Security Groups sichtbar                          | OK       | 14.12  | Julian/Jayden|

### Screenshots

### T1

<img width="793" height="974" alt="image" src="https://github.com/user-attachments/assets/9aa1ea6d-d38e-437c-9174-295a22ed5673" />

### T2

<img width="2251" height="1127" alt="image" src="https://github.com/user-attachments/assets/836d1b21-029a-478d-8b46-f87e397d015c" />

### T3

<img width="1923" height="1020" alt="image" src="https://github.com/user-attachments/assets/cdfff8a4-8e69-40d2-aa91-f1e61616f483" />


### T4

<img width="800" height="569" alt="image" src="https://github.com/user-attachments/assets/bed01807-2aa8-44d6-a0f0-a1692bbc1c5a" />

<img width="1768" height="819" alt="image" src="https://github.com/user-attachments/assets/27f06736-c258-4916-91cf-059a08a4ff22" />

### T5

<img width="2260" height="999" alt="image" src="https://github.com/user-attachments/assets/453e7b68-54ea-478e-a76f-79677881232b" />

## 5. Zusammenarbeit & Git
### Commit-Strategie
Im Git-Repository wurden folgende Regeln beachtet:

Feature Branches: Wir hatten zwar Branches aber wir haben sie nicht benutzt und haben alles im Main Branch gemacht.

### Kurze Beschreibung der Zusammenarbeit
Das Team arbeitete eng zusammen, indem Aufgaben in kleinere Teile zerlegt und parallel bearbeitet wurden. Git und GitHub wurden als Versionierungssystem verwendet,
und regelmässige Meetings halfen dabei, den Fortschritt zu überprüfen und Probleme zu lösen.

## 6. Schwierigkeiten

Die fehlerhaften Skripts finden sie unter ["/M346-projekt/Fehlerhafte-Skripts"](/Fehlerhafte-Skripts)
Während der Umsetzung des Projekts traten erhebliche Schwierigkeiten bei der Ausführung des Skripts auf, die eine erfolgreiche Bereitstellung der Nextcloud-Umgebung verhinderten. Ein zentrales Hindernis war der Prozessschritt zur Initialisierung der Datenbank-Instanz, bei dem das Skript regelmässig ohne erkennbaren Fortschritt stoppte. Dies führte dazu, dass die notwendige Infrastruktur für die Datenspeicherung nicht aufgebaut werden konnte und der gesamte Installationsvorgang frühzeitig zum Erliegen kam. Selbst in den Fällen, in denen das Deployment scheinbar abgeschlossen wurde, trat ein weiteres kritisches Problem auf, da die Nextcloud-Webseite im Browser nicht geladen werden konnte. Trotz der aktiven Instanzen in der AWS-Konsole blieb der Zugriff auf die Benutzeroberfläche verwehrt, wodurch das System für den Endnutzer nicht erreichbar war. Insgesamt erwies sich das man auch einigermassen schlau promten muss, anschliessend funktionierte es aber auch.

## 7. Reflexion
### Eymen
Das Projekt war eine grossartige Gelegenheit, Nextcloud auf einer Cloud-Infrastruktur zu implementieren und mit AWS zu arbeiten. Besonders spannend war es, die Architektur mit einem separaten Web- und Datenbankserver zu entwerfen, was für Skalierbarkeit und Sicherheit wichtig ist. Ich hatte die Verantwortung für den Webserver und die Konfiguration von Nextcloud. Dabei stiess ich auf einige Herausforderungen, insbesondere bei der Integration der MariaDB-Datenbank mit Nextcloud und der Netzwerkkonfiguration in AWS. Es war nicht immer sofort klar, welche Sicherheitsgruppen und IP-Konfigurationen optimal sind.

Im Rückblick würde ich beim nächsten Mal sicherstellen, dass die Server-Initialisierung parallel erfolgt, anstatt auf eine Instanz zu warten, um Zeit zu sparen. Zudem könnte man die Konfiguration von Nextcloud besser automatisieren und auf Fehlermeldungen besser reagieren, falls etwas während der Installation schiefgeht.

### Jayden
Als Verantwortlicher für den Datenbankserver war meine Aufgabe, die MariaDB-Datenbank auf dem DB-Server zu installieren und richtig zu konfigurieren. Dies war zunächst eine Herausforderung, da die Datenbankverbindung zwischen dem Webserver und dem DB-Server sicher und stabil eingerichtet werden musste. Ein Problem war, dass AWS Instanzen mit internen IPs arbeiten und diese korrekt konfiguriert werden müssen, was manchmal zu Verwirrung führte. Besonders als die Verbindung zwischen Webserver und DB-Server nicht sofort funktionierte, verbrachte ich etwas Zeit mit der Überprüfung der Netzwerkrouten und der Sicherheitsgruppen.

Eine wichtige Erkenntnis war, dass die Konfiguration der Datenbankzugriffsrechte und die Firewall sehr genau geprüft werden müssen, um Kommunikationsprobleme zu vermeiden. In Zukunft würde ich diese Prozesse weiter automatisieren und mehr Protokolle verwenden, um eventuelle Fehlerquellen schnell zu identifizieren.

### Julian
Meine Aufgabe war es, die Dokumentation des Projekts zu erstellen und beim Debuggen der Skripte zu helfen. Ich sorgte dafür, dass alle Schritte des Projekts klar und nachvollziehbar beschrieben wurden. Zudem unterstützte ich bei der Fehlerbehebung, insbesondere bei der Konfiguration der Datenbankverbindung und der AWS Instanzen.

Im Rückblick würde ich die Testfälle noch stärker in die Dokumentation integrieren, um die Nachvollziehbarkeit zu verbessern. Zudem wäre es hilfreich, die Skripte mit detaillierteren Kommentaren und einer besseren Fehlerbehandlung auszustatten, um die Nutzung und das Troubleshooting zu erleichtern.

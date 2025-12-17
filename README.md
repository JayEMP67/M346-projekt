# Projekt Modul 346 – Nextcloud

## Team
- Eymen – Webserver & Nextcloud
- Jayden – Datenbankserver
- Julian – IaC & Dokumentation

## Ziele
- Nextcloud in der Cloud aufsetzen (Web + DB separat)
- Installation via Skript automatisieren
- Projekt und Tests in Markdown dokumentieren

# Inhaltsverzeichnis

1. [Einleitung](#1-einleitung)
   - [Ziel des Projekts](#ziel-des-projekts)
   - [Kurzbeschreibung von Nextcloud](#kurzbeschreibung-von-nextcloud)
   - [Team & Rollen](#team--rollen)

2. [Architektur](#2-architektur)
   - [Beschreibung: Webserver + DB-Server](#beschreibung-webserver--db-server)
   - [kleine Skizze](#kleine-skizze)

3. [Installation / Inbetriebnahme](#3-installation--inbetriebnahme)
   - [Voraussetzungen](#voraussetzungen)
   - [Ausführen von install-dbsh](#ausführen-von-install-dbsh)
   - [Ausführen von install-nextcloud-websh](#ausführen-von-install-nextcloud-websh)
   - [IP finden / URL aufrufen](#wo-finde-ich-die-ip--wie-rufe-ich-die-url-auf)

4. [Tests](#4-tests)
   - [Testfälle](#testfälle)
   - [Screenshots](#screenshots)

5. [Zusammenarbeit & Git](#5-zusammenarbeit--git)
   - [Rollen](#rollen)
   - [Commit-Strategie](#commit-strategie)
   - [Beschreibung der Zusammenarbeit](#kurze-beschreibung-der-zusammenarbeit)

6. [Reflexion](#6-reflexion)
   - [Person A](#person-a)
   - [Person B](#person-b)
   - [Person C](#person-c)

# Nextcloud-Projekt – Modul 346

## 1. Einleitung

### Ziel des Projekts
Das Ziel dieses Projekts war es, **Nextcloud auf einer AWS-Infrastruktur** bereitzustellen, wobei Webserver und Datenbankserver getrennt voneinander laufen. Dies sollte eine hohe Verfügbarkeit und Skalierbarkeit der Anwendung gewährleisten.

### Kurzbeschreibung von Nextcloud
**Nextcloud** ist eine Open-Source-Plattform für **Cloud-Speicher** und **Dateisynchronisation**, die es Nutzern ermöglicht, ihre Daten in einer sicheren Umgebung zu speichern und über verschiedene Geräte zu synchronisieren. Es bietet eine **Weboberfläche**, mobile Apps und eine **starke Integration von Kollaborationswerkzeugen**, die es Nutzern ermöglichen, Dokumente zu bearbeiten, Dateien zu teilen und gemeinsam zu arbeiten.

### Team & Rollen
Das Projekt wurde im Team durchgeführt. Die Aufgaben wurden wie folgt verteilt:
- **Eymen**: Architekturplanung, Webserver-Implementierung und Nextcloud-Konfiguration
- **Jayden**: Implementierung der Datenbankinfrastruktur und Skripte für die Datenbankbereitstellung
- **Julian**: Dokumentation des Projekts, Tests und Implementierung von IaC (Infrastructure as Code)

## 2. Architektur

### Beschreibung: Webserver + DB-Server
Die Architektur des Projekts umfasst zwei Hauptkomponenten:
- **Webserver**: Der Webserver hostet die Nextcloud-Anwendung und ermöglicht Nutzern den Zugriff auf ihre Dateien und Daten. Er wird über **Apache** und **PHP** betrieben, mit einer Datenbankverbindung zu **MariaDB**.
- **Datenbankserver**: Der DB-Server speichert alle Daten von Nextcloud, einschließlich Benutzerinformationen und Datei-Metadaten. Er wird mit **MariaDB** betrieben und ist über eine **private IP-Adresse** mit dem Webserver verbunden, um die Sicherheit der Kommunikation zu gewährleisten.

Die Kommunikation zwischen dem Webserver und dem Datenbankserver erfolgt über interne Netzwerke innerhalb der AWS-Infrastruktur. Der Webserver ist öffentlich zugänglich, während der Datenbankserver in einer privaten Subnetz-Konfiguration betrieben wird, um die Sicherheit zu erhöhen.

## 3. Installation / Inbetriebnahme
### Voraussetzungen
### Ausführen von `install-db.sh`
### Ausführen von `install-nextcloud-web.sh`
### Wo finde ich die IP / wie rufe ich die URL auf

## 4. Tests
### Testfälle
| Test-ID | Beschreibung                     | Erwartung                               | Ergebnis | Datum | Tester |
|---------|----------------------------------|-------------------------------------------|----------|-------|--------|
| T1      | `install-db.sh` ausführen        | DB + User + PW werden erstellt            | OK       | ...   | Jayden     |
| T2      | `install-nextcloud-web.sh` ausführen | Nextcloud-Installer erscheint            | OK       | ...   | Julian    |
| T3      | Installer mit DB-Daten ausfüllen | Nextcloud installiert sich                | OK       | ...   | Eymen     |
| T4      | Login mit Admin                  | Dashboard lädt                            | OK       | ...   | Eymen    |
| T5      | MySQL Workbench auf DB verbinden | Tabellen sichtbar                          | OK       | ...   | Julian/Jayden|

### Screenshots

## 5. Zusammenarbeit & Git
### Rollen
### Commit-Strategie
### Kurze Beschreibung der Zusammenarbeit

## 6. Reflexion
### Person A
### Person B
### Person C

## 7. Quellen
### Links zu Nextcloud, MySQL, Tutorials


7. [Quellen](#7-quellen)
   - [Links](#links-zu-nextcloud-mysql-tutorials)

## 7. Quellen
- Links zu Nextcloud, MySQL, Tutorials

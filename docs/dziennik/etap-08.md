# Dziennik: etap 8 (monitoring Zabbix)

**Data:** 2026-10-25

## Wykonane prace
- Wybór Zabbix 7.0.32 LTS; obrazy przypięte tagiem i skrótem
  (ADR-024, ADR-025); weryfikacja PHP-FPM 8.5.12 (PHP2Shell).
- Rola zabbix_server: serwer, interfejs i PostgreSQL 17.11, trzy sieci,
  interfejs za Traefikiem z certyfikatem ze step-ca.
- Rola zabbix_agent: agent Zabbix 2 z repozytorium Debiana na dc1,
  svc01 i hypervisorze (grupa monitored); monitorowanie Dockera na svc01.
- Playbook zabbix-config.yml: zmiana domyślnego hasła Admin przez
  JSON-RPC, grupa hostów i rejestracja hostów z szablonami, wyłączenie
  domyślnego hosta Zabbix server, katalog LDAPS z JIT provisioning,
  konto awaryjne Admin (ADR-026).
- Test awarii: wykrycie niedostępności agenta dc1.
- Decyzje zakresu: bez Grafany, bez monitorowania Proxmox VE przez API,
  bez powiadomień (kierunki rozwoju).

## Napotkane problemy

| Problem | Przyczyna | Rozwiązanie |
|---|---|---|
| Brak tagu alpine-8.0-latest | Zabbix 8.0 LTS jeszcze nie wydany | wybór 7.0 LTS |
| Tag alpine-7.0.X not found | symbol zastępczy zamiast numeru wersji | podstawienie 7.0.32 |
| Brak programu php w /usr/bin | PHP działa jako php-fpm85 w /usr/sbin | wyszukiwanie w /usr/bin i /usr/sbin |
| Różne obrazy dla tagów tej samej wersji | dwie kompilacje z tego samego dnia | przypięcie przez skrót manifestu |
| Role Zabbixa nie wykonały się | rola nie zapisana w playbooku | zapisanie pliku; git status --short przed uruchomieniem |
| Certyfikat TRAEFIK DEFAULT CERT | Traefik nie znał usługi (kontener nie istniał) | uruchomienie usługi; certyfikat ze step-ca automatycznie |
| 404 od API przy modułach community.zabbix | domyślna ścieżka /zabbix | ansible_zabbix_url_path: "" |
| Hasło Admin w niewłaściwej grupie zmiennych | potrzebne hostowi zabbix-api, nie svc01 | przeniesienie do group_vars/zabbix_api |
| Logowanie AD nie działało mimo udanego testu | JIT wymaga LDAP jako metody domyślnej | LDAP domyślnie; konto awaryjne Admin w grupie z logowaniem wewnętrznym |
| Czerwona ikona ZBX przy svc01 | połączenie z kontenera do hosta bez maskowania adresu (172.21.0.2) | stała podsieć 172.30.0.0/24 dopuszczona w Server agenta |
| cd /opt/stack/zabbix: Permission denied | katalog 0750 root (plik z sekretami) | sudo docker compose --project-directory |
| Problem dc1 niewidoczny na liście | filtr ograniczony do hosta Zabbix server | wyczyszczenie filtra |
| Brak problemu przy krótkiej awarii | wyzwalacz wymaga 3 minut braku danych | test z przerwą 5 minut |
| Host Zabbix server stale niedostępny | domyślny host z agentem 127.0.0.1 w kontenerze | wyłączenie hosta przez API |
| Brak powiadomień o awarii | nie skonfigurowano typów mediów i akcji | poza zakresem; kierunek rozwoju |

## Pomiary

| Operacja | Wynik |
|---|---|
| Wdrożenie roli zabbix_server | 55 s |
| Pomiary (pozycje) w Zabbixie | 746, z czego 574 na svc01 (kontenery) |
| Czas wykrycia niedostępności agenta | ok. 3 min (próg wyzwalacza), wykrycie 14:58:30 |
| Czas potwierdzenia naprawy | do uzupełnienia |
| Ponowne wykonanie svc.yml i monitoring.yml | changed=0 |
| Ponowne wykonanie zabbix-config.yml | changed=1 (pole hasła tylko do zapisu) |

## Wnioski
- Test otwarcia portu nie potwierdza działania usługi; dopiero dziennik
  agenta ujawnił odrzucane połączenia.
- Udany test konfiguracji LDAP nie gwarantował działania logowania;
  różnica wynikała z mechanizmu JIT i metody domyślnej.
- Monitoring obejmuje wykrywanie; powiadamianie jest osobnym elementem.

## Otwarte kwestie
- Powiadomienia (np. e-mail, Telegram).
- Monitorowanie Proxmox VE przez API kontem tylko do odczytu.
- Niezależny monitoring na Raspberry Pi 5.
- Pośrednik gniazda Dockera dla agenta i Traefika.
- Widżet domyślnego pulpitu odwołujący się do wyłączonego hosta.

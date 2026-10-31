# Wyniki testów

## 1. Zgodność środowiska z kodem

| Test | Wynik |
|---|---|
| site.yml, pierwsze uruchomienie (2026-10-27) | 1 min 35 s; zmiany zewnętrzne na dc1 (1) i zabbix-api (2) |
| site.yml, drugie uruchomienie | jedyna zmiana: katalog użytkowników Zabbixa (pole hasła tylko do zapisu) |
| deploy.sh na działającym środowisku (2026-10-27) | 89 s: Terraform 2 s, maszyny 2 s, Ansible 85 s; brak zmian poza Zabbixem |
| deploy.sh po przywróceniu z vzdump (2026-10-31) | 102 s; svc01 changed=0 |

## 2. Kopie zapasowe

| Pomiar | restic (dane usług) | vzdump (maszyna svc01) |
|---|---|---|
| Czas wykonania | 45–47 s (svc01), 4 s (dc1) | 49 s |
| Rozmiar | ok. 80 MB po kompresji (417 MB danych, 5,38×); dc1: 1,7 MB | 2,09 GB (50 GiB dysków, 88,9% pustych bloków) |
| Przerwa w działaniu usług | step-ca 1 s, Gitea 13 s, BookStack 16 s, Zabbix 15 s | brak |
| Spójność | gwarantowana (kopia na zimno, samba-tool) | jak po nagłym wyłączeniu |
| Szyfrowanie | AES-256 | brak |

## 3. Odtworzenie pojedynczej usługi (restic)

| Test | Wynik |
|---|---|
| BookStack po trwałym usunięciu książki (2026-10-25) | 16 s; dane przywrócone; pozostałe usługi bez przerwy |
| Cztery usługi po INC-01 (2026-10-27) | ok. 1 min; baza Zabbixa uruchomiona poprawnie |

## 4. Awaria svc01 (2026-10-31)

### Scenariusz A: odbudowa z kodu i kopii usług

| Zdarzenie | Czas |
|---|---|
| Koniec kopii restic | 11:15:24 |
| Awaria (qm destroy 101) | 11:18:47 |
| Terraform | 13 s |
| Oczekiwanie na maszynę | 13 s |
| Ansible | 648 s (96% czasu) |
| Wszystkie testy akceptacyjne | 11:30:05 |
| **RTO** | **11 min 18 s** |
| **RPO** | **3 min 23 s** |

Próba 1 (INC-03): ok. 43 min z diagnozą i dwiema poprawkami kodu.
Odcisk certyfikatu głównego niezmieniony we wszystkich próbach.

### Scenariusz B: przywrócenie z kopii vzdump

| Zdarzenie | Czas |
|---|---|
| Kopia vzdump | 10:24:57–10:25:46 |
| Awaria | 11:34:52 |
| qmrestore i start maszyny | 32 s (do 11:35:24) |
| Usługi przez HTTPS | 11:35:59 |
| **RTO** | **ok. 1 min 7 s** |
| **RPO** | **69 min 6 s** |

Znaczniki BookStack po scenariuszu B: A (przed kopią) obecny,
B i C (po kopiach) nieobecne. Bazy PostgreSQL i MariaDB uruchomiły się
poprawnie z kopii spójnej jak po wyłączeniu.

## 5. Porównanie metod

| Kryterium | A: kod i restic | B: vzdump |
|---|---|---|
| RTO | 11 min 18 s | ok. 1 min 7 s |
| RPO zmierzone | 3 min 23 s | 69 min 6 s |
| RPO przy harmonogramie dobowym | do 24 h | do 24 h |
| Możliwość częstszych kopii | wysoka (przyrostowe, małe) | niska (2 GB na kopię) |
| Stan po odtworzeniu | świeży system | system z chwili kopii |
| Szczegółowość | pojedyncza usługa | cała maszyna |
| Zależności | internet (Debian, Docker Hub, GitHub) | Proxmox i NAS |

## 6. Wnioski

1. Metoda B jest ok. 10 razy szybsza; czas metody A zdominowany przez
   instalację pakietów i pobieranie obrazów (wypiekanie obrazów jako
   kierunek rozwoju).
2. RPO wyznacza harmonogram kopii, nie metoda; kopie danych usług
   pozwalają na częstsze wykonywanie.
3. Odtwarzanie z kodu zależy od zewnętrznych źródeł (lokalne lustro
   pakietów i obrazów jako kierunek rozwoju).
4. Metody się uzupełniają (ADR-027); po przywróceniu z B deploy.sh
   doprowadza maszynę do zgodności z kodem.
5. Testy wykryły sześć błędów niewidocznych podczas pracy na
   istniejącym środowisku (INC-01, INC-03, INC-04).

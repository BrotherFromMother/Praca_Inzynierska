# Dziennik: etap 9 (kopie zapasowe i odtwarzanie)

**Data:** 2026-10-25

## Wykonane prace
- Analiza danych usług: co wymaga kopii, a co jest odtwarzalne
  z kodu lub automatycznie (certyfikaty Traefika).
- Porównanie kopii maszyn (vzdump) i kopii danych usług; przyjęcie
  obu jako obrony warstwowej (ADR-027).
- Udział homelab-backup na Synology z dostępem NFS dla dc1 i svc01.
- Rola backup: restic, montowanie NFS, inicjalizacja repozytoriów,
  skrypt kopii (samba-tool na dc1, kopia wolumenów na zimno na svc01),
  timer systemd o 1:30, katalog pamięci podręcznej restic.
- Pierwsze kopie i weryfikacja (restic snapshots, stats, check).
- Test odtworzenia BookStacka po trwałym usunięciu danych.
- Procedura odtwarzania (docs/runbook-odtwarzanie.md).

## Napotkane problemy

| Problem | Przyczyna | Rozwiązanie |
|---|---|---|
| mount.nfs4: access denied | reguły NFS folderu nie zostały zapisane (brak eksportu w showmount -e) | dodanie reguł i zapisanie okna edycji folderu |
| showmount: command not found | program w /usr/sbin, poza ścieżką użytkownika; polecenie wykonane w WSL zamiast na svc01 | sudo showmount; sprawdzanie znaku zachęty |
| Plik testowy zapisany lokalnie | brak kontroli montowania przed zapisem | mountpoint przed zapisem; kontrola w skrypcie i RequiresMountsFor w usłudze |
| Permission denied przy ls na udziale | zawartość dostępna tylko dla roota | cecha pożądana (dane wrażliwe) |
| Brak szablonu homelab-backup.timer.j2 | błędna nazwa pliku | zmiana nazwy |
| restic: unable to open cache | usługa systemd bez katalogu domowego | CacheDirectory i RESTIC_CACHE_DIR w usłudze |
| Kontener whoami nadal działał | zmiana traefik_whoami_enabled nie została zapisana w etapie 7 | ustawienie false i ponowne wykonanie svc.yml |

## Pomiary

| Operacja | Wynik |
|---|---|
| Kopia katalogu Samby AD (dc1) | 4 s, 1,7 MB |
| Kopia usług svc01 | 45 s, 417 MB danych (ok. 80 MB po kompresji, 5,38×) |
| Przerwa w działaniu podczas kopii | step-ca 1 s, Gitea 13 s, BookStack 16 s, Zabbix 15 s |
| Odtworzenie BookStacka (RTO pojedynczej usługi) | 16 s |
| Utrata danych (RPO) | do 24 h przy kopii dobowej |
| restic check | brak błędów |

## Wnioski
- Koszt spójnej kopii na zimno to czas restartu usługi, a nie czas
  kopiowania danych.
- Kopie per usługa pozwalają odtworzyć jedną usługę bez wpływu na
  pozostałe; kopia maszyny cofnęłaby wszystkie usługi svc01.
- Kopia jest wiarygodna dopiero po udanym teście odtworzenia.

## Otwarte kwestie
- Kopia poza siedzibą (reguła 3-2-1).
- Monitorowanie świeżości kopii w Zabbixie (plik last-success).
- Pełny test awarii svc01 z pomiarem RTO i RPO (etap 11).
- Przechowywanie hasła restic i hasła sejfu Ansible poza infrastrukturą.

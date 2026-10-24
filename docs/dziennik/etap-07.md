# Dziennik: etap 7 (BookStack)

**Data:** 2026-10-24

## Wykonane prace
- Wybór obrazu LinuxServer.io i weryfikacja wersji PHP pod kątem
  PHP2Shell (PHP 8.5.12 z 21.10.2026).
- Rola bookstack: BookStack i MariaDB w sieci wewnętrznej, LDAPS
  z weryfikacją certyfikatu, identyfikacja po objectGUID,
  synchronizacja ról z grupami przy każdym logowaniu (ADR-023).
- Mapowanie ról: Admin ↔ grp-it-admins, Editor ↔ grp-wiki-users,
  idempotentne polecenie SQL z ROW_COUNT.
- Usunięcie domyślnego konta admin@admin.com.
- Wyłączenie usługi testowej whoami jedną zmienną (remove_orphans).
- Reguła NRPT na stacji administratora (zamknięcie kwestii z etapu 6).

## Napotkane problemy

| Problem | Przyczyna | Rozwiązanie |
|---|---|---|
| Pozorne zawieszenie przy pobieraniu obrazu | docker pull -q bez paska postępu przy dużym obrazie | sesja SSH i polecenia wykonywane pojedynczo, bez -q |
| Polecenia wykonane lokalnie zamiast na svc01 | ' ' zamknęło cudzysłów polecenia ssh | interaktywna sesja SSH |
| bookstack_app_key is undefined | brak zapisanych zmian w group_vars/docker_hosts/vars.yml | zapisanie pliku; kontrola grep -c przed uruchomieniem; łączenie poleceń przez && |
| git i wiki nie otwierały się w przeglądarce | DNS karty przewodowej laptopa | reguła NRPT dla .homelab.internal, wyczyszczenie pamięci DNS przeglądarki |
| Jan nie mógł się zalogować | wpis w menedżerze haseł niezgodny z sejfem | hasło odczytane z sejfu; sejf jako jedyne źródło prawdy |

## Wnioski
- Schemat usługi z etapu 6 (Compose, sieć wewnętrzna bazy, etykiety
  Traefika, LDAPS) skrócił wdrożenie kolejnej usługi do jednego dnia.
- Brak wartości domyślnych dla sekretów powoduje czytelny błąd zamiast
  cichego pominięcia, w przeciwieństwie do sytuacji z etapu 6.
- Dwie usługi korzystają z tych samych kont z różnymi uprawnieniami
  wynikającymi z grup.

## Otwarte kwestie
- Rola samba_dc nie usuwa rekordów DNS usuniętych z listy (np. whoami).
- Usunięcie domyślnego konta BookStacka wykonane ręcznie.

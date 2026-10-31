# Dziennik: etap 11 (testy i pomiary)

**Data:** 2026-10-31

## Wykonane prace
- Skrypt verify.sh: testy akceptacyjne z trybem oczekiwania (ADR-030).
- Przygotowanie: znaczniki w BookStacku, kopia restic, ręczna kopia
  vzdump svc01.
- Rotacja klucza automatyzacji po ujawnieniu (INC-02, ADR-031).
- Scenariusz A, próba 1: wykrycie dwóch błędów (INC-03) i poprawki.
- Scenariusz A, próba 2: czysty pomiar RTO i RPO.
- Scenariusz B: przywrócenie z vzdump, pomiar, doprowadzenie do
  zgodności z kodem.
- Kopie kluczy i sekretów w menedżerze haseł, zweryfikowane
  odtworzeniem (stacja robocza przestaje być pojedynczym punktem awarii).

## Napotkane problemy

| Problem | Przyczyna | Rozwiązanie |
|---|---|---|
| Ujawnienie klucza automatyzacji (INC-02) | sh zamiast ssh | rotacja playbookiem, ignore_changes w module Terraform |
| Plan Terraform chciał zmienić klucze dc1 i svc01 | zmiana pliku .pub, brak lifecycle | ignore_changes = [initialization[0].user_account] |
| Filtr journalctl -n 3 nie pokazał wyniku kopii | linia wyniku czwarta od końca | -n 6 |
| CERTIFICATE_VERIFY_FAILED przy odbudowie (INC-03) | handler przebudowy magazynu na końcu playbooka | weryfikacja magazynu i flush_handlers |
| Ten sam błąd przy ponownym przebiegu | handler utracony po błędzie | force_handlers = True |
| verify.sh nie wykrył brakujących kontenerów | test sprawdzał tylko istniejące | lista oczekiwanych kontenerów |
| verify.sh: błąd testu kontenerów po scenariuszu B | brak accept-new przy nowym kluczu serwera | StrictHostKeyChecking=accept-new |
| Brak kopii nocnych vzdump (INC-04) | zadanie o 2:00, serwer wyłączany na noc | zmiana harmonogramu |
| Logowanie kluczem homelab bez hasła w teście kopii | agent SSH; Bitwarden przechowuje klucz odszyfrowany | test z SSH_AUTH_SOCK= |

## Pomiary

| Operacja | Wynik |
|---|---|
| Kopia vzdump svc01 | 49 s, 2,09 GB |
| Scenariusz A, próba 1 | ok. 43 min (z diagnozą i poprawkami) |
| **Scenariusz A, próba 2** | **RTO 11 min 18 s, RPO 3 min 23 s** |
| Scenariusz A: udział faz | Terraform 13 s, maszyny 13 s, Ansible 648 s |
| **Scenariusz B** | **RTO ok. 1 min 7 s, RPO 69 min 6 s** |
| qmrestore | 32 s (88,9% bloków pustych) |
| deploy.sh po scenariuszu B | 102 s, svc01 changed=0 |
| Rotacja klucza | ok. 10 min, bez utraty dostępu |

Szczegółowe zestawienie: docs/wyniki-testow.md; incydenty:
docs/incydenty.md.

## Wnioski
- Testy odbudowy od zera wykrywają zależności od istniejącego stanu.
- Metoda B jest ok. 10 razy szybsza, metoda A daje spójność,
  szczegółowość, szyfrowanie i świeży system; metody się uzupełniają.
- RPO zależy od harmonogramu kopii, a nie od metody.

## Otwarte kwestie
- Harmonogram vzdump i monitorowanie świeżości kopii (INC-04).
- Test odtworzenia Samby AD (procedura sekcja 3 niezweryfikowana).
- Koperta awaryjna z sekretami krytycznymi.
- Data w komentarzu nowego klucza (2026-10-28 zamiast 2026-10-31).

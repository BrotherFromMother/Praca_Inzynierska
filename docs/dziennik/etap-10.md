# Dziennik: etap 10 (wdrożenie jednym poleceniem)

**Data:** 2026-10-27

## Wykonane prace
- Playbook site.yml w kolejności zależności; ca_trust w dc-tls.yml;
  rola backup w svc.yml przed usługami (ADR-028).
- Rola backup_restore: przywracanie danych usług, gdy ich wolumeny nie
  istnieją, przed startem usług (ADR-029).
- Skrypt deploy.sh: Terraform, oczekiwanie na maszyny, site.yml,
  pomiar czasu.
- Test zbieżności na działającym środowisku.

## Napotkane problemy

| Problem | Przyczyna | Rozwiązanie |
|---|---|---|
| ansible-lint name[template] | zmienna Jinja w środku nazwy zadania | zmienne tylko na końcu nazwy |
| load-failure w edytorze dla restore_stack.yml | rozszerzenie analizuje plik poza rolą | rozstrzyga ansible-lint w terminalu |
| **Nadpisanie danych działających usług (INC-01)** | lista wolumenów przekazana jako jeden argument | konkatenacja list w argv; przywrócenie z kopii 18:42 |
| Uszkodzona baza Zabbixa | nadpisanie plików pod działającą bazą | przywrócenie po identyfikatorze kopii |
| Brak kopii nocnych 26–27.10 (INC-04) | serwer wyłączony | Persistent=true nadrobił kopię; monitorowanie kopii |
| journalctl: Failed to parse timestamp: today 18:50 | nieobsługiwany format | pełna data i godzina |
| Polecenia ssh wykonywane na svc01 zamiast na laptopie | pomyłka terminala | kontrola znaku zachęty |
| Kontener whoami działał od etapu 7 | zmiana zmiennej nie została zapisana | sed i ponowne wdrożenie; wartości defaults niewidoczne w poleceniach ad-hoc |

## Pomiary

| Operacja | Wynik |
|---|---|
| site.yml na działającym środowisku | 1 min 35 s |
| deploy.sh na działającym środowisku | 89 s (Terraform 2 s, maszyny 2 s, Ansible 85 s) |
| Przywrócenie czterech usług po INC-01 | ok. 1 min |

## Wnioski
- Test roli odtwarzania na działającym środowisku jest obowiązkowy;
  wykrył błąd, który przy odbudowie byłby niewidoczny.
- Kopie na zimno i Persistent=true pozwoliły na pełną naprawę.

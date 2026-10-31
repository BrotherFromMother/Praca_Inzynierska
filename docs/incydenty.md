# Rejestr incydentów

Analizy poincydentalne w formule bez szukania winnych (*blameless*):
celem jest zrozumienie przyczyn i wdrożenie działań zapobiegawczych.

| Nr | Data | Tytuł | Waga |
|---|---|---|---|
| INC-01 | 2026-10-27 | Nadpisanie danych działających usług przez rolę backup_restore | wysoka |
| INC-02 | 2026-10-31 | Ujawnienie klucza prywatnego automatyzacji | średnia |
| INC-03 | 2026-10-31 | Nieudana odbudowa svc01: magazyn certyfikatów i utracony handler | średnia |
| INC-04 | 2026-10-25 – 31 | Ciche niewykonywanie kopii nocnych | wysoka |

---

## INC-01: Nadpisanie danych działających usług przez rolę backup_restore

**Data:** 2026-10-27, ok. 18:44–19:30 CET

### Przebieg

| Czas (CET) | Zdarzenie |
|---|---|
| 18:41:21 | start svc01 po wyłączeniu od 25.10 (zob. INC-04) |
| 18:42:55–18:43:40 | kopia nadrabiająca (Persistent=true), na zimno, udana |
| ok. 18:44 | test 1 roli backup_restore na działającym środowisku: przywrócenie wszystkich czterech usług (changed=8) pod działające bazy |
| 19:00:10–19:00:45 | kopia ręczna zapisuje nadpisany stan; baza Zabbixa nie startuje, skrypt kończy się błędem |
| od 19:00:45 | zabbix-db w pętli restartów: PANIC: could not locate a valid checkpoint record |
| ok. 19:20 | wykrycie (analiza wyniku testu 1), wstrzymanie timera kopii |
| ok. 19:25 | czyste przywrócenie czterech usług z kopii z 18:42 (po identyfikatorach) |
| 19:32 | świeża kopia, ponowne włączenie timera |

### Przyczyna źródłowa
Zadanie sprawdzające istnienie wolumenów przekazywało listę wolumenów
jako jeden element argv; Ansible zamienił listę na tekst, skrypt
sprawdzał nieistniejący wolumen i zawsze zwracał „brak wolumenów”.
docker volume create dla istniejącego wolumenu nie zgłasza błędu, więc
nic nie zatrzymało przywracania.

### Skutki
- Niespójne pliki baz PostgreSQL (Gitea, Zabbix), MariaDB (BookStack)
  i step-ca; baza Zabbixa nie mogła wystartować (niezgodność pliku
  sterującego z dziennikiem WAL).
- Kopia z 19:00 zawierała uszkodzony stan.
- Utrata danych z ok. 40 minut (historia Zabbixa, certyfikaty wydane
  przez step-ca, odnawialne automatycznie).

### Co zadziałało
- Kopie na zimno z 18:42 i Persistent=true (bez kopii nadrabiającej
  ostatnią dobrą kopią byłaby kopia z 25.10).
- Odłożenie bieżących danych na bok zamiast ich usuwania.
- Skrypt kopii zakończył się błędem zamiast zgłosić sukces.

### Działania
- Poprawka argv (konkatenacja list), test na działającym środowisku:
  wszystkie przywrócenia pominięte.
- Przywracanie po identyfikatorze kopii zamiast latest, gdy najnowsza
  kopia może być uszkodzona.
- Monitorowanie wyników kopii (INC-04).

---

## INC-02: Ujawnienie klucza prywatnego automatyzacji

**Data:** 2026-10-31, ok. 10:20 CET

### Przebieg
Literówka sh zamiast ssh w poleceniu `ssh -i ~/.ssh/portal_automation_ed25519 …`
spowodowała wykonanie pliku klucza jako skryptu powłoki; komunikaty
błędów zawierały kolejne linie klucza i zostały wklejone do rozmowy
z asystentem.

### Ocena
Klucz bez hasła, dostęp do konta ansible z sudo na dc1 i svc01;
maszyny niedostępne z internetu. Zgodnie z zasadą klucz uznano za
przejęty.

### Działania (ok. 10 minut, bez utraty dostępu)
1. Nowy klucz ed25519.
2. Dodanie nowego klucza (logowanie starym), test.
3. Zamiana plików, usunięcie pozostałych kluczy (exclusive), test:
   stary klucz odrzucany (Permission denied).
4. shred starego klucza.
5. ignore_changes dla kluczy cloud-init w module Terraform.
6. Kopie wszystkich kluczy i sekretów w menedżerze haseł, sprawdzone
   odtworzeniem i użyciem (ADR-031).

### Wnioski
- Procedura rotacji zapisana jako playbook.
- Kluczy prywatnych nie wyświetla się; porównanie przez odcisk
  (ssh-keygen -lf).

---

## INC-03: Nieudana odbudowa svc01 (scenariusz A, próba 1)

**Data:** 2026-10-31, 10:27–11:10 CET

### Przebieg

| Czas | Zdarzenie |
|---|---|
| ok. 10:27 | awaria: qm destroy 101 |
| 10:28:00–10:40:07 | deploy.sh: maszyna i dane odtworzone, błąd w roli gitea: CERTIFICATE_VERIFY_FAILED |
| 10:44:46–10:48:45 | ponowne deploy.sh: ten sam błąd, changed=0 |
| 11:01:41–11:08:12 | deploy.sh po poprawkach: sukces |
| 11:09:53 | wszystkie testy akceptacyjne przechodzą |

### Przyczyny
1. Rola ca_trust kopiowała certyfikat główny i zlecała przebudowę
   magazynu handlerowi, wykonywanemu na końcu playbooka; rola gitea
   sprawdzała HTTPS wcześniej. Na dotychczasowej maszynie magazyn był
   przebudowany od etapu 6 (ukryta zależność od istniejącego stanu).
2. Po błędzie Ansible nie wykonał zaplanowanego handlera; przy kolejnym
   przebiegu plik już istniał, więc handler nie został zaplanowany
   ponownie.
3. Test kontenerów w verify.sh sprawdzał tylko działanie istniejących
   kontenerów i nie wykrył braku BookStacka i Zabbixa.

### Działania
- ca_trust: sprawdzenie dowiązania homelab-root-ca.pem w magazynie,
  przebudowa przy braku, meta: flush_handlers.
- force_handlers = True w ansible.cfg.
- verify.sh: lista dziewięciu oczekiwanych kontenerów;
  StrictHostKeyChecking=accept-new (wykryte w scenariuszu B).
- Powtórzenie scenariusza A od zera: sukces bez ingerencji (11 min 18 s).

### Wniosek
Odtwarzanie należy testować na zupełnie nowej maszynie; automatyzacja
powinna weryfikować efekt, a nie tylko wykonanie kroku.

---

## INC-04: Ciche niewykonywanie kopii nocnych

**Okres:** co najmniej 2026-10-25 – 2026-10-31

### Ustalenia
- Serwer był wyłączany na noc (np. od 25.10 19:24:57 do 27.10
  18:41:21 według dziennika systemd i uptime).
- Kopie restic (timer 1:30): nadrabiane po starcie dzięki
  Persistent=true, ale tylko jedno pominięte uruchomienie.
- Kopie vzdump (zadanie 2:00): Proxmox nie nadrabia pominiętych zadań;
  w magazynie nas-backup nie było ani jednej kopii nocnej dc1 i svc01.
- Nieudana kopia z 27.10 19:00 (INC-01) również nie została zauważona.

### Przyczyna
Harmonogram kopii niedopasowany do godzin pracy sprzętu; brak
monitorowania wykonania i świeżości kopii.

### Działania
- Harmonogram vzdump dopasowany do godzin pracy serwera.
- Monitorowanie świeżości kopii w Zabbixie (plik last-success).

### Wniosek
Kopie, których wykonania nikt nie monitoruje, mogą nie istnieć
przez długi czas bez niczyjej wiedzy.

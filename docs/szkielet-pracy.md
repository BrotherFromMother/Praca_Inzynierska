# Szkielet pracy inżynierskiej (wariant B)

**Temat:** Projekt i implementacja środowiska korporacyjnego opartego
na konteneryzacji usług

**Format (wymagania zajęć):** Times New Roman 12 pkt, interlinia 1,5,
marginesy 25 mm.

**Objętość orientacyjna:** 55–70 stron bez załączników.

## Powiązanie z zadaniami z zajęć przygotowujących

| Zajęcia | Zadanie | Miejsce w pracy |
|---|---|---|
| 2 | tematyka, cel i zakres | 1.1–1.3 |
| 3 | promotor i temat | strona tytułowa |
| 4 | cztery zagadnienia z krótkim komentarzem | 2.1 |
| 5 | analiza wybranego zagadnienia (min. 1 strona) | 2.2 |
| 6 | analiza min. czterech podobnych rozwiązań (min. 4 strony) | 2.3 |
| 7 | wymagania funkcjonalne, diagram przypadków użycia | 3.1–3.3 |
| 8 | opis trzech przypadków użycia (min. 1,5 strony) | 3.4 |
| 9 | narzędzia i technologie z uzasadnieniem (min. 1 strona) | 4.5 |

Teksty oddane na zajęciach mogą posłużyć jako pierwsze wersje tych
podrozdziałów (do aktualizacji pod wariant B).

---

## Streszczenie i słowa kluczowe (PL, EN)

Ok. pół strony w każdym języku; pisane na końcu.
Słowa kluczowe: infrastruktura jako kod, Active Directory, konteneryzacja,
kopie zapasowe, odtwarzanie po awarii.

---

## 1. Wstęp (4–5 stron)

### 1.1 Motywacja i tło problemu
Małe i średnie organizacje potrzebują typowych usług (katalog
użytkowników, repozytorium kodu, dokumentacja, monitoring), lecz rzadko
dysponują zespołem do ich utrzymania; ręcznie konfigurowane środowiska
są trudne do odtworzenia po awarii. Zmiany licencjonowania VMware
(źródło: TODO z ADR-001) jako tło wyboru platformy otwartej.

### 1.2 Cel pracy
Zaprojektowanie i wdrożenie środowiska usług firmowych z centralnym
zarządzaniem tożsamością, w pełni opisanego kodem, z kopiami zapasowymi
i zweryfikowaną procedurą odtwarzania po awarii.

### 1.3 Zakres pracy
W zakresie: wirtualizacja (Proxmox VE), infrastruktura jako kod
(Terraform, Ansible), Samba AD z LDAPS, własny urząd certyfikacji,
usługi w kontenerach (Gitea, BookStack, Zabbix) za Traefikiem, kopie
zapasowe w dwóch warstwach, testy odtworzenia z pomiarem RTO i RPO.
Poza zakresem (z uzasadnieniem w rozdz. 7): stacje robocze Windows
i GPO, segmentacja VLAN, portal samoobsługowy, kopia poza siedzibą.

### 1.4 Struktura pracy
Krótki opis rozdziałów 2–7.

**Materiały:** ADR-011 (zmiana zakresu), ADR-001.

---

## 2. Analiza problemu i przegląd rozwiązań (12–15 stron)

### 2.1 Kluczowe zagadnienia (zajęcia 4)
Cztery zagadnienia, każde z komentarzem w jednym, dwóch zdaniach:
1. **Zarządzanie tożsamością i dostępem**: jedno konto pracownika
   i uprawnienia nadawane grupami zamiast kont w każdej usłudze.
2. **Powtarzalność wdrożeń (infrastruktura jako kod)**: środowisko
   opisane kodem można odtworzyć, przeglądać i wersjonować.
3. **Bezpieczna komunikacja (PKI, TLS)**: szyfrowanie i uwierzytelnianie
   usług wewnętrznych bez publicznych certyfikatów.
4. **Ciągłość działania (kopie zapasowe i odtwarzanie)**: spójne kopie,
   mierzalne RTO i RPO, przetestowana procedura.

### 2.2 Analiza wybranego zagadnienia: ciągłość działania (zajęcia 5)
Pojęcia RTO, RPO, reguła 3-2-1; kopie maszyn a kopie danych aplikacji;
spójność kopii (na zimno, migawka, jak po wyłączeniu); znaczenie testów
odtworzenia. Min. 1 strona, w tym pół strony tekstu.
**Materiały:** ADR-027, docs/wyniki-testow.md (tylko jako zapowiedź).

### 2.3 Przegląd podobnych rozwiązań (zajęcia 6)
Min. cztery rozwiązania, łącznie min. 4 strony, w tym 2 strony tekstu.
Proponowany zestaw (gotowe platformy usług dla małych organizacji):

| Rozwiązanie | Charakterystyka do opisu |
|---|---|
| Microsoft Windows Server (AD DS, AD CS) i Microsoft 365 / Entra ID | standard rynkowy; licencje, zależność od dostawcy, chmura |
| Univention Corporate Server | Linux z katalogiem zgodnym z AD i katalogiem aplikacji |
| NethServer 8 | platforma oparta na kontenerach z modułami usług |
| Zentyal Server | linuksowy zamiennik Windows Server dla MŚP |
| (opcjonalnie) FreeIPA | katalog i PKI w świecie Linuksa, brak zgodności z AD |

### 2.4 Porównanie i wnioski
Tabela porównawcza (koszt, zgodność z AD, automatyzacja przez kod,
kopie i odtwarzanie, konteneryzacja, kontrola nad danymi) oraz
uzasadnienie budowy własnego środowiska: pełna automatyzacja
i zweryfikowane odtwarzanie, których gotowe platformy nie zapewniają
w tej postaci.

---

## 3. Wymagania i przypadki użycia (7–9 stron)

### 3.1 Aktorzy
Administrator IT (Anna Nowak, grp-it-admins), pracownik (Jan Kowalski),
administrator infrastruktury (autor, stacja z repozytorium), procesy
automatyczne (timer kopii, monitoring).

### 3.2 Wymagania funkcjonalne (zajęcia 7)
Np. WF-01 logowanie do usług kontem domenowym; WF-02 uprawnienia
w usługach wynikające z grup AD; WF-03 szyfrowany dostęp HTTPS
z certyfikatami zaufanego urzędu; WF-04 wdrożenie i weryfikacja
środowiska jednym poleceniem; WF-05 codzienne spójne kopie danych;
WF-06 odtworzenie pojedynczej usługi; WF-07 odtworzenie maszyny po
awarii; WF-08 monitorowanie maszyn i kontenerów z wykrywaniem awarii;
WF-09 rotacja kluczy dostępu.

### 3.3 Wymagania niefunkcjonalne i diagram przypadków użycia
Bezpieczeństwo (sekrety poza repozytorium, LDAPS, zasada minimalnych
uprawnień), idempotentność i zbieżność, mierzalne RTO/RPO, wyłącznie
oprogramowanie otwarte, ograniczenia sprzętowe (32 GB RAM).
Diagram przypadków użycia (UML).

### 3.4 Opis trzech przypadków użycia (zajęcia 8)
Min. 1,5 strony; dla każdego: aktorzy, warunki początkowe, przebieg
główny, przebiegi alternatywne, warunki końcowe.
1. **Odtworzenie usług po awarii serwera** (charakterystyczny).
2. **Nadanie dostępu nowemu pracownikowi przez grupę AD**
   (charakterystyczny): jedno członkostwo w grupie daje dostęp
   do Gitei, BookStacka i Zabbixa z właściwą rolą.
3. **Weryfikacja zgodności środowiska z kodem** (deploy.sh, verify.sh).

**Materiały:** ADR-017, ADR-021, ADR-023, ADR-026, ADR-028–030,
docs/runbook-odtwarzanie.md.

---

## 4. Projekt systemu (10–12 stron)

### 4.1 Architektura ogólna
Diagram: Lenovo (Proxmox: dc1, svc01, szablon), Synology (NFS: dyski,
kopie vzdump, repozytoria restic), stacja administratora, GitHub.
Przydział zasobów. **Materiały:** ADR-001–004, ADR-015, ADR-018.

### 4.2 Warstwa infrastruktury jako kod
Podział Terraform (maszyny) i Ansible (konfiguracja), struktura
repozytorium, moduł vm, role, sejf, konta z minimalnymi uprawnieniami.
**Materiały:** ADR-005–010, ADR-013–014, ADR-016, ADR-031.

### 4.3 Tożsamość, DNS i PKI
Domena ad.homelab.internal, strefa homelab.internal, struktura OU
i RBAC, konto svc-ldap-bind, step-ca (ACME dla usług, CSR dla dc1),
łańcuch zaufania. **Materiały:** ADR-012, ADR-015, ADR-017, ADR-019.

### 4.4 Warstwa usług
Traefik jako jedyny punkt wejścia, sieci Dockera (proxy, internal),
Gitea, BookStack, Zabbix, przypinanie obrazów.
**Materiały:** ADR-020–026.

### 4.5 Narzędzia i technologie (zajęcia 9)
Min. 1 strona, w tym ¾ strony tekstu; dla każdego: do czego użyte
i dlaczego. Proxmox VE, Debian 13 i cloud-init, Terraform (bpg/proxmox),
Ansible (Vault, ansible-lint, community.zabbix), Samba AD, step-ca,
Docker i Compose, Traefik, Gitea, BookStack, Zabbix, PostgreSQL
i MariaDB, restic, Synology (NFS), Git i GitHub, WSL2, menedżer haseł.

### 4.6 Projekt kopii zapasowych i odtwarzania
Dwie warstwy, kopia na zimno, harmonogram i nadrabianie, retencja,
szyfrowanie, rola backup_restore. **Materiały:** ADR-027, ADR-029.

---

## 5. Implementacja (14–18 stron)

Opis etapów z wybranymi listingami (pełna lista w załączniku).
Akcent na problemy i ich rozwiązania, nie na kolejne polecenia.

| Podrozdział | Etapy | Listingi | Dziennik |
|---|---|---|---|
| 5.1 Platforma i stacja administratora | 1–2 | 5.1– | etap-01, etap-02 |
| 5.2 Szablon i moduł maszyn | 3–4 | | etap-03, etap-04 |
| 5.3 Kontroler domeny | 5 | | etap-05 |
| 5.4 Urząd certyfikacji, Traefik, Gitea | 6 | | etap-06 |
| 5.5 BookStack | 7 | | etap-07 |
| 5.6 Monitoring | 8 | 5.119–5.133 | etap-08 |
| 5.7 Kopie zapasowe | 9 | 5.134–5.143 | etap-09 |
| 5.8 Wdrożenie jednym poleceniem | 10 | 5.144–5.148, 5.156–5.158 | etap-10 |

Zakresy listingów dla etapów 1–7 do uzupełnienia z docs/listingi.md.
Wybór do tekstu: ok. 25–30 listingów; reszta w załączniku.

---

## 6. Testy i ewaluacja (10–12 stron)

### 6.1 Metodyka
Testy akceptacyjne (verify.sh), definicje pomiarów RTO i RPO,
znaczniki danych, scenariusze. **Materiały:** ADR-030.

### 6.2 Zgodność i idempotentność
Zbieżność site.yml i deploy.sh. **Listingi:** 5.144, 5.148, 5.155.

### 6.3 Kopie i odtworzenie pojedynczej usługi
Czas, rozmiar, przerwa w działaniu, odtworzenie BookStacka.
**Listingi:** 5.135–5.138.

### 6.4 Awaria maszyny svc01: scenariusze A i B
Tabele czasów, wykres udziału faz, znaczniki danych.
**Listingi:** 5.149, 5.152–5.154. **Materiały:** docs/wyniki-testow.md.

### 6.5 Monitoring: wykrycie awarii
Test agenta dc1. **Listing:** 5.128.

### 6.6 Incydenty wykryte podczas testów
INC-01–INC-04 w skrócie (przyczyna, skutek, działanie).
**Materiały:** docs/incydenty.md, listingi 5.145–5.147, 5.150–5.151.

### 6.7 Porównanie metod odtwarzania i wnioski
Tabela porównawcza, interpretacja RTO i RPO, zależność od internetu.

---

## 7. Podsumowanie (3–4 strony)

### 7.1 Realizacja celów
Odniesienie do celu z 1.2 i wymagań z rozdz. 3 (tabela wymaganie →
realizacja → dowód).

### 7.2 Ograniczenia
Pojedynczy kontroler domeny; brak stacji Windows i GPO (ADR-015);
monitoring na tym samym sprzęcie co usługi; brak kopii poza siedzibą;
brak segmentacji VLAN; nieprzetestowane odtworzenie Samby AD;
zależność odtwarzania z kodu od internetu.

### 7.3 Kierunki rozwoju
Stacja Windows z GPO (dystrybucja certyfikatu, zasady haseł); drugi
kontroler domeny; monitoring świeżości kopii i powiadomienia;
niezależny monitoring na Raspberry Pi 5; kopia poza siedzibą; obrazy
wypiekane Packerem; lokalne lustro pakietów i obrazów; segmentacja
sieci; portal samoobsługowy.

---

## Bibliografia
Dokumentacja oficjalna (Proxmox VE, Samba, Terraform, Ansible, step-ca,
Traefik, Gitea, BookStack, Zabbix, restic, Docker), standardy (RFC dla
LDAP, TLS, ACME; ICANN dla .internal), źródło o licencjonowaniu VMware,
literatura o infrastrukturze jako kod i ciągłości działania.

## Załączniki
A. Lista decyzji architektonicznych (ADR-001–031, skrót)
B. Procedura odtwarzania (docs/runbook-odtwarzanie.md)
C. Rejestr incydentów (docs/incydenty.md)
D. Wybrane pełne listingi
E. Struktura repozytorium i instrukcja uruchomienia

---

## Kolejność pisania

| Kolejność | Rozdział | Uzasadnienie |
|---|---|---|
| 1 | 6. Testy | gotowe dane: wyniki-testow.md, incydenty.md |
| 2 | 5. Implementacja | gotowe dzienniki i listingi |
| 3 | 4. Projekt | gotowe ADR-y |
| 4 | 3. Wymagania | wynikają z tego, co zbudowano |
| 5 | 2. Analiza | wymaga źródeł i bibliografii |
| 6 | 7. Podsumowanie, 1. Wstęp, streszczenie | na końcu |

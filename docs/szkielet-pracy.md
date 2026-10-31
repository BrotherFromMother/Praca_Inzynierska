# Szkielet pracy inżynierskiej, wersja 2

**Temat:** Projekt i implementacja środowiska korporacyjnego opartego
na konteneryzacji usług

**Profil:** praca projektowo-wdrożeniowa z zakresu systemów
informacyjnych i sieci komputerowych (infrastruktura, nie aplikacja).

**Objętość orientacyjna:** 55–70 stron bez załączników.

## Wymagania redakcyjne wydziału (skrót)

| Element | Ustawienie |
|---|---|
| Tekst | Times New Roman 12 pkt, wyjustowany, interlinia 1,5, odstęp przed 6 pt, wcięcie pierwszego wiersza 1 cm |
| Marginesy | 2,5 cm z każdej strony |
| Nagłówek strony | tytuł pracy, podkreślony (poza stroną tytułową i kartą dyplomową) |
| Rozdział | TNR 16 pkt, pogrubiona, wersaliki, wysunięcie 0,75 cm, przed i po 12 pt |
| Podrozdział | TNR 14 pkt, pogrubiona, wersaliki, wysunięcie 1,25 cm, przed i po 12 pt |
| Podrozdział 2. rzędu | TNR 12 pkt, pogrubiona, wysunięcie 1,25 cm, przed i po 6 pt |
| Tabela | wyrównanie do lewej, podpis nad tabelą |
| Rysunek | wyśrodkowany, podpis pod rysunkiem, ze źródłem (lub „opracowanie własne”) |
| Numeracja | dwustopniowa x.y w obrębie rozdziału |
| Cytowanie | system vancouverski, numery w nawiasach kwadratowych [1] |

## Kolejność stron

1. Strona tytułowa
2. Skan karty dyplomowej
3. Abstract (1 strona, EN)
4. Streszczenie (1 strona, PL)
5. Spis treści
6. Wykaz skrótów
7. Cel i zakres pracy
8. Wstęp
9. Rozdziały 1–6
10. Spis literatury
11. Załączniki

## Powiązanie z zadaniami z zajęć przygotowujących

| Zajęcia | Zadanie | Miejsce w pracy |
|---|---|---|
| 2 | tematyka, cel i zakres | Cel i zakres pracy |
| 3 | promotor i temat | strona tytułowa |
| 4 | cztery zagadnienia z komentarzem | 1.1 |
| 5 | analiza wybranego zagadnienia (min. 1 strona) | 1.2 |
| 6 | analiza min. czterech podobnych rozwiązań (min. 4 strony) | 1.3 |
| 7 | wymagania funkcjonalne (zakres funkcjonalności) | 2.1 |
| 8 | trzy aspekty rozwiązania problemu (min. 1,5 strony) | 2.2 |
| 9 | narzędzia i technologie z uzasadnieniem (min. 1 strona) | 2.4 |

---

## Abstract / Streszczenie (po 1 stronie)
Pisane na końcu. Słowa kluczowe: infrastruktura jako kod, Active
Directory, konteneryzacja, kopie zapasowe, odtwarzanie po awarii.

## Wykaz skrótów
ACME, AD, ADR, API, CA, CSR, DNS, GPO, HTTPS, IaC, JIT, LDAP, LDAPS,
LTS, NAS, NFS, OU, PKI, RBAC, RPO, RTO, SSH, TLS, TOTP, VM, WAL i inne
używane w tekście.

## Cel i zakres pracy (1–1,5 strony)
**Cel:** zaprojektowanie i wdrożenie środowiska usług firmowych
z centralnym zarządzaniem tożsamością, w pełni opisanego kodem,
z kopiami zapasowymi i zweryfikowaną procedurą odtwarzania po awarii.

**Zakres:** wirtualizacja (Proxmox VE), infrastruktura jako kod
(Terraform, Ansible), Samba AD z LDAPS, własny urząd certyfikacji,
usługi w kontenerach (Gitea, BookStack, Zabbix) za Traefikiem, kopie
w dwóch warstwach, testy odtworzenia z pomiarem RTO i RPO.

**Poza zakresem:** stacje Windows i GPO, segmentacja VLAN, portal
samoobsługowy, kopia poza siedzibą (uzasadnienie w rozdz. 6).

**Materiały:** ADR-011, zadanie z zajęć 2.

## Wstęp (2–3 strony)
Motywacja: potrzeby małych i średnich organizacji, ręcznie
konfigurowane środowiska trudne do odtworzenia, zmiany licencjonowania
VMware (źródło: TODO z ADR-001). Krótki opis układu pracy.

---

## 1. Przegląd literatury i istniejących rozwiązań (12–15 stron)

### 1.1 Kluczowe zagadnienia (zajęcia 4)
1. Zarządzanie tożsamością i dostępem (katalog, grupy, RBAC).
2. Powtarzalność wdrożeń (infrastruktura jako kod).
3. Bezpieczna komunikacja wewnętrzna (PKI, TLS, ACME).
4. Ciągłość działania (kopie zapasowe, odtwarzanie).

### 1.2 Ciągłość działania: analiza zagadnienia (zajęcia 5)
RTO, RPO, reguła 3-2-1, kopie maszyn a kopie danych aplikacji,
spójność kopii, znaczenie testów odtworzenia.

### 1.3 Przegląd podobnych rozwiązań (zajęcia 6)

| Rozwiązanie | Do opisu |
|---|---|
| Windows Server (AD DS, AD CS) i Microsoft 365 / Entra ID | standard rynkowy, licencje, zależność od dostawcy |
| Univention Corporate Server | katalog zgodny z AD, katalog aplikacji |
| NethServer 8 | platforma oparta na kontenerach |
| Zentyal Server | linuksowy zamiennik Windows Server dla MŚP |
| (opcjonalnie) FreeIPA | katalog i PKI w świecie Linuksa |

### 1.4 Porównanie i wnioski z przeglądu
Tabela (koszt, zgodność z AD, automatyzacja kodem, kopie i odtwarzanie,
konteneryzacja, kontrola nad danymi); uzasadnienie własnego rozwiązania.

---

## 2. Założenia projektowe i metodyka realizacji (6–8 stron)

### 2.1 Wymagania funkcjonalne i niefunkcjonalne (zajęcia 7)
Tabela wymagań, np.:
WF-01 logowanie do usług kontem domenowym; WF-02 uprawnienia z grup AD;
WF-03 HTTPS z certyfikatami zaufanego urzędu; WF-04 wdrożenie
i weryfikacja jednym poleceniem; WF-05 codzienne spójne kopie;
WF-06 odtworzenie pojedynczej usługi; WF-07 odtworzenie maszyny;
WF-08 monitorowanie z wykrywaniem awarii; WF-09 rotacja kluczy.
Niefunkcjonalne: bezpieczeństwo sekretów, minimalne uprawnienia,
zbieżność i idempotentność, mierzalne RTO i RPO, oprogramowanie
otwarte, ograniczenia sprzętowe.
Zamiast diagramu przypadków użycia: diagram kontekstowy (użytkownicy,
administrator, usługi, systemy zewnętrzne).

### 2.2 Kluczowe aspekty rozwiązania (zajęcia 8, min. 1,5 strony)
1. **Jedno konto pracownika i uprawnienia z grup AD** we wszystkich
   usługach (LDAPS, mapowanie grup na role).
2. **Środowisko odtwarzalne z kodu** (Terraform, Ansible, sejf,
   jedno polecenie).
3. **Zweryfikowana ciągłość działania** (dwie warstwy kopii, testy
   z pomiarem RTO i RPO).

### 2.3 Metodyka realizacji
Podział na etapy z kryteriami ukończenia; dokumentowanie decyzji
(ADR) i przebiegu (dzienniki); wersjonowanie w Git; kontrola jakości
kodu (ansible-lint, terraform validate); testy akceptacyjne
i scenariusze awarii; analizy poincydentalne.

### 2.4 Narzędzia i technologie (zajęcia 9, min. 1 strona)
Dla każdego: zastosowanie i uzasadnienie. Proxmox VE, Debian 13
i cloud-init, Terraform (bpg/proxmox), Ansible (Vault, ansible-lint,
community.zabbix), Samba AD, step-ca, Docker i Compose, Traefik, Gitea,
BookStack, Zabbix, PostgreSQL, MariaDB, restic, Synology (NFS), Git
i GitHub, WSL2, menedżer haseł.

**Materiały:** ADR-005–010, ADR-013–031 (uzasadnienia wyborów).

---

## 3. Projekt środowiska (10–12 stron)

3.1 Architektura ogólna i przydział zasobów (ADR-001–004, 015, 018)
3.2 Infrastruktura jako kod: Terraform, Ansible, repozytorium, sekrety
    (ADR-005–010, 013–014, 016, 031)
3.3 Tożsamość, DNS i PKI (ADR-012, 015, 017, 019)
3.4 Warstwa usług: Traefik, sieci Dockera, Gitea, BookStack, Zabbix
    (ADR-020–026)
3.5 Kopie zapasowe i odtwarzanie (ADR-027, 029)

---

## 4. Implementacja (14–18 stron)

Etapy z krótkimi fragmentami kodu i wyników; pełne listingi
w załączniku D. Akcent na problemy i decyzje.

| Podrozdział | Etapy | Dziennik |
|---|---|---|
| 4.1 Platforma i stacja administratora | 1–2 | etap-01, etap-02 |
| 4.2 Szablon i moduł maszyn | 3–4 | etap-03, etap-04 |
| 4.3 Kontroler domeny | 5 | etap-05 |
| 4.4 Urząd certyfikacji, Traefik, Gitea | 6 | etap-06 |
| 4.5 BookStack | 7 | etap-07 |
| 4.6 Monitoring | 8 | etap-08 |
| 4.7 Kopie zapasowe | 9 | etap-09 |
| 4.8 Wdrożenie jednym poleceniem | 10 | etap-10 |

---

## 5. Testy i analiza wyników (10–12 stron)

5.1 Metodyka testów i pomiarów (ADR-030)
5.2 Zgodność środowiska z kodem
5.3 Kopie i odtworzenie pojedynczej usługi
5.4 Awaria maszyny svc01: scenariusze A i B
5.5 Wykrywanie awarii przez monitoring
5.6 Incydenty wykryte podczas testów (INC-01–INC-04)
5.7 Porównanie metod odtwarzania

**Materiały:** docs/wyniki-testow.md, docs/incydenty.md, dziennik
etapu 11.

---

## 6. Podsumowanie i wnioski (3–4 strony)

6.1 Realizacja celu i wymagań (tabela: wymaganie → realizacja → dowód)
6.2 Wnioski szczegółowe (z testów i incydentów)
6.3 Wnioski uogólnione
6.4 Ograniczenia: pojedynczy kontroler domeny; brak stacji Windows
    i GPO; monitoring na tym samym sprzęcie co usługi; brak kopii poza
    siedzibą; brak segmentacji VLAN; nieprzetestowane odtworzenie Samby;
    zależność odtwarzania z kodu od internetu
6.5 Kierunki rozwoju

---

## Spis literatury
System vancouverski, numeracja w kolejności pierwszego cytowania.

## Załączniki
A. Decyzje architektoniczne (ADR-001–031, skrót)
B. Procedura odtwarzania
C. Rejestr incydentów
D. Listingi kodu i wyników
E. Struktura repozytorium i instrukcja uruchomienia

---

## Kolejność pisania

| Kolejność | Część | Uzasadnienie |
|---|---|---|
| 1 | 5. Testy i analiza wyników | gotowe dane |
| 2 | 4. Implementacja | gotowe dzienniki i listingi |
| 3 | 3. Projekt | gotowe ADR-y |
| 4 | 2. Założenia i metodyka | wynikają ze zbudowanego rozwiązania |
| 5 | 1. Przegląd | wymaga źródeł |
| 6 | 6. Podsumowanie, cel i zakres, wstęp, streszczenia, wykaz skrótów | na końcu |

Uwaga: listingi w dokumentacji mają numery 5.x z etapu prac; przy
redakcji zostaną przenumerowane według rozdziałów pracy (4.x, 5.x)
oraz załącznika D.

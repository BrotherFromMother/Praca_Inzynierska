# Dziennik: etap 5 (kontroler domeny dc1, Samba AD)

**Daty:** 2026-10-21 – 2026-10-22

## Wykonane prace
- Decyzja: Samba AD w osobnej maszynie wirtualnej, bez kontenera
  i bez Windows Server (ADR-015).
- Refaktoryzacja modułu Terraform: zmiana nazwy portal-vm na vm,
  obsługa pełnego klonu, autostartu, maszyn bez puli, opisów i etykiet;
  walidacja zależna od dwóch zmiennych (pełny klon wymaga magazynu,
  klon połączony nie może go mieć).
- Maszyna dc1 (VMID 100, 192.168.1.40) jako pełny klon na local-lvm,
  w konfiguracji platform.
- Ansible Vault: hasła administratora, konta usługowego i użytkowników
  testowych w zaszyfrowanym pliku (ADR-016).
- Rola samba_dc: /etc/hosts i szablon cloud-init, stały resolv.conf,
  wyłączenie systemd-resolved, instalacja Samby, utworzenie domeny
  ad.homelab.internal, konfiguracja Kerberos.
- Struktura katalogu: OU, grupy RBAC, konto usługowe svc-ldap-bind,
  użytkownicy jan.kowalski i anna.nowak, wyłączone wygasanie haseł
  kont technicznych (ADR-017).
- Strefa DNS homelab.internal z rekordami usług na svc01.

## Napotkane problemy

| Problem | Przyczyna | Rozwiązanie |
|---|---|---|
| Nazwa hosta wskazywała 127.0.1.1 | cloud-init generuje /etc/hosts z adresem pętli zwrotnej i odtwarza go przy starcie | podmiana szablonu cloud-init (/etc/cloud/templates/hosts.debian.tmpl) |
| Port 53 zajęty | systemd-resolved nasłuchuje na 127.0.0.53 i 127.0.0.54 | stały resolv.conf zapisany przed zamaskowaniem systemd-resolved |
| ansible-lint: var-naming[no-role-prefix] | zmienne z przedrostkiem samba_ zamiast pełnej nazwy roli samba_dc_ | zmiana nazw poleceniem sed z wyrażeniem regularnym |
| Brak szablonu hosts.j2 | literówka w nazwie pliku (host.j2) | zmiana nazwy pliku |
| Brak znaku nowej linii w dc.yml | ustawienia edytora | opcja Insert Final Newline w ustawieniach WSL w VS Code |
| Ostrzeżenie o wygaśnięciu hasła za 41 dni | domyślna polityka haseł Samby (42 dni) | samba-tool user setexpiry --noexpiry dla kont technicznych, sprawdzane flagą 65536 w userAccountControl |
| samba --version: command not found | program w /usr/sbin, poza ścieżką zwykłego użytkownika | sudo samba --version (niepotrzebne w roli) |
| Puste wyniki tail -1 | samba-tool kończy wynik pustą linią | grep zamiast tail |
| ldapsearch: Invalid credentials (52e) | hasło wprowadzane ręcznie różniło się od zapisanego w sejfie (niewidoczne znaki przy wklejaniu) | diagnoza przez zawężanie: LDAP odrzucony, LDAPS osiągalny, kinit poprawny, UPN obecny; hasło z pliku (ldapsearch -y) zadziałało |

## Pomiary

| Operacja | Czas |
|---|---|
| Pełny klon dc1 na local-lvm | 1 min 29 s (klon połączony: 4–13 s) |
| Rola base na dc1 (z aktualizacjami) | 1 min 31 s |
| Role base i samba_dc, utworzenie domeny | 2 min 9 s |
| Ponowne wykonanie roli samba_dc | changed=0 |

## Wnioski
- Rozpoznanie stanu maszyny przed napisaniem roli pozwoliło uniknąć
  błędów wynikających z założeń o obrazie chmurowym.
- Narzędzia nieidempotentne (samba-tool) można bezpiecznie używać
  w Ansible, stosując wzorzec odczytu stanu przed zmianą lub kod
  wyjścia polecenia sprawdzającego.
- Kody błędów AD (np. 52e) i testy innymi protokołami (Kerberos)
  pozwalają szybko zawęzić przyczynę problemu z uwierzytelnianiem.

## Otwarte kwestie
- Certyfikat LDAPS kontrolera jest samopodpisany; zaufany certyfikat
  po wdrożeniu step-ca (etap 6).
- Kontroler domeny jako pojedynczy punkt awarii; DC2 jako kierunek
  rozwoju.
- Zarządzanie zasadami grupy (GPO) wymaga stacji z Windows i RSAT
  (poza zakresem MVP).

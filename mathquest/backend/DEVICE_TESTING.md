# Testare l'app sul telefono fisico

Se le lezioni non si caricano sull'iPhone ("request timed out") e da Safari sul telefono non si apre `http://IP_MAC:8080/api/lessons`, il telefono non raggiunge il backend. Ecco cosa fare, in ordine.

## 1. Firewall (test veloce)

- **Mac**: Preferenze di sistema → Sicurezza e privacy → Firewall.
- Disattiva temporaneamente il firewall e riprova da Safari sull'iPhone: `http://IP_DELLA_MAC:8080/api/lessons`.
- Se si apre → il problema era il firewall. Riattivalo e aggiungi una regola che consente connessioni in entrata sulla porta 8080 per il processo del server.

## 2. Hotspot del telefono (soluzione che funziona quasi sempre)

- Sul **iPhone**: Impostazioni → Hotspot personale → attivalo.
- Sulla **Mac**: connettiti al Wi‑Fi dell'hotspot (stesso iPhone).
- Sulla Mac in Terminale: `ifconfig | grep "inet " | grep -v 127.0.0.1` e prendi l'IP (es. `172.20.10.x`).
- Aggiorna l'app con questo IP:
  - **iOS**: `mathquest/iOS/Core/Network/APIConfig.swift` e `Info.plist` (chiave `APIBaseURL`).
  - **Android**: `mathquest/android/lib/core/network/api_config.dart`.
- Riavvia il backend (se serve), ricompila l'app e prova. Mac e telefono sono sulla stessa “rete” (l’iPhone è il router), quindi la connessione funziona.

## 3. Stessa rete Wi‑Fi “normale”

- Collega **Mac e iPhone** allo stesso Wi‑Fi di casa (stesso SSID).
- Sulla Mac: `ifconfig` → prendi l’IP (es. `192.168.1.x`).
- Metti questo IP nell’app (come sopra) e assicurati che il firewall non blocchi la porta 8080.

## Verifica backend

Sulla Mac, con il backend avviato:

```bash
curl -s -w "\nHTTP: %{http_code}\n" http://localhost:8080/api/lessons -H "Authorization: Bearer mock-dev-token"
```

Deve restituire JSON e `HTTP: 200`.

# ClaudeBar

<p align="center">
  <img src="../assets/icons/claudebar-macOS-Dark-1024x1024@1x.png" alt="Icona ClaudeBar" width="128" height="128">
</p>

<p align="center">
  <strong>Un'applicazione nativa della barra dei menu di macOS per monitorare i limiti di utilizzo di Claude in tempo reale.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="Licenza">
</p>

<p align="center">
  <a href="../README.md">English</a> •
  <a href="README-TR.md">Türkçe</a> •
  <a href="README-ZH.md">中文</a> •
  <a href="README-HI.md">हिन्दी</a> •
  <a href="README-ES.md">Español</a> •
  <a href="README-FR.md">Français</a> •
  <a href="README-AR.md">العربية</a> •
  <a href="README-PT.md">Português</a> •
  <a href="README-JA.md">日本語</a> •
  <a href="README-RU.md">Русский</a> •
  <a href="README-IT.md">Italiano</a>
</p>

> **Nota:** Questa traduzione è stata generata dall'IA e potrebbe contenere errori o imprecisioni. Invia una Pull Request per le correzioni.

---

## Funzionalità

- **Monitoraggio Utilizzo in Tempo Reale** - Visualizza i limiti della sessione corrente e settimanali a colpo d'occhio
- **Badge del Piano** - Mostra il tuo abbonamento attuale (Pro, Max, Team)
- **Supporto Utilizzo Extra** - Traccia i crediti pay-as-you-go quando abilitato
- **Barre di avanzamento colorate** - Verde, giallo, arancione, rosso in base alla percentuale di utilizzo
- **Supporto multilingua** - Inglese, turco, cinese, spagnolo, russo con selettore lingua nell'app
- **Notifiche Personalizzabili** - Ricevi notifiche al 50%, 75%, 100% o al ripristino
- **Aggiornamento Automatico** - Intervallo di aggiornamento configurabile (30s, 1m, 2m, 5m)
- **Avvio al Login** - Avvia opzionalmente con il tuo Mac
- **Percentuale nella Barra dei Menu** - Mostra/nascondi la percentuale accanto all'icona
- **Esperienza Nativa** - Costruito con SwiftUI, segue le linee guida di design macOS
- **Leggero** - Utilizzo minimo delle risorse, nessun Electron
- **Incentrato sulla Privacy** - Nessuna analisi, nessuna telemetria

## Screenshot

<p align="center">
  <img src="../screenshots/app-screenshot.png" alt="Vista Generale di ClaudeBar" width="380">
</p>

<p align="center">
  <em>Monitoraggio utilizzo in tempo reale con badge del piano</em>
</p>

<details>
<summary><strong>Altri Screenshot</strong></summary>

<br>

| Impostazioni | Notifiche | Informazioni |
|:------------:|:---------:|:------------:|
| <img src="../screenshots/settings-screenshot.png" alt="Impostazioni" width="250"> | <img src="../screenshots/notifications-screenshot.png" alt="Notifiche" width="250"> | <img src="../screenshots/about-screenshot.png" alt="Informazioni" width="250"> |

</details>

## Requisiti

- macOS 14.0 (Sonoma) o successivo
- [Claude Code](https://claude.ai/code) installato e con accesso effettuato
- Abbonamento attivo Claude Pro, Max o Team

## Installazione

### Scarica il Binario Pre-compilato

Scarica l'ultimo `.app` dalla pagina [Releases](https://github.com/kemalasliyuksek/claudebar/releases), poi trascinalo nella cartella Applicazioni.

> **Nota:** Se macOS mostra "ClaudeBar è danneggiato e non può essere aperto", esegui il seguente comando per rimuovere il flag di quarantena:
> ```bash
> xattr -cr ClaudeBar.app
> ```

### Compila dal Codice Sorgente

```bash
git clone https://github.com/kemalasliyuksek/claudebar.git
cd claudebar
./build.sh
```

Il bundle dell'applicazione verrà creato in `.build/release/ClaudeBar.app`.

Per installare:
```bash
cp -r .build/release/ClaudeBar.app /Applications/
```

## Utilizzo

1. Assicurati di aver effettuato l'accesso a Claude Code (il comando `claude` deve funzionare nel terminale)
2. Avvia ClaudeBar da Applicazioni o Spotlight
3. Clicca sull'icona del misuratore nella barra dei menu per visualizzare i limiti di utilizzo

### Impostazioni

Clicca sull'icona ⚙️ per configurare:

| Impostazione | Descrizione |
|-------------|-------------|
| Avvio al login | Avvio automatico all'accesso |
| Mostra % nella barra dei menu | Visualizza la percentuale accanto all'icona della barra dei menu |
| Lingua | Scegli la lingua dell'app (Sistema, English, Türkçe, 中文, Español, Русский) |
| Intervallo di aggiornamento | Frequenza di recupero dei dati di utilizzo (30s - 5m) |
| Notifica al 50% | Invia notifica al 50% di utilizzo |
| Notifica al 75% | Invia notifica al 75% di utilizzo |
| Notifica al raggiungimento del limite | Invia notifica quando il limite viene raggiunto |
| Notifica al ripristino | Invia notifica quando il limite viene ripristinato |

### Informazioni

Clicca sull'icona ⓘ per visualizzare informazioni sull'app, crediti e link.

## Come Funziona

ClaudeBar legge le credenziali OAuth dal Portachiavi macOS che Claude Code memorizza quando effettui l'accesso. Quindi interroga l'API di Anthropic per ottenere i tuoi limiti di utilizzo attuali.

### Architettura

```
┌─────────────────┐                      ┌───────────────────────────┐
│                 │  Memorizza token     │                           │
│   Claude Code   │─────────────────────▶│    Portachiavi macOS      │
│   (CLI login)   │                      │ "Claude Code-credentials" │
└─────────────────┘                      └───────────────────────────┘
                                                     │
                                                     │ Legge i token
                                                     ▼
┌─────────────────┐                      ┌───────────────────────────┐
│                 │ GET /api/oauth/usage │                           │
│  Anthropic API  │◀─────────────────────│        ClaudeBar          │
│                 │─────────────────────▶│                           │
└─────────────────┘  Dati di utilizzo    └───────────────────────────┘
```

## Note Importanti

### Accesso al Portachiavi

Al primo avvio, macOS potrebbe chiederti di consentire a ClaudeBar l'accesso al Portachiavi. Clicca su **Consenti Sempre** per un funzionamento senza interruzioni.

### Privacy

- Legge solo le credenziali esistenti dal Portachiavi
- Tutte le comunicazioni utilizzano HTTPS
- Nessun dato memorizzato al di fuori del Portachiavi di sistema
- Nessuna analisi o telemetria
- Completamente open source

## Contribuire

I contributi sono benvenuti! Non esitare a inviare una Pull Request.

1. Fai il fork del repository
2. Crea il tuo branch di funzionalità (`git checkout -b feature/funzionalità-fantastica`)
3. Effettua il commit delle modifiche (`git commit -m 'Aggiungere funzionalità fantastica'`)
4. Effettua il push al branch (`git push origin feature/funzionalità-fantastica`)
5. Apri una Pull Request

## Licenza

Questo progetto è concesso in licenza con la Licenza MIT - consulta il file [LICENSE](../LICENSE) per i dettagli.

## Autore

**Kemal Aslıyüksek** - [@kemalasliyuksek](https://github.com/kemalasliyuksek)

## Avvertenza

Questo è un progetto comunitario non ufficiale e non è affiliato, ufficialmente mantenuto o approvato da Anthropic. Usalo a tua discrezione.

# 📷 Importa Foto

**Importa Foto** è una semplice app per Windows pensata per il nonno — collega la fotocamera via USB e importa tutte le foto e video nuovi con un solo click, senza duplicati.

![Screenshot dell'app](docs/screenshot-main.png)

---

## ✨ Funzionalità

- **Rilevamento automatico** della fotocamera — nessun percorso da inserire
- **Nessun duplicato** — confronta i file già presenti e salta quelli copiati in precedenza
- **Cartella di destinazione personalizzabile** dal pannello impostazioni
- **Ricorda le impostazioni** tra un avvio e l'altro
- **Interfaccia semplice e pulita** in stile Windows 11

---

## 📸 Screenshot

| Importazione in corso | Pannello impostazioni |
|:---:|:---:|
| ![Progresso](docs/screenshot-progress.png) | ![Impostazioni](docs/screenshot-settings.png) |

---

## 🚀 Installazione

### 1. Installer Standard (Consigliato)
Scarica ed esegui il file eseguibile per un'installazione guidata:

👉 **[Scarica ImportaFoto-setup.exe](https://raw.githubusercontent.com/Flavio-coding/importa-foto/main/ImportaFoto-setup.exe)**

> [!IMPORTANT]
> **Nota sulla sicurezza:** Essendo un software di uno sviluppatore indipendente, Windows SmartScreen potrebbe mostrare un avviso.
> Per procedere: clicca su **"Ulteriori informazioni"** e poi su **"Esegui comunque"**.

---

### 2. Installazione alternativa via PowerShell
Apri **PowerShell** come amministratore e incolla questo comando, poi premi invio:

```powershell
irm https://raw.githubusercontent.com/Flavio-coding/importa-foto/main/installer.ps1 | iex
```

---

## 🗑️ Disinstallazione

Apri **PowerShell** come amministratore e incolla questo comando, poi premi invio:

```powershell
irm https://raw.githubusercontent.com/Flavio-coding/importa-foto/main/uninstaller.ps1 | iex
```
---

## 📖 Come si usa

1. Collega la fotocamera al PC via USB
2. Apri **Importa Foto** dal menu Start o dal Desktop
3. Attendi il conteggio delle foto nuove
4. Premi **Importa**
5. Al termine puoi chiudere la finestra

> Per cambiare la cartella di destinazione, clicca l'icona ⚙️ in alto a sinistra.

---

## ⚙️ Come funziona

Quando apri Importa Foto, l'app cerca automaticamente tra i dischi rimovibili collegati al PC una cartella `DCIM` — quella che tutte le fotocamere usano per salvare le foto. Se la trova, conta quante foto non sono ancora state copiate nella cartella di destinazione. Se non la trova, riprova ogni 2 secondi per un minuto.

Una volta premuto **Importa**, l'app copia i file uno per uno confrontando nome e dimensione: se un file con lo stesso nome esiste già nella destinazione e ha la stessa dimensione, viene saltato. Se ha dimensione diversa — per esempio una foto modificata — viene copiato con un nome leggermente diverso per non sovrascrivere nulla.

Il pannello **⚙️ Impostazioni**, accessibile dall'icona in alto a sinistra, permette di scegliere la cartella dove salvare le foto. La scelta viene ricordata automaticamente anche dopo aver chiuso e riaperto l'app. 

---

## 🖥️ Prossimamente su questi schermi
-  Query di ricerca personalizzate nelle impostazioni
-  Codice sorgente pubblico
-  Tutorial dell'app al primo avvio
-  Installer e uninstaller grafici

# 💻 CPU a 16-bit basata su Macchina a Stati Finiti (FSM)

## 📌 1. Panoramica del Progetto

Questo progetto implementa un'unità di elaborazione centrale (**CPU**) custom a **16 bit** interamente descritta in **VHDL**, destinata all'implementazione su FPGA (tramite Vivado). L'architettura utilizza una **Macchina a Stati Finiti (FSM)** per controllare il ciclo di Fetch-Execute, permettendo l'esecuzione di istruzioni in **più cicli di clock** (architettura multiciclo).

---

## 🏗️ 2. Architettura della CPU

### 2.1 Set di Istruzioni (Instruction Set Architecture - ISA)

* **Larghezza Istruzione:** 16 bit.
* **Formato Base:** `[Unused/Reg2] [Reg1] [Opcode]` (16 bit)
    * **Opcode (bit 0-3):** Definisce l'operazione (es. `LOAD`, `ADD`).
    * **Reg1 (bit 4-7):** Solitamente il registro a cui si riferisce l'operazione specificata (es. `LOAD`, `ADD`).
    * **Reg2 (bit 8-11):** Usato solitamente come registro di **Destinazione** di una `MOVE` o`ADDR`. Ignorato per operazioni immediate.

| Opcode (Binario) | Hex | Nome | Funzione |
| :---: | :---: | :---: | :--- |
| `0001` | 1 | **STORE** | Salva il contenuto di un Registro in Memoria. |
| `0010` | 2 | **LOAD** | Carica un Valore Immediato in un Registro. |
| `0011` | 3 | **LOADM** | Carica un valore da Memoria in un Registro (Indiretto). |
| `0100` | 4 | **ADD** | Somma un Valore Immediato a un Registro. |
| `0101` | 5 | **SUB** | Sottrae un Valore Immediato da un Registro. |
| `0110` | 6 | **JUMPZ** | Salta a LABEL se il Flag Z (Zero) è alto. |
| `0111` | 7 | **JUMPNZ**| Salta a LABEL se il Flag NZ (Non-Zero) è alto. |
| `1000` | 8 | **COMPARE** | Compara due Registri e aggiorna i Flag di condizione. |
| `1001` | 9 | **LABEL** | Definisce un punto di salto (salva l'indirizzo PC). |
| `1010` | A | **ADDR** | Somma tra due Registri (`Rx = Rx + Ry`). |
| `1011` | B | **SUBR** | Sottrazione tra due Registri (`Rx = Rx - Ry`). |
| `1100` | C | **MOVE** | Sposta il valore da un Registro a un altro (`Rx = Ry`). |

### 2.2 Register File

Il set di registri è composto da **6 registri generici a 16 bit** (`RX`, `RY`, `RZ`, `RA`, `RB`, `RC`).

| Registro | Identificativo (Binario) | 
| :---: | :---: | 
| **RX** | `0000` | 
| **RY** | `0001` | 
| **RZ** | `0010` |
| **RA** | `0011` | 
| **RB** | `0100` | 
| **RC** | `0101` |

### 2.3 Flag di Condizione

La CPU gestisce quattro flag di condizione che vengono aggiornati dalle istruzioni `COMPARE` e utilizzati dalle istruzioni di salto.

* **Z (Zero):** Settato se il risultato dell'ultima operazione è zero.
* **NZ (Non-Zero):** Settato se il risultato non è zero.
* **N (Negative):** Settato se il risultato è negativo.
* **P (Positive):** Settato se il risultato è positivo.

---

## ⚙️ 3. Macchina a Stati Finiti (FSM) - Logica di Controllo

La FSM è il cuore della CPU, gestendo il flusso di esecuzione delle istruzioni in più cicli.

### 3.1 Stati Principali (Fasi di Esecuzione)

La FSM opera su una logica multiciclo, controllata dai seguenti stati:

| Stato VHDL | Descrizione | Funzione |
| :---: | :--- | :--- |
| `init` | Inizializzazione | Resetta tutti i registri e il Program Counter (PC). |
| `execute` | **Fetch & Decode** | Preleva l'istruzione in `DATA_IN`, decodifica e imposta i flag di controllo. |
| `wait_address` | Gestione Memoria (Fase 1) | Attende l'indirizzo da utilizzare (`STORE` o `LOADM`). |
| `wait_data` | Gestione ALU (Immediato) | Invia l'operando immediato alla ALU (gestendo anche il complemento a uno per la sottrazione). |
| `write_reg` | Write-Back | Scrive il risultato finale (ALU/Memoria/Dato) nel registro di destinazione. |
| `write_mem` | Scrittura Memoria | Ciclo dedicato all'invio del dato sulla bus dati per l'operazione `STORE`. |
| `compare` | Aggiornamento Flag | Ciclo dedicato all'aggiornamento dei flag di condizione. |
| `wait_generic` | Sincronizzazione | Stato di transizione usato per mantenere i segnali di controllo attivi durante i ritardi. |

### 3.2 Persistenza dei Segnali (Il segreto multiciclo)

La chiave per la corretta sequenza di esecuzione in questa architettura è la **persistenza dei segnali di controllo** (`flag_alu`, `flag_sub`, `flag_reg`).

Questi flag sono implementati come registri all'interno dell'FSM e vengono **azzerati solo ed esclusivamente all'inizio dello stato `execute`**. Questo meccanismo assicura che lo stato `write_reg` (che avviene diversi cicli dopo) "ricordi" se deve scrivere un risultato proveniente dalla **ALU** (`ALU_REG`) o un valore letto dalla Memoria (`DATA_IN`).

---

## 📂 4. Struttura dei File

I file principali del progetto sono:

* `FSM.vhd`: Contiene la Macchina a Stati Finiti (FSM) che controlla il flusso i registri si cache e il PC.
* `cpu_defs.vhd`: Package contenente tutte le costanti di Opcode e le definizioni dei Registri (es. `REG_O`, `FLAG_M`).
* `ALU.vhd`
* `blk_mem_gen_0.vhd`: Modulo della RAM per contenere le istruzioni.
* `TOP_CPU.vhd`: Integra FSM, ALU e Memoria.
* `.gitignore`: **Cruciale** per ignorare tutti i file di log, sintesi e simulazione generati da Vivado.

---

## 🛠️ 5. Utilizzo e Test

1.  Clonare la repository:
    ```bash
    git clone [URL]
    ```
2.  Aprire il progetto in **Vivado**.
3.  Simulare il file `TOP_CPU_tb.vhd` per osservare la corretta transizione degli stati.
4.  Sintetizzare per la piattaforma FPGA di destinazione (specificare la board).

---

## 🧐 6. Opcode tipico

0012	OP_LOAD	 Ry Carica un valore immediato nel registro Ry (Memory Data Reg).
00AF	(Dato)	0x00AF	Valore immediato: 175 (dec). Ora Ry = 175.
0011	OP_STORE	Ry	Salva il contenuto di Ry in Memoria.
0650	(Dato)	0x0650	Indirizzo di memoria: MEM[0x0650] <= Ry.
0023	OP_LOADM	Rz	Carica nel registro Rz un valore prelevato dalla memoria.
0650	(Dato)	0x0650	Legge dall'indirizzo 0x0650. Ora Rz = MEM[0x0650] (quindi Rz = 175).
021a	OP_ADDR	 Ry, Rz 	Somma tra registri: Ry <= Ry + Rz. (175 + 175 = 350).
021b	 OP_SUBR	Ry, Rz	Sottrazione tra registri: Ry <= Ry - Rz. (350 - 175 = 175). Ry torna al valore originale.
0014	 OP_ADD Ry	Somma immediata al registro Ry.
0016	(Dato)	0x0016	Valore: 22. Ry <= Ry + 22 (175 + 22 = 197).
0015	 OP_SUB Ry	Sottrazione immediata al registro Ry.
0016	(Dato)	0x0016	Valore: 22. Ry <= Ry - 22 (197 - 22 = 175).
0218	 OP_COMPARE Ry, Rz Compara Ry con Rz. (175 vs 175). Setta il FLAG Z (Zero) a 1 perché sono uguali.
0024	OP_ADD	Rz	Somma immediata al registro Rz.
0001	(Dato)	0x0001	Incrementa Rz di 1. Ora Rz = 176.
0218	 OP_COMPARE Ry, Rz Compara Ry (175) con Rz (176). Setta FLAG NZ (Non Zero) e probabilmente FLAG N (Negative).
0002 OP_LOAD Rx	Carica un valore immediato nel registro Rx (Counter/Offset Reg).
00B0	(Dato)	0x00B0	Valore: 176. Ora Rx = 176.
0009	OP_LABEL	-	Etichetta di salto. Salva il PC corrente per i salti futuri (Inizio Loop).
052c	OP_MOVE	 Rc, Rz 	Sposta il valore da Rz a Rc (Rc <= Rz)
0024 OP_ADD	Rz	Somma immediata al registro Rz.
00B0	(Dato)	0x00B0	Aggiunge 176 a Rz. Rz <= Rz + 176.
0005	 OP_SUB	 Rx	Sottrazione immediata al registro Rx.
0001	(Dato)	0x0001	Decrementa Rx di 1 (Counter loop).
0308 	OP_COMPARE	Rx, Ra	Compara Rx con Ra (Ra contiene 0 di default).
0007	OP_JUMPNZ	-	Salta all'istruzione LABEL (indirizzo salvato in 0009) se il risultato della comparazione non era Zero.

---

## 👤 Autore

**Raffaele Petrolo** 

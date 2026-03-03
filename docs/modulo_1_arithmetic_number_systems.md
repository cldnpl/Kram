# Modulo 1: Arithmetic & Number Systems

**Focus:** Dalle scuole medie all’inizio delle superiori (biennio).

---

## 1. Sets of Numbers — Insiemi numerici

### Introduzione teorica

Gli **insiemi numerici** sono la base di tutta la matematica: servono a dare nomi precisi ai “tipi” di numeri che usiamo (naturali, interi, razionali) e a capire in quale insieme ha senso fare certe operazioni. Si parte dall’**insieme dei numeri naturali** $\mathbb{N}$ (contare e ordinare), si passa agli **interi** $\mathbb{Z}$ (per poter sottrarre senza uscire dall’insieme) e ai **razionali** $\mathbb{Q}$ (per poter dividere in generale). Ogni passaggio risponde a un’esigenza: “vorremmo che questa operazione abbia sempre un risultato nell’insieme”.

### Proprietà e regole

- **$\mathbb{N}$ (numeri naturali):**
  - Contiene $0, 1, 2, 3, \ldots$ (in alcune convenzioni si esclude lo zero e si indica $\mathbb{N}^*$).
  - **Chiusura:** somma e prodotto di due naturali sono naturali.
  - La **sottrazione** non è sempre possibile in $\mathbb{N}$ (es. $3 - 5$ non è in $\mathbb{N}$).

- **$\mathbb{Z}$ (numeri interi):**
  - Contiene $\ldots, -2, -1, 0, 1, 2, \ldots$
  - **Chiusura:** somma, sottrazione e prodotto di interi sono interi.
  - La **divisione** non è sempre un intero (es. $7 \div 2$ non è in $\mathbb{Z}$).

- **$\mathbb{Q}$ (numeri razionali):**
  - Sono tutti i numeri esprimibili come **frazione** $\frac{p}{q}$ con $p, q \in \mathbb{Z}$ e $q \neq 0$.
  - Ogni **decimale limitato** o **periodico** è razionale.
  - **Chiusura:** somma, sottrazione, prodotto e quoziente (con divisore $\neq 0$) di razionali sono razionali.

### Formule chiave

- Insieme dei naturali (con zero):
  $$\mathbb{N} = \{0,\,1,\,2,\,3,\,\ldots\}$$

- Insieme degli interi:
  $$\mathbb{Z} = \{\ldots,\,-2,\,-1,\,0,\,1,\,2,\,\ldots\}$$

- Definizione di razionale:
  $$\mathbb{Q} = \left\{\frac{p}{q} \;\Big|\; p,\,q \in \mathbb{Z},\; q \neq 0\right\}$$

- Relazione di inclusione:
  $$\mathbb{N} \subseteq \mathbb{Z} \subseteq \mathbb{Q}$$

### Esempi svolti passaggio per passaggio

**Esempio 1 (facile)**  
Stabilire in quali insiemi vive il numero $5$.

- $5 \in \mathbb{N}$ (è un naturale).
- $5 \in \mathbb{Z}$ (ogni naturale è intero).
- $5 \in \mathbb{Q}$ perché $5 = \frac{5}{1}$ (è razionale).

**Esempio 2 (medio)**  
Stabilire in quali insiemi vive $-3$.

- $-3 \notin \mathbb{N}$ (i naturali sono $\geq 0$).
- $-3 \in \mathbb{Z}$ (è intero).
- $-3 \in \mathbb{Q}$ perché $-3 = \frac{-3}{1}$.

**Esempio 3 (più impegnativo)**  
Dimostrare che $\frac{2}{5} + \frac{1}{3}$ è un numero razionale.

- Si riduce a denominatore comune: $\frac{2}{5} = \frac{6}{15}$, $\frac{1}{3} = \frac{5}{15}$.
- Somma: $\frac{6}{15} + \frac{5}{15} = \frac{11}{15}$.
- $11$ e $15$ sono interi, $15 \neq 0$, quindi $\frac{11}{15} \in \mathbb{Q}$.

### Errori comuni da evitare

- **Confondere $\mathbb{N}$ con $\mathbb{N}^*$:** verificare se nel tuo testo lo zero è incluso o meno nei naturali.
- **Dire che $\pi$ o $\sqrt{2}$ sono razionali:** non lo sono; i razionali sono solo decimali limitati o periodici.
- **Dimenticare $q \neq 0$** nella definizione di $\mathbb{Q}$: la frazione deve avere denominatore non nullo.

### Placeholder per immagini

- [IMG: Diagramma di Venn che mostra $\mathbb{N}$ dentro $\mathbb{Z}$ e $\mathbb{Z}$ dentro $\mathbb{Q}$, con esempi di numeri in ciascuna regione.]
- [IMG: Schema “operazione → insieme”: somma/prodotto in $\mathbb{N}$, sottrazione in $\mathbb{Z}$, divisione in $\mathbb{Q}$.]

---

## 2. Fundamental Operations — Operazioni fondamentali

### Introduzione teorica

Le **quattro operazioni** (addizione, sottrazione, moltiplicazione, divisione) sono il cuore dell’aritmetica. Oltre a definirle in modo preciso, è essenziale conoscere **proprietà** (commutativa, associativa, distributiva) e le **potenze** e **radici**, che generalizzano moltiplicazione e divisione. Le potenze con esponente naturale sono “moltiplicazioni ripetute”; le **radici** sono l’operazione inversa delle potenze e si scrivono con esponente frazionario quando si lavora in $\mathbb{Q}$ o $\mathbb{R}$.

### Proprietà e regole

- **Addizione:** commutativa ($a + b = b + a$), associativa $(a + b) + c = a + (b + c)$, elemento neutro $0$.
- **Moltiplicazione:** commutativa, associativa, elemento neutro $1$, elemento assorbente $0$ ($a \cdot 0 = 0$).
- **Distributività:** $a \cdot (b + c) = a \cdot b + a \cdot c$.
- **Potenze (esponente naturale):** $a^n = a \cdot a \cdots a$ ($n$ volte); $a^0 = 1$ per $a \neq 0$; $a^{-n} = \frac{1}{a^n}$ per $a \neq 0$.
- **Prodotto e quoziente di potenze stessa base:** $a^m \cdot a^n = a^{m+n}$, $\frac{a^m}{a^n} = a^{m-n}$ (con $a \neq 0$).
- **Radici:** $\sqrt[n]{a} = b \Leftrightarrow b^n = a$; per $n$ pari si richiede $a \geq 0$ e $\sqrt[n]{a} \geq 0$; per $n$ dispari $a$ può essere negativo.

### Formule chiave

- Potenza con esponente naturale ($n \geq 1$):
  $$a^n = \underbrace{a \cdot a \cdots a}_{n \text{ volte}}$$

- Proprietà delle potenze (stessa base):
  $$a^m \cdot a^n = a^{m+n}, \qquad \frac{a^m}{a^n} = a^{m-n},\qquad (a^m)^n = a^{m \cdot n}$$

- Potenza di prodotto e quoziente:
  $$(a \cdot b)^n = a^n \cdot b^n, \qquad \left(\frac{a}{b}\right)^n = \frac{a^n}{b^n} \quad (b \neq 0)$$

- Radice $n$-esima e esponente frazionario (per $a > 0$):
  $$\sqrt[n]{a} = a^{1/n}, \qquad \sqrt[n]{a^m} = a^{m/n}$$

- Proprietà delle radici (con radicandi non negativi se $n$ pari):
  $$\sqrt[n]{a \cdot b} = \sqrt[n]{a} \cdot \sqrt[n]{b}, \qquad \sqrt[n]{\frac{a}{b}} = \frac{\sqrt[n]{a}}{\sqrt[n]{b}} \quad (b \neq 0)$$

### Esempi svolti passaggio per passaggio

**Esempio 1 (facile)**  
Calcolare $2^3 \cdot 2^2$.

- Stessa base: si sommano gli esponenti: $2^3 \cdot 2^2 = 2^{3+2} = 2^5 = 32$.

**Esempio 2 (medio)**  
Calcolare $\dfrac{3^5}{3^2}$ e $5^{-2}$.

- $\dfrac{3^5}{3^2} = 3^{5-2} = 3^3 = 27$.
- $5^{-2} = \dfrac{1}{5^2} = \dfrac{1}{25}$.

**Esempio 3 (più impegnativo)**  
Semplificare $\sqrt{18} + \sqrt{8}$ (scrivere in forma più semplice).

- $\sqrt{18} = \sqrt{9 \cdot 2} = \sqrt{9} \cdot \sqrt{2} = 3\sqrt{2}$.
- $\sqrt{8} = \sqrt{4 \cdot 2} = 2\sqrt{2}$.
- Quindi $\sqrt{18} + \sqrt{8} = 3\sqrt{2} + 2\sqrt{2} = 5\sqrt{2}$.

### Errori comuni da evitare

- **Scrivere $-3^2 = 9$:** per convenzione $-3^2 = -(3^2) = -9$; il quadrato riguarda solo il $3$. Per “meno tre al quadrato” si deve scrivere $(-3)^2 = 9$.
- **Applicare $(a + b)^n = a^n + b^n$:** è falso in generale (vale solo per $n = 1$). Esempio: $(1+2)^2 = 9 \neq 1^2 + 2^2 = 5$.
- **Radice di somma:** $\sqrt{a + b} \neq \sqrt{a} + \sqrt{b}$ in generale.

### Placeholder per immagini

- [IMG: Schema delle quattro operazioni con simboli e nomi (addendo + addendo = somma, ecc.).]
- [IMG: Albero “base ed esponente” per una potenza $a^n$ con esempi numerici.]
- [IMG: Grafico o schema che confronta $\sqrt{a+b}$ e $\sqrt{a}+\sqrt{b}$ con numeri per mostrare che non sono uguali.]

---

## 3. Expressions & Order of Operations — Espressioni e ordine delle operazioni

### Introduzione teorica

Un’**espressione** è una scrittura che combina numeri e operazioni. Per attribuirle un **unico** valore numerico è necessario un accordo sull’**ordine** con cui eseguire le operazioni. **PEMDAS** (Parentheses, Exponents, Multiplication, Division, Addition, Subtraction) e **BODMAS** (Brackets, Orders, Division, Multiplication, Addition, Subtraction) codificano quest’ordine: prima le **parentesi** (dall’interno verso l’esterno), poi **esponenti/radici**, poi **moltiplicazioni e divisioni** da sinistra a destra, infine **addizioni e sottrazioni** da sinistra a destra.

### Proprietà e regole

- Le **parentesi** (tonde, quadre, graffe) stabiliscono priorità: si calcola prima il contenuto delle parentesi più interne.
- **Potenze e radici** hanno priorità rispetto a moltiplicazione e divisione.
- **Moltiplicazione e divisione** hanno priorità rispetto a addizione e sottrazione.
- A parità di priorità (es. solo moltiplicazioni e divisioni) si procede **da sinistra a destra**.
- La **linea di frazione** equivale a parentesi attorno a numeratore e denominatore.

### Formule chiave

- Ordine (PEMDAS/BODMAS), in sintesi:
  1. Parentesi (e contenuto di radici/potenze)
  2. Esponenti e radici
  3. Moltiplicazione e divisione (ordine da sinistra)
  4. Addizione e sottrazione (ordine da sinistra)

- Esempio di lettura:
  $$2 + 3 \cdot 4 = 2 + 12 = 14 \quad \text{(prima } 3 \cdot 4\text{)}$$

  $$(2 + 3) \cdot 4 = 5 \cdot 4 = 20 \quad \text{(prima la parentesi)}$$

- Attenzione al segno meno:
  $$-3^2 = -(3^2) = -9, \qquad (-3)^2 = 9$$

### Esempi svolti passaggio per passaggio

**Esempio 1 (facile)**  
Calcolare $10 - 6 \div 2 + 1$.

- Nessuna parentesi; divisione prima di sottrazione e addizione: $6 \div 2 = 3$.
- Resta: $10 - 3 + 1$. Da sinistra: $10 - 3 = 7$, poi $7 + 1 = 8$.
- Risultato: $8$.

**Esempio 2 (medio)**  
Calcolare $2 \cdot 3^2 + 4$.

- Prima la potenza: $3^2 = 9$.
- Poi il prodotto: $2 \cdot 9 = 18$.
- Poi la somma: $18 + 4 = 22$.
- Risultato: $22$.

**Esempio 3 (più impegnativo)**  
Calcolare $\dfrac{1/2 + 1/3}{2}$ (la barra di frazione principale ha sotto solo $2$).

- Numeratore: $\dfrac{1}{2} + \dfrac{1}{3} = \dfrac{3}{6} + \dfrac{2}{6} = \dfrac{5}{6}$.
- L’espressione è $\dfrac{5/6}{2} = \dfrac{5}{6} \div 2 = \dfrac{5}{6} \cdot \dfrac{1}{2} = \dfrac{5}{12}$.
- Risultato: $\dfrac{5}{12}$.

### Errori comuni da evitare

- **Eseguire $2 + 3 \cdot 4$ come $5 \cdot 4 = 20$:** l’ordine corretto è prima $3 \cdot 4$, quindi $2 + 12 = 14$.
- **Interpretare male $-3^2$:** è $-9$, non $+9$.
- **Dimenticare che numeratore e denominatore vanno calcolati separatamente** prima di fare la divisione finale.

### Placeholder per immagini

- [IMG: Diagramma a livelli: Livello 1 Parentesi, Livello 2 Esponenti/radici, Livello 3 × e ÷, Livello 4 + e −.]
- [IMG: Espressione tipo $2 + 3 \cdot (4 - 1)^2$ con frecce che indicano l’ordine di calcolo (prima $(4-1)$, poi il quadrato, poi il prodotto, poi la somma).]

---

## 4. Divisibility & Prime Numbers — Divisibilità e numeri primi

### Introduzione teorica

La **divisibilità** studia quando un intero **divide** un altro (resto zero). **Multipli** e **divisori** sono nozioni inverse; **MCD** (Massimo Comune Divisore) e **mcm** (minimo comune multiplo) servono per semplificare frazioni, ridurre a denominatore comune e risolvere problemi di scomposizione. I **numeri primi** sono i “mattoni” degli interi: ogni intero $> 1$ si scrive in modo unico (a meno dell’ordine) come prodotto di primi (**teorema fondamentale dell’aritmetica**).

### Proprietà e regole

- **Multiplo:** $a$ è multiplo di $b$ ($b \neq 0$) se esiste $k \in \mathbb{Z}$ tale che $a = b \cdot k$. Si scrive $b \mid a$ (“$b$ divide $a$”).
- **Divisore:** $d$ è divisore di $n$ se $n = d \cdot q$ per qualche intero $q$, cioè $d \mid n$.
- **Numero primo:** intero $p \geq 2$ i cui unici divisori positivi sono $1$ e $p$.
- **MCD:** massimo intero positivo che divide tutti i numeri dati; si può calcolare con la **scomposizione in fattori primi** (prendere i fattori comuni con l’**esponente minimo**) o con l’**algoritmo di Euclide**.
- **mcm:** minimo intero positivo multiplo di tutti i numeri dati; con la scomposizione si prendono **tutti** i fattori con l’**esponente massimo**.
- **Relazione:** per due interi positivi $a$, $b$: $\text{MCD}(a,b) \cdot \text{mcm}(a,b) = a \cdot b$.

### Formule chiave

- Definizione di divisibilità:
  $$b \mid a \;\Leftrightarrow\; \exists\, k \in \mathbb{Z} \colon a = b \cdot k$$

- MCD e mcm da scomposizione (con $p$ primo):
  $$\text{MCD}(a,b) = p_1^{\min(\alpha_1,\beta_1)} \cdots p_k^{\min(\alpha_k,\beta_k)}$$
  $$\text{mcm}(a,b) = p_1^{\max(\alpha_1,\beta_1)} \cdots p_k^{\max(\alpha_k,\beta_k)}$$

- Relazione fondamentale:
  $$\text{MCD}(a,b) \cdot \text{mcm}(a,b) = a \cdot b$$

### Esempi svolti passaggio per passaggio

**Esempio 1 (facile)**  
Trovare i divisori positivi di $18$.

- $18 = 2 \cdot 9 = 2 \cdot 3^2$. I divisori sono $1$, $2$, $3$, $6$, $9$, $18$ (tutte le combinazioni $2^0 \cdot 3^0$, $2^1$, $3^1$, $3^2$, $2 \cdot 3$, $2 \cdot 3^2$).

**Esempio 2 (medio)**  
Calcolare $\text{MCD}(24, 36)$ e $\text{mcm}(24, 36)$.

- $24 = 2^3 \cdot 3$, $36 = 2^2 \cdot 3^2$.
- MCD: fattori comuni con esponente minimo: $2^2 \cdot 3 = 12$.
- mcm: tutti i fattori con esponente massimo: $2^3 \cdot 3^2 = 72$.
- Verifica: $12 \cdot 72 = 864 = 24 \cdot 36$.

**Esempio 3 (più impegnativo)**  
Calcolare $\text{MCD}(48, 180)$ con l’algoritmo di Euclide.

- $180 = 48 \cdot 3 + 36$
- $48 = 36 \cdot 1 + 12$
- $36 = 12 \cdot 3 + 0$
- L’ultimo resto non nullo è $12$, quindi $\text{MCD}(48, 180) = 12$.

### Errori comuni da evitare

- **Considerare $1$ come numero primo:** per definizione i primi sono $\geq 2$ e $1$ è escluso.
- **Confondere MCD e mcm:** il MCD non può superare i numeri dati; il mcm non può essere minore del più grande dei numeri.
- **Dimenticare gli esponenti zero** nella scomposizione quando un primo non compare (es. $24 = 2^3 \cdot 3^1 \cdot 5^0$).

### Placeholder per immagini

- [IMG: Tabella o lista dei numeri primi minori di 50 (2, 3, 5, 7, 11, …) con breve spiegazione del crivello.]
- [IMG: Diagramma ad albero per la scomposizione di un numero (es. 60) in fattori primi.]
- [IMG: Schema dell’algoritmo di Euclide con due numeri e i resti successivi fino a resto 0.]

---

## 5. Fractions & Ratios — Frazioni e rapporti

### Introduzione teorica

Le **frazioni** rappresentano parti di un intero e divisioni tra interi; i **rapporti** e le **proporzioni** confrontano quantità. **Frazioni equivalenti**, **operazioni** con le frazioni, **percentuali** e **proporzioni** sono strumenti quotidiani in matematica e in molte applicazioni. La **riduzione ai minimi termini** (dividere numeratore e denominatore per il loro MCD) e l’uso del **mcm** per il denominatore comune sono procedure da padroneggiare bene.

### Proprietà e regole

- **Equivalenza:** $\dfrac{a}{b} = \dfrac{c}{d}$ se e solo se $a \cdot d = b \cdot c$ ($b, d \neq 0$).
- **Riduzione:** si divide numeratore e denominatore per $\text{MCD}(a,b)$ per ottenere la forma ridotta.
- **Somma/differenza:** stesso denominatore $\Rightarrow$ si opera sui numeratori; denominatori diversi $\Rightarrow$ si riduce a denominatore comune (in genere il mcm).
- **Prodotto:** $\dfrac{a}{b} \cdot \dfrac{c}{d} = \dfrac{a \cdot c}{b \cdot d}$.
- **Quoziente:** $\dfrac{a}{b} \div \dfrac{c}{d} = \dfrac{a}{b} \cdot \dfrac{d}{c}$ ($c \neq 0$).
- **Percentuale:** $x\% = \dfrac{x}{100}$; $x\%$ di $N$ è $\dfrac{x}{100} \cdot N$.
- **Proporzione:** $a : b = c : d \Leftrightarrow \dfrac{a}{b} = \dfrac{c}{d} \Leftrightarrow a \cdot d = b \cdot c$ (proprietà fondamentale).

### Formule chiave

- Equivalenza di frazioni:
  $$\frac{a}{b} = \frac{c}{d} \;\Leftrightarrow\; a \cdot d = b \cdot c \quad (b,\,d \neq 0)$$

- Operazioni:
  $$\frac{a}{b} \pm \frac{c}{d} = \frac{ad \pm bc}{bd}, \qquad \frac{a}{b} \cdot \frac{c}{d} = \frac{ac}{bd}, \qquad \frac{a}{b} \div \frac{c}{d} = \frac{ad}{bc} \quad (b,\,c,\,d \neq 0)$$

- Proporzione e termine incognito (con $b,\,d \neq 0$):
  $$a : b = c : d \;\Leftrightarrow\; ad = bc; \qquad \text{se } a : b = x : d \text{ allora } x = \frac{ad}{b}$$

- Percentuale:
  $$x\% \text{ di } N = \frac{x}{100} \cdot N$$

### Esempi svolti passaggio per passaggio

**Esempio 1 (facile)**  
Ridurre $\dfrac{18}{24}$ ai minimi termini.

- $\text{MCD}(18, 24) = 6$ (da $18 = 2 \cdot 3^2$, $24 = 2^3 \cdot 3$).
- $\dfrac{18}{24} = \dfrac{18 \div 6}{24 \div 6} = \dfrac{3}{4}$.

**Esempio 2 (medio)**  
Calcolare $\dfrac{2}{5} + \dfrac{1}{3}$ e $\dfrac{2}{3} \div \dfrac{4}{5}$.

- mcm$(5,3) = 15$. $\dfrac{2}{5} = \dfrac{6}{15}$, $\dfrac{1}{3} = \dfrac{5}{15}$ $\Rightarrow$ $\dfrac{2}{5} + \dfrac{1}{3} = \dfrac{11}{15}$.
- $\dfrac{2}{3} \div \dfrac{4}{5} = \dfrac{2}{3} \cdot \dfrac{5}{4} = \dfrac{10}{12} = \dfrac{5}{6}$ (dopo semplificazione).

**Esempio 3 (più impegnativo)**  
In una proporzione $3 : 4 = x : 12$ trovare $x$. Poi: “Il 15% di un numero è 45. Qual è il numero?”

- Da $3 : 4 = x : 12$ si ha $3 \cdot 12 = 4x$, quindi $x = \dfrac{36}{4} = 9$.
- Se $\dfrac{15}{100} \cdot N = 45$, allora $N = 45 \cdot \dfrac{100}{15} = 300$.

### Errori comuni da evitare

- **Sommare numeratori e denominatori:** $\dfrac{a}{b} + \dfrac{c}{d} \neq \dfrac{a+c}{b+d}$ in generale.
- **Semplificare in modo errato:** si possono semplificare solo **fattori** comuni a numeratore e denominatore (es. $\dfrac{2+1}{2+3} \neq \dfrac{1}{3}$).
- **Invertire la proporzione:** in $a : b = c : d$ i medi sono $b$ e $c$, gli estremi $a$ e $d$; la proprietà fondamentale è $ad = bc$, non $ab = cd$.

### Placeholder per immagini

- [IMG: Cerchio (o rettangolo) diviso in parti uguali per illustrare $\frac{3}{4}$ e $\frac{2}{3}$ e la somma con denominatore comune.]
- [IMG: Schema “proporzione $a:b=c:d$” con frecce che collegano i termini e l’uguaglianza $ad=bc$.]
- [IMG: Diagramma a blocchi per il calcolo di una percentuale (es. 20% di 80) con passaggi scritti.]

---

*Fine Modulo 1 — Arithmetic & Number Systems.*

Quando vuoi, posso procedere con il **Modulo 2: Algebra (The Core)** e generare il file `modulo_2_algebra.md`.

package lesson

import (
	"strconv"
	"strings"
)

type lessonContent struct {
	Title    string
	Category string
	Intro    string
}

// parseItemID parses ids like "16-2" -> ("16", 2, true). For plain section ids ("16") it returns ok=false.
func parseItemID(id string) (sectionID string, itemIndex int, ok bool) {
	sectionID, rest, found := strings.Cut(id, "-")
	if !found {
		return "", 0, false
	}
	if sectionID == "" || rest == "" {
		return "", 0, false
	}
	n, err := strconv.Atoi(rest)
	if err != nil || n < 0 {
		return "", 0, false
	}
	return sectionID, n, true
}

// contentByLang maps language code -> lesson id -> content.
// English ("en") is the default and lives in lessonContentByID.
var contentByLang = map[string]map[string]lessonContent{
	"en": lessonContentByID,
	"it": lessonContentByID_it,
	"fr": lessonContentByID_fr,
	"es": lessonContentByID_es,
	"uz": lessonContentByID_uz,
}

func normalizeLessonLang(lang string) string {
	switch strings.ToLower(strings.TrimSpace(lang)) {
	case "it":
		return "it"
	case "fr":
		return "fr"
	case "es":
		return "es"
	case "uz":
		return "uz"
	default:
		return "en"
	}
}

// getContentByID returns content for both section ids ("1".."27") and item ids ("1-0"..),
// in the requested language (falls back to English).
func getContentByID(id, lang string) (lessonContent, bool) {
	id = strings.TrimSpace(id)
	if id == "" {
		return lessonContent{}, false
	}

	normalizedLang := normalizeLessonLang(lang)
	m := lessonContentByID
	if lm, ok := contentByLang[normalizedLang]; ok {
		m = lm
	}

	if c, ok := m[id]; ok {
		return c, true
	}

	// Fallback: if an item id is requested but missing, use the section overview.
	if sectionID, _, ok := parseItemID(id); ok {
		if c, ok := m[sectionID]; ok {
			return c, true
		}
	}

	// Final fallback: English
	if normalizedLang != "en" {
		return getContentByID(id, "en")
	}

	return lessonContent{}, false
}

var lessonContentByID = map[string]lessonContent{
	// ---------------------------
	// Arithmetic & Number Systems
	// ---------------------------
	"1": {
		Title:    "Sets of Numbers",
		Category: "Arithmetic & Number Systems",
		Intro: `In this section you learn the main number sets used in mathematics and why we need them.

Key idea: we enlarge the set when an operation would “leave” the previous one.

[BOX]
**Summary:** ℕ ⊆ ℤ ⊆ ℚ. In ℕ, 3 − 5 is not in ℕ so we need ℤ; in ℤ, 7 ÷ 2 is not in ℤ so we need ℚ.
[/BOX]

[DIAGRAM:euler-venn-sets]`,
	},
	"1-0": {
		Title:    "Natural numbers ℕ",
		Category: "Arithmetic & Number Systems",
		Intro: `**Natural numbers** are the first numbers we learn: they are used to **count** objects (one, two, three, …) and to **order** them (first, second, third, …). In mathematics they form a set called **ℕ**, which is the foundation of arithmetic and of all larger number systems.

**Definition.** The set of natural numbers is ℕ = {0, 1, 2, 3, 4, 5, …}. In some textbooks the symbol **ℕ** excludes zero and only positive integers are considered; in that case the set is often written **ℕ*** = {1, 2, 3, …}. In this course we include zero in ℕ.

[DIAGRAM:number-line]

**Why zero?** Including zero allows us to say “how many elements are in the empty set?” — the answer is 0. It also makes the link with integers and algebra cleaner (zero is the **neutral element** for addition).

**Main properties of ℕ:**
• **Closure under addition:** if a and b are natural numbers, then a + b is also a natural number. So you never “leave” ℕ when you add.
• **Closure under multiplication:** if a, b ∈ ℕ, then a·b ∈ ℕ. Again, multiplying two natural numbers always gives a natural number.
• **Not closed under subtraction:** if a < b, then a − b is negative, so it is **not** in ℕ. For example, 3 − 5 = −2. This is the main reason we later introduce **integers** ℤ.
• **Order:** for any two natural numbers a and b, exactly one of these holds: a < b, a = b, or a > b. So ℕ is **totally ordered**.
• **Well-ordering:** every non-empty subset of ℕ has a **smallest element**. This property is used in proofs by induction.

[BOX]
**Formal definition (optional)**
ℕ is the smallest set that contains 0 and such that if n is in the set, then n + 1 is in the set.
[/BOX]

[BOX]
**Examples**
7 ∈ ℕ
7 + 2 = 9 ∈ ℕ
7·4 = 28 ∈ ℕ
3 − 5 = −2  →  −2 ∉ ℕ (so subtraction is not always possible in ℕ)
[/BOX]

**Common mistakes to avoid:** Do not confuse ℕ with ℕ* if your book uses both. Always check whether zero is included. Remember that **negative numbers are not natural numbers** — they belong to ℤ.`,
	},
	"1-1": {
		Title:    "Integers ℤ",
		Category: "Arithmetic & Number Systems",
		Intro: `**Integers** extend the natural numbers by including **negative** numbers and zero. We need them so that **subtraction** is always possible (within ℤ): for any two integers a and b, the difference a − b is again an integer.

**Definition.** The set of integers is ℤ = {…, −3, −2, −1, 0, 1, 2, 3, …}. So ℤ contains all **natural numbers** (0, 1, 2, …) and their **opposites** (−1, −2, −3, …).

**Main properties of ℤ:**
• **Closure under addition:** if a, b ∈ ℤ then a + b ∈ ℤ.
• **Closure under subtraction:** if a, b ∈ ℤ then a − b ∈ ℤ. This is the key improvement over ℕ.
• **Closure under multiplication:** if a, b ∈ ℤ then a·b ∈ ℤ.
• **Division is not always an integer:** for example 7 ÷ 2 is not an integer. So we will later need **rational numbers** ℚ when we want to divide freely.
• **Sign rules for multiplication:** (−)·(−) = (+), (−)·(+) = (−), (+)·(+) = (+). Same rules apply to division when the result is an integer.
• **Absolute value:** |a| is the distance of a from 0 on the number line. So |−7| = 7 and |5| = 5. We have |a·b| = |a|·|b| and |a + b| ≤ |a| + |b| (triangle inequality).

[DIAGRAM:number-line]

[BOX]
**Formulas**
(−a)·(−b) = a·b
|a| = a if a ≥ 0, and |a| = −a if a < 0
[/BOX]

[BOX]
**Examples**
(−3) + 5 = 2
(−3) − 5 = −8
(−3)·(−4) = 12
|−7| = 7
7 ÷ 2 is not in ℤ (we need ℚ for that)
[/BOX]

**Common mistakes:** Do not write (−3)·(−4) = −12; the correct result is +12. Remember that **subtraction** of a positive is like adding a negative: a − b = a + (−b).`,
	},
	"1-2": {
		Title:    "Rational numbers ℚ",
		Category: "Arithmetic & Number Systems",
		Intro: `**Rational numbers** are numbers that can be written as **fractions** of two integers: a **numerator** and a **denominator** (nonzero). They include all integers (e.g. 5 = 5/1) and all **terminating** or **repeating** decimals. We need ℚ so that **division** is always possible (except division by zero).

**Definition.** ℚ = { p/q : p, q ∈ ℤ, q ≠ 0 }. Two fractions p/q and r/s represent the **same** rational number when p·s = q·r (cross-multiplication).

[DIAGRAM:number-line]

**Key facts:**
• **Decimals:** Every rational number has a decimal expansion that either **terminates** (e.g. 1/4 = 0.25) or **repeats** (e.g. 1/3 = 0.333… = 0.3̅). Conversely, every terminating or repeating decimal is rational.
• **Simplification:** You can simplify a fraction by dividing numerator and denominator by their **GCD**. The fraction is in **lowest terms** when GCD(numerator, denominator) = 1.
• **Closure:** ℚ is closed under **addition**, **subtraction**, **multiplication**, and **division** (by a nonzero rational). So within ℚ we can do all four operations freely (except ÷ by 0).
• **Density:** Between any two distinct rationals there is another rational (in fact infinitely many). So ℚ is **dense** on the number line, but it still has “gaps” (e.g. √2 is not rational).

[BOX]
**Formulas**
a/b = c/d  ⇔  a·d = b·c   (b, d ≠ 0)
Reduction: divide numerator and denominator by GCD(p, q)
[/BOX]

[BOX]
**Examples**
0.25 = 25/100 = 1/4
1.3̅ = 1.333… = 4/3
−2/5 ∈ ℚ
5 = 5/1 ∈ ℚ
[/BOX]

**Common mistakes:** Do not forget q ≠ 0 in the definition. Do not assume that every decimal is rational — **non-repeating, non-terminating** decimals (like π or √2) are **irrational**.`,
	},
	"2": {
		Title:    "Fundamental Operations",
		Category: "Arithmetic & Number Systems",
		Intro: `This section covers the **four basic operations** (addition, subtraction, multiplication, division), **powers** and their properties, and **roots**. These are the building blocks of all arithmetic and algebra.

**What you will learn:**
• **The four operations** — definitions, **commutativity**, **associativity**, and the **distributive law**. Division with **remainder**.
• **Powers** — definition as repeated multiplication, exponent zero and negative exponents, and the main **rules** (product, quotient, power of a power).
• **Roots** — the inverse of powers, **n-th root** definition, when radicands can be negative, and the link with **fractional exponents**.

**Important:** Always respect the **order of operations** (PEMDAS/BODMAS): parentheses first, then exponents and roots, then multiplication and division (left to right), then addition and subtraction (left to right).

[BOX]
**Order of operations (PEMDAS/BODMAS)**
1) Parentheses (and brackets)
2) Exponents and roots
3) Multiplication and division (left to right)
4) Addition and subtraction (left to right)
[/BOX]

[DIAGRAM:number-line]`,
	},
	"2-0": {
		Title:    "The four operations",
		Category: "Arithmetic & Number Systems",
		Intro: `The **four basic operations** of arithmetic are **addition** (+), **subtraction** (−), **multiplication** (· or ×), and **division** (÷ or /). They are the building blocks of all numerical calculations.

**Addition:** a + b = c. The numbers a and b are called **addends**; c is the **sum**. Addition is **commutative** (a + b = b + a) and **associative** ((a + b) + c = a + (b + c)). Zero is the **identity**: a + 0 = a.

**Subtraction:** a − b = c means that b + c = a. So subtraction is the **inverse** of addition. It is **not** commutative: a − b ≠ b − a in general.

**Multiplication:** a·b = c. The numbers a and b are **factors**; c is the **product**. Multiplication is **commutative** and **associative**. One is the **identity**: a·1 = a. Zero is **absorbing**: a·0 = 0.

**Division:** a ÷ b = q (with b ≠ 0) means that a = b·q. If a is not a multiple of b, we get a **remainder** r: a = b·q + r with 0 ≤ r < |b|. Division is the **inverse** of multiplication and is **not** commutative.

**Distributive law:** a·(b + c) = a·b + a·c. This connects addition and multiplication and is used in expanding brackets and factoring.

[BOX]
**Properties (summary)**
a + b = b + a   and   a·b = b·a  (commutative)
(a + b) + c = a + (b + c)   and   (a·b)·c = a·(b·c)  (associative)
a·(b + c) = a·b + a·c  (distributive)
[/BOX]

[BOX]
**Examples**
12 − 5 = 7
12 ÷ 5 = 2 remainder 2   because  12 = 5·2 + 2
3·(2 + 4) = 3·2 + 3·4 = 6 + 12 = 18
[/BOX]

[DIAGRAM:number-line]`,
	},
	"2-1": {
		Title:    "Powers and their properties",
		Category: "Arithmetic & Number Systems",
		Intro: `**Powers** (or **exponentiation**) represent **repeated multiplication**. The notation aⁿ means “a multiplied by itself n times”. Powers are used everywhere: in formulas (e.g. area of a square), in scientific notation, and later in calculus (exponential and logarithmic functions).

**Definition.** For a **natural number** n ≥ 1: aⁿ = a·a·…·a (n factors). We call **a** the **base** and **n** the **exponent**. By convention: **a⁰ = 1** for any a ≠ 0 (and sometimes 0⁰ is left undefined). For **negative exponents**: **a⁻ⁿ = 1/aⁿ** when a ≠ 0, so that the rule aᵐ·aⁿ = aᵐ⁺ⁿ still holds when we allow negative n.

**Main properties (same base):**
• **Product:** aⁿ·aᵐ = aⁿ⁺ᵐ  (add exponents when multiplying).
• **Quotient:** aⁿ/aᵐ = aⁿ⁻ᵐ  (subtract exponents when dividing), with a ≠ 0.
• **Power of a power:** (aⁿ)ᵐ = aⁿᵐ  (multiply exponents).

[DIAGRAM:powers-properties-table]

**Properties (product and quotient inside the power):**
• (a·b)ⁿ = aⁿ·bⁿ
• (a/b)ⁿ = aⁿ/bⁿ  for b ≠ 0

These rules hold when the exponents are integers (and, with care, for rational exponents when we define roots).

[BOX]
**Formulas**
aⁿ·aᵐ = aⁿ⁺ᵐ
aⁿ/aᵐ = aⁿ⁻ᵐ   (a ≠ 0)
(aⁿ)ᵐ = aⁿᵐ
(ab)ⁿ = aⁿbⁿ   and   (a/b)ⁿ = aⁿ/bⁿ
a⁰ = 1  (a ≠ 0)   and   a⁻ⁿ = 1/aⁿ
[/BOX]

[BOX]
**Examples**
2³·2² = 2⁵ = 32
3⁴/3² = 3² = 9
5⁻² = 1/5² = 1/25
(2·3)² = 2²·3² = 4·9 = 36
[/BOX]

**Common mistake:** Do not confuse −aⁿ with (−a)ⁿ. We have −3² = −9 but (−3)² = 9. The exponent applies only to the number immediately before it unless parentheses say otherwise.`,
	},
	"2-2": {
		Title:    "Roots",
		Category: "Arithmetic & Number Systems",
		Intro: `**Roots** are the **inverse operation** of powers: taking the **n-th root** of a number a means finding a number b such that bⁿ = a. The most common is the **square root** (n = 2), written √a.

**Definition.** ⁿ√a = b means **bⁿ = a**. We call n the **index**, a the **radicand**, and b the **n-th root** of a. When n = 2 we usually write √a instead of ²√a.

**When is the root defined (in the reals)?**
• **Even index (n = 2, 4, 6, …):** For ⁿ√a to be a **real** number, we need **a ≥ 0**. By convention, ⁿ√a denotes the **non-negative** root (the principal root). So √4 = 2, not −2, even though (−2)² = 4.
• **Odd index (n = 1, 3, 5, …):** The n-th root exists for **any** real a. If a < 0, then ⁿ√a is negative. For example ³√(−8) = −2 because (−2)³ = −8.

**Fractional exponents.** For a > 0 we define **a^(1/n) = ⁿ√a** and more generally **a^(m/n) = ⁿ√(aᵐ)** (with n > 0). So roots are a special case of powers with rational exponents. This makes the usual power rules (product, quotient) extend to roots.

**Properties:** ⁿ√(a·b) = ⁿ√a · ⁿ√b and ⁿ√(a/b) = ⁿ√a / ⁿ√b (for b ≠ 0), when all roots are defined. **Warning:** √(a + b) is **not** equal to √a + √b in general.

[BOX]
**Formulas**
ⁿ√a = b  ⇔  bⁿ = a
ⁿ√a = a^(1/n)   (a > 0)
ⁿ√(a·b) = ⁿ√a · ⁿ√b    and    ⁿ√(a/b) = ⁿ√a / ⁿ√b
[/BOX]

[BOX]
**Examples**
√9 = 3
³√(−8) = −2
√2 = 2^(1/2)
√18 = √(9·2) = 3√2
[/BOX]

**Common mistakes:** Do not write √(a²) = a for negative a: we have √(a²) = |a|. Do not split the root over a sum: √(a + b) ≠ √a + √b.

[DIAGRAM:number-line]`,
	},
	"3": {
		Title:    "Expressions & Order of Operations",
		Category: "Arithmetic & Number Systems",
		Intro: `An **expression** is a combination of numbers, operations, and sometimes variables. To give it a **unique** value we must agree on the **order** in which to perform the operations. **PEMDAS** (Parentheses, Exponents, Multiplication, Division, Addition, Subtraction) and **BODMAS** (Brackets, Orders, Division, Multiplication, Addition, Subtraction) are two names for the same rule.

**What you will see:** How to apply **parentheses** and **PEMDAS/BODMAS** step by step, and how to avoid common errors (e.g. −3² vs (−3)², or the fraction bar acting as parentheses).

[BOX]
**PEMDAS / BODMAS**
1) Parentheses (and brackets, from innermost outward)
2) Exponents and roots (Orders)
3) Multiplication and Division (left to right)
4) Addition and Subtraction (left to right)
[/BOX]

[DIAGRAM:number-line]`,
	},
	"3-0": {
		Title:    "Use of parentheses and PEMDAS/BODMAS",
		Category: "Arithmetic & Number Systems",
		Intro: `**Parentheses** (and brackets, braces) force a specific order of evaluation: we always compute what is **inside** them first. Without parentheses, **PEMDAS/BODMAS** tells us the order: first exponents and roots, then multiplication and division from left to right, then addition and subtraction from left to right.

**Why it matters.** The expression 2 + 3·4 has only one correct value: we do 3·4 = 12 first, then 2 + 12 = **14**. If we did 2 + 3 first we would get 5·4 = 20, which is wrong. So **parentheses change the meaning**: (2 + 3)·4 = 20.

**Common pitfalls:**
• **Leading minus and exponent:** The notation **−3²** means −(3²) = −9, because the exponent applies only to the 3. If you want “minus three squared” you must write **(−3)²** = 9. This is a very frequent error.
• **Fraction bar:** A **fraction bar** acts like parentheses around the numerator and around the denominator. So in (1/2 + 1/3)/2 you first compute 1/2 + 1/3 = 5/6, then (5/6)/2 = 5/12.
• **Nested brackets:** Work from the **innermost** pair outward. Example: 2·[3 + (4−1)] = 2·[3 + 3] = 2·6 = 12.

[BOX]
**Order reminder**
Exponents and roots before × and ÷; × and ÷ before + and −.
At same level, go **left to right**.
[/BOX]

[BOX]
**Examples**
2 + 3·4 = 2 + 12 = 14   (not 5·4)
(2 + 3)·4 = 5·4 = 20
10 − 6 ÷ 2 + 1 = 10 − 3 + 1 = 8
−3² = −9   and   (−3)² = 9
(1/2 + 1/3)·6 = (5/6)·6 = 5
[/BOX]

[DIAGRAM:number-line]`,
	},
	"4": {
		Title:    "Divisibility & Prime Numbers",
		Category: "Arithmetic & Number Systems",
		Intro: `**Divisibility** studies when one integer **divides** another with no remainder. This is the foundation for **prime factorization**, **GCD** (Greatest Common Divisor), and **LCM** (Least Common Multiple), which you need for simplifying fractions, finding common denominators, and solving many number problems.

**What you will see:** **Multiples** and the notation b | a (“b divides a”); **divisors** of a number; **GCD** (how to find it by prime factorization or the **Euclidean algorithm**); **LCM** and the relation GCD·LCM = a·b for two positive integers.

[BOX]
**Formulas**
b | a ⇔ a = b·k (k integer)
GCD·LCM = a·b
[/BOX]

[BOX]
**Examples**
GCD(12,18) = 6
LCM(12,18) = 36
[/BOX]

[DIAGRAM:prime-factorization-tree]`,
	},
	"4-0": {
		Title:    "Multiples",
		Category: "Arithmetic & Number Systems",
		Intro: `A **multiple** of an integer b (with b ≠ 0) is any integer that can be written as **b·k** for some integer k. So the **multiples of b** are …, −2b, −b, 0, b, 2b, 3b, …. Equivalently, we say that **b divides a** (or **b is a divisor of a**) when a is a multiple of b.

**Notation.** We write **b | a** to mean “b divides a”, i.e. there exists an integer k such that **a = b·k**. So 3 | 12 because 12 = 3·4. We write **b ∤ a** when b does not divide a (e.g. 3 ∤ 10).

**Properties:** For any integers a, b, c (with divisors nonzero when needed): (1) a | a and a | 0; (2) if a | b and b | c then a | c; (3) if a | b and a | c then a | (b ± c); (4) if a | b then a | (b·k) for any integer k. **Multiples of b** form an infinite list in both directions; the **positive** multiples are b, 2b, 3b, ….

[BOX]
**Definition**
b | a  ⇔  there exists integer k such that  a = b·k
[/BOX]

[BOX]
**Examples**
12 is a multiple of 3 because 12 = 3·4  ⇒  3 | 12
−15 is a multiple of 5 because −15 = 5·(−3)  ⇒  5 | (−15)
7 ∤ 20 because no integer k gives 7k = 20
[/BOX]

[DIAGRAM:prime-factorization-tree]`,
	},
	"4-1": {
		Title:    "Divisors",
		Category: "Arithmetic & Number Systems",
		Intro: `A **divisor** of an integer n is an integer d such that **n = d·q** for some integer q; in other words, **d | n**. The divisors of n are also called **factors** of n. We often consider only **positive** divisors when n > 0.

**Finding divisors.** For small numbers you can list all pairs (d, q) with d·q = n. For larger numbers, the efficient way is **prime factorization**: write n as a product of primes, e.g. n = p₁^a₁ · p₂^a₂ · … · pₖ^aₖ. Then every positive divisor has the form p₁^b₁ · p₂^b₂ · … · pₖ^bₖ where **0 ≤ bᵢ ≤ aᵢ** for each i. So the **number** of positive divisors is **(a₁+1)(a₂+1)…(aₖ+1)**.

**Useful facts:** 1 and n always divide n. If n = d·q then d and q are a “divisor pair”; you only need to check d up to √n to find all positive divisors of a positive n. **Prime numbers** are those integers ≥ 2 whose only positive divisors are 1 and themselves.

[BOX]
**From prime factorization**
n = 2^a · 3^b · …  ⇒  divisors = 2^i · 3^j · …  with 0 ≤ i ≤ a, 0 ≤ j ≤ b, …
Number of positive divisors = (a+1)(b+1)…
[/BOX]

[BOX]
**Example**
18 = 2·3²
Positive divisors: 1, 2, 3, 6, 9, 18
(Exponents 0,1 for 2 and 0,1,2 for 3 → (1+1)(2+1) = 6 divisors.)
[/BOX]

[DIAGRAM:prime-factorization-tree]`,
	},
	"4-2": {
		Title:    "GCD (Greatest Common Divisor)",
		Category: "Arithmetic & Number Systems",
		Intro: `The **GCD** (Greatest Common Divisor) of two or more integers is the **largest positive integer** that **divides all** of them. It is used to simplify fractions (divide numerator and denominator by their GCD) and to solve many number-theory problems. Notation: **gcd(a, b)** or **MCD(a, b)**.

**Method 1 — Prime factorization.** Write each number as a product of primes. The GCD is the product of each **common prime** raised to the **smallest** exponent that appears. For example 24 = 2³·3 and 36 = 2²·3²; common primes are 2 and 3; smallest exponents are 2 and 1, so gcd(24, 36) = 2²·3 = **12**.

**Method 2 — Euclidean algorithm.** This is faster for large numbers. Key fact: **gcd(a, b) = gcd(b, a mod b)**. So replace (a, b) by (b, a mod b) until the second number is 0; then the first number is the GCD. Example: gcd(48, 18) → gcd(18, 12) → gcd(12, 6) → gcd(6, 0) ⇒ **gcd = 6**.

**Properties:** gcd(a, b) = gcd(|a|, |b|); gcd(a, 0) = |a|; gcd(a, b) divides any integer linear combination a·m + b·n (in particular **Bézout’s identity**: there exist integers m, n such that a·m + b·n = gcd(a, b)).

[BOX]
**Formulas**
gcd(a, b) from prime factors: take common primes with **minimum** exponent
Euclidean step: gcd(a, b) = gcd(b, a mod b)
gcd(a, 0) = |a|
[/BOX]

[BOX]
**Example (prime factors)**
24 = 2³·3
36 = 2²·3²
GCD(24, 36) = 2²·3 = 12
[/BOX]`,
	},
	"4-3": {
		Title:    "LCM (Least Common Multiple)",
		Category: "Arithmetic & Number Systems",
		Intro: `The **LCM** (Least Common Multiple) of two or more **positive** integers is the **smallest positive integer** that is a **multiple of all** of them. It is used to find a **common denominator** when adding fractions and in many timing or repetition problems. Notation: **lcm(a, b)** or **mcm(a, b)**.

**Method — Prime factorization.** Write each number as a product of primes. The LCM is the product of **all** primes that appear, each raised to the **largest** exponent that appears in any of the numbers. For 24 = 2³·3 and 36 = 2²·3², we take 2³ and 3², so lcm(24, 36) = 2³·3² = **72**.

**Relation with GCD.** For two positive integers a and b we have the very useful identity: **gcd(a, b) · lcm(a, b) = a · b**. So you can compute the LCM as lcm(a, b) = (a·b) / gcd(a, b). This is often easier once you have the GCD (e.g. from the Euclidean algorithm).

**Properties:** Any common multiple of a and b is a multiple of lcm(a, b). The LCM of more than two numbers can be found by taking the LCM of the first two, then the LCM of that result with the next number, and so on.

[BOX]
**Formulas**
lcm(a, b) from prime factors: take **all** primes with **maximum** exponent
gcd(a, b) · lcm(a, b) = a · b   ⇒   lcm(a, b) = (a·b) / gcd(a, b)
[/BOX]

[BOX]
**Example**
24 = 2³·3
36 = 2²·3²
LCM(24, 36) = 2³·3² = 72
Check: GCD·LCM = 12·72 = 864 = 24·36
[/BOX]

[DIAGRAM:prime-factorization-tree]`,
	},
	"5": {
		Title:    "Fractions & Ratios",
		Category: "Arithmetic & Number Systems",
		Intro: `Fractions represent parts of a whole and ratios compare quantities.

You’ll use equivalent fractions, operations, percentages, and proportions.

[BOX]
**Formulas**
a/b + c/d = (ad+bc)/(bd)
a/b · c/d = ac/(bd)
percentage = (part/whole)·100
[/BOX]

[BOX]
**Examples**
1/2 + 1/3 = 5/6
2/3 · 3/4 = 1/2
25% of 80 = 20
[/BOX]

[DIAGRAM:fraction]`,
	},
	"5-0": {
		Title:    "Equivalent fractions",
		Category: "Arithmetic & Number Systems",
		Intro: `Two fractions **a/b** and **c/d** (with b, d ≠ 0) represent the **same rational number** when **a·d = b·c**. We then say they are **equivalent**. For example 2/4 and 1/2 are equivalent because 2·2 = 4·1. So one rational number has infinitely many **representations** as a fraction; we usually prefer the one in **lowest terms** (numerator and denominator with no common factor other than ±1).

**How to simplify.** To reduce a/b to lowest terms, divide **both** numerator and denominator by their **GCD**: if g = gcd(a, b), then a/b = (a÷g)/(b÷g) and (a÷g) and (b÷g) have GCD 1. For example 18/24: gcd(18, 24) = 6, so 18/24 = 3/4.

**How to build equivalent fractions.** Multiply or divide **both** numerator and denominator by the **same nonzero** integer. So 2/3 = 4/6 = 6/9 = … and 12/18 = 2/3 (after dividing by 6). This is used to find a **common denominator** when adding or comparing fractions.

[BOX]
**Equivalence**
a/b = c/d  ⇔  a·d = b·c   (b, d ≠ 0)
Simplify: divide numerator and denominator by gcd(a, b)
[/BOX]

[BOX]
**Examples**
6/8 = 3/4  (gcd(6,8)=2)
10/15 = 2/3  (gcd(10,15)=5)
Check: 6·4 = 24 = 8·3; 10·3 = 30 = 15·2
[/BOX]

[DIAGRAM:fraction]`,
	},
	"5-1": {
		Title:    "Operations with fractions",
		Category: "Arithmetic & Number Systems",
		Intro: `**Addition and subtraction.** To add or subtract two fractions, first rewrite them with a **common denominator**. The simplest common denominator is often the **LCM** of the two denominators. Then add or subtract the **numerators** and keep the denominator. Formula: **a/b ± c/d = (ad ± bc)/bd** (you can always use the product bd as denominator, then simplify).

**Multiplication.** Multiply **numerators** together and **denominators** together: **(a/b)·(c/d) = (ac)/(bd)**. Simplify before or after multiplying to keep numbers smaller. No common denominator is needed.

**Division.** Dividing by a fraction is the same as **multiplying by its reciprocal**: **(a/b) ÷ (c/d) = (a/b)·(d/c) = (ad)/(bc)** (with b, c ≠ 0). So “flip” the divisor and multiply.

**Mixed numbers.** A mixed number like 2 1/3 means 2 + 1/3. Convert to an improper fraction (2 1/3 = 7/3) when you need to compute, then convert back if required.

[BOX]
**Formulas**
a/b + c/d = (ad + bc)/bd
a/b − c/d = (ad − bc)/bd
(a/b)·(c/d) = (ac)/(bd)
(a/b) ÷ (c/d) = (a/b)·(d/c) = (ad)/(bc)
[/BOX]

[BOX]
**Examples**
1/3 + 1/2 = 2/6 + 3/6 = 5/6
(2/5)·(3/4) = 6/20 = 3/10
(2/3) ÷ (4/5) = (2/3)·(5/4) = 10/12 = 5/6
[/BOX]

[DIAGRAM:fraction]`,
	},
	"5-2": {
		Title:    "Percentages",
		Category: "Arithmetic & Number Systems",
		Intro: `A percentage is “per 100”.

Conversions:
- x% = x/100
- x% of N = (x/100)·N
- A is what percent of B?  (A/B)·100%
- Increase by p%: multiply by (1 + p/100); decrease by p%: multiply by (1 − p/100)

[BOX]
**Formulas**
x% of N = (x/100)·N
[/BOX]

[BOX]
**Examples**
20% of 80 = 0.2·80 = 16
15 out of 60 = (15/60)·100% = 25%
Increase 50 by 10%: 50·1.10 = 55
Decrease 200 by 15%: 200·0.85 = 170
[/BOX]

[DIAGRAM:fraction]`,
	},
	"5-3": {
		Title:    "Proportions",
		Category: "Arithmetic & Number Systems",
		Intro: `A **proportion** is an **equality of two ratios**. We write **a : b = c : d** (or a/b = c/d) to mean that the two ratios are equal. Proportions are used in scaling, similar figures, and many real-world problems (e.g. “if 3 books cost 12 euros, how much do 5 books cost?”).

**Fundamental property (cross-multiplication).** For b, d ≠ 0 we have: **a/b = c/d** if and only if **a·d = b·c**. So the product of the **extremes** (a and d) equals the product of the **means** (b and c). This is the main tool to **solve** for an unknown in a proportion.

**Finding an unknown term.** In **a : b = x : d**, we get x = **(a·d)/b**. In **a : b = c : x**, we get x = **(b·c)/a**. Always check that denominators (b, d, or the unknown) are nonzero. **Direct proportionality:** y = k·x means y/x = k (constant); so ratios y/x are equal for corresponding pairs. **Inverse proportionality:** y = k/x means x·y = k; product is constant.

[BOX]
**Formulas**
a : b = c : d  ⇔  a/b = c/d  ⇔  a·d = b·c
Unknown in a : b = x : d  ⇒  x = (a·d)/b
Unknown in a : b = c : x  ⇒  x = (b·c)/a
[/BOX]

[BOX]
**Example**
3 : 4 = x : 12
Cross-multiply: 3·12 = 4·x  ⇒  36 = 4x  ⇒  x = 9
Check: 3/4 = 9/12  ✓
[/BOX]

[DIAGRAM:fraction]`,
	},

	// -------
	// Algebra
	// -------
	"6": {
		Title:    "Monomials & Polynomials",
		Category: "Algebra",
		Intro: `This section introduces **monomials** (products of a coefficient and powers of variables) and **polynomials** (sums of monomials). You will learn **operations** (add, subtract, multiply), the **degree** of a polynomial, and **special products** such as the square of a binomial and the difference of two squares. These are the basis for factoring and solving equations.

[BOX]
**Summary**
(a+b)² = a²+2ab+b²
(a−b)² = a²−2ab+b²
(a+b)(a−b) = a²−b²
[/BOX]

[BOX]
**Examples**
(x+3)² = x²+6x+9
(2x−1)(2x+1) = 4x²−1
[/BOX]

[DIAGRAM:square-binomial]`,
	},
	"6-0": {
		Title:    "Operations",
		Category: "Algebra",
		Intro: `A **monomial** is a product of a **coefficient** (a number) and **variables** raised to **non-negative integer** exponents, e.g. 3x²y, −2a, 7. A **polynomial** is a **sum** of monomials (the monomials are called **terms**), e.g. 2x³ − x + 5. **Like terms** have the same variable part (e.g. 2x² and 5x²); only like terms can be **combined** when adding or subtracting.

**Addition and subtraction.** Add or subtract the **coefficients** of like terms; leave the variable part unchanged. Example: 2x² + 5x² = 7x². For polynomials, group like terms and combine: (3x² + 2x − 1) + (x² − 4x + 5) = 4x² − 2x + 4.

**Multiplication.** For **monomial × monomial**: multiply coefficients and add exponents of each variable (a^m · a^n = a^(m+n)). Example: 3xy · 2x² = 6x³y. For **polynomial × polynomial**, use the **distributive law** (every term of the first times every term of the second), then combine like terms. Example: (x + 2)(x − 3) = x·x − 3x + 2x − 6 = x² − x − 6.

[BOX]
**Rules**
Like terms: same variables, same exponents → add coefficients
a^m · a^n = a^(m+n)
(a + b)(c + d) = ac + ad + bc + bd
[/BOX]

[BOX]
**Examples**
2x² + 5x² = 7x²
3xy · 2x² = 6x³y
(x + 2)(x − 3) = x² − 3x + 2x − 6 = x² − x − 6
[/BOX]

[DIAGRAM:square-binomial]`,
	},
	"6-1": {
		Title:    "Degree of a polynomial",
		Category: "Algebra",
		Intro: `The **degree** of a monomial is the **sum of the exponents** of all its variables (e.g. 4x²y³ has degree 2+3 = 5). The **degree of a polynomial** is the **maximum** degree among its terms.

**Definitions:**
- Degree of a monomial: sum of exponents (e.g., 4x²y³ has degree 2 + 3 = 5)
- Degree of a polynomial: maximum degree among its terms

[BOX]
Examples
P(x) = 2x³ − x + 5 has degree 3
Q(x, y) = 3x²y + 7y⁴ has degree 4 (because of y⁴)
[/BOX]

[DIAGRAM:square-binomial]`,
	},
	"6-2": {
		Title:    "Special products (e.g. square of a binomial)",
		Category: "Algebra",
		Intro: `**Special products** are algebraic identities that appear very often. Memorizing them saves time and helps with **factoring** (going from expanded form back to a product). The three most important are: **square of a sum**, **square of a difference**, and **difference of two squares**.

**Square of a sum:** (a + b)² = **a² + 2ab + b²**. So you get the squares of both terms **plus twice their product**. Do not write (a + b)² = a² + b² (that is wrong unless ab = 0).

**Square of a difference:** (a − b)² = **a² − 2ab + b²**. Same structure but the cross term is **minus** twice the product.

**Difference of two squares:** (a + b)(a − b) = **a² − b²**. The cross terms cancel, so you get only the difference of the squares. This is extremely useful for factoring expressions like x² − 9 or 4a² − 25b².

[DIAGRAM:square-binomial]

**Other useful ones:** (a + b)³ = a³ + 3a²b + 3ab² + b³; (a − b)³ = a³ − 3a²b + 3ab² − b³; (a + b + c)² = a² + b² + c² + 2ab + 2ac + 2bc.

[BOX]
**Formulas**
(a + b)² = a² + 2ab + b²
(a − b)² = a² − 2ab + b²
(a + b)(a − b) = a² − b²
[/BOX]

[BOX]
**Examples**
(2x + 1)² = 4x² + 4x + 1
(x − 3)(x + 3) = x² − 9
(3a − 2b)² = 9a² − 12ab + 4b²
[/BOX]`,
	},
	"7": {
		Title:    "Factoring Polynomials",
		Category: "Algebra",
		Intro: `**Factoring** is writing a polynomial as a **product** of simpler factors. It is the reverse of expanding and is essential for **solving equations** (setting each factor to zero), simplifying rational expressions, and finding roots. You will see **common factoring** (GCF), **Ruffini's rule** (synthetic division) to find linear factors, and **difference of squares** (and other special forms).

[BOX]
**Summary**
Common factor: ab+ac = a(b+c)
Difference of squares: a²−b² = (a+b)(a−b)
[/BOX]

[BOX]
**Examples**
3x²+6x = 3x(x+2)
x²−9 = (x+3)(x−3)
[/BOX]

[DIAGRAM:ruffini-flow]`,
	},
	"7-0": {
		Title:    "Common factoring",
		Category: "Algebra",
		Intro: `**Common factoring** (factoring out the **GCF** — Greatest Common Factor) means writing the polynomial as a **product** where one factor is common to every term. So you **pull out** that common factor and leave the remaining sum inside parentheses.

**Steps.** (1) Find the **GCD of the coefficients** of all terms. (2) For each variable that appears, take the **smallest exponent** with which it appears in any term. (3) The GCF is the product of that number and those variable powers. (4) Write each term as (GCF)·(remaining part) and then factor: **GCF·(term₁/GCF + term₂/GCF + …)**.

**Example:** In 6x²y + 9xy², coefficients 6 and 9 have gcd 3; x appears with exponents 2 and 1 (min 1); y with 1 and 2 (min 1). So GCF = 3xy. Then 6x²y + 9xy² = 3xy·2x + 3xy·3y = **3xy(2x + 3y)**. Always check by expanding back.

[BOX]
**Procedure**
GCF = gcd(coefficients) × (each variable)^(minimum exponent)
Polynomial = GCF · (remaining sum)
[/BOX]

[BOX]
**Examples**
6x²y + 9xy² = 3xy(2x + 3y)
4a³ − 8a² + 2a = 2a(2a² − 4a + 1)
[/BOX]

[DIAGRAM:ruffini-flow]`,
	},
	"7-1": {
		Title:    "Ruffini's Rule",
		Category: "Algebra",
		Intro: `Ruffini’s rule (synthetic division) divides P(x) by **(x − c)**. If **remainder = 0**, then (x − c) is a **factor** and c is a **root**. Choose c using the **rational root theorem** (candidates: ± divisors of constant / divisors of leading coefficient). Then P(x) = (x − c)·Q(x).

[DIAGRAM:ruffini-flow]

**How to choose candidates:**
- Rational root theorem: candidates are ±(divisors of constant term)/(divisors of leading coefficient)

[BOX]
Example
P(x) = x³ − 2x² − x + 2
Try c = 1 → remainder 0
So P(x) = (x − 1)(x² − x − 2) = (x − 1)(x − 2)(x + 1)
[/BOX]`,
	},
	"7-2": {
		Title:    "Difference of Squares",
		Category: "Algebra",
		Intro: `A **difference of two squares** has the form **A² − B²** and factors as **(A − B)(A + B)**. This is one of the most useful factoring patterns: as soon as you see two terms that are **perfect squares** separated by a minus sign, apply this formula.

**What counts as a square.** **A** and **B** can be numbers (9 = 3², 25 = 5²), variables (x², a⁴ = (a²)²), or products (4a² = (2a)², 25b² = (5b)²). So 4a² − 25b² = (2a)² − (5b)² = **(2a − 5b)(2a + 5b)**. **Warning:** A **sum** of squares (A² + B²) does **not** factor over the reals (it would need complex numbers).

**Procedure.** (1) Identify A² and B² (write each term as something squared). (2) A is the “positive” square root of the first term, B of the second. (3) Write (A − B)(A + B). Always check by expanding: (A−B)(A+B) = A² − B².

[BOX]
**Formula**
A² − B² = (A − B)(A + B)
[/BOX]

[BOX]
**Examples**
x² − 9 = (x − 3)(x + 3)
4a² − 25b² = (2a − 5b)(2a + 5b)
x⁴ − 16 = (x²)² − 4² = (x² − 4)(x² + 4) = (x−2)(x+2)(x²+4)
[/BOX]

[DIAGRAM:square-binomial]`,
	},
	"8": {
		Title:    "Linear Equations & Inequalities",
		Category: "Algebra",
		Intro: `**Linear equations** (first-degree equations) have the form ax + b = 0 with a ≠ 0; their solution is **x = −b/a**. **Literal equations** contain letters as parameters; you solve for one variable in terms of the others. These are the foundation for all algebraic problem solving and for systems of equations.

[BOX]
**Formulas**
ax + b = 0 ⇒ x = −b/a (a≠0)
[/BOX]

[BOX]
**Examples**
2x+6=0 ⇒ x=−3
3x−1>5 ⇒ x>2
[/BOX]

[DIAGRAM:linear-line]`,
	},
	"8-0": {
		Title:    "First-degree equations",
		Category: "Algebra",
		Intro: `A **first-degree** (or **linear**) equation in one variable x has the form **ax + b = 0** (or can be rearranged to it) with **a ≠ 0**. There is exactly **one solution**: **x = −b/a**. Equivalently, you can say: isolate x by moving all terms with x to one side and constants to the other, then divide by the coefficient of x.

**Steps.** (1) **Simplify** both sides (expand, combine like terms). (2) Move x-terms to one side and numbers to the other (add or subtract the same quantity from both sides). (3) **Divide** both sides by the coefficient of x. (4) **Check** by substituting the solution back into the original equation. If the equation has fractions, multiply both sides by the **LCM of the denominators** to clear them first.

**Equations that are always true** (e.g. 2x + 4 = 2(x + 2)) have **infinitely many** solutions; those that are never true (e.g. x + 1 = x + 2) have **no** solution.

[BOX]
**Standard form and solution**
ax + b = 0, a ≠ 0  ⇒  x = −b/a
[/BOX]

[BOX]
**Example**
3x − 5 = 2x + 1
3x − 2x = 1 + 5
x = 6
Check: 3·6 − 5 = 13, 2·6 + 1 = 13  ✓
[/BOX]

[DIAGRAM:linear-line]`,
	},
	"8-1": {
		Title:    "Literal equations",
		Category: "Algebra",
		Intro: `A **literal equation** is one that contains **parameters** — letters that stand for constants (e.g. a, b, k). The goal is to **solve for one variable** (often x) in terms of the others. The same steps as for numerical equations apply: isolate the desired variable by adding, subtracting, multiplying, or dividing both sides (treating the other letters as numbers). You must **track conditions**: for example, if you divide by an expression, that expression must be **nonzero**; if you take a square root, the radicand must be ≥ 0 when working in the reals.

**Typical forms.** Solve for x: **ax + b = c** ⇒ x = (c − b)/a, with **a ≠ 0**. Solve for x: **ax + b = cx + d** ⇒ ax − cx = d − b ⇒ x(a − c) = d − b ⇒ x = (d − b)/(a − c), with **a ≠ c**. When the equation has the variable in a denominator, multiply through by the denominator and then restrict the domain (denominator ≠ 0).

[BOX]
**Idea**
Treat parameters as constants; isolate the requested variable. State restrictions (e.g. denominator ≠ 0).
[/BOX]

[BOX]
**Example**
Solve for x: 2x + a = 4
2x = 4 − a
x = (4 − a)/2
(No restriction: solution valid for all a.)
[/BOX]

[DIAGRAM:linear-line]`,
	},
	"9": {
		Title:    "Quadratic Equations",
		Category: "Algebra",
		Intro: `**Quadratic equations** have the form **ax² + bx + c = 0** with **a ≠ 0**. They have at most **two** real solutions. You will learn **complete** and **incomplete** quadratics (missing b or c), the **discriminant** Δ = b² − 4ac (which tells how many real roots there are), the **quadratic formula**, and **factoring** trinomials to solve quickly when possible.

[BOX]
**Formulas**
ax²+bx+c=0
Δ=b²−4ac
x=(−b±√Δ)/(2a)
[/BOX]

[BOX]
**Examples**
x²−5x+6=0 ⇒ Δ=1, x=2 or x=3
[/BOX]

[DIAGRAM:parabola]`,
	},
	"9-0": {
		Title:    "Complete and incomplete quadratics",
		Category: "Algebra",
		Intro: `A **complete** quadratic has the form **ax² + bx + c = 0** with **a ≠ 0** and all three coefficients present. An **incomplete** quadratic is missing the linear term (**ax² + c = 0**) or the constant term (**ax² + bx = 0**). Incomplete ones are solved without the full quadratic formula.

**Type 1: ax² + c = 0.** Isolate x²: x² = −c/a. So **x = ±√(−c/a)**. In the **reals**, we need **−c/a ≥ 0** (so −c/a is non-negative). Example: 2x² − 8 = 0 ⇒ x² = 4 ⇒ x = ±2.

**Type 2: ax² + bx = 0.** Factor out x: **x(ax + b) = 0**. So either **x = 0** or **ax + b = 0**, i.e. **x = −b/a**. So the two solutions are always **0** and **−b/a**. Example: 3x² + 6x = 0 ⇒ 3x(x + 2) = 0 ⇒ x = 0 or x = −2.

[BOX]
**Formulas**
ax² + c = 0  ⇒  x = ±√(−c/a)   (real if −c/a ≥ 0)
ax² + bx = 0  ⇒  x(ax + b) = 0  ⇒  x = 0  or  x = −b/a
[/BOX]

[BOX]
**Examples**
2x² − 8 = 0  ⇒  x² = 4  ⇒  x = ±2
3x² + 6x = 0  ⇒  3x(x+2) = 0  ⇒  x = 0 or x = −2
[/BOX]

[DIAGRAM:parabola]`,
	},
	"9-1": {
		Title:    "The Discriminant (Δ)",
		Category: "Algebra",
		Intro: `For the quadratic **ax² + bx + c = 0** (a ≠ 0), the **discriminant** is **Δ = b² − 4ac**. It tells you **how many real solutions** the equation has and appears under the square root in the **quadratic formula**: **x = (−b ± √Δ)/(2a)**.

**Interpretation.** **Δ > 0:** two **distinct** real roots (the parabola crosses the x-axis twice). **Δ = 0:** one real root (a **double** root; the parabola is tangent to the x-axis). **Δ < 0:** **no** real roots (the parabola does not cross the x-axis; the two complex roots are conjugate). So before solving, compute Δ to know what to expect. The roots are **rational** only when Δ is a perfect square (and a, b, c are rational).

[DIAGRAM:discriminant-table]

**Quadratic formula.** Always works for any quadratic: **x = (−b ± √(b² − 4ac))/(2a)**. Write the equation in the form ax² + bx + c = 0, identify a, b, c, then substitute. Simplify √Δ when possible.

[BOX]
**Formulas**
Δ = b² − 4ac
x = (−b ± √Δ)/(2a)
Δ > 0: two roots; Δ = 0: one (double) root; Δ < 0: no real roots
[/BOX]

[BOX]
**Example**
x² − 5x + 6 = 0  ⇒  a=1, b=−5, c=6
Δ = 25 − 24 = 1
x = (5 ± 1)/2  ⇒  x = 3 or x = 2
[/BOX]`,
	},
	"9-2": {
		Title:    "Factoring quadratic trinomials",
		Category: "Algebra",
		Intro: `When a quadratic **factors nicely**, solving by factoring is often the **fastest** method: you get **(x − r₁)(x − r₂) = 0**, so **x = r₁** or **x = r₂**. For **x² + sx + p** (leading coefficient 1), find two numbers whose **sum** is **s** and whose **product** is **p**. Then x² + sx + p = (x + α)(x + β) where α + β = s and α·β = p. So the roots are −α and −β.

**General trinomial ax² + bx + c.** You can try factoring by grouping or by finding pairs (r, s) such that r·s = ac and r + s = b, then splitting the middle term. If no simple factorization exists, use the **quadratic formula**. **Perfect square:** x² + 2qx + q² = (x + q)²; then the equation has a double root x = −q.

**Procedure.** (1) Write in standard form (right-hand side 0). (2) Try to factor (look for sum/product or grouping). (3) Set each factor to 0 and solve. (4) If factoring is hard, use x = (−b ± √Δ)/(2a).

[BOX]
**For x² + sx + p**
Find α, β with α + β = s and α·β = p. Then x² + sx + p = (x + α)(x + β). Roots: −α, −β.
[/BOX]

[BOX]
**Example**
x² + 5x + 6 = 0. Need α+β = 5, αβ = 6 → α=2, β=3.
(x + 2)(x + 3) = 0  ⇒  x = −2 or x = −3
[/BOX]

[DIAGRAM:parabola]`,
	},
	"10": {
		Title:    "Systems of Equations",
		Category: "Algebra",
		Intro: `A **system of equations** is a set of equations that must be satisfied **at the same time**. You look for values of the unknowns (e.g. x and y) that satisfy **every** equation. For **linear** systems of two equations in two unknowns there are three main methods: **substitution**, **comparison**, and **Cramer's rule** (determinants). The solution (if unique) is the intersection of two lines in the plane.

[BOX]
**Summary**
Substitution: isolate one variable, substitute
Cramer: x=Dx/D, y=Dy/D
[/BOX]

[BOX]
**Examples**
{x+y=5, x−y=1} ⇒ x=3, y=2
[/BOX]

[DIAGRAM:two-lines]`,
	},
	"10-0": {
		Title:    "Substitution",
		Category: "Algebra",
		Intro: `**Substitution** works by solving **one** equation for **one** variable (e.g. express y in terms of x), then **substituting** that expression into the **other** equation. You get a single equation in one unknown; solve it, then back-substitute to get the other variable.

**Steps.** (1) Choose one equation and solve for one variable (pick the one that looks easiest, e.g. if one equation is x − y = 1 then x = 1 + y). (2) Substitute into the other equation (every occurrence of that variable is replaced by the expression). (3) Solve the resulting equation. (4) Use the value found to get the other variable from the expression you had. (5) Check by plugging both values into the original equations.

**When to use.** Substitution is convenient when one equation is already solved for a variable or can be solved easily (e.g. no coefficients in front of the variable).

[BOX]
**Procedure**
1) Solve one equation for one variable.
2) Substitute into the other equation.
3) Solve; then back-substitute.
[/BOX]

[BOX]
**Example**
{ 2x + y = 8,  x − y = 1 }
From second: x = 1 + y. Substitute: 2(1 + y) + y = 8 ⇒ 2 + 3y = 8 ⇒ y = 2. Then x = 1 + 2 = 3. Solution: (3, 2).
[/BOX]

[DIAGRAM:two-lines]`,
	},
	"10-1": {
		Title:    "Comparison",
		Category: "Algebra",
		Intro: `The **comparison** (or **equating**) method: solve **both** equations for the **same** variable (e.g. y in terms of x), then **set the two expressions equal**. You get one equation in one unknown. Solve it, then substitute back to get the other variable.

**Steps.** (1) From the first equation, express one variable (e.g. y) in terms of the other (x). (2) From the second equation, express the same variable (y) in terms of x. (3) Set the two expressions equal: you get an equation in x only. (4) Solve for x. (5) Plug x into either expression to get y. This is especially handy when both equations are already (or easily) in the form y = ….

**Relation to substitution.** Comparison is like substitution where the “substituted” expression comes from the second equation instead of the first; the idea is the same (reduce to one variable).

[BOX]
**Procedure**
1) Solve both equations for the same variable (e.g. y).
2) Set the two expressions equal.
3) Solve for the remaining variable; then find the other.
[/BOX]

[DIAGRAM:two-lines]

[BOX]
**Example**
2x + y = 8 ⇒ y = 8 − 2x.  x − y = 1 ⇒ y = x − 1.
8 − 2x = x − 1 ⇒ 3x = 9 ⇒ x = 3. Then y = 3 − 1 = 2. Solution: (3, 2).
[/BOX]`,
	},
	"10-2": {
		Title:    "Cramer's method",
		Category: "Algebra",
		Intro: `Cramer’s rule gives the solution of a **2×2** linear system using **determinants**. For **a₁x + b₁y = c₁**, **a₂x + b₂y = c₂**, **Det = a₁b₂ − a₂b₁**. If **Det ≠ 0**: **x = (c₁b₂ − c₂b₁)/Det**, **y = (a₁c₂ − a₂c₁)/Det**. Replace the first column with (c₁,c₂) for x, second for y. If Det = 0 the system has no unique solution.

[BOX]
**Formulas (2×2)**
Det = a₁b₂ − a₂b₁
x = (c₁b₂ − c₂b₁) / Det
y = (a₁c₂ − a₂c₁) / Det   (Det ≠ 0)
[/BOX]

[BOX]
**Example**
{ 2x + y = 8,  x − y = 1 }  ⇒  Det = 2·(−1)−1·1 = −3
x = (8·(−1)−1·1)/(−3) = 3,  y = (2·1−1·8)/(−3) = 2
[/BOX]

[DIAGRAM:two-lines]`,
	},

	// -------------------------
	// Geometry & Trigonometry
	// -------------------------
	"11": {
		Title:    "Plane Geometry",
		Category: "Geometry & Trigonometry",
		Intro: `**Plane geometry** studies figures in **two dimensions**: **segments** (length, midpoint), **angles** (complementary, supplementary, vertical, bisector), **triangles** (angle sum 180°, inequality, area), **quadrilaterals** (trapezoid, parallelogram, rectangle, rhombus, square), and **polygons** (sum of interior angles, regular polygons). These are the basis for congruence, similarity, and trigonometry.

[BOX]
**Formulas**
Triangle area = (1/2)·b·h
Sum of angles in a triangle = 180°
Regular polygon interior angle = (n−2)·180°/n
[/BOX]

[BOX]
**Examples**
Triangle b=6 h=4 ⇒ A=12
Hexagon interior angle = 120°
[/BOX]

[DIAGRAM:geometry-formulary]`,
	},
	"11-0": {
		Title:    "Segments",
		Category: "Geometry & Trigonometry",
		Intro: `A **segment** is the set of points on a line **between** two given points **A** and **B**, including A and B. We write **AB** (or **BA**) for the segment; **AB** also often denotes its **length** (the distance from A to B). In coordinate geometry, if A = (x₁,y₁) and B = (x₂,y₂), then **AB = √[(x₂−x₁)² + (y₂−y₁)²]**.

[DIAGRAM:segment]

**Midpoint.** The **midpoint M** of segment AB is the point that is **equidistant** from A and B: **AM = MB**. So M lies halfway between A and B. In coordinates: **M = ((x₁+x₂)/2, (y₁+y₂)/2)**.

**Segment addition.** If point **C** is **between** A and B (on the segment AB), then **AB = AC + CB**. So the whole length is the sum of the two parts. This is used to set up equations when a segment is split into parts.

[BOX]
**Formulas**
Length: AB = √[(x₂−x₁)² + (y₂−y₁)²]
Midpoint: M = ((x₁+x₂)/2, (y₁+y₂)/2)
If C between A and B: AB = AC + CB
[/BOX]

[BOX]
**Example**
If AB = 10 and M is the midpoint, then AM = MB = 5.
[/BOX]`,
	},
	"11-1": {
		Title:    "Angles",
		Category: "Geometry & Trigonometry",
		Intro: `An **angle** is formed by two **rays** (half-lines) that share the same **vertex** (origin). Angles are measured in **degrees** (°) or **radians**. **Complementary** angles add up to **90°**; **supplementary** angles add up to **180°**. So the complement of 35° is 55°; the supplement of 100° is 80°.

[DIAGRAM:angle]

**Vertical angles.** When two lines intersect, the pairs of **opposite** (vertical) angles are **equal**. So if one angle is 40°, the angle opposite to it is also 40°; the other two (supplementary to 40°) are 140° each.

**Angle bisector.** A ray that splits an angle into **two equal** angles is called an **angle bisector**. So the bisector of a 60° angle creates two 30° angles. In triangles, the **incenter** is where the three angle bisectors meet.

[BOX]
**Key facts**
Complementary: α + β = 90°
Supplementary: α + β = 180°
Vertical angles are equal. Bisector → two equal angles.
[/BOX]

[BOX]
**Example**
Angle 35° → complement 55° (35° + 55° = 90°). Supplement of 35° is 145°.
[/BOX]`,
	},
	"11-2": {
		Title:    "Triangles",
		Category: "Geometry & Trigonometry",
		Intro: `A **triangle** is a polygon with **three sides** and **three angles**. The **sum of the interior angles** of any triangle is **180°**. So if two angles are known, the third is 180° minus their sum. The **triangle inequality** says: each side is **less than** the sum of the other two (e.g. a < b + c). So three positive numbers are sides of a triangle if and only if the sum of any two is greater than the third.

[DIAGRAM:triangle]

**Area.** The area of a triangle is **A = (1/2)·base·height**, where the **height** is the perpendicular distance from the vertex opposite the base to the line containing the base. So if base = 10 and height = 6, then A = 30. **Heron’s formula** gives the area from the three sides: A = √[s(s−a)(s−b)(s−c)] where s = (a+b+c)/2 is the semiperimeter.

**Special triangles.** **Right triangle:** one angle 90°; **isosceles:** two sides equal; **equilateral:** all sides and angles equal (each angle 60°).

[BOX]
**Formulas**
Sum of angles = 180°
Triangle inequality: a < b + c, b < a + c, c < a + b
Area: A = (1/2)·base·height
[/BOX]

[BOX]
**Example**
Base = 10, height = 6  ⇒  A = (10·6)/2 = 30
[/BOX]`,
	},
	"11-3": {
		Title:    "Quadrilaterals",
		Category: "Geometry & Trigonometry",
		Intro: `A **quadrilateral** is a polygon with **four sides**. The **sum of the interior angles** of any quadrilateral is **360°**. Special types (each with extra properties): **Trapezoid** — at least one pair of parallel sides; **parallelogram** — both pairs of opposite sides parallel (and then opposite sides are equal, opposite angles equal, consecutive angles supplementary, diagonals bisect each other); **rectangle** — parallelogram with all angles 90° (diagonals equal); **rhombus** — parallelogram with all four sides equal (diagonals perpendicular); **square** — rectangle and rhombus (all sides equal, all angles 90°).

[DIAGRAM:quadrilateral]

**Hierarchy.** Every rectangle is a parallelogram; every rhombus is a parallelogram; every square is both a rectangle and a rhombus. **Area:** parallelogram = base·height; rectangle = length·width; trapezoid = (1/2)·(sum of parallel sides)·height.

[BOX]
**Facts**
Quadrilateral: angle sum = 360°
Parallelogram: opposite sides parallel and equal, diagonals bisect
Rectangle: parallelogram with 90° angles. Square: all sides equal, 90°
[/BOX]

[BOX]
**Example**
In a parallelogram, consecutive angles are supplementary (sum 180°).
[/BOX]`,
	},
	"11-4": {
		Title:    "Polygons",
		Category: "Geometry & Trigonometry",
		Intro: `A **polygon** is a closed figure formed by a finite chain of **line segments** (sides); the segments meet at **vertices**. A polygon is **convex** if no line through a side enters the interior. For a convex **n-gon** (n sides), the **sum of the interior angles** is **(n − 2)·180°**. So triangle: 180°; quadrilateral: 360°; pentagon: 540°; hexagon: 720°.

[DIAGRAM:polygon]

**Regular polygon.** All sides and all angles are equal. Each interior angle of a regular n-gon is **((n − 2)·180°)/n**. So regular hexagon: each angle = 720°/6 = **120°**. The **exterior angle** (one at each vertex, if you extend one side) of a regular n-gon is **360°/n**; interior + exterior = 180° at each vertex.

[BOX]
**Formulas (convex n-gon)**
Sum of interior angles = (n − 2)·180°
Each interior angle (regular) = (n − 2)·180° / n
[/BOX]

[BOX]
**Example**
Hexagon (n=6): sum = 4·180° = 720°. Regular hexagon: each angle = 120°.
[/BOX]`,
	},
	"12": { Title: "Congruence & Similarity", Category: "Geometry & Trigonometry", Intro: `Congruence is “same shape and same size”. Similarity is “same shape, scaled”.

[BOX]
**Summary**
Pythagoras: a²+b²=c²
Similar triangles: corresponding sides proportional
[/BOX]

[BOX]
**Examples**
Right triangle legs 3,4 ⇒ hypotenuse=5
[/BOX]

[DIAGRAM:triangle-criteria]` },
	"12-0": {
		Title:    "Criteria for triangles",
		Category: "Geometry & Trigonometry",
		Intro: `**Congruence** of triangles: two triangles are **congruent** if there is a one-to-one correspondence between their vertices such that all three sides and all three angles match. You do **not** need to check all six: **SSS** (three sides equal), **SAS** (two sides and the **included** angle equal), or **ASA/AAS** (two angles and a side equal) guarantee congruence. **Warning:** SSA (two sides and a non-included angle) does **not** always determine a unique triangle.

[DIAGRAM:triangle-criteria]

**Similarity** of triangles: two triangles are **similar** if corresponding angles are equal (and then corresponding sides are automatically in proportion), or if the three sides are in proportion (**SSS proportional**), or two sides are in proportion and the **included** angle is equal (**SAS proportional**). The **AA** criterion (two angles equal) is enough because the third angle is then determined. So if two triangles have angles (30°, 60°, 90°) they are similar.

[BOX]
**Congruence:** SSS, SAS, ASA/AAS. **Similarity:** AA, SSS proportional, SAS proportional.
[/BOX]

[BOX]
**Example**
Triangles with angles (30°, 60°, 90°) are similar by AA (and thus sides proportional).
[/BOX]`,
	},
	"12-1": {
		Title:    "Pythagoras' and Euclid's theorems",
		Category: "Geometry & Trigonometry",
		Intro: `For right triangles, Pythagoras connects the side lengths.

[DIAGRAM:pythagoras-euclid]

[BOX]
Pythagoras
a² + b² = c²  (c is the hypotenuse)
[/BOX]

Euclid’s theorems (right triangle, altitude to the hypotenuse):
- a² = c·p, b² = c·q, where p and q are projections on the hypotenuse (p + q = c)
- h² = p·q

[BOX]
Example
If a = 3 and b = 4, then c = 5 because 3² + 4² = 25.
[/BOX]`,
	},
	"13": {
		Title:    "Circle & Pi",
		Category: "Geometry & Trigonometry",
		Intro: `The **circle** is the set of points at a fixed distance **r** (the **radius**) from a point **O** (the **center**). You will use **circumference** C = 2πr, **area** A = πr², **tangents** (line touching the circle at one point, perpendicular to radius), and **secants** (line cutting the circle in two points) with the **power of a point**.

[BOX]
**Formulas**
C=2πr
A=πr²
[/BOX]

[BOX]
**Examples**
r=5 ⇒ C=10π≈31.4, A=25π≈78.5
[/BOX]

[DIAGRAM:circle]`,
	},
	"13-0": {
		Title:    "Circumference",
		Category: "Geometry & Trigonometry",
		Intro: `The circumference is the “perimeter” of a circle.

[BOX]
Formula
C = 2πr
[/BOX]

[BOX]
Example
r = 5 ⇒ C = 10π ≈ 31.42
[/BOX]

[DIAGRAM:circle]`,
	},
	"13-1": {
		Title:    "Area",
		Category: "Geometry & Trigonometry",
		Intro: `The **area** of a circle of radius **r** is **A = πr²**. So the area is **proportional to the square** of the radius: if you double the radius, the area is multiplied by 4. The formula can be derived by “slicing” the circle into many narrow sectors and rearranging them into a shape that approximates a rectangle of height r and base πr.

**Sector area.** For a sector with central angle θ (in **radians**), the area of the sector is **A_sector = (1/2)·r²·θ** (it is the fraction θ/(2π) of the full circle area πr²). So half a circle (θ = π) has area (1/2)πr².

[BOX]
**Formulas**
Circle area: A = πr²
Sector area (θ in radians): A = (1/2)r²θ = (θ/(2π))·πr²
[/BOX]

[BOX]
**Example**
r = 5  ⇒  A = 25π ≈ 78.54
[/BOX]

[DIAGRAM:circle]`,
	},
	"13-2": {
		Title:    "Tangents",
		Category: "Geometry & Trigonometry",
		Intro: `A **tangent** to a circle is a line that touches the circle at **exactly one point** (the **point of tangency**). The **radius** drawn to the point of tangency is **perpendicular** to the tangent. So if you know the radius to the point of contact, the tangent line is the line through that point that is perpendicular to the radius.

[DIAGRAM:tangent-secant]

**Tangent segments from an external point.** If **P** is outside the circle and **PT** and **PS** are the two segments from P to the points of tangency on the circle, then **PT = PS** (the two tangent segments from an external point are **equal**). This is useful for solving problems where a point is connected to a circle by two tangents.

[BOX]
**Key facts**
Radius to point of tangency ⊥ tangent
From external P, the two tangent segments to the circle are equal: PT = PS
[/BOX]

[BOX]
**Example**
From external point P, if PT and PS are tangents, then PT = PS.
[/BOX]`,
	},
	"13-3": {
		Title:    "Secants",
		Category: "Geometry & Trigonometry",
		Intro: `A **secant** is a line that **intersects** the circle in **two points**. **Power of a point:** If **P** is a point and a line through P intersects the circle at points **A** and **B** (with A between P and B if P is outside), then the product **PA · PB** depends only on **P** and the circle, **not** on the choice of the secant. So for any other secant through P meeting the circle at C and D, we have **PA·PB = PC·PD**. If P is **outside** the circle and **PT** is a tangent segment, then **PA·PB = PT²** (tangent-secant power).

This “power” is used to find unknown lengths when you have intersecting chords or secants. **Chord-chord:** If two chords intersect at P inside the circle, then PA·PB = PC·PD.

[BOX]
**Power of a point (P outside)**
PA · PB = constant for any secant through P. For tangent PT: PA·PB = PT²
[/BOX]

[BOX]
**Example**
Secant through P: PA = 3, PB = 12  ⇒  PA·PB = 36. Any other secant through P gives the same product.
[/BOX]

[DIAGRAM:tangent-secant]`,
	},
	"14": {
		Title:    "Solid Geometry",
		Category: "Geometry & Trigonometry",
		Intro: `**Solid geometry** studies **three-dimensional** figures: **prisms** (two parallel congruent bases, volume = base area × height), **pyramids** (one base, vertex, volume = (1/3)×base×height), **cylinders** (circular bases, V = πr²h), **cones** (circular base, V = (1/3)πr²h), and **spheres** (V = (4/3)πr³, surface area = 4πr²). You will use these formulas for volume and lateral/total surface area.

[BOX]
**Formulas**
Prism V=B·h
Pyramid V=(1/3)B·h
Cylinder V=πr²h
Cone V=(1/3)πr²h
Sphere V=(4/3)πr³
[/BOX]

[BOX]
**Examples**
Cylinder r=3 h=10 ⇒ V=90π≈283
[/BOX]

[DIAGRAM:geometry-formulary]`,
	},
	"14-0": {
		Title:    "Prisms",
		Category: "Geometry & Trigonometry",
		Intro: `A **prism** is a solid with **two parallel**, **congruent** faces (the **bases**) and **lateral faces** that are parallelograms. If the lateral edges are perpendicular to the bases, the prism is **right**; then the lateral faces are rectangles. The **volume** is **V = (base area)·h**, where **h** is the height (perpendicular distance between the bases). So the volume is the same as for a cylinder with the same base area and height.

[DIAGRAM:geometry-formulary]

**Lateral surface area** (right prism): the sum of the areas of the lateral faces equals **(perimeter of base)·h**. **Total surface area** = 2·(base area) + lateral area. So for a rectangular prism (box) with dimensions ℓ, w, h: V = ℓwh and surface area = 2(ℓw + ℓh + wh).

[BOX]
**Formulas**
Volume: V = (base area)·h
Lateral area (right prism): (base perimeter)·h
[/BOX]

[BOX]
**Example**
Base area = 12, height = 5  ⇒  V = 60
[/BOX]`,
	},
	"14-1": {
		Title:    "Pyramids",
		Category: "Geometry & Trigonometry",
		Intro: `A **pyramid** is a solid with a **polygonal base** and a **vertex** (apex) not in the plane of the base; the lateral faces are triangles that meet at the vertex. The **height** **h** is the perpendicular distance from the vertex to the base plane. The **volume** is **V = (1/3)·(base area)·h** — one third of the volume of a prism with the same base and height. So the pyramid “fits” three times into the corresponding prism.

**Lateral surface area** is the sum of the areas of the triangular lateral faces. For a **regular** pyramid (base is a regular polygon and the apex is above the center), the lateral faces are congruent isosceles triangles; you can find their area using the **slant height** (from apex to the midpoint of a base edge). **Total surface area** = base area + lateral area.

[BOX]
**Formula**
V = (1/3)·(base area)·h
[/BOX]

[BOX]
**Example**
Base area = 30, height = 9  ⇒  V = (1/3)·30·9 = 90
[/BOX]

[DIAGRAM:geometry-formulary]`,
	},
	"14-2": {
		Title:    "Cylinders",
		Category: "Geometry & Trigonometry",
		Intro: `A **right circular cylinder** has two **parallel circular bases** of radius **r** and **height** **h** (the perpendicular distance between the bases). The lateral surface is a rectangle “wrapped” around: one side is the height h, the other is the circumference of the base 2πr. So **volume** **V = πr²h** (base area πr² times height). **Lateral surface area** = **2πrh**. **Total surface area** (including the two circular bases) = **2πr² + 2πrh** = 2πr(r + h).

So the cylinder is like a “prism” with a circular base: V = (base area)·h with base area = πr². The formulas are used for cans, pipes, and any round solid with parallel circular cross-sections.

[BOX]
**Formulas**
V = πr²h
Lateral area = 2πrh. Total surface area = 2πr² + 2πrh
[/BOX]

[BOX]
**Example**
r = 2, h = 5  ⇒  V = π·4·5 = 20π
[/BOX]

[DIAGRAM:geometry-formulary]`,
	},
	"14-3": {
		Title:    "Cones",
		Category: "Geometry & Trigonometry",
		Intro: `A **right circular cone** has a **circular base** of radius **r** and a **vertex** (apex) on the line through the center of the base, perpendicular to the base. The **height** **h** is the distance from the vertex to the base. The **slant height** **a** (or ℓ) is the distance from the vertex to a point on the base circle; by Pythagoras, **a² = r² + h²**. The **volume** is **V = (1/3)πr²h** — one third of the volume of the cylinder with the same base and height.

[DIAGRAM:geometry-formulary]

**Lateral surface area** (the curved part) = **πr·a** (if you “unroll” the cone you get a sector of a circle of radius a and arc length 2πr). **Total surface area** = πr² + πra = πr(r + a).

[BOX]
**Formulas**
V = (1/3)πr²h
a² = r² + h². Lateral area = πr·a
[/BOX]

[BOX]
**Example**
r = 3, h = 4  ⇒  V = (1/3)π·9·4 = 12π. Slant height a = √(9+16) = 5.
[/BOX]`,
	},
	"14-4": {
		Title:    "Spheres (Volume & Surface Area)",
		Category: "Geometry & Trigonometry",
		Intro: `A **sphere** is the set of all points in space at a fixed distance **r** (the **radius**) from a given point (the **center**). So it is the “surface” of a ball. The **surface area** is **S = 4πr²** — four times the area of a great circle (circle of radius r through the center). The **volume** of the **ball** (solid sphere) is **V = (4/3)πr³**. So the volume is (4/3) times the volume of a cylinder that circumscribes the sphere (cylinder of radius r and height 2r has volume 2πr³; the sphere is two-thirds of that).

**Useful relation:** The derivative of the volume with respect to r is dV/dr = 4πr² = surface area. So the surface area is the “rate of change” of volume as the radius grows.

[BOX]
**Formulas**
Surface area: S = 4πr²
Volume: V = (4/3)πr³
[/BOX]

[BOX]
**Example**
r = 3  ⇒  S = 4π·9 = 36π,  V = (4/3)π·27 = 36π
[/BOX]

[DIAGRAM:solid-sphere]`,
	},
	"15": {
		Title:    "Goniometry & Trigonometry",
		Category: "Geometry & Trigonometry",
		Intro: `**Trigonometry** studies the link between **angles** and **ratios** of sides in right triangles, and the **unit circle** (radius 1) where each angle corresponds to a point (cos θ, sin θ). You will use the **unit circle**, **radians** (180° = π rad), **sine**, **cosine**, **tangent**, the identity sin²θ + cos²θ = 1, and the **law of sines** and **law of cosines** for non-right triangles.

[BOX]
**Formulas**
sin²θ+cos²θ=1
Law of sines: a/sinA=b/sinB=c/sinC
Law of cosines: c²=a²+b²−2ab·cosC
[/BOX]

[BOX]
**Examples**
sin(30°)=1/2
cos(60°)=1/2
[/BOX]

[DIAGRAM:unit-circle]`,
	},
	"15-0": {
		Title:    "The Unit Circle",
		Category: "Geometry & Trigonometry",
		Intro: `The **unit circle** is the circle of **radius 1** with center at the **origin** (0, 0). Each **angle** θ (measured from the positive x-axis, counterclockwise) corresponds to a **unique point** on the circle: the point at distance 1 from the origin in that direction. The **coordinates** of that point are **(cos θ, sin θ)**. So **cos θ** is the x-coordinate and **sin θ** is the y-coordinate. This defines sine and cosine for **any** angle (not only acute).

[DIAGRAM:unit-circle]

**Radians.** Angles can be measured in **radians**: the angle (in rad) is the **arc length** on the unit circle. So **360° = 2π rad**, **180° = π rad**, **90° = π/2 rad**. To convert: **degrees → radians** multiply by π/180; **radians → degrees** multiply by 180/π.

[BOX]
**Conversions**
360° = 2π rad,  180° = π rad,  90° = π/2 rad
Point on unit circle: (cos θ, sin θ)
[/BOX]`,
	},
	"15-1": {
		Title:    "Sine, Cosine, Tangent",
		Category: "Geometry & Trigonometry",
		Intro: `On the **unit circle**, for angle θ: **cos θ** = x-coordinate, **sin θ** = y-coordinate. So the point is (cos θ, sin θ). **Tangent** is **tan θ = sin θ / cos θ** (when cos θ ≠ 0). In a **right triangle** with angle θ, opposite side a, adjacent b, hypotenuse c: sin θ = a/c, cos θ = b/c, tan θ = a/b.

**Fundamental identity:** **sin²θ + cos²θ = 1** (from x² + y² = 1 on the unit circle). So sin θ = ±√(1 − cos²θ) and cos θ = ±√(1 − sin²θ); the sign depends on the quadrant. **Special angles** (memorize): 0, π/6 (30°), π/4 (45°), π/3 (60°), π/2 (90°) — use the unit circle or the 30-60-90 and 45-45-90 triangles to get exact values.

[DIAGRAM:trig-graphs]

[BOX]
**Identity**
sin²θ + cos²θ = 1
tan θ = sin θ / cos θ
[/BOX]

[BOX]
**Special angles (rad)**
sin(0)=0, cos(0)=1; sin(π/6)=1/2, cos(π/6)=√3/2
sin(π/4)=cos(π/4)=√2/2; sin(π/2)=1, cos(π/2)=0
[/BOX]`,
	},
	"15-2": {
		Title:    "Law of Sines/Cosines",
		Category: "Geometry & Trigonometry",
		Intro: `For **any** triangle (not necessarily right) with sides **a, b, c** opposite angles **A, B, C**:

**Law of Sines:** **a/sin A = b/sin B = c/sin C** (each ratio equals 2R, where R is the circumradius). Use it when you know **two angles and a side** (AAS or ASA) or **two sides and an angle opposite one of them** (SSA — be careful: sometimes two triangles, one, or none). **Law of Cosines:** **a² = b² + c² − 2bc·cos A** (and similarly for b² and c²). Use it when you know **three sides** (SSS) or **two sides and the included angle** (SAS). It generalizes the Pythagorean theorem: when A = 90°, cos A = 0 so a² = b² + c².

[BOX]
**Law of Sines:** a/sin A = b/sin B = c/sin C
**Law of Cosines:** a² = b² + c² − 2bc·cos A
[/BOX]

[BOX]
**Example (cosine)**
b=5, c=7, A=60°: a² = 25+49−2·5·7·(1/2) = 74−35 = 39  ⇒  a = √39
[/BOX]

[DIAGRAM:triangle]`,
	},

	// -------------------------
	// Pre-Calculus & Analysis
	// -------------------------
	"16": {
		Title:    "Functions & Domain",
		Category: "Pre-Calculus & Analysis",
		Intro: `**Functions** assign to each input (e.g. x) exactly one output (e.g. y = f(x)). The **domain** is the set of allowed inputs; the **range** is the set of possible outputs. You will study **real functions of a real variable**, **classification** (injective, surjective, even/odd), and **how to find the domain** (denominators ≠ 0, even roots ≥ 0, log argument > 0).

[BOX]
**Summary**
Domain restrictions: denominator≠0, even root≥0, log argument>0
[/BOX]

[BOX]
**Examples**
f(x)=1/(x−2) ⇒ domain: x≠2
f(x)=√(x−1) ⇒ domain: x≥1
[/BOX]

[DIAGRAM:graph-transformations]`,
	},
	"16-0": {
		Title:    "Real functions of a real variable",
		Category: "Pre-Calculus & Analysis",
		Intro: `A **real function of a real variable** is a rule that assigns to each real number **x** in a set **D** (the **domain**) exactly one real number **f(x)**. We write **y = f(x)**; the **graph** is the set of points **(x, f(x))** in the plane. The **range** (or image) is the set of all values f(x) as x runs over the domain.

**Examples.** **f(x) = x²**: domain ℝ, range [0, +∞). **g(x) = 1/x**: domain ℝ \\ {0} (all reals except 0), range ℝ \\ {0}. **h(x) = √x**: domain [0, +∞), range [0, +∞). The domain is determined by the **expression**: no division by zero, no even root of a negative number (in ℝ), no log of a non-positive number. The **codomain** is the set we consider for outputs (often ℝ); the range is the actual set of outputs.

[BOX]
**Notation**
y = f(x),  x ∈ Domain(f) ⊆ ℝ.  Graph = {(x, f(x))}
[/BOX]

[BOX]
**Examples**
f(x)=x²: domain ℝ, range [0, +∞).  g(x)=1/x: domain ℝ\\{0}
[/BOX]

[DIAGRAM:domain-graph]`,
	},
	"16-1": {
		Title:    "Classification",
		Category: "Pre-Calculus & Analysis",
		Intro: `**Injective (one-to-one):** different inputs give different outputs: if **x₁ ≠ x₂** then **f(x₁) ≠ f(x₂)**. So each value in the range comes from at most one x. **Surjective (onto):** every element of the codomain is the image of some x (range = codomain). **Bijective:** both injective and surjective; then f has an **inverse** function f⁻¹.

**Even:** **f(−x) = f(x)** for all x (graph symmetric about the **y-axis**). **Odd:** **f(−x) = −f(x)** (graph symmetric about the **origin**). So f(x)=x² is even; f(x)=x³ is odd; f(x)=x+1 is neither. Many functions are neither even nor odd. To check: compute f(−x) and compare to f(x) and −f(x).

[BOX]
**Definitions**
Injective: x₁≠x₂ ⇒ f(x₁)≠f(x₂). Surjective: range = codomain. Bijective: both.
Even: f(−x)=f(x). Odd: f(−x)=−f(x).
[/BOX]

[BOX]
**Examples**
f(x)=x³: injective on ℝ, odd.  f(x)=x²: not injective on ℝ, even.
[/BOX]

[DIAGRAM:graph-transformations]`,
	},
	"16-2": {
		Title:    "Finding the domain",
		Category: "Pre-Calculus & Analysis",
		Intro: `The **domain** of a function given by a formula is the set of **x** for which the expression is **defined** (and real, if we work in ℝ). **Checklist:** (1) **Denominators** must be **≠ 0**. So 1/(x−2) has domain x ≠ 2. (2) **Even roots** (√, ⁴√, …): the **radicand** must be **≥ 0**. So √(x+1) requires x+1 ≥ 0, i.e. x ≥ −1. (3) **Logarithms:** the **argument** must be **> 0**. So ln(x−3) requires x−3 > 0, i.e. x > 3. (4) **Fractional exponents** (e.g. x^(1/2)): if the exponent has an even denominator in lowest terms, we usually take **base ≥ 0** for real output.

[DIAGRAM:domain-graph]

If the function is a **sum**, **difference**, or **product** of several parts, the domain is the **intersection** of the domains of each part (and then exclude where denominators are zero). For a **composition** f(g(x)), x must be in the domain of g and g(x) must be in the domain of f.

[BOX]
**Checklist**
Denominators ≠ 0. Even roots: radicand ≥ 0. log: argument > 0.
[/BOX]

[BOX]
**Examples**
f(x)=1/(x−2) ⇒ domain x ≠ 2.  f(x)=√(x+1) ⇒ x ≥ −1.  f(x)=ln(x−3) ⇒ x > 3.
[/BOX]`,
	},
	"17": {
		Title:    "Properties of Functions",
		Category: "Pre-Calculus & Analysis",
		Intro: `Beyond domain and range, we study **symmetries** (even/odd), **intercepts** (where the graph crosses the axes), and **sign** (where f(x) > 0, < 0, or = 0). These help sketch the graph and solve inequalities.

[BOX]
**Summary**
Even: f(−x)=f(x); Odd: f(−x)=−f(x)
Intercepts: y-intercept f(0), x-intercepts f(x)=0
[/BOX]

[BOX]
**Examples**
f(x)=x² is even
f(x)=x³ is odd
[/BOX]

[DIAGRAM:graph-transformations]`,
	},
	"17-0": {
		Title:    "Symmetries (Even/Odd)",
		Category: "Pre-Calculus & Analysis",
		Intro: `**Even function:** **f(−x) = f(x)** for all x in the domain. The graph is **symmetric about the y-axis**: if (a, f(a)) is on the graph, so is (−a, f(a)). Examples: x², x⁴, cos x, |x|. **Odd function:** **f(−x) = −f(x)** for all x. The graph is **symmetric about the origin**: if (a, f(a)) is on the graph, so is (−a, −f(a)). Examples: x, x³, sin x.

**How to check:** Replace x by −x in the formula and simplify. If you get f(x), the function is even; if you get −f(x), it is odd; otherwise it is **neither**. Many functions (e.g. x+1, eˣ) are neither. **Use:** Even/odd symmetry reduces the work when sketching or integrating over symmetric intervals.

[BOX]
**Tests**
Even: f(−x) = f(x)  (y-axis symmetry)
Odd:  f(−x) = −f(x)  (origin symmetry)
[/BOX]

[BOX]
**Examples**
f(x)=x²−1: f(−x)=x²−1=f(x) → even.  g(x)=x³+x: g(−x)=−x³−x=−g(x) → odd.  h(x)=x+1: neither.
[/BOX]

[DIAGRAM:graph-transformations]`,
	},
	"17-1": {
		Title:    "Intercepts",
		Category: "Pre-Calculus & Analysis",
		Intro: `**y-intercept:** the point where the graph crosses the **y-axis**. So **x = 0**; the y-intercept is **(0, f(0))**, provided **0** is in the domain. **x-intercepts (zeros):** the points where the graph crosses the **x-axis**. So **f(x) = 0**; solve the equation to find the x-values, then the intercepts are **(x, 0)**. The x-intercepts are exactly the **roots** (zeros) of the function.

**Why they matter:** Intercepts help sketch the graph and often appear in applied problems (e.g. break-even when profit = 0). A function can have **no** x-intercepts (e.g. f(x)=x²+1), **one** (e.g. f(x)=x² at 0), or **many**. For polynomials, the number of real roots is at most the degree.

[BOX]
**Finding intercepts**
y-intercept: (0, f(0))  if 0 ∈ domain
x-intercepts: solve f(x) = 0  →  points (x, 0)
[/BOX]

[BOX]
**Example**
f(x)=x²−4.  y-intercept: f(0)=−4 → (0,−4).  Zeros: x²−4=0 → x=±2 → (−2,0), (2,0).
[/BOX]

[DIAGRAM:graph-transformations]`,
	},
	"17-2": {
		Title:    "Sign study",
		Category: "Pre-Calculus & Analysis",
		Intro: `A **sign study** finds where **f(x) > 0**, **f(x) < 0**, or **f(x) = 0**. This is used to solve **inequalities** (e.g. f(x) ≥ 0) and to sketch the graph (above or below the x-axis).

**Method.** (1) **Factor** f(x) (or write it in a form where zeros are clear). (2) Find all **zeros** (f(x)=0) and points where f is **undefined** (e.g. vertical asymptotes). These split the real line into **intervals**. (3) On each interval, f has **constant sign** (it cannot change sign without crossing zero or a discontinuity). **Test** one value in each interval to determine whether f is positive or negative there. (4) At the zeros, f(x)=0. For **strict** inequalities (> or <), the zeros are excluded; for ≥ or ≤ they are included.

[BOX]
**Procedure**
1) Factor; find zeros and discontinuities. 2) Intervals. 3) Test one point per interval.
[/BOX]

[BOX]
**Example**
f(x)=x²−4=(x−2)(x+2). Zeros: x=±2.  f>0 for x<−2 or x>2;  f<0 for −2<x<2.
[/BOX]

[DIAGRAM:graph-transformations]`,
	},
	"18": {
		Title:    "Exponential & Logarithms",
		Category: "Pre-Calculus & Analysis",
		Intro: `**Exponential** (eˣ, aˣ) and **logarithmic** (ln x, log x) functions are **inverses**: ln(eˣ)=x and e^(ln x)=x for x>0. Both are **strictly monotone**, so you can solve equations and inequalities by “taking ln” or “taking exp” on both sides. You will solve **equations and inequalities** involving eˣ and ln x.

[BOX]
**Formulas**
ln(eˣ)=x; e^(ln x)=x
log_a(x·y)=log_a(x)+log_a(y)
log_a(xⁿ)=n·log_a(x)
[/BOX]

[BOX]
**Examples**
eˣ=5 ⇒ x=ln 5≈1.61
ln(x)=3 ⇒ x=e³≈20.09
[/BOX]

[DIAGRAM:exp-log-graphs]`,
	},
	"18-0": {
		Title:    "Equations and inequalities with eˣ and log(x)",
		Category: "Pre-Calculus & Analysis",
		Intro: `**eˣ** is **strictly increasing** on ℝ; **ln x** is **strictly increasing** on (0, +∞). So **e^a = e^b ⇔ a = b** and **ln u = ln v ⇔ u = v** (for u, v > 0). **Inverses:** ln(eˣ)=x for all x; e^(ln x)=x for x>0. So to solve **e^(f(x)) = e^(g(x))**, equate **f(x)=g(x)**. To solve **ln(f(x))=c**, write **f(x)=e^c** (and require f(x)>0). For **inequalities**, use the same monotonicity: eˣ > e^a ⇔ x > a; ln x < ln a ⇔ 0 < x < a (for a>0).

[DIAGRAM:exp-log-graphs]

**Domain:** For ln(f(x)), need **f(x) > 0**. When solving, always check that solutions lie in the domain.

[BOX]
**Facts**
e^a = e^b ⇔ a = b.  ln u = ln v ⇔ u = v (u,v>0).  ln(eˣ)=x, e^(ln x)=x (x>0).
[/BOX]

[BOX]
**Examples**
e^(2x)=e^(x+1) ⇒ 2x=x+1 ⇒ x=1.  ln(x)=2 ⇒ x=e².
eˣ>e² ⇒ x>2.  ln(x)≤0 ⇒ 0<x≤1.
[/BOX]`,
	},
	"19": {
		Title:    "Analytic Geometry",
		Category: "Pre-Calculus & Analysis",
		Intro: `**Analytic geometry** describes geometric figures using **coordinates** and **equations**. You will work with the **line** (slope-intercept, point-slope, general form), the **circle** (center-radius equation), the **parabola** (vertex, axis), the **ellipse** (semi-axes), and the **hyperbola** (equations and asymptotes) in the Cartesian plane.

[DIAGRAM:conics]`,
	},
	"19-0": {
		Title:    "The line",
		Category: "Pre-Calculus & Analysis",
		Intro: `A **line** in the plane can be given by **slope-intercept** form **y = mx + q** (m = slope, q = y-intercept), **point-slope** form **y − y₁ = m(x − x₁)** (line through (x₁,y₁) with slope m), or **general** form **ax + by + c = 0**. The **slope** through two points (x₁,y₁) and (x₂,y₂) is **m = (y₂−y₁)/(x₂−x₁)** (undefined if x₁=x₂, i.e. vertical line). **Parallel** lines have the **same** slope; **perpendicular** lines have slopes whose product is **−1** (m₁·m₂ = −1).

**From two points:** Compute m, then use point-slope with one of the points. **Vertical line:** x = constant. **Horizontal line:** y = constant (slope 0).

[BOX]
**Formulas**
Slope: m = (y₂−y₁)/(x₂−x₁)
Point-slope: y − y₁ = m(x − x₁).  Slope-intercept: y = mx + q
[/BOX]

[BOX]
**Example**
Through (1,2) and (3,6): m = (6−2)/(3−1) = 2.  y − 2 = 2(x−1) ⇒ y = 2x.
[/BOX]`,
	},
	"19-1": {
		Title:    "The circle",
		Category: "Pre-Calculus & Analysis",
		Intro: `A **circle** is the set of points at distance **r** (the **radius**) from a fixed point **(h, k)** (the **center**). Equation: **(x − h)² + (y − k)² = r²**. Expanding gives **x² + y² + αx + βy + γ = 0** with α = −2h, β = −2k, γ = h²+k²−r². So from the expanded form, **center = (−α/2, −β/2)** and **r = √(α²/4 + β²/4 − γ)** (we need α²/4 + β²/4 − γ ≥ 0 for a real circle).

**Tangent line** at a point on the circle: perpendicular to the radius at that point. **Distance from center to line:** if the line is ax+by+c=0, distance = |ah+bk+c|/√(a²+b²). The line is tangent when this equals r.

[BOX]
**Equation**
(x − h)² + (y − k)² = r².  Center (h,k), radius r.
From x²+y²+αx+βy+γ=0: center (−α/2, −β/2), r = √(α²/4+β²/4−γ).
[/BOX]

[BOX]
**Example**
x²+y²−4x+2y−4=0  ⇒  center (2,−1), r²=4+1+4=9  ⇒  r=3.
[/BOX]`,
	},
	"19-2": {
		Title:    "The parabola",
		Category: "Pre-Calculus & Analysis",
		Intro: `A **parabola** (vertical axis) is the graph of **y = ax² + bx + c** with **a ≠ 0**. It opens **upward** if a > 0 and **downward** if a < 0. The **vertex** (minimum or maximum point) has **x-coordinate x_V = −b/(2a)**; then **y_V = f(x_V)**. So the vertex is **(x_V, y_V)**. The **axis of symmetry** is the vertical line **x = x_V**. You can also complete the square to get **y = a(x − x_V)² + y_V**.

**Roots (x-intercepts):** solve ax²+bx+c=0; the quadratic formula gives 0, 1, or 2 roots depending on the discriminant. **y-intercept:** (0, c).

[BOX]
**Vertex**
x_V = −b/(2a),  y_V = f(x_V)
[/BOX]

[BOX]
**Example**
y = x²−4x+3:  x_V = 4/2 = 2,  y_V = 4−8+3 = −1.  Vertex (2, −1).
[/BOX]`,
	},
	"19-3": {
		Title:    "The ellipse",
		Category: "Pre-Calculus & Analysis",
		Intro: `An **ellipse** (centered at the origin, axes along the coordinate axes) has equation **x²/a² + y²/b² = 1** with **a, b > 0**. The numbers **a** and **b** are the **semi-axes** (half the lengths of the axes). Usually we take **a ≥ b**; then the **major axis** is along the x-axis (length 2a) and the **minor axis** along the y-axis (length 2b). The **foci** are on the major axis at (±c, 0) where **c² = a² − b²** (so c < a). For any point on the ellipse, the sum of distances to the two foci is **2a**.

**Eccentricity** e = c/a (0 < e < 1). If the center is (h, k), the equation is (x−h)²/a² + (y−k)²/b² = 1.

[BOX]
**Equation (center at origin)**
x²/a² + y²/b² = 1.  Semi-axes a, b.  Foci (±c,0) with c² = a²−b².
[/BOX]

[BOX]
**Example**
x²/9 + y²/4 = 1  ⇒  a=3, b=2.  c²=9−4=5  ⇒  c=√5.
[/BOX]`,
	},
	"19-4": {
		Title:    "The hyperbola in the Cartesian plane",
		Category: "Pre-Calculus & Analysis",
		Intro: `A **hyperbola** (centered at the origin) has two standard forms. **Opens left/right:** **x²/a² − y²/b² = 1** (a, b > 0). The branches go to the left and right; **vertices** at (±a, 0); **foci** at (±c, 0) with **c² = a² + b²**. **Opens up/down:** **y²/b² − x²/a² = 1**; vertices (0, ±b), foci (0, ±c). In both cases the **asymptotes** are the lines **y = ±(b/a)x** (for the first form). The hyperbola approaches these lines as |x| or |y| → ∞.

**Eccentricity** e = c/a > 1. For center (h, k), replace x by (x−h) and y by (y−k) in the equation.

[BOX]
**Equations**
x²/a² − y²/b² = 1  (opens left/right).  y²/b² − x²/a² = 1  (opens up/down).
Asymptotes: y = ±(b/a)x.  c² = a² + b².
[/BOX]

[BOX]
**Example**
x²/4 − y²/9 = 1  ⇒  a=2, b=3.  Asymptotes: y = ±(3/2)x.
[/BOX]

[DIAGRAM:conics]`,
	},

	// ----------------------
	// Differential Calculus
	// ----------------------
	"20": {
		Title:    "Limits & Continuity",
		Category: "Differential Calculus",
		Intro: `**Limits** describe the value a function **approaches** as the variable approaches a point (or ±∞). **Finite** limits (lim_{x→a} f(x) = L) and **infinite** limits (vertical asymptotes), **indeterminate forms** (0/0, ∞/∞, etc.) and how to resolve them, and **asymptotes** (vertical, horizontal, oblique) are the main topics.

[DIAGRAM:limits-graph]`,
	},
	"20-0": {
		Title:    "Finite and infinite limits",
		Category: "Differential Calculus",
		Intro: `**lim_{x→a} f(x) = L** (finite) means: as x gets close to a (from either side), f(x) gets arbitrarily close to **L**. The limit does **not** depend on f(a); it only depends on the behavior **near** a. **One-sided limits:** **lim_{x→a⁺}** (right) and **lim_{x→a⁻}** (left); the (two-sided) limit exists and equals L if and only if both one-sided limits exist and equal L.

**Infinite limits:** **lim_{x→a} f(x) = +∞** means f(x) grows without bound as x → a (e.g. lim_{x→0⁺} 1/x = +∞). So the line **x = a** is a **vertical asymptote**. **Limits at infinity:** **lim_{x→+∞} f(x) = L** means f(x) approaches L as x gets larger and larger (e.g. lim_{x→+∞} 1/x = 0). Then **y = L** is a **horizontal asymptote** (at +∞).

[BOX]
**Definitions**
Finite: lim_{x→a} f(x) = L.  Infinite: f(x) → ±∞ (vertical asymptote x = a).
At infinity: lim_{x→±∞} f(x) = L (horizontal asymptote y = L).
[/BOX]

[BOX]
**Examples**
lim_{x→+∞} 1/x = 0.  lim_{x→0⁺} 1/x = +∞,  lim_{x→0⁻} 1/x = −∞.
[/BOX]

[DIAGRAM:limits-graph]`,
	},
	"20-1": {
		Title:    "Indeterminate forms",
		Category: "Differential Calculus",
		Intro: `Indeterminate forms require algebraic work because the “naive” substitution is ambiguous.

**Forms:** 0/0, ∞/∞, 0·∞, ∞−∞, 1^∞. **Techniques:** factor and cancel, rationalize, known limits (e.g. lim (sin x)/x = 1), or L’Hôpital (limit f/g = limit f'/g' for 0/0 or ∞/∞).

[BOX]
**Known limit:** lim_{x→0} (sin x)/x = 1
[/BOX]

[BOX]
**Example**
lim_{x→0} (sin x)/x = 1
[/BOX]

[DIAGRAM:limits-graph]`,
	},
	"20-2": {
		Title:    "Asymptotes",
		Category: "Differential Calculus",
		Intro: `**Vertical asymptote** **x = a:** **lim_{x→a} f(x) = ±∞** (one or both one-sided limits are infinite). So the graph “blows up” near x = a. Typically a is where the **denominator** is zero (and numerator nonzero). **Horizontal asymptote** **y = L:** **lim_{x→+∞} f(x) = L** or **lim_{x→−∞} f(x) = L**. So the graph approaches the line y = L as x → ±∞. For rational functions, compare degrees of numerator and denominator: if degree(num) < degree(den), limit 0; if equal, limit = ratio of leading coefficients.

**Oblique (slant) asymptote:** When lim_{x→±∞} f(x) = ±∞ but f(x)/x tends to a finite **m**, the line **y = mx + q** is an oblique asymptote if **q = lim (f(x) − mx)** (finite). So **m = lim f(x)/x** and **q = lim (f(x) − mx)** as x → ±∞.

[BOX]
**Rules**
Vertical: x = a if lim_{x→a} f(x) = ±∞
Horizontal: y = L if lim_{x→±∞} f(x) = L
Oblique: y = mx + q with m = lim f(x)/x, q = lim (f(x)−mx)
[/BOX]

[BOX]
**Example**
f(x) = (2x+1)/x = 2 + 1/x.  Horizontal: y = 2.  Vertical: x = 0.
[/BOX]

[DIAGRAM:limits-graph]`,
	},
	"21": {
		Title:    "The Derivative Concept",
		Category: "Differential Calculus",
		Intro: `The **derivative** of f at x is the **instantaneous rate of change** of f and the **slope of the tangent line** to the graph at (x, f(x)). It is defined as the limit of the **difference quotient** [f(x+h)−f(x)]/h as h→0. You will see the **difference quotient** and the **geometric meaning** (tangent slope).

[DIAGRAM:derivative-tangent]`,
	},
	"21-0": {
		Title:    "Difference quotient",
		Category: "Differential Calculus",
		Intro: `The **difference quotient** is **[f(x+h) − f(x)] / h** (with **h ≠ 0**). It represents the **average rate of change** of f over the interval from x to x+h (slope of the **secant** line through (x, f(x)) and (x+h, f(x+h))). As **h → 0**, this average rate tends to the **instantaneous** rate of change at x — which is the **derivative** **f'(x)**. So **f'(x) = lim_{h→0} [f(x+h) − f(x)]/h**, provided the limit exists.

**Example:** For f(x)=x², [f(x+h)−f(x)]/h = [(x+h)²−x²]/h = (2xh+h²)/h = 2x+h → **2x** as h→0. So (x²)' = 2x.

[BOX]
**Definition**
Difference quotient: [f(x+h) − f(x)] / h
Derivative: f'(x) = lim_{h→0} [f(x+h) − f(x)]/h
[/BOX]

[BOX]
**Example**
f(x)=x²: [(x+h)²−x²]/h = 2x+h  →  f'(x)=2x
[/BOX]

[DIAGRAM:derivative-tangent]`,
	},
	"21-1": {
		Title:    "Geometric meaning",
		Category: "Differential Calculus",
		Intro: `**Geometrically**, **f'(x₀)** is the **slope of the tangent line** to the graph of y = f(x) at the point **(x₀, f(x₀))**. The tangent line is the limit of secant lines through (x₀, f(x₀)) and (x₀+h, f(x₀+h)) as h→0; its slope is exactly f'(x₀). So the **equation of the tangent line** at x₀ is **y − f(x₀) = f'(x₀)(x − x₀)**, or **y = f(x₀) + f'(x₀)(x − x₀)**.

[DIAGRAM:derivative-tangent]

**Interpretation:** f'(x) > 0 means the function is **increasing** (locally); f'(x) < 0 means **decreasing**; f'(x) = 0 often indicates a **critical point** (max, min, or saddle). The derivative also gives **instantaneous velocity** when f is position.

[BOX]
**Tangent line at x₀**
Slope = f'(x₀).  Equation: y − f(x₀) = f'(x₀)(x − x₀)
[/BOX]

[BOX]
**Example**
f(x)=x² ⇒ f'(x)=2x.  At x₀=1: slope = 2, tangent: y − 1 = 2(x−1) ⇒ y = 2x − 1.
[/BOX]`,
	},
	"22": {
		Title:    "Differentiation Rules",
		Category: "Differential Calculus",
		Intro: `**Differentiation rules** let you compute derivatives without using the limit definition every time: **power rule** (xⁿ)' = n·xⁿ⁻¹, **product rule** (fg)' = f'g + fg', **quotient rule** (f/g)' = (f'g − fg')/g², and **chain rule** for compositions: (f(g(x)))' = f'(g(x))·g'(x).

[DIAGRAM:derivatives-table]`,
	},
	"22-0": {
		Title:    "Power rule",
		Category: "Differential Calculus",
		Intro: `The **power rule** says: for any real **n**, **(xⁿ)' = n·xⁿ⁻¹**. So the derivative of xⁿ is n times x raised to (n−1). This holds for **negative** n (e.g. x⁻¹, x⁻²), **fractional** n (e.g. x^(1/2), x^(3/2)), and of course positive integers. **Constants:** (c·xⁿ)' = c·n·xⁿ⁻¹. **Sum:** (f + g)' = f' + g', so you differentiate term by term.

**Examples:** (x⁵)' = 5x⁴. For **√x = x^(1/2)**: (x^(1/2))' = (1/2)x^(−1/2) = 1/(2√x). For **1/x = x⁻¹**: (x⁻¹)' = −x⁻² = −1/x².

[BOX]
**Power rule**
(xⁿ)' = n·xⁿ⁻¹   (n real, x > 0 if n not integer)
[/BOX]

[DIAGRAM:derivatives-table]

[BOX]
**Examples**
(x⁵)' = 5x⁴.  (√x)' = (1/2)x^(−1/2) = 1/(2√x).
[/BOX]`,
	},
	"22-1": {
		Title:    "Product rule",
		Category: "Differential Calculus",
		Intro: `The **product rule**: **(fg)' = f'·g + f·g'**. So the derivative of a product is **not** the product of the derivatives; you get two terms: derivative of the first times the second, plus the first times the derivative of the second. For three factors: (fgh)' = f'gh + fg'h + fgh'. **Remember:** (f·g)' ≠ f'·g' in general.

**Use:** Whenever you have a product of two (or more) functions of x, apply the product rule. Sometimes it helps to factor the result (e.g. take common factor eˣ out) to simplify.

[BOX]
**Product rule**
(fg)' = f'g + fg'
[/BOX]

[BOX]
**Example**
(x²eˣ)' = 2x·eˣ + x²·eˣ = eˣ(2x + x²)
[/BOX]

[DIAGRAM:derivatives-table]`,
	},
	"22-2": {
		Title:    "Quotient rule",
		Category: "Differential Calculus",
		Intro: `The **quotient rule** (for **g ≠ 0**): **(f/g)' = (f'·g − f·g') / g²**. So the derivative of a quotient is: (derivative of numerator × denominator − numerator × derivative of denominator) **divided by the square of the denominator**. **Do not** forget the **g²** in the denominator and the **minus** in the numerator.

**Alternative:** You can sometimes write f/g = f·g⁻¹ and use the product rule and chain rule: (f·g⁻¹)' = f'·g⁻¹ + f·(−g⁻²·g') = (f'g − fg')/g². **Example:** (1/x)' = (0·x − 1·1)/x² = −1/x², or (x⁻¹)' = −x⁻².

[BOX]
**Quotient rule**
(f/g)' = (f'g − fg') / g²   (g ≠ 0)
[/BOX]

[BOX]
**Example**
(1/x)' = −1/x².  Or (x/(x²+1))' = (1·(x²+1) − x·2x)/(x²+1)² = (1−x²)/(x²+1)².
[/BOX]

[DIAGRAM:derivatives-table]`,
	},
	"22-3": {
		Title:    "Chain rule",
		Category: "Differential Calculus",
		Intro: `The **chain rule** applies to **compositions**: if **y = f(g(x))**, then **y' = f'(g(x))·g'(x)**. So you differentiate the **outer** function (with the inner left as is) and **multiply** by the derivative of the **inner** function. In Leibniz notation: **dy/dx = (dy/du)·(du/dx)** where u = g(x).

**Use:** For **e^(g(x))**: derivative = e^(g(x))·g'(x). For **sin(g(x))**: cos(g(x))·g'(x). For **(g(x))ⁿ**: n·(g(x))ⁿ⁻¹·g'(x). So (e^(x²))' = e^(x²)·2x; (sin(2x))' = cos(2x)·2; ((x²+1)⁵)' = 5(x²+1)⁴·2x.

[BOX]
**Chain rule**
(f(g(x)))' = f'(g(x))·g'(x)
[/BOX]

[BOX]
**Examples**
(e^(x²))' = e^(x²)·2x.  (sin(2x))' = cos(2x)·2.
[/BOX]

[DIAGRAM:derivatives-table]`,
	},
	"23": {
		Title:    "Function Study",
		Category: "Differential Calculus",
		Intro: `Using the **first derivative** you find **critical points** (f'(x)=0 or f' undefined) and **intervals of increase/decrease**. **Local maxima and minima** occur at critical points (first derivative test: sign change of f'). Using the **second derivative** you study **concavity** and **points of inflection** (where concavity changes).

[DIAGRAM:critical-points]`,
	},
	"23-0": {
		Title:    "Maxima and Minima",
		Category: "Differential Calculus",
		Intro: `**Critical points** are where **f'(x) = 0** or **f'** is **undefined** (but f is defined). **Local maxima** and **minima** can only occur at critical points or at endpoints of the domain. **First derivative test:** On an interval, if **f'** changes from **positive to negative** at a critical point, that point is a **local maximum**; if **f'** changes from **negative to positive**, it is a **local minimum**. If f' does not change sign, the critical point is a **saddle** (neither max nor min).

[DIAGRAM:critical-points]

**Second derivative test:** If f'(c)=0 and **f''(c) < 0**, then c is a local **maximum**; if **f''(c) > 0**, c is a local **minimum**. If f''(c)=0 the test is inconclusive.

[BOX]
**First derivative test**
f' changes + → − : local max.  f' changes − → + : local min.
[/BOX]

[BOX]
**Example**
f(x)=x²: f'(x)=2x ⇒ critical point x=0.  f' changes − to + ⇒ local min at (0,0).
[/BOX]`,
	},
	"23-1": {
		Title:    "Points of inflection",
		Category: "Differential Calculus",
		Intro: `A **point of inflection** is a point on the graph where the **concavity** changes: the curve goes from **concave up** (f'' > 0, “cup”) to **concave down** (f'' < 0, “cap”) or vice versa. So at an inflection point, **f''** changes **sign** (from + to − or − to +). **Candidates** are where **f''(x) = 0** or f'' is undefined; then check that f'' actually **changes sign** at that point (not just touches 0). A point where f''=0 but f'' does not change sign is **not** an inflection point.

**Concavity:** f'' > 0 ⇒ concave up; f'' < 0 ⇒ concave down. Inflection points are useful for sketching the graph and for optimization (e.g. minimizing cost).

[BOX]
**Definition**
Inflection: concavity changes  ⇔  f'' changes sign (typically f''(c)=0).
[/BOX]

[BOX]
**Example**
f(x)=x³: f''(x)=6x.  At x=0, f'' changes from − to + ⇒ inflection at (0,0).
[/BOX]

[DIAGRAM:critical-points]`,
	},

	// ----------------
	// Integral Calculus
	// ----------------
	"24": {
		Title:    "Indefinite Integrals",
		Category: "Integral Calculus",
		Intro: `**Indefinite integrals** represent **antiderivatives** (primitive functions): **∫ f(x) dx = F(x) + C** where **F'(x) = f(x)** and **C** is an arbitrary constant. You will see **primitive functions** (F such that F' = f) and **immediate** integration rules (power rule, 1/x, eˣ, sin/cos).

[DIAGRAM:primitive]`,
	},
	"24-0": {
		Title:    "Primitive functions",
		Category: "Integral Calculus",
		Intro: `A **primitive** (or **antiderivative**) of a function **f** is a function **F** such that **F'(x) = f(x)** for all x in the domain. So differentiation “undoes” integration. **Indefinite integral:** **∫ f(x) dx = F(x) + C**, where F is any primitive and **C** is an arbitrary **constant of integration**. So if F is one primitive, **F + C** is also a primitive for any constant C; the family of all primitives is **F(x) + C**.

**Uniqueness:** Two primitives of the same function differ by a constant. So we always write **+ C** when giving the indefinite integral. **Example:** (x²)' = 2x, so ∫ 2x dx = x² + C.

[BOX]
**Definition**
F is a primitive of f if F'(x) = f(x).  ∫ f(x) dx = F(x) + C.
[/BOX]

[BOX]
**Example**
f(x)=2x  ⇒  F(x)=x² (since (x²)'=2x).  So ∫ 2x dx = x² + C.
[/BOX]

[DIAGRAM:primitive]`,
	},
	"24-1": {
		Title:    "Immediate integration rules",
		Category: "Integral Calculus",
		Intro: `**Immediate** (basic) integration rules are the reverse of differentiation. **Power rule:** **∫ xⁿ dx = xⁿ⁺¹/(n+1) + C** for **n ≠ −1** (so ∫ 1 dx = x + C, ∫ x dx = x²/2 + C). **n = −1:** **∫ (1/x) dx = ln|x| + C**. **Exponential:** **∫ eˣ dx = eˣ + C**. **Trig:** **∫ cos x dx = sin x + C**, **∫ sin x dx = −cos x + C**. **Linearity:** **∫ (af(x) + bg(x)) dx = a∫ f dx + b∫ g dx**. So you integrate **term by term** and pull out constants.

**Sum of terms:** ∫ (3x² + 2x + 1) dx = 3·(x³/3) + 2·(x²/2) + x + C = x³ + x² + x + C. Always add **+ C** at the end.

[BOX]
**Formulas**
∫ xⁿ dx = xⁿ⁺¹/(n+1) + C  (n≠−1).  ∫ 1/x dx = ln|x| + C.  ∫ eˣ dx = eˣ + C.
∫ cos x dx = sin x + C.  ∫ sin x dx = −cos x + C.
[/BOX]

[BOX]
**Example**
∫ (3x² + 2x + 1) dx = x³ + x² + x + C
[/BOX]

[DIAGRAM:primitive]`,
	},
	"25": {
		Title:    "Integration Methods",
		Category: "Integral Calculus",
		Intro: `When the integrand is not a simple combination of immediate rules, use **integration by substitution** (reverse of the chain rule: set u = g(x), du = g'(x)dx) or **integration by parts** (from (uv)' = u'v + uv': ∫ u dv = uv − ∫ v du). These are the two main techniques for non-immediate integrals.

[DIAGRAM:integral-area]`,
	},
	"25-0": {
		Title:    "Integration by substitution",
		Category: "Integral Calculus",
		Intro: `**Substitution** (change of variable) is the reverse of the **chain rule**. **Idea:** set **u = g(x)** so that the integrand becomes a function of u and **du = g'(x) dx** (or dx = du/g'(x)). Then ∫ f(g(x))·g'(x) dx = ∫ f(u) du; if you know a primitive F(u) of f(u), the result is **F(g(x)) + C**.

**Steps:** (1) Choose u = g(x) so that g'(x) dx (or part of it) appears in the integral. (2) Compute du = g'(x) dx and replace. (3) Integrate with respect to u. (4) Substitute back u = g(x) and add + C. **Example:** ∫ 2x·e^(x²) dx: u = x², du = 2x dx ⇒ ∫ e^u du = e^u + C = e^(x²) + C.

[BOX]
**Procedure**
u = g(x),  du = g'(x) dx  ⇒  ∫ f(g(x))·g'(x) dx = ∫ f(u) du
[/BOX]

[BOX]
**Example**
∫ 2x·e^(x²) dx.  u = x², du = 2x dx  ⇒  ∫ e^u du = e^u + C = e^(x²) + C
[/BOX]

[DIAGRAM:substitution]`,
	},
	"25-1": {
		Title:    "Integration by parts",
		Category: "Integral Calculus",
		Intro: `**Integration by parts** comes from **(uv)' = u'v + uv'**, so **∫ u'v dx = uv − ∫ uv' dx**. In differential form: **∫ u dv = uv − ∫ v du**. You **choose** u and dv so that (1) **du** and **v** are easy to compute, and (2) **∫ v du** is simpler than ∫ u dv. **LIATE** (Log, Inverse trig, Algebraic, Trig, Exponential) is a common guideline: often choose u to be the “earlier” type and dv the rest.

**Example:** ∫ x·eˣ dx. Let u = x (du = dx), dv = eˣ dx (v = eˣ). Then ∫ x eˣ dx = x·eˣ − ∫ eˣ dx = x·eˣ − eˣ + C = eˣ(x−1) + C. Sometimes you need to apply parts **twice** (e.g. ∫ x² eˣ dx).

[BOX]
**Formula**
∫ u dv = uv − ∫ v du
[/BOX]

[BOX]
**Example**
∫ x eˣ dx: u=x, dv=eˣ dx  ⇒  x eˣ − ∫ eˣ dx = eˣ(x−1) + C
[/BOX]

[DIAGRAM:parts]`,
	},
	"26": {
		Title:    "Definite Integrals",
		Category: "Integral Calculus",
		Intro: `**Definite integrals** **∫_a^b f(x) dx** represent the **signed area** between the graph of f and the x-axis from x = a to x = b (positive where f ≥ 0, negative where f ≤ 0). The **Fundamental Theorem of Calculus** says: if F is any antiderivative of f (F' = f), then **∫_a^b f(x) dx = F(b) − F(a)**. So you find a primitive F and evaluate at the endpoints.

[DIAGRAM:integral-area]`,
	},
	"26-0": {
		Title:    "Calculating the area under a curve",
		Category: "Integral Calculus",
		Intro: `The **definite integral** **∫_a^b f(x) dx** is the **signed** (net) area between the graph of **y = f(x)** and the **x-axis** over the interval [a, b]: area above the axis counts **positive**, below counts **negative**. If **f(x) ≥ 0** on [a, b], then ∫_a^b f(x) dx equals the **geometric** area of the region under the curve. If f takes both signs, the integral is the **difference** (area above minus area below).

[DIAGRAM:integral-area]

**Computation:** By the **FTC**, ∫_a^b f(x) dx = **F(b) − F(a)** where F is any antiderivative of f. So find F (indefinite integral), then plug in b and a and subtract. **Example:** ∫_0^1 x² dx = [x³/3]_0^1 = 1/3 − 0 = 1/3 (area under y = x² from 0 to 1).

[BOX]
**Meaning**
∫_a^b f(x) dx = signed area between graph and x-axis on [a,b].
If f ≥ 0: geometric area.  FTC: = F(b) − F(a).
[/BOX]

[BOX]
**Example**
∫_0^1 x² dx = [x³/3]_0^1 = 1/3
[/BOX]`,
	},
	"26-1": {
		Title:    "The Fundamental Theorem of Calculus",
		Category: "Integral Calculus",
		Intro: `The **Fundamental Theorem of Calculus (FTC)** has two parts. **Part 1:** If f is continuous on [a,b] and we define **F(x) = ∫_a^x f(t) dt**, then **F'(x) = f(x)** (so F is an antiderivative of f). **Part 2:** If f is continuous on [a,b] and **F** is **any** antiderivative of f (i.e. F' = f), then **∫_a^b f(x) dx = F(b) − F(a)**. We often write **F(b) − F(a) = [F(x)]_a^b**.

So to compute a definite integral: (1) find **any** primitive F of f (indefinite integral), (2) evaluate **F(b) − F(a)**. This is the main tool for calculating areas and many applied quantities.

[BOX]
**FTC (Part 2)**
∫_a^b f(x) dx = F(b) − F(a)   where F' = f
[/BOX]

[BOX]
**Example**
∫_0^1 x² dx = [x³/3]_0^1 = 1/3 − 0 = 1/3
[/BOX]

[DIAGRAM:integral-area]`,
	},
	"27": {
		Title:    "Applications",
		Category: "Integral Calculus",
		Intro: `**Applications** of integrals include **area** between curves, **volume** of solids of revolution (disk/washer method), arc length, work, and many physics/geometry problems. You will see **volumes** (e.g. rotation about the x-axis: V = π∫ (f(x))² dx) and **areas of plane figures** (area between y = f(x) and y = g(x) is ∫ (f − g) dx).

[DIAGRAM:solids-of-revolution]`,
	},
	"27-0": {
		Title:    "Calculation of volumes",
		Category: "Integral Calculus",
		Intro: `**Disk method** (solid of revolution): Rotate the region under **y = f(x)** (with f(x) ≥ 0) from x = a to x = b about the **x-axis**. Each vertical slice becomes a **disk** of radius f(x) and thickness dx; the volume is **V = π ∫_a^b (f(x))² dx**. **Washer method:** If the region is between **y = f(x)** and **y = g(x)** (with f ≥ g ≥ 0), rotation about the x-axis gives **V = π ∫_a^b [(f(x))² − (g(x))²] dx** (outer radius f, inner g).

[DIAGRAM:solids-of-revolution]

**Cone:** Rotating the line y = (r/h)x from 0 to h about the x-axis gives a cone of radius r and height h: V = π ∫_0^h (r²/h²)x² dx = (1/3)πr²h.

[BOX]
**Disk method (about x-axis)**
V = π ∫_a^b (f(x))² dx.  Washer: V = π ∫_a^b (f² − g²) dx
[/BOX]

[BOX]
**Example (cone)**
y = (r/h)x on [0,h]: V = π ∫ (r²/h²)x² dx = (1/3)πr²h
[/BOX]`,
	},
	"27-1": {
		Title:    "Areas of plane figures",
		Category: "Integral Calculus",
		Intro: `The **area between two curves** **y = f(x)** and **y = g(x)** from x = a to x = b (where **f(x) ≥ g(x)** on [a,b]) is **A = ∫_a^b (f(x) − g(x)) dx**. So you integrate the **vertical** distance (top minus bottom) between the curves. If the curves cross, split the interval at the intersection points so that on each subinterval one function is always on top; then add the absolute areas (or use |f − g|).

**Procedure:** (1) Find intersection points (solve f(x) = g(x)). (2) Determine which curve is on top on each interval. (3) Integrate (top − bottom) over each interval. (4) Add. **Example:** Between y = x and y = x² on [0,1]: x ≥ x², so A = ∫_0^1 (x − x²) dx = 1/2 − 1/3 = 1/6.

[DIAGRAM:area-between-curves]

[BOX]
**Formula (f ≥ g on [a,b])**
A = ∫_a^b (f(x) − g(x)) dx
[/BOX]

[BOX]
**Example**
Area between y = x and y = x² on [0,1]: ∫_0^1 (x − x²) dx = 1/6
[/BOX]`,
	},
}

func buildLessonContentForLang(lang string) map[string]lessonContent {
	normalizedLang := normalizeLessonLang(lang)
	if normalizedLang == "en" {
		return lessonContentByID
	}

	translations := translationMap(normalizedLang)
	if len(translations) == 0 {
		return lessonContentByID
	}

	localized := make(map[string]lessonContent, len(lessonContentByID))
	for id, content := range lessonContentByID {
		if t, ok := translations[content.Title]; ok {
			content.Title = t
		}
		if t, ok := translations[content.Category]; ok {
			content.Category = t
		}
		localized[id] = content
	}
	return localized
}

var lessonContentByID_it = buildLessonContentForLang("it")
var lessonContentByID_fr = buildLessonContentForLang("fr")
var lessonContentByID_es = buildLessonContentForLang("es")
var lessonContentByID_uz = buildLessonContentForLang("uz")

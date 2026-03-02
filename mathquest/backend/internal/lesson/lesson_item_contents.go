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

// getContentByID returns content for both section ids ("1".."27") and item ids ("1-0"..).
func getContentByID(id string) (lessonContent, bool) {
	if c, ok := lessonContentByID[id]; ok {
		return c, true
	}
	// Fallback: if an item id is requested but missing, use the section overview.
	if sectionID, _, ok := parseItemID(id); ok {
		if c, ok := lessonContentByID[sectionID]; ok {
			return c, true
		}
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
Example
- In ℕ (natural numbers) you can do 7 + 2, but 3 − 5 is not in ℕ.
- To include negative results, we move to ℤ (integers).
[/BOX]`,
	},
	"1-0": {
		Title:    "Natural numbers ℕ",
		Category: "Arithmetic & Number Systems",
		Intro: `Natural numbers are used to count and order.

Definition: ℕ = {0, 1, 2, 3, 4, …}. (Some textbooks use ℕ* = {1, 2, 3, …}.)

Main properties:
- Closed under addition and multiplication: if a, b ∈ ℕ then a + b ∈ ℕ and a·b ∈ ℕ
- Not closed under subtraction: a − b may be negative
- Order: for any a, b ∈ ℕ, either a ≤ b or b ≤ a

[BOX]
Example
7 ∈ ℕ
7 + 2 = 9 ∈ ℕ
7·4 = 28 ∈ ℕ
3 − 5 = −2 (not in ℕ)
[/BOX]`,
	},
	"1-1": {
		Title:    "Integers ℤ",
		Category: "Arithmetic & Number Systems",
		Intro: `Integers extend natural numbers by adding negatives.

Definition: ℤ = {…, −3, −2, −1, 0, 1, 2, 3, …}.

Rules you should know:
- Closed under +, −, ·
- Division is not always an integer (e.g., 7/2)
- Sign rules: (−)·(−) = (+), (−)·(+) = (−)
- Absolute value: |a| is the distance from 0

[BOX]
Examples
(−3) + 5 = 2
(−3) − 5 = −8
(−3)·(−4) = 12
|−7| = 7
[/BOX]`,
	},
	"1-2": {
		Title:    "Rational numbers ℚ",
		Category: "Arithmetic & Number Systems",
		Intro: `Rational numbers are fractions of integers.

Definition: ℚ = { p/q : p, q ∈ ℤ, q ≠ 0 }.

Key facts:
- Terminating decimals and repeating decimals are rational
- You can simplify a fraction by dividing numerator and denominator by their GCD
- Closed under +, −, ·, ÷ (division by nonzero)

[BOX]
Examples
0.25 = 25/100 = 1/4
1.3̅ = 1.333… = 4/3
−2/5 ∈ ℚ
[/BOX]`,
	},
	"2": {
		Title:    "Fundamental Operations",
		Category: "Arithmetic & Number Systems",
		Intro: `This section covers the four basic operations and the rules for powers and roots.

[BOX]
Reminder
Order of operations matters: do powers/roots before multiplication/division, and those before addition/subtraction.
[/BOX]`,
	},
	"2-0": {
		Title:    "The four operations",
		Category: "Arithmetic & Number Systems",
		Intro: `The four operations are addition, subtraction, multiplication, and division.

Properties:
- Addition and multiplication are commutative: a + b = b + a, a·b = b·a
- Addition and multiplication are associative: (a + b) + c = a + (b + c), (a·b)·c = a·(b·c)
- Subtraction and division are not commutative
- Distributive law: a(b + c) = ab + ac

[BOX]
Examples
12 − 5 = 7
12 ÷ 5 = 2 remainder 2 (since 12 = 5·2 + 2)
3(2 + 4) = 3·2 + 3·4 = 18
[/BOX]`,
	},
	"2-1": {
		Title:    "Powers and their properties",
		Category: "Arithmetic & Number Systems",
		Intro: `Powers are repeated multiplication.

Definition: aⁿ means a·a·…·a (n times), with n ∈ ℕ and n ≥ 1.
Special cases:
- a⁰ = 1 (for a ≠ 0)
- a⁻ⁿ = 1/aⁿ (for a ≠ 0)

[BOX]
Formulas
aⁿ·aᵐ = aⁿ⁺ᵐ
aⁿ/aᵐ = aⁿ⁻ᵐ  (a ≠ 0)
(aⁿ)ᵐ = aⁿᵐ
(ab)ⁿ = aⁿbⁿ
[/BOX]

[BOX]
Examples
2³·2² = 2⁵ = 32
3⁴/3² = 3² = 9
5⁻² = 1/25
[/BOX]`,
	},
	"2-2": {
		Title:    "Roots",
		Category: "Arithmetic & Number Systems",
		Intro: `A root is the inverse operation of a power.

Definition: ⁿ√a = b means bⁿ = a.

Important details:
- If n is even, you need a ≥ 0 (in real numbers) and ⁿ√a ≥ 0
- If n is odd, a can be negative
- Roots can be written as fractional exponents: ⁿ√a = a^(1/n) (for a > 0)

[BOX]
Examples
√9 = 3
³√(−8) = −2
√(2) = 2^(1/2)
[/BOX]`,
	},
	"3": {
		Title:    "Expressions & Order of Operations",
		Category: "Arithmetic & Number Systems",
		Intro: `Expressions follow a standard evaluation order.

[BOX]
PEMDAS / BODMAS
1) Parentheses/Brackets
2) Exponents/Orders (powers, roots)
3) Multiplication and Division (left to right)
4) Addition and Subtraction (left to right)
[/BOX]`,
	},
	"3-0": {
		Title:    "Use of parentheses and PEMDAS/BODMAS",
		Category: "Arithmetic & Number Systems",
		Intro: `Parentheses change the meaning of an expression, so always apply PEMDAS/BODMAS.

Common pitfalls:
- A leading minus can act on the whole power: −3² = −(3²) = −9, while (−3)² = 9
- A fraction bar behaves like parentheses around numerator and denominator

[BOX]
Examples
2 + 3·4 = 14, but (2 + 3)·4 = 20
10 − 6 ÷ 2 + 1 = 10 − 3 + 1 = 8
(1/2 + 1/3)·6 = 5
[/BOX]`,
	},
	"4": {
		Title:    "Divisibility & Prime Numbers",
		Category: "Arithmetic & Number Systems",
		Intro: `Divisibility is about whether one integer divides another with no remainder.

This is the foundation for prime factorization, GCD, and LCM.`,
	},
	"4-0": {
		Title:    "Multiples",
		Category: "Arithmetic & Number Systems",
		Intro: `An integer a is a multiple of b (b ≠ 0) if a = b·k for some integer k.
Notation: b | a (“b divides a”).

[BOX]
Examples
12 is a multiple of 3 because 12 = 3·4  ⇒  3 | 12
−15 is a multiple of 5 because −15 = 5·(−3)
[/BOX]`,
	},
	"4-1": {
		Title:    "Divisors",
		Category: "Arithmetic & Number Systems",
		Intro: `A divisor of n is an integer d such that n = d·q for some integer q.

To find divisors efficiently, use prime factorization.

[BOX]
Example
18 = 2·3²
Positive divisors: 1, 2, 3, 6, 9, 18
[/BOX]`,
	},
	"4-2": {
		Title:    "GCD (Greatest Common Divisor)",
		Category: "Arithmetic & Number Systems",
		Intro: `The GCD of two integers is the largest positive integer that divides both.

Two common methods:
- Prime factorization: take common prime factors with the smallest exponents
- Euclidean algorithm: repeatedly apply gcd(a, b) = gcd(b, a mod b)

[BOX]
Example (prime factors)
24 = 2³·3
36 = 2²·3²
GCD(24, 36) = 2²·3 = 12
[/BOX]`,
	},
	"4-3": {
		Title:    "LCM (Least Common Multiple)",
		Category: "Arithmetic & Number Systems",
		Intro: `The LCM of two positive integers is the smallest positive integer that is a multiple of both.

Method:
- Prime factorization: take all primes with the largest exponents

[BOX]
Example
24 = 2³·3
36 = 2²·3²
LCM(24, 36) = 2³·3² = 72

Check: GCD·LCM = 12·72 = 24·36
[/BOX]`,
	},
	"5": {
		Title:    "Fractions & Ratios",
		Category: "Arithmetic & Number Systems",
		Intro: `Fractions represent parts of a whole and ratios compare quantities.

You’ll use equivalent fractions, operations, percentages, and proportions.`,
	},
	"5-0": {
		Title:    "Equivalent fractions",
		Category: "Arithmetic & Number Systems",
		Intro: `Two fractions a/b and c/d are equivalent if a·d = b·c (with b, d ≠ 0).

How to simplify:
- Divide numerator and denominator by their GCD

[BOX]
Examples
6/8 = 3/4
10/15 = 2/3
Because 6·4 = 8·3 and 10·3 = 15·2
[/BOX]`,
	},
	"5-1": {
		Title:    "Operations with fractions",
		Category: "Arithmetic & Number Systems",
		Intro: `Rules:
- Add/subtract: use a common denominator (usually the LCM)
- Multiply: multiply numerators and denominators
- Divide: multiply by the reciprocal

[BOX]
Formulas
a/b + c/d = (ad + bc)/bd
(a/b)·(c/d) = (ac)/(bd)
(a/b) ÷ (c/d) = (a/b)·(d/c)
[/BOX]

[BOX]
Examples
1/3 + 1/2 = 5/6
(2/5)·(3/4) = 3/10
(2/3) ÷ (4/5) = 5/6
[/BOX]`,
	},
	"5-2": {
		Title:    "Percentages",
		Category: "Arithmetic & Number Systems",
		Intro: `A percentage is “per 100”.

Conversions:
- x% = x/100
- x% of N = (x/100)·N
- A is what percent of B?  (A/B)·100%

[BOX]
Examples
20% of 80 = 0.2·80 = 16
15 out of 60 = (15/60)·100% = 25%
Increase 50 by 10%: 50·1.10 = 55
[/BOX]`,
	},
	"5-3": {
		Title:    "Proportions",
		Category: "Arithmetic & Number Systems",
		Intro: `A proportion is an equality of two ratios:
a : b = c : d  ⇔  a/b = c/d.

Fundamental property (cross-multiplication):

[BOX]
Formula
a : b = c : d  ⇔  a·d = b·c   (with b, d ≠ 0)
[/BOX]

[BOX]
Example
3 : 4 = x : 12
3/4 = x/12  ⇒  x = (3·12)/4 = 9
[/BOX]`,
	},

	// -------
	// Algebra
	// -------
	"6": {
		Title:    "Monomials & Polynomials",
		Category: "Algebra",
		Intro: `This section introduces algebraic expressions built from numbers and variables (monomials and polynomials).`,
	},
	"6-0": {
		Title:    "Operations",
		Category: "Algebra",
		Intro: `A monomial is a product of a coefficient and variables with non‑negative integer exponents, like 3x²y.
A polynomial is a sum of monomials, like 2x³ − x + 5.

Operations:
- Add/subtract like terms (same variable part)
- Multiply using distributive law
- Multiply monomials by adding exponents of same base

[BOX]
Examples
2x² + 5x² = 7x²
3xy · 2x² = 6x³y
(x + 2)(x − 3) = x² − x − 6
[/BOX]`,
	},
	"6-1": {
		Title:    "Degree of a polynomial",
		Category: "Algebra",
		Intro: `Degree measures “how powerful” the highest term is.

Definitions:
- Degree of a monomial: sum of exponents (e.g., 4x²y³ has degree 2 + 3 = 5)
- Degree of a polynomial: maximum degree among its terms

[BOX]
Examples
P(x) = 2x³ − x + 5 has degree 3
Q(x, y) = 3x²y + 7y⁴ has degree 4 (because of y⁴)
[/BOX]`,
	},
	"6-2": {
		Title:    "Special products (e.g. square of a binomial)",
		Category: "Algebra",
		Intro: `Special products are patterns you should recognize immediately.

[BOX]
Formulas
(a + b)² = a² + 2ab + b²
(a − b)² = a² − 2ab + b²
(a + b)(a − b) = a² − b²
[/BOX]

[BOX]
Examples
(2x + 1)² = 4x² + 4x + 1
(x − 3)(x + 3) = x² − 9
[/BOX]`,
	},
	"7": {
		Title:    "Factoring Polynomials",
		Category: "Algebra",
		Intro: `Factoring rewrites a polynomial as a product. It is the reverse of expanding and is essential for solving equations.`,
	},
	"7-0": {
		Title:    "Common factoring",
		Category: "Algebra",
		Intro: `Common factoring means pulling out the greatest common factor (GCF).

Steps:
- Find the GCF of coefficients
- Find the smallest exponent of each variable common to all terms
- Factor it out

[BOX]
Examples
6x²y + 9xy² = 3xy(2x + 3y)
4a³ − 8a² + 2a = 2a(2a² − 4a + 1)
[/BOX]`,
	},
	"7-1": {
		Title:    "Ruffini's Rule",
		Category: "Algebra",
		Intro: `Ruffini’s rule (synthetic division) divides a polynomial P(x) by (x − c).

If the remainder is 0, then:
- (x − c) is a factor of P(x)
- c is a root of P(x)

How to choose candidates:
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
		Intro: `A difference of squares is one of the fastest patterns to factor.

[BOX]
Formula
A² − B² = (A − B)(A + B)
[/BOX]

Tips:
- Look for perfect squares (like x², 9, 4a², 25b²)
- Rewrite numbers as squares when possible

[BOX]
Examples
x² − 9 = (x − 3)(x + 3)
4a² − 25b² = (2a − 5b)(2a + 5b)
[/BOX]`,
	},
	"8": {
		Title:    "Linear Equations & Inequalities",
		Category: "Algebra",
		Intro: `Linear equations and inequalities are the base case for algebraic problem solving.`,
	},
	"8-0": {
		Title:    "First-degree equations",
		Category: "Algebra",
		Intro: `A first-degree (linear) equation in x has the form ax + b = 0 with a ≠ 0.

Method:
- Move constants to one side
- Divide by the coefficient of x
- Check the solution

[BOX]
Example
3x − 5 = 2x + 1
3x − 2x = 1 + 5
x = 6
[/BOX]`,
	},
	"8-1": {
		Title:    "Literal equations",
		Category: "Algebra",
		Intro: `A literal equation contains parameters (letters that are constants for the problem).

Goal: isolate the required variable while tracking conditions (like denominators ≠ 0).

[BOX]
Example
Solve for x: 2x + a = 4
2x = 4 − a
x = (4 − a)/2
[/BOX]`,
	},
	"9": {
		Title:    "Quadratic Equations",
		Category: "Algebra",
		Intro: `Quadratic equations have the form ax² + bx + c = 0 with a ≠ 0.`,
	},
	"9-0": {
		Title:    "Complete and incomplete quadratics",
		Category: "Algebra",
		Intro: `A quadratic can be:
- Complete: ax² + bx + c = 0
- Incomplete: missing b or c

[BOX]
Examples
ax² + c = 0  ⇒  x = ±√(−c/a) (real only if −c/a ≥ 0)
ax² + bx = 0  ⇒  x(ax + b) = 0  ⇒  x = 0 or x = −b/a
[/BOX]`,
	},
	"9-1": {
		Title:    "The Discriminant (Δ)",
		Category: "Algebra",
		Intro: `The discriminant tells you how many real solutions a quadratic has.

[BOX]
Formula
For ax² + bx + c = 0:
Δ = b² − 4ac
x = (−b ± √Δ)/(2a)
[/BOX]

Interpretation:
- Δ > 0: two distinct real roots
- Δ = 0: one real root (double)
- Δ < 0: no real roots

[BOX]
Example
x² − 5x + 6 = 0
Δ = 25 − 24 = 1
x = (5 ± 1)/2 ⇒ x = 3 or x = 2
[/BOX]`,
	},
	"9-2": {
		Title:    "Factoring quadratic trinomials",
		Category: "Algebra",
		Intro: `When possible, factoring is the fastest way to solve.

For x² + sx + p:
Find numbers a and b such that a + b = s and ab = p.

[BOX]
Example
x² + 5x + 6 = 0
2 + 3 = 5 and 2·3 = 6
(x + 2)(x + 3) = 0 ⇒ x = −2, −3
[/BOX]`,
	},
	"10": {
		Title:    "Systems of Equations",
		Category: "Algebra",
		Intro: `A system asks for values that satisfy all equations at once.`,
	},
	"10-0": {
		Title:    "Substitution",
		Category: "Algebra",
		Intro: `Substitution:
- Solve one equation for one variable
- Substitute into the other equation

[BOX]
Example
{ 2x + y = 8,  x − y = 1 }
From the second: x = 1 + y
2(1 + y) + y = 8 ⇒ 3y = 6 ⇒ y = 2
x = 3
[/BOX]`,
	},
	"10-1": {
		Title:    "Comparison",
		Category: "Algebra",
		Intro: `Comparison:
- Solve both equations for the same variable
- Set the expressions equal

[BOX]
Example
y = 8 − 2x
y = x − 1
8 − 2x = x − 1 ⇒ 3x = 9 ⇒ x = 3
y = 2
[/BOX]`,
	},
	"10-2": {
		Title:    "Cramer's method",
		Category: "Algebra",
		Intro: `Cramer’s rule solves a 2×2 linear system using determinants.

System:
a₁x + b₁y = c₁
a₂x + b₂y = c₂

[BOX]
Formulas
Det = a₁b₂ − a₂b₁
x = (c₁b₂ − c₂b₁)/Det
y = (a₁c₂ − a₂c₁)/Det
(valid only if Det ≠ 0)
[/BOX]

[BOX]
Example
{ 2x + y = 8,  x − y = 1 }
Det = 2·(−1) − 1·1 = −3
x = (8·(−1) − 1·1)/(−3) = 3
y = (2·1 − 1·8)/(−3) = 2
[/BOX]`,
	},

	// -------------------------
	// Geometry & Trigonometry
	// -------------------------
	"11": { Title: "Plane Geometry", Category: "Geometry & Trigonometry", Intro: `Plane geometry studies shapes in 2D: segments, angles, triangles, quadrilaterals, and polygons.` },
	"11-0": {
		Title:    "Segments",
		Category: "Geometry & Trigonometry",
		Intro: `A segment is the part of a line between two points A and B (written AB).

Important concepts:
- Length AB is the distance between A and B
- Midpoint M of AB satisfies AM = MB
- Segment addition: if C is between A and B, then AB = AC + CB

[BOX]
Example
If AB = 10 and M is the midpoint, then AM = MB = 5.
[/BOX]`,
	},
	"11-1": {
		Title:    "Angles",
		Category: "Geometry & Trigonometry",
		Intro: `An angle is formed by two rays with the same origin.

Key facts:
- Complementary angles sum to 90°
- Supplementary angles sum to 180°
- Vertical (opposite) angles are equal
- Angle bisector splits an angle into two equal angles

[BOX]
Example
If an angle is 35°, its complement is 55° (because 35° + 55° = 90°).
[/BOX]`,
	},
	"11-2": {
		Title:    "Triangles",
		Category: "Geometry & Trigonometry",
		Intro: `A triangle has 3 sides and 3 angles.

Properties:
- Sum of interior angles: 180°
- Triangle inequality: each side is less than the sum of the other two
- Area: A = (base·height)/2

[BOX]
Example
Base = 10, height = 6 ⇒ A = (10·6)/2 = 30
[/BOX]`,
	},
	"11-3": {
		Title:    "Quadrilaterals",
		Category: "Geometry & Trigonometry",
		Intro: `A quadrilateral has 4 sides; the sum of interior angles is 360°.

Common types:
- Trapezoid: at least one pair of parallel sides
- Parallelogram: opposite sides parallel (and equal)
- Rectangle: parallelogram with 90° angles
- Rhombus: parallelogram with all sides equal
- Square: rectangle + rhombus

[BOX]
Example
In a parallelogram, consecutive angles are supplementary (sum to 180°).
[/BOX]`,
	},
	"11-4": {
		Title:    "Polygons",
		Category: "Geometry & Trigonometry",
		Intro: `A polygon is a closed chain of segments.

For a convex n‑gon:

[BOX]
Formulas
Sum of interior angles = (n − 2)·180°
Each interior angle (regular n‑gon) = ((n − 2)·180°)/n
[/BOX]

[BOX]
Example
For a hexagon (n = 6): sum = 4·180° = 720°.
Regular hexagon: each interior angle = 720°/6 = 120°.
[/BOX]`,
	},
	"12": { Title: "Congruence & Similarity", Category: "Geometry & Trigonometry", Intro: `Congruence is “same shape and same size”. Similarity is “same shape, scaled”.` },
	"12-0": {
		Title:    "Criteria for triangles",
		Category: "Geometry & Trigonometry",
		Intro: `Triangle congruence criteria:
- SSS: three sides equal
- SAS: two sides and the included angle equal
- ASA/AAS: two angles and a side equal

Triangle similarity criteria:
- AA: two angles equal
- SSS proportional: three sides in proportion
- SAS proportional: two sides in proportion and included angle equal

[BOX]
Example
If two triangles have angles (30°, 60°, 90°) they are similar by AA.
[/BOX]`,
	},
	"12-1": {
		Title:    "Pythagoras' and Euclid's theorems",
		Category: "Geometry & Trigonometry",
		Intro: `For right triangles, Pythagoras connects the side lengths.

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
	"13": { Title: "Circle & Pi", Category: "Geometry & Trigonometry", Intro: `Circles connect geometry with π, lengths, and areas.` },
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
[/BOX]`,
	},
	"13-1": {
		Title:    "Area",
		Category: "Geometry & Trigonometry",
		Intro: `The area of a circle depends on the square of the radius.

[BOX]
Formula
A = πr²
[/BOX]

[BOX]
Example
r = 5 ⇒ A = 25π ≈ 78.54
[/BOX]`,
	},
	"13-2": {
		Title:    "Tangents",
		Category: "Geometry & Trigonometry",
		Intro: `A tangent touches a circle at exactly one point.

Key facts:
- The radius to the point of tangency is perpendicular to the tangent
- From an external point P, the two tangent segments to the circle have equal length

[BOX]
Example
If PT and PS are tangents from P to the circle, then PT = PS.
[/BOX]`,
	},
	"13-3": {
		Title:    "Secants",
		Category: "Geometry & Trigonometry",
		Intro: `A secant intersects the circle in two points.

Power of a point (secant-secant):

[BOX]
Formula
From external point P, if a secant meets the circle at A and B (A closer to P):
PA · PB is constant for all secants through P.
[/BOX]

[BOX]
Example
If PA = 3 and PB = 12, then PA·PB = 36. Any other secant through P will have the same product.
[/BOX]`,
	},
	"14": { Title: "Solid Geometry", Category: "Geometry & Trigonometry", Intro: `Solid geometry studies 3D shapes: prisms, pyramids, cylinders, cones, and spheres.` },
	"14-0": {
		Title:    "Prisms",
		Category: "Geometry & Trigonometry",
		Intro: `A prism has two parallel congruent bases and lateral faces.

[BOX]
Formulas
Volume: V = (base area)·h
Lateral area (right prism): (base perimeter)·h
[/BOX]

[BOX]
Example
Base area = 12, height = 5 ⇒ V = 60
[/BOX]`,
	},
	"14-1": {
		Title:    "Pyramids",
		Category: "Geometry & Trigonometry",
		Intro: `A pyramid has a polygon base and a vertex.

[BOX]
Formula
V = (1/3)·(base area)·h
[/BOX]

[BOX]
Example
Base area = 30, height = 9 ⇒ V = (1/3)·30·9 = 90
[/BOX]`,
	},
	"14-2": {
		Title:    "Cylinders",
		Category: "Geometry & Trigonometry",
		Intro: `A right cylinder has circular bases of radius r and height h.

[BOX]
Formulas
V = πr²h
Surface area: S = 2πr² + 2πrh
[/BOX]

[BOX]
Example
r = 2, h = 5 ⇒ V = π·4·5 = 20π
[/BOX]`,
	},
	"14-3": {
		Title:    "Cones",
		Category: "Geometry & Trigonometry",
		Intro: `A right cone has a circular base (radius r) and height h.

[BOX]
Formulas
V = (1/3)πr²h
Lateral area: S_lat = πr·a  (a = slant height)
[/BOX]

[BOX]
Example
r = 3, h = 4 ⇒ V = (1/3)π·9·4 = 12π
[/BOX]`,
	},
	"14-4": {
		Title:    "Spheres (Volume & Surface Area)",
		Category: "Geometry & Trigonometry",
		Intro: `A sphere is the set of points at distance r from a center.

[BOX]
Formulas
Surface area: S = 4πr²
Volume: V = (4/3)πr³
[/BOX]

[BOX]
Example
r = 3 ⇒ S = 36π, V = 36π
[/BOX]`,
	},
	"15": { Title: "Goniometry & Trigonometry", Category: "Geometry & Trigonometry", Intro: `Trigonometry connects angles to ratios and coordinates.` },
	"15-0": {
		Title:    "The Unit Circle",
		Category: "Geometry & Trigonometry",
		Intro: `The unit circle has radius 1 and center at the origin.

Radians:

[BOX]
Conversions
360° = 2π rad
180° = π rad
90° = π/2 rad
[/BOX]

On the unit circle, an angle θ corresponds to a point (cos θ, sin θ).`,
	},
	"15-1": {
		Title:    "Sine, Cosine, Tangent",
		Category: "Geometry & Trigonometry",
		Intro: `Definitions (unit circle):
- cos θ = x‑coordinate
- sin θ = y‑coordinate
- tan θ = sin θ / cos θ (when cos θ ≠ 0)

[BOX]
Identity
sin²θ + cos²θ = 1
[/BOX]

[BOX]
Special angles
sin(0)=0, cos(0)=1
sin(π/6)=1/2, cos(π/6)=√3/2
sin(π/4)=√2/2, cos(π/4)=√2/2
sin(π/2)=1, cos(π/2)=0
[/BOX]`,
	},
	"15-2": {
		Title:    "Law of Sines/Cosines",
		Category: "Geometry & Trigonometry",
		Intro: `These laws solve non‑right triangles.

[BOX]
Law of Sines
a/sin A = b/sin B = c/sin C
[/BOX]

[BOX]
Law of Cosines
a² = b² + c² − 2bc·cos A
[/BOX]

[BOX]
Example (cosine law)
If b=5, c=7, A=60°:
a² = 25 + 49 − 2·5·7·cos60° = 74 − 35 = 39 ⇒ a = √39
[/BOX]`,
	},

	// -------------------------
	// Pre-Calculus & Analysis
	// -------------------------
	"16": { Title: "Functions & Domain", Category: "Pre-Calculus & Analysis", Intro: `Functions describe how one quantity depends on another. The domain is where the function is defined.` },
	"16-0": {
		Title:    "Real functions of a real variable",
		Category: "Pre-Calculus & Analysis",
		Intro: `A real function of a real variable maps real inputs to real outputs.

Notation: y = f(x), with x ∈ Domain(f) ⊆ ℝ.
The graph is the set of points (x, f(x)).

[BOX]
Examples
f(x) = x² has domain ℝ and range [0, +∞)
g(x) = 1/x has domain ℝ \\ {0}
[/BOX]`,
	},
	"16-1": {
		Title:    "Classification",
		Category: "Pre-Calculus & Analysis",
		Intro: `Common ways to classify functions:
- Injective (one‑to‑one): different inputs give different outputs
- Surjective (onto): every value in the codomain is hit
- Bijective: both injective and surjective (has an inverse)
- Even: f(−x) = f(x)
- Odd: f(−x) = −f(x)

[BOX]
Examples
f(x)=x³ is injective on ℝ (and odd)
f(x)=x² is not injective on ℝ (and is even)
[/BOX]`,
	},
	"16-2": {
		Title:    "Finding the domain",
		Category: "Pre-Calculus & Analysis",
		Intro: `To find the domain, list the values of x that make the expression meaningful (in ℝ).

Checklist:
- Denominators ≠ 0
- Even roots: radicand ≥ 0
- Logarithms: argument > 0
- Fractional exponents: usually require base > 0

[BOX]
Examples
f(x)=1/(x−2) ⇒ x ≠ 2
f(x)=√(x+1) ⇒ x ≥ −1
f(x)=ln(x−3) ⇒ x > 3
[/BOX]`,
	},
	"17": { Title: "Properties of Functions", Category: "Pre-Calculus & Analysis", Intro: `Once you have a function, you can study symmetry, intercepts, and where it is positive/negative.` },
	"17-0": {
		Title:    "Symmetries (Even/Odd)",
		Category: "Pre-Calculus & Analysis",
		Intro: `Symmetry tests:
- Even: f(−x) = f(x)  → symmetry about the y‑axis
- Odd:  f(−x) = −f(x) → symmetry about the origin

[BOX]
Examples
f(x) = x² − 1 is even
g(x) = x³ + x is odd
h(x) = x + 1 is neither
[/BOX]`,
	},
	"17-1": {
		Title:    "Intercepts",
		Category: "Pre-Calculus & Analysis",
		Intro: `Intercepts are where the graph crosses the axes.

- y‑intercept: set x = 0 (if allowed)
- x‑intercepts (zeros): solve f(x) = 0

[BOX]
Example
f(x)=x²−4
y‑intercept: f(0)=−4 → (0, −4)
x‑intercepts: x²−4=0 → x=±2 → (−2,0), (2,0)
[/BOX]`,
	},
	"17-2": {
		Title:    "Sign study",
		Category: "Pre-Calculus & Analysis",
		Intro: `A sign study determines where f(x) is positive, negative, or zero.

Method (typical for factored expressions):
- Factor f(x)
- Find zeros and points where f is undefined
- Make a sign chart by testing intervals

[BOX]
Example
f(x)=x²−4=(x−2)(x+2)
Zeros at x=−2 and x=2
f(x)>0 for x<−2 or x>2
f(x)<0 for −2<x<2
[/BOX]`,
	},
	"18": { Title: "Exponential & Logarithms", Category: "Pre-Calculus & Analysis", Intro: `Exponential and logarithmic equations rely on inverse functions and monotonicity.` },
	"18-0": {
		Title:    "Equations and inequalities with eˣ and log(x)",
		Category: "Pre-Calculus & Analysis",
		Intro: `Core facts:
- eˣ is strictly increasing on ℝ
- ln(x) is strictly increasing on (0, +∞)
- ln and exp are inverses: ln(eˣ)=x, e^(ln x)=x (x>0)

[BOX]
Examples (equations)
e^(2x) = e^(x+1) ⇒ 2x = x + 1 ⇒ x = 1
ln(x) = 2 ⇒ x = e²
[/BOX]

[BOX]
Examples (inequalities)
eˣ > e² ⇒ x > 2
ln(x) ≤ 0 ⇒ 0 < x ≤ 1
[/BOX]`,
	},
	"19": { Title: "Analytic Geometry", Category: "Pre-Calculus & Analysis", Intro: `Analytic geometry describes geometric objects with equations in the coordinate plane.` },
	"19-0": {
		Title:    "The line",
		Category: "Pre-Calculus & Analysis",
		Intro: `Common forms:
- Slope-intercept: y = mx + q
- General: ax + by + c = 0

[BOX]
Formulas
Slope through two points (x₁,y₁),(x₂,y₂):
m = (y₂ − y₁)/(x₂ − x₁)
Point-slope form:
y − y₁ = m(x − x₁)
[/BOX]

[BOX]
Example
Through (1,2) and (3,6):
m = (6−2)/(3−1)=2
y − 2 = 2(x − 1) ⇒ y = 2x
[/BOX]`,
	},
	"19-1": {
		Title:    "The circle",
		Category: "Pre-Calculus & Analysis",
		Intro: `A circle with center (h,k) and radius r:

[BOX]
Equation
(x − h)² + (y − k)² = r²
[/BOX]

Expanded form: x² + y² + αx + βy + γ = 0.
Center: (−α/2, −β/2), radius: r = √(α²/4 + β²/4 − γ).

[BOX]
Example
x² + y² − 4x + 2y − 4 = 0
Center (2, −1), radius 3
[/BOX]`,
	},
	"19-2": {
		Title:    "The parabola",
		Category: "Pre-Calculus & Analysis",
		Intro: `A vertical parabola can be written as y = ax² + bx + c (a ≠ 0).

Vertex:

[BOX]
Formula
x_V = −b/(2a)
y_V = f(x_V)
[/BOX]

[BOX]
Example
y = x² − 4x + 3
x_V = 2, y_V = −1
So the vertex is (2, −1)
[/BOX]`,
	},
	"19-3": {
		Title:    "The ellipse",
		Category: "Pre-Calculus & Analysis",
		Intro: `An ellipse centered at the origin with axes aligned:

[BOX]
Equation
x²/a² + y²/b² = 1
[/BOX]

Here a and b are the semi-axes (a is the semi-major axis if a ≥ b).

[BOX]
Example
x²/9 + y²/4 = 1 has semi-axes a=3 and b=2
[/BOX]`,
	},
	"19-4": {
		Title:    "The hyperbola in the Cartesian plane",
		Category: "Pre-Calculus & Analysis",
		Intro: `A standard hyperbola centered at the origin:

[BOX]
Equations
x²/a² − y²/b² = 1  (opens left/right)
y²/b² − x²/a² = 1  (opens up/down)
Asymptotes: y = ±(b/a)x
[/BOX]

[BOX]
Example
x²/4 − y²/9 = 1 has asymptotes y = ±(3/2)x
[/BOX]`,
	},

	// ----------------------
	// Differential Calculus
	// ----------------------
	"20": { Title: "Limits & Continuity", Category: "Differential Calculus", Intro: `Limits describe what a function approaches near a point or at infinity.` },
	"20-0": {
		Title:    "Finite and infinite limits",
		Category: "Differential Calculus",
		Intro: `A limit describes the value f(x) approaches as x approaches a point.

Two common cases:
- Finite limit: lim_{x→a} f(x) = L
- Infinite limit: lim_{x→a} f(x) = +∞ or −∞ (vertical blow-up)

[BOX]
Examples
lim_{x→+∞} 1/x = 0
lim_{x→0⁺} 1/x = +∞
[/BOX]`,
	},
	"20-1": {
		Title:    "Indeterminate forms",
		Category: "Differential Calculus",
		Intro: `Indeterminate forms require algebraic work because the “naive” substitution is ambiguous.

Common indeterminate forms:
- 0/0, ∞/∞
- 0·∞, ∞−∞
- 1^∞, 0⁰, ∞⁰

Typical techniques:
- Factor and cancel
- Rationalize (use conjugates)
- Use known limits (e.g., sin x / x → 1 as x→0)

[BOX]
Example
lim_{x→0} (sin x)/x = 1
[/BOX]`,
	},
	"20-2": {
		Title:    "Asymptotes",
		Category: "Differential Calculus",
		Intro: `Asymptotes describe how a graph behaves far away or near a vertical blow-up.

[BOX]
Rules
Vertical: x = a if lim_{x→a} f(x) = ±∞
Horizontal: y = L if lim_{x→±∞} f(x) = L
Oblique: y = mx + q if
m = lim f(x)/x and q = lim (f(x) − mx) as x→±∞
[/BOX]

[BOX]
Example
f(x) = (2x + 1)/x = 2 + 1/x
Horizontal asymptote: y = 2
Vertical asymptote: x = 0
[/BOX]`,
	},
	"21": { Title: "The Derivative Concept", Category: "Differential Calculus", Intro: `Derivatives measure instantaneous rate of change and the slope of the tangent line.` },
	"21-0": {
		Title:    "Difference quotient",
		Category: "Differential Calculus",
		Intro: `The difference quotient is the average rate of change:

[BOX]
Formula
[f(x+h) − f(x)] / h   (h ≠ 0)
[/BOX]

[BOX]
Example
f(x)=x²:
[(x+h)² − x²]/h = (2xh + h²)/h = 2x + h
[/BOX]`,
	},
	"21-1": {
		Title:    "Geometric meaning",
		Category: "Differential Calculus",
		Intro: `The derivative is the limit of the difference quotient:

[BOX]
Definition
f'(x) = lim_{h→0} [f(x+h) − f(x)]/h
[/BOX]

Geometrically, f'(x₀) is the slope of the tangent line at (x₀, f(x₀)).

[BOX]
Example
f(x)=x² ⇒ f'(x)=2x
At x₀=1, slope = 2
Tangent: y − 1 = 2(x − 1) ⇒ y = 2x − 1
[/BOX]`,
	},
	"22": { Title: "Differentiation Rules", Category: "Differential Calculus", Intro: `Rules let you differentiate quickly without going back to the limit definition each time.` },
	"22-0": {
		Title:    "Power rule",
		Category: "Differential Calculus",
		Intro: `Power rule:

[BOX]
Formula
(xⁿ)' = n·xⁿ⁻¹
[/BOX]

[BOX]
Examples
(x⁵)' = 5x⁴
(√x)' = (x^(1/2))' = (1/2)x^(−1/2) = 1/(2√x)
[/BOX]`,
	},
	"22-1": {
		Title:    "Product rule",
		Category: "Differential Calculus",
		Intro: `Product rule:

[BOX]
Formula
(fg)' = f'g + fg'
[/BOX]

[BOX]
Example
f(x)=x², g(x)=eˣ
(x²eˣ)' = 2x·eˣ + x²·eˣ = eˣ(x² + 2x)
[/BOX]`,
	},
	"22-2": {
		Title:    "Quotient rule",
		Category: "Differential Calculus",
		Intro: `Quotient rule (g ≠ 0):

[BOX]
Formula
(f/g)' = (f'g − fg') / g²
[/BOX]

[BOX]
Example
(1/x)' = (x⁻¹)' = −x⁻² = −1/x²
[/BOX]`,
	},
	"22-3": {
		Title:    "Chain rule",
		Category: "Differential Calculus",
		Intro: `Chain rule for compositions:

[BOX]
Formula
If y = f(g(x)), then y' = f'(g(x))·g'(x)
[/BOX]

[BOX]
Examples
(e^(x²))' = e^(x²)·2x
(sin(2x))' = cos(2x)·2
[/BOX]`,
	},
	"23": { Title: "Function Study", Category: "Differential Calculus", Intro: `Derivatives help you locate extrema and changes in concavity.` },
	"23-0": {
		Title:    "Maxima and Minima",
		Category: "Differential Calculus",
		Intro: `Local extrema often occur at critical points (where f'(x)=0 or f' is undefined).

First derivative test:
- f' changes + → − : local maximum
- f' changes − → + : local minimum

[BOX]
Example
f(x)=x²
f'(x)=2x ⇒ critical point at x=0
f' changes from − to +, so x=0 is a local minimum (f(0)=0)
[/BOX]`,
	},
	"23-1": {
		Title:    "Points of inflection",
		Category: "Differential Calculus",
		Intro: `An inflection point is where concavity changes.

Often:
- Find where f''(x)=0 (candidates)
- Check if f'' changes sign

[BOX]
Example
f(x)=x³
f''(x)=6x
At x=0, f'' changes from negative to positive ⇒ inflection at (0,0)
[/BOX]`,
	},

	// ----------------
	// Integral Calculus
	// ----------------
	"24": { Title: "Indefinite Integrals", Category: "Integral Calculus", Intro: `Indefinite integrals give families of antiderivatives (primitive functions).` },
	"24-0": {
		Title:    "Primitive functions",
		Category: "Integral Calculus",
		Intro: `A function F is a primitive (antiderivative) of f if F'(x) = f(x).

[BOX]
Key idea
If F is a primitive, then F + C is also a primitive (C is any constant).
[/BOX]

[BOX]
Example
If f(x)=2x then a primitive is F(x)=x², because (x²)'=2x.
So ∫ 2x dx = x² + C.
[/BOX]`,
	},
	"24-1": {
		Title:    "Immediate integration rules",
		Category: "Integral Calculus",
		Intro: `Basic rules you should memorize:

[BOX]
Formulas
∫ xⁿ dx = xⁿ⁺¹/(n+1) + C   (n ≠ −1)
∫ 1/x dx = ln|x| + C
∫ eˣ dx = eˣ + C
∫ cos x dx = sin x + C
∫ sin x dx = −cos x + C
[/BOX]

[BOX]
Example
∫ (3x² + 2x + 1) dx = x³ + x² + x + C
[/BOX]`,
	},
	"25": { Title: "Integration Methods", Category: "Integral Calculus", Intro: `When the integral is not immediate, use substitution or integration by parts.` },
	"25-0": {
		Title:    "Integration by substitution",
		Category: "Integral Calculus",
		Intro: `Substitution is the inverse of the chain rule.

Idea:
- Set u = g(x)
- Replace dx using du = g'(x) dx

[BOX]
Example
∫ 2x·e^(x²) dx
Let u = x² ⇒ du = 2x dx
Then ∫ e^u du = e^u + C = e^(x²) + C
[/BOX]`,
	},
	"25-1": {
		Title:    "Integration by parts",
		Category: "Integral Calculus",
		Intro: `Integration by parts comes from the product rule.

[BOX]
Formula
∫ u dv = u·v − ∫ v du
[/BOX]

[BOX]
Example
∫ x eˣ dx
Choose u=x ⇒ du=dx
dv=eˣ dx ⇒ v=eˣ
Result: x eˣ − ∫ eˣ dx = x eˣ − eˣ + C = eˣ(x − 1) + C
[/BOX]`,
	},
	"26": { Title: "Definite Integrals", Category: "Integral Calculus", Intro: `Definite integrals compute net area and connect to antiderivatives via the Fundamental Theorem of Calculus.` },
	"26-0": {
		Title:    "Calculating the area under a curve",
		Category: "Integral Calculus",
		Intro: `The definite integral ∫_a^b f(x) dx represents signed area between the graph and the x-axis.

If f(x) ≥ 0 on [a,b], it equals geometric area.

[BOX]
Example
∫_0^1 x² dx is the area under y=x² from 0 to 1.
[/BOX]`,
	},
	"26-1": {
		Title:    "The Fundamental Theorem of Calculus",
		Category: "Integral Calculus",
		Intro: `If f is continuous on [a,b] and F is any antiderivative of f, then:

[BOX]
FTC
∫_a^b f(x) dx = F(b) − F(a)
[/BOX]

[BOX]
Example
∫_0^1 x² dx = [x³/3]_0^1 = 1/3
[/BOX]`,
	},
	"27": { Title: "Applications", Category: "Integral Calculus", Intro: `Integrals can compute areas and volumes in many real problems.` },
	"27-0": {
		Title:    "Calculation of volumes",
		Category: "Integral Calculus",
		Intro: `Disk method (rotation around the x-axis):

[BOX]
Formula
V = π ∫_a^b (f(x))² dx
[/BOX]

[BOX]
Example (cone)
Rotate y = (r/h)x on [0,h]:
V = π ∫_0^h (r²/h²)x² dx = (1/3)πr²h
[/BOX]`,
	},
	"27-1": {
		Title:    "Areas of plane figures",
		Category: "Integral Calculus",
		Intro: `Area between two curves y=f(x) and y=g(x) (with f ≥ g):

[BOX]
Formula
A = ∫_a^b (f(x) − g(x)) dx
[/BOX]

[BOX]
Example
Area between y=x and y=x² on [0,1]:
∫_0^1 (x − x²) dx = [x²/2 − x³/3]_0^1 = 1/6
[/BOX]`,
	},
}


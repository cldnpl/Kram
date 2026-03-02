package lesson

import (
	"github.com/gofiber/fiber/v2"
)

// getLessonDetail returns lesson content (detailed explanation) and topic-specific exercises for the given id.
func getLessonDetail(id string) (title, category string, content fiber.Map, exercises []fiber.Map) {
	switch id {
	case "1":
		title = "The Basics"
		category = "Arithmetic & Number Systems"
		content = fiber.Map{
			"intro": "Order of operations (PEMDAS / BODMAS)\n\nWhen you see an expression like 3 + 4 × 2, the order in which you perform operations matters. PEMDAS (Parentheses, Exponents, Multiplication and Division, Addition and Subtraction) or BODMAS (Brackets, Orders, Division and Multiplication, Addition and Subtraction) tells you: first do any calculations inside parentheses or brackets; then evaluate exponents (powers); then multiplication and division from left to right; finally addition and subtraction from left to right. So 3 + 4 × 2 = 3 + 8 = 11, not 14.\n\nLong division is a method for dividing multi-digit numbers. You divide the dividend by the divisor digit by digit, bringing down the next digit when needed, and writing the quotient on top. It relies on place value: each digit represents ones, tens, hundreds, and so on. Always align columns carefully so that ones line up with ones, tens with tens, etc.\n\nMulti-digit multiplication works the same way: multiply each digit of one number by each digit of the other, and add the partial products, shifting left for each new place (ones, tens, hundreds). For example, 23 × 45 = (23 × 5) + (23 × 40) = 115 + 920 = 1035. Mastering these basics is essential for all later arithmetic and algebra.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "What is 3 + 4 × 2?", "type": "multiple_choice", "options": []string{"11", "14", "10", "24"}, "correct_answer": "11", "xp_reward": 10},
			{"id": "e2", "question": "In 48 ÷ 6 × 2, what is the result?", "type": "multiple_choice", "options": []string{"4", "16", "12", "6"}, "correct_answer": "16", "xp_reward": 10},
		}
	case "2":
		title = "Fractions & Decimals"
		category = "Arithmetic & Number Systems"
		content = fiber.Map{
			"intro": "What is a fraction?\n\nA fraction a/b represents a part of a whole: the numerator a tells you how many parts you have, and the denominator b tells you into how many equal parts the whole is divided. For example, 3/4 means 3 parts out of 4 equal parts. Fractions can be proper (numerator smaller than denominator), improper (numerator larger), or mixed (a whole number plus a fraction).\n\nConverting between fractions and decimals\n\nTo convert a fraction to a decimal, divide the numerator by the denominator. For example, 3/4 = 3 ÷ 4 = 0.75. Some fractions give terminating decimals (like 1/2 = 0.5); others give repeating decimals, where a block of digits repeats forever (e.g. 1/3 = 0.333..., 1/7 = 0.142857142857...). To convert a terminating decimal to a fraction, write the decimal as the numerator and a power of 10 as the denominator (e.g. 0.75 = 75/100), then simplify.\n\nSimplification\n\nTo simplify a fraction, divide both the numerator and the denominator by their greatest common factor (GCF). For example, 8/12 has GCF 4, so 8/12 = 2/3. A fraction is in lowest terms when the numerator and denominator have no common factor other than 1.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "What is 3/4 as a decimal?", "type": "multiple_choice", "options": []string{"0.34", "0.75", "0.43", "3.4"}, "correct_answer": "0.75", "xp_reward": 10},
			{"id": "e2", "question": "Simplify 8/12 to lowest terms.", "type": "multiple_choice", "options": []string{"4/6", "2/3", "1/2", "8/12"}, "correct_answer": "2/3", "xp_reward": 10},
		}
	case "3":
		title = "Number Theory"
		category = "Arithmetic & Number Systems"
		content = fiber.Map{
			"intro": "Prime factorization\n\nEvery integer greater than 1 can be written uniquely as a product of prime numbers (up to the order of factors). This is the fundamental theorem of arithmetic. For example, 12 = 2 × 2 × 3 = 2² × 3. To find the prime factorization, divide the number by the smallest prime (2, 3, 5, 7, ...) and repeat with the quotient until you get 1.\n\nSieve of Eratosthenes\n\nThis ancient algorithm finds all primes up to a given limit. Write the numbers from 2 to n, then repeatedly cross out multiples of the smallest uncrossed number (2, then 3, then 5, ...). What remains are the primes. It is efficient for generating a list of small primes.\n\nEuclidean algorithm (GCF)\n\nThe greatest common factor (GCF) of two numbers is the largest integer that divides both. The Euclidean algorithm finds it by repeated division: gcd(a, b) = gcd(b, a mod b) until b = 0; then the GCF is the last nonzero remainder. For example, gcd(48, 18) = gcd(18, 12) = gcd(12, 6) = gcd(6, 0) = 6.\n\nModular arithmetic\n\nWe say a ≡ b (mod n) if a and b have the same remainder when divided by n. We work with remainders: for example, 7 mod 3 = 1, and (a + b) mod n = ((a mod n) + (b mod n)) mod n. Modular arithmetic is used in cryptography, coding theory, and many algorithms.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "What is the prime factorization of 18?", "type": "multiple_choice", "options": []string{"2 × 9", "3 × 6", "2 × 3²", "18"}, "correct_answer": "2 × 3²", "xp_reward": 12},
			{"id": "e2", "question": "What is 14 mod 5?", "type": "multiple_choice", "options": []string{"2", "3", "4", "0"}, "correct_answer": "4", "xp_reward": 10},
		}
	case "4":
		title = "Scientific Notation"
		category = "Arithmetic & Number Systems"
		content = fiber.Map{
			"intro": "What is scientific notation?\n\nScientific notation writes numbers in the form a × 10ⁿ where 1 ≤ |a| < 10 (one nonzero digit to the left of the decimal) and n is an integer. For example, 5,400,000 = 5.4 × 10⁶ and 0.00032 = 3.2 × 10⁻⁴. This makes very large and very small numbers easier to read, compare, and use in calculations.\n\nPowers of 10\n\nMultiplying by 10ⁿ shifts the decimal point n places to the right (or left if n is negative). So 3.5 × 10³ = 3500 and 3.5 × 10⁻² = 0.035. When multiplying two numbers in scientific notation, multiply the decimal parts and add the exponents: (a × 10ⁿ)(b × 10ᵐ) = (ab) × 10ⁿ⁺ᵐ.\n\nSignificant figures\n\nSignificant figures are the digits in a number that carry meaning (precision). Rules: nonzero digits are always significant; zeros between nonzero digits are significant; leading zeros are not; trailing zeros are significant if there is a decimal point. For example, 0.00340 has three significant figures. When multiplying or dividing, round the result to the same number of significant figures as the least precise factor.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "Write 5,400 in scientific notation.", "type": "multiple_choice", "options": []string{"54 × 10²", "5.4 × 10³", "0.54 × 10⁴", "5.4 × 10²"}, "correct_answer": "5.4 × 10³", "xp_reward": 10},
			{"id": "e2", "question": "How many significant figures does 0.00340 have?", "type": "multiple_choice", "options": []string{"2", "3", "5", "4"}, "correct_answer": "3", "xp_reward": 10},
		}
	case "5":
		title = "Linear Algebra"
		category = "Algebra (The Core)"
		content = fiber.Map{
			"intro": "Slope-intercept form (y = mx + b)\n\nEvery non-vertical line in the plane can be written as y = mx + b. Here m is the slope (rise over run: the change in y divided by the change in x) and b is the y-intercept (the y-coordinate where the line crosses the y-axis). If you know the slope and one point, you can find b by substituting that point into the equation.\n\nPoint-slope form\n\nIf you know the slope m and a point (x₁, y₁) on the line, the equation is y - y₁ = m(x - x₁). This is useful when you are given two points: first find the slope m = (y₂ - y₁)/(x₂ - x₁), then plug into point-slope form with either point.\n\nSolving systems of linear equations\n\nA system of two equations in two unknowns (e.g. 2x + y = 5 and x - y = 1) has a solution (x, y) that satisfies both. Substitution: solve one equation for one variable and substitute into the other, then solve. Elimination: add or subtract multiples of the equations so that one variable cancels, then solve for the other and back-substitute. Both methods give the same solution.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "In y = 2x + 3, what is the slope?", "type": "multiple_choice", "options": []string{"3", "2", "x", "y"}, "correct_answer": "2", "xp_reward": 10},
			{"id": "e2", "question": "For the line through (1,2) with slope 4, point-slope form is:", "type": "multiple_choice", "options": []string{"y - 2 = 4(x - 1)", "y = 4x + 1", "y - 1 = 4(x - 2)", "y + 2 = 4(x + 1)"}, "correct_answer": "y - 2 = 4(x - 1)", "xp_reward": 12},
		}
	case "6":
		title = "Polynomials"
		category = "Algebra (The Core)"
		content = fiber.Map{
			"intro": "FOIL (First, Outer, Inner, Last)\n\nTo multiply two binomials (a + b)(c + d), multiply each term in the first by each term in the second: First (a×c), Outer (a×d), Inner (b×c), Last (b×d), then add: ac + ad + bc + bd. Example: (x + 3)(x + 2) = x² + 2x + 3x + 6 = x² + 5x + 6.\n\nDifference of squares\n\nThe identity a² - b² = (a + b)(a - b) lets you factor a difference of two perfect squares into a product of two binomials. For example, x² - 9 = (x + 3)(x - 3). This is used in factoring, simplifying expressions, and solving equations.\n\nSynthetic division\n\nSynthetic division is a shortcut for dividing a polynomial by a linear factor (x - c). You write the coefficients of the polynomial and c, then perform a simple algorithm that gives the quotient and remainder. It is faster than long division when the divisor is of the form x - c.\n\nBinomial theorem\n\nThe binomial theorem expands (a + b)ⁿ as a sum of terms of the form C(n,k) aⁿ⁻ᵏ bᵏ, where C(n,k) are binomial coefficients (from Pascal's triangle). For example, (a + b)² = a² + 2ab + b² and (a + b)³ = a³ + 3a²b + 3ab² + b³.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "Expand (x + 3)(x + 2) using FOIL.", "type": "multiple_choice", "options": []string{"x² + 5x + 6", "x² + 6", "x² + 5x + 5", "2x² + 5x + 6"}, "correct_answer": "x² + 5x + 6", "xp_reward": 12},
			{"id": "e2", "question": "Factor x² - 9 using difference of squares.", "type": "multiple_choice", "options": []string{"(x-3)²", "(x+3)(x-3)", "(x-9)(x+1)", "x(x-9)"}, "correct_answer": "(x+3)(x-3)", "xp_reward": 12},
		}
	case "7":
		title = "Quadratic Equations"
		category = "Algebra (The Core)"
		content = fiber.Map{
			"intro": "Completing the square\n\nTo solve ax² + bx + c = 0 or to rewrite it in vertex form, we complete the square. For x² + bx, add (b/2)² to get x² + bx + (b/2)² = (x + b/2)². Then solve (x + b/2)² = (b/2)² - c (after moving c to the right). This always works and leads to the quadratic formula.\n\nThe discriminant\n\nThe discriminant of ax² + bx + c = 0 is Δ = b² - 4ac. It tells you how many real roots there are: if Δ > 0, there are two distinct real roots; if Δ = 0, there is one repeated real root (a double root); if Δ < 0, there are no real roots (two complex roots). So you can decide the number and type of roots without solving.\n\nVertex form\n\nThe vertex form of a parabola is y = a(x - h)² + k. The vertex (turning point) is at (h, k). If a > 0 the parabola opens upward; if a < 0 it opens downward. Converting from standard form to vertex form is done by completing the square.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "For x² - 4x + 3 = 0, the discriminant is:", "type": "multiple_choice", "options": []string{"-4", "4", "0", "16"}, "correct_answer": "4", "xp_reward": 12},
			{"id": "e2", "question": "The vertex of y = (x - 2)² + 5 is at:", "type": "multiple_choice", "options": []string{"(-2, 5)", "(2, 5)", "(2, -5)", "(-2, -5)"}, "correct_answer": "(2, 5)", "xp_reward": 10},
		}
	case "8":
		title = "Inequalities"
		category = "Algebra (The Core)"
		content = fiber.Map{
			"intro": "Linear inequalities in two variables\n\nAn inequality like y < 2x + 1 or y ≥ 3x - 2 describes a region of the plane, not just a line. First graph the boundary line (y = 2x + 1 or y = 3x - 2). Use a dashed line for strict inequalities (< or >) and a solid line for non-strict (≤ or ≥).\n\nShading the region\n\nFor y < (or ≤) mx + b, shade the region below the line; for y > (or ≥) mx + b, shade above. To check which side to shade, pick a test point not on the line (often (0,0) if it is not on the line) and see whether it satisfies the inequality. If it does, shade that side; otherwise shade the other side. The solution set of a system of inequalities is the overlap (intersection) of the shaded regions.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "For y ≤ 3x - 2, which region do we shade?", "type": "multiple_choice", "options": []string{"Above the line", "Below the line", "On the line only", "Neither"}, "correct_answer": "Below the line", "xp_reward": 10},
			{"id": "e2", "question": "For a strict inequality we use a _____ line.", "type": "multiple_choice", "options": []string{"solid", "dashed", "thick", "curved"}, "correct_answer": "dashed", "xp_reward": 8},
		}
	case "9":
		title = "Advanced Algebra"
		category = "Algebra (The Core)"
		content = fiber.Map{
			"intro": "Logarithmic laws\n\nThe logarithm log_b(a) answers: b to what power equals a? So log(ab) = log a + log b (product rule), log(a/b) = log a - log b (quotient rule), and log(aⁿ) = n log a (power rule). The natural logarithm ln x uses base e. These laws let you simplify and solve exponential and logarithmic equations.\n\nInverse functions\n\nA function f has an inverse f⁻¹ if f⁻¹(f(x)) = x and f(f⁻¹(y)) = y whenever defined. So f⁻¹ \"undoes\" f. For example, if f(x) = 2x + 1, then f⁻¹(x) = (x - 1)/2. Not every function has an inverse; only one-to-one functions do. The graph of f⁻¹ is the reflection of the graph of f across the line y = x.\n\nMatrix multiplication and Cramer's rule\n\nMatrices can be multiplied when the number of columns of the first equals the number of rows of the second; the (i,j) entry of the product is the dot product of row i of the first with column j of the second. Cramer's rule gives a formula for the solution of a linear system Ax = b using determinants: x_i = det(A_i)/det(A), where A_i is A with the i-th column replaced by b. It is mainly used for small systems.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "log(10) + log(100) equals:", "type": "multiple_choice", "options": []string{"log(110)", "log(1000)", "2", "3"}, "correct_answer": "3", "xp_reward": 12},
			{"id": "e2", "question": "If f(x) = 2x + 1, then f⁻¹(5) equals:", "type": "multiple_choice", "options": []string{"11", "2", "9", "4"}, "correct_answer": "2", "xp_reward": 12},
		}
	case "10":
		title = "Euclidean Laws"
		category = "Geometry & Trigonometry"
		content = fiber.Map{
			"intro": "Parallel lines and transversals\n\nWhen a transversal crosses two parallel lines, corresponding angles are equal, alternate interior angles are equal, and same-side interior angles are supplementary (add to 180°). These facts are used constantly in proofs and in finding unknown angles in figures.\n\nCongruent triangles (SSS, SAS, ASA)\n\nTwo triangles are congruent if they have the same size and shape (all sides and angles match). We can prove congruence using: SSS (three sides equal), SAS (two sides and the included angle equal), or ASA (two angles and the included side equal). Note: SSA (or ASS) is not a valid congruence criterion. Congruence implies that all corresponding parts are equal.\n\nPythagorean theorem\n\nIn a right triangle with legs a and b and hypotenuse c, a² + b² = c². The hypotenuse is the side opposite the right angle. This is used to find a missing side length when two sides are known, and it is the basis for distance in the coordinate plane and for trigonometry.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "In a right triangle with legs 3 and 4, the hypotenuse is:", "type": "multiple_choice", "options": []string{"5", "7", "12", "6"}, "correct_answer": "5", "xp_reward": 10},
			{"id": "e2", "question": "Which criterion proves triangle congruence?", "type": "multiple_choice", "options": []string{"AAA", "SSA", "SSS", "ASS"}, "correct_answer": "SSS", "xp_reward": 10},
		}
	case "11":
		title = "Circles"
		category = "Geometry & Trigonometry"
		content = fiber.Map{
			"intro": "Chords and tangents\n\nA chord is a line segment whose endpoints lie on the circle. The perpendicular from the center to a chord bisects the chord. A tangent is a line that touches the circle at exactly one point; the radius to that point is perpendicular to the tangent. Two tangents from an external point to a circle are equal in length.\n\nSector area and arc length\n\nThe area of a sector (a \"slice\" of the circle with central angle θ in degrees) is (θ/360°) × πr². So a semicircle (θ = 180°) has area (1/2)πr². The arc length (the length of the curved part of the sector) is (θ/360°) × 2πr, which is the same fraction of the full circumference 2πr. In radians, sector area = (1/2)r²θ and arc length = rθ.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "For a circle of radius 6, the area of a 90° sector is:", "type": "multiple_choice", "options": []string{"9π", "36π", "6π", "12π"}, "correct_answer": "9π", "xp_reward": 12},
			{"id": "e2", "question": "A line that touches a circle at exactly one point is a:", "type": "multiple_choice", "options": []string{"chord", "secant", "tangent", "radius"}, "correct_answer": "tangent", "xp_reward": 8},
		}
	case "12":
		title = "Solid Geometry"
		category = "Geometry & Trigonometry"
		content = fiber.Map{
			"intro": "Euler's formula for polyhedra\n\nA polyhedron is a 3D shape with flat faces. For any convex polyhedron, V - E + F = 2, where V = number of vertices, E = number of edges, F = number of faces. For example, a cube has V = 8, F = 6, so E = 8 - 2 + 6 = 12. This identity is a fundamental result in geometry and topology.\n\nVolume of pyramids and cones\n\nThe volume of a pyramid (or cone) with base area B and height h is V = (1/3)Bh. So it is one-third of the volume of a prism (or cylinder) with the same base and height. For a cone with radius r and height h, B = πr², so V = (1/3)πr²h. This can be derived by integration or by comparing with a circumscribed prism.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "A cube has 8 vertices and 6 faces. How many edges?", "type": "multiple_choice", "options": []string{"10", "12", "14", "16"}, "correct_answer": "12", "xp_reward": 12},
			{"id": "e2", "question": "Volume of a cone with base radius 3 and height 4:", "type": "multiple_choice", "options": []string{"12π", "36π", "6π", "24π"}, "correct_answer": "12π", "xp_reward": 12},
		}
	case "13":
		title = "Trigonometry"
		category = "Geometry & Trigonometry"
		content = fiber.Map{
			"intro": "Law of Sines and Law of Cosines\n\nIn any triangle, the Law of Sines states a/sin A = b/sin B = c/sin C (sides opposite angles A, B, C). It is useful when you know two angles and a side, or two sides and a non-included angle. The Law of Cosines is c² = a² + b² - 2ab cos C; it generalizes the Pythagorean theorem and is used when you know two sides and the included angle, or all three sides.\n\nDouble-angle identities\n\nsin(2θ) = 2 sin θ cos θ and cos(2θ) = cos²θ - sin²θ = 2cos²θ - 1 = 1 - 2sin²θ. These express trig functions of 2θ in terms of θ and are used in integration, solving equations, and simplifying expressions.\n\nInverse trig functions\n\narcsin, arccos, and arctan return the angle (usually in a restricted range) whose sine, cosine, or tangent is the given number. For example, arcsin(1) = π/2, arccos(0) = π/2, arctan(1) = π/4. They are the inverses of sin, cos, tan on restricted domains.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "sin(2θ) equals:", "type": "multiple_choice", "options": []string{"2 sin θ", "sin θ + sin θ", "2 sin θ cos θ", "sin² θ"}, "correct_answer": "2 sin θ cos θ", "xp_reward": 12},
			{"id": "e2", "question": "arcsin(1) in radians is:", "type": "multiple_choice", "options": []string{"0", "π/2", "π", "π/4"}, "correct_answer": "π/2", "xp_reward": 10},
		}
	case "14":
		title = "Functions"
		category = "Pre-Calculus & Analysis"
		content = fiber.Map{
			"intro": "Even and odd functions\n\nA function f is even if f(-x) = f(x) for all x in the domain; its graph is symmetric about the y-axis (e.g. f(x) = x², cos x). A function is odd if f(-x) = -f(x); its graph is symmetric about the origin (e.g. f(x) = x³, sin x). Many functions are neither. Knowing even/odd can simplify integrals and series.\n\nAsymptotes\n\nA vertical asymptote occurs at x = a if the function grows without bound (or tends to ±∞) as x approaches a (e.g. 1/x has a vertical asymptote at x = 0). A horizontal asymptote is a horizontal line y = L that the graph approaches as x → ∞ or x → -∞; it describes long-run behavior. For rational functions, horizontal asymptotes depend on the degrees of numerator and denominator.\n\nPiecewise functions\n\nA piecewise function is defined by different formulas on different intervals. For example, |x| = x if x ≥ 0 and -x if x < 0. When evaluating or graphing, use the formula that applies to the relevant interval.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "f(x) = x² is:", "type": "multiple_choice", "options": []string{"odd", "even", "neither", "both"}, "correct_answer": "even", "xp_reward": 10},
			{"id": "e2", "question": "f(x) = 1/x has a vertical asymptote at:", "type": "multiple_choice", "options": []string{"y = 0", "x = 1", "x = 0", "x = -1"}, "correct_answer": "x = 0", "xp_reward": 10},
		}
	case "15":
		title = "Sequences"
		category = "Pre-Calculus & Analysis"
		content = fiber.Map{
			"intro": "Arithmetic sequences\n\nIn an arithmetic sequence, each term is obtained by adding a fixed number d (the common difference) to the previous term. The n-th term is aₙ = a₁ + (n - 1)d. For example, 2, 5, 8, 11, ... has a₁ = 2 and d = 3, so aₙ = 2 + 3(n - 1). The sum of the first n terms is Sₙ = n(a₁ + aₙ)/2 = n/2 × (first + last).\n\nGeometric sequences\n\nIn a geometric sequence, each term is obtained by multiplying the previous term by a fixed number r (the common ratio). The n-th term is aₙ = a₁·rⁿ⁻¹. For example, 1, 1/2, 1/4, ... has a₁ = 1 and r = 1/2. The sum of the first n terms is Sₙ = a₁(1 - rⁿ)/(1 - r) when r ≠ 1.\n\nSum to infinity\n\nFor a geometric sequence with |r| < 1, the sum to infinity (the limit of Sₙ as n → ∞) is S = a₁/(1 - r). For example, 1 + 1/2 + 1/4 + ... = 1/(1 - 1/2) = 2. If |r| ≥ 1 and a₁ ≠ 0, the series diverges.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "In 2, 5, 8, 11,..., the common difference is:", "type": "multiple_choice", "options": []string{"2", "3", "5", "8"}, "correct_answer": "3", "xp_reward": 10},
			{"id": "e2", "question": "Sum to infinity of 1 + 1/2 + 1/4 + ... equals:", "type": "multiple_choice", "options": []string{"1", "2", "∞", "1/2"}, "correct_answer": "2", "xp_reward": 12},
		}
	case "16":
		title = "Limits"
		category = "Pre-Calculus & Analysis"
		content = fiber.Map{
			"intro": "The squeeze theorem\n\nIf g(x) ≤ f(x) ≤ h(x) for all x near a (except possibly at a), and if lim_{x→a} g(x) = lim_{x→a} h(x) = L, then lim_{x→a} f(x) = L. So f is \"squeezed\" between g and h and must have the same limit. This is especially useful when f is hard to evaluate directly (e.g. lim_{x→0} (sin x)/x = 1).\n\nL'Hôpital's rule\n\nWhen lim f(x)/g(x) is in the indeterminate form 0/0 or ∞/∞, and f and g are differentiable, then lim f(x)/g(x) = lim f'(x)/g'(x) (provided the limit on the right exists or is ±∞). So we can replace the ratio by the ratio of derivatives. Use it repeatedly if needed. It does not apply to forms like 0×∞ or 1^∞ without rewriting.\n\nLimits at infinity\n\nLimits as x → ∞ or x → -∞ describe horizontal asymptotes and long-run behavior. For rational functions, compare the degrees of numerator and denominator; for exponentials and logarithms, use known growth rates.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "lim (x→0) sin(x)/x equals:", "type": "multiple_choice", "options": []string{"0", "1", "∞", "undefined"}, "correct_answer": "1", "xp_reward": 12},
			{"id": "e2", "question": "L'Hôpital's rule applies when the limit is in the form:", "type": "multiple_choice", "options": []string{"1/1", "0/0 or ∞/∞", "0 × ∞", "1^∞"}, "correct_answer": "0/0 or ∞/∞", "xp_reward": 10},
		}
	case "17":
		title = "Fundamental Rules"
		category = "Differential Calculus (Derivatives)"
		content = fiber.Map{
			"intro": "Power rule\n\nThe derivative of xⁿ (n any real number) is nxⁿ⁻¹. So d/dx(x⁴) = 4x³, d/dx(√x) = d/dx(x^{1/2}) = (1/2)x^{-1/2} = 1/(2√x). This is one of the most used rules and is derived from the limit definition of the derivative.\n\nProduct rule\n\nFor a product of two functions, (fg)' = f'g + fg'. So the derivative of a product is not the product of the derivatives. For example, (x² sin x)' = 2x sin x + x² cos x. Remember: derivative of first times second, plus first times derivative of second.\n\nQuotient rule\n\nFor a quotient, (f/g)' = (f'g - fg')/g². So the derivative of f/g has the denominator g² and the numerator f'g - fg'. A common mnemonic: \"low d-high minus high d-low, over low squared.\"\n\nChain rule\n\nFor a composition f(g(x)), the derivative is d/dx f(g(x)) = f'(g(x))·g'(x). So you take the derivative of the \"outer\" function evaluated at the inner function, and multiply by the derivative of the inner function. For example, d/dx sin(x²) = cos(x²)·2x.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "d/dx(x⁴) equals:", "type": "multiple_choice", "options": []string{"4x³", "x³", "4x⁴", "3x⁴"}, "correct_answer": "4x³", "xp_reward": 10},
			{"id": "e2", "question": "For (fg)', we use the _____ rule.", "type": "multiple_choice", "options": []string{"chain", "product", "quotient", "power"}, "correct_answer": "product", "xp_reward": 8},
		}
	case "18":
		title = "Transcendental Derivatives"
		category = "Differential Calculus (Derivatives)"
		content = fiber.Map{
			"intro": "Derivative of e^x\n\nThe exponential function e^x has the unique property that it is its own derivative: d/dx(e^x) = e^x. So the slope of the curve y = e^x at any point equals the value of the function at that point. This is why e is the natural base for exponentials and logarithms in calculus.\n\nDerivative of ln x\n\nFor x > 0, d/dx(ln x) = 1/x. So the natural logarithm is the antiderivative of 1/x. This follows from the fact that ln x and e^x are inverses: differentiating ln(e^x) = x gives (1/e^x)·e^x = 1, and the derivative of ln x comes from the inverse function rule.\n\nDerivatives of sin x and cos x\n\nd/dx(sin x) = cos x and d/dx(cos x) = -sin x. So sine and cosine alternate under differentiation. From these we get d/dx(tan x) = sec²x and the other trig derivatives. When the argument is a function of x (e.g. sin(2x)), use the chain rule: d/dx sin(2x) = cos(2x)·2.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "d/dx(e^x) equals:", "type": "multiple_choice", "options": []string{"xe^(x-1)", "e^x", "0", "1"}, "correct_answer": "e^x", "xp_reward": 10},
			{"id": "e2", "question": "d/dx(ln x) for x > 0 is:", "type": "multiple_choice", "options": []string{"1/x", "x", "ln x", "1"}, "correct_answer": "1/x", "xp_reward": 10},
		}
	case "19":
		title = "Applications"
		category = "Differential Calculus (Derivatives)"
		content = fiber.Map{
			"intro": "Implicit differentiation\n\nWhen y is given implicitly by an equation (e.g. x² + y² = 25 or x³ + y³ = 6xy), we differentiate both sides with respect to x, treating y as a function of x. Every time we differentiate a term in y, we multiply by dy/dx (chain rule). Then we solve for dy/dx. This gives the slope of the curve without solving for y explicitly.\n\nMean Value Theorem (MVT)\n\nIf f is continuous on [a,b] and differentiable on (a,b), then there exists at least one c in (a,b) such that f'(c) = (f(b) - f(a))/(b - a). So the average rate of change over [a,b] equals the instantaneous rate of change at some point c. The MVT is used to prove many other theorems and to bound function values.\n\nFirst and second derivative tests\n\nWhere f'(x) = 0 (critical points), the first derivative test checks the sign of f' on either side to decide local max or min. The second derivative test: if f''(c) > 0 at a critical point c, then f has a local minimum there; if f''(c) < 0, a local maximum. f'' also indicates concavity: f'' > 0 means the graph is concave up; f'' < 0 means concave down. Points where concavity changes are inflection points.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "Where f'(x) = 0 and f''(x) > 0, we have a:", "type": "multiple_choice", "options": []string{"local max", "local min", "inflection point", "none"}, "correct_answer": "local min", "xp_reward": 12},
			{"id": "e2", "question": "The Mean Value Theorem relates f' to:", "type": "multiple_choice", "options": []string{"area", "average rate of change", "limit", "integral"}, "correct_answer": "average rate of change", "xp_reward": 10},
		}
	case "20":
		title = "Integration Basics"
		category = "Integral Calculus (Accumulation)"
		content = fiber.Map{
			"intro": "Fundamental Theorem of Calculus (FTC)\n\nPart I: If f is continuous on [a,b] and F is any antiderivative of f (i.e. F' = f), then ∫_a^b f(x)dx = F(b) - F(a). So the definite integral is computed by evaluating an antiderivative at the endpoints and subtracting. This links the two main ideas of calculus: derivatives and accumulation.\n\nPart II: If f is continuous and we define F(x) = ∫_a^x f(t)dt, then F'(x) = f(x). So the derivative of the integral (with variable upper limit) gives back the integrand. This says that integration and differentiation are inverse operations.\n\nRiemann sums\n\nA Riemann sum approximates ∫_a^b f(x)dx by dividing [a,b] into subintervals, choosing a sample point in each, and summing f(sample) × (width). The limit of these sums as the partition gets finer is the definite integral. Left, right, and midpoint sums are common approximations; the limit is the same for any choice of sample points when f is integrable.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "∫₀¹ x² dx equals:", "type": "multiple_choice", "options": []string{"1/2", "1/3", "1", "2"}, "correct_answer": "1/3", "xp_reward": 12},
			{"id": "e2", "question": "FTC Part II says d/dx ∫ₐˣ f(t)dt =", "type": "multiple_choice", "options": []string{"F(x)", "f(a)", "f(x)", "0"}, "correct_answer": "f(x)", "xp_reward": 10},
		}
	case "21":
		title = "Techniques"
		category = "Integral Calculus (Accumulation)"
		content = fiber.Map{
			"intro": "U-substitution\n\nThis reverses the chain rule. If you see an integral of the form ∫ f(g(x)) g'(x) dx, let u = g(x), so du = g'(x)dx. Then the integral becomes ∫ f(u) du, which may be easier. For example, ∫ 2x e^{x²} dx: let u = x², du = 2x dx, so the integral is ∫ e^u du = e^u + C = e^{x²} + C. Always substitute back to the original variable unless you change the limits to u.\n\nIntegration by parts\n\nThe formula ∫ u dv = uv - ∫ v du comes from the product rule (uv)' = u'v + uv'. Choose u and dv so that du and v are easy to find and ∫ v du is simpler than ∫ u dv. Typically we let u be a function that simplifies when differentiated (e.g. ln x, xⁿ) and dv be the rest of the integrand.\n\nPartial fractions and trig substitution\n\nPartial fractions decompose a rational function into simpler fractions that can be integrated term by term. Trig substitution (e.g. x = a sin θ for √(a² - x²)) uses trigonometric identities to turn certain radicals into expressions that are easier to integrate.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "Integration by parts comes from the _____ rule.", "type": "multiple_choice", "options": []string{"chain", "quotient", "product", "power"}, "correct_answer": "product", "xp_reward": 10},
			{"id": "e2", "question": "For ∫ 2x·e^(x²) dx, a good substitution is u =", "type": "multiple_choice", "options": []string{"2x", "e^x", "x²", "e^(x²)"}, "correct_answer": "x²", "xp_reward": 12},
		}
	case "22":
		title = "Applications"
		category = "Integral Calculus (Accumulation)"
		content = fiber.Map{
			"intro": "Area between two curves\n\nIf f(x) ≥ g(x) on [a,b], the area between the curves y = f(x) and y = g(x) from x = a to x = b is ∫_a^b (f(x) - g(x)) dx. So we integrate the difference (top minus bottom). If the curves cross, split the interval at the intersection points and compute the integral of |f(x) - g(x)| on each subinterval, or use the formula with the correct order of f and g on each part.\n\nSolids of revolution: disk and washer methods\n\nWhen you rotate the region under y = f(x) from x = a to x = b about the x-axis, each vertical slice becomes a disk of radius f(x). The volume is ∫_a^b π (f(x))² dx (disk method). When the region is between two curves y = f(x) and y = g(x) (with f ≥ g), rotation about the x-axis gives a \"washer\": outer radius f(x), inner radius g(x). The volume is ∫_a^b π (f(x)² - g(x)²) dx (washer method). So we use the disk when there is no hole, and the washer when there is a hole in the solid.",
		}
		exercises = []fiber.Map{
			{"id": "e1", "question": "Area between y = x² and y = x from 0 to 1 is given by:", "type": "multiple_choice", "options": []string{"∫₀¹ x² dx", "∫₀¹ (x - x²) dx", "∫₀¹ x dx", "∫₀¹ (x² - x) dx"}, "correct_answer": "∫₀¹ (x - x²) dx", "xp_reward": 12},
			{"id": "e2", "question": "The washer method is used when the solid has a:", "type": "multiple_choice", "options": []string{"hole", "curve", "vertex", "tangent"}, "correct_answer": "hole", "xp_reward": 10},
		}
	default:
		title = "Lesson"
		category = "Math"
		content = fiber.Map{"intro": "Review the topic and practice the exercises below."}
		exercises = []fiber.Map{
			{"id": "e1", "question": "What is 7 + 5?", "type": "multiple_choice", "options": []string{"10", "12", "13", "14"}, "correct_answer": "12", "xp_reward": 10},
			{"id": "e2", "question": "What is 3 × 4?", "type": "multiple_choice", "options": []string{"7", "12", "14", "9"}, "correct_answer": "12", "xp_reward": 10},
		}
	}
	return
}

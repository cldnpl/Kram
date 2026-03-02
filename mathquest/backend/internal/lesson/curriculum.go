package lesson

import "github.com/gofiber/fiber/v2"

// curriculum returns the full math curriculum: categories and subtopics.
func curriculum() []fiber.Map {
	return []fiber.Map{
		{
			"id":        "arithmetic",
			"title":     "Arithmetic & Number Systems",
			"subtopics": arithmeticSubtopics(),
		},
		{
			"id":        "algebra",
			"title":     "Algebra (The Core)",
			"subtopics": algebraSubtopics(),
		},
		{
			"id":        "geometry",
			"title":     "Geometry & Trigonometry",
			"subtopics": geometrySubtopics(),
		},
		{
			"id":        "precalc",
			"title":     "Pre-Calculus & Analysis",
			"subtopics": precalcSubtopics(),
		},
		{
			"id":        "differential",
			"title":     "Differential Calculus (Derivatives)",
			"subtopics": differentialSubtopics(),
		},
		{
			"id":        "integral",
			"title":     "Integral Calculus (Accumulation)",
			"subtopics": integralSubtopics(),
		},
	}
}

func arithmeticSubtopics() []fiber.Map {
	return []fiber.Map{
		{"id": "1", "title": "The Basics", "description": "PEMDAS/BODMAS, Long Division, Multi-digit Multiplication", "coin_cost": 10, "coin_reward": 15, "difficulty": 1},
		{"id": "2", "title": "Fractions & Decimals", "description": "Converting between them, Simplification, Repeating Decimals", "coin_cost": 12, "coin_reward": 18, "difficulty": 2},
		{"id": "3", "title": "Number Theory", "description": "Prime Factorization, Sieve of Eratosthenes, Euclidean Algorithm (for GCF), Modular Arithmetic", "coin_cost": 15, "coin_reward": 25, "difficulty": 3},
		{"id": "4", "title": "Scientific Notation", "description": "Powers of 10, Significant Figures", "coin_cost": 10, "coin_reward": 15, "difficulty": 1},
	}
}

func algebraSubtopics() []fiber.Map {
	return []fiber.Map{
		{"id": "5", "title": "Linear Algebra", "description": "Slope-Intercept Form (y=mx+b), Point-Slope Form, Solving Systems (Substitution vs. Elimination)", "coin_cost": 15, "coin_reward": 25, "difficulty": 2},
		{"id": "6", "title": "Polynomials", "description": "FOIL Method, Difference of Squares, Synthetic Division, Binomial Theorem", "coin_cost": 18, "coin_reward": 28, "difficulty": 3},
		{"id": "7", "title": "Quadratic Equations", "description": "Completing the Square, The Discriminant, Vertex Form", "coin_cost": 15, "coin_reward": 25, "difficulty": 2},
		{"id": "8", "title": "Inequalities", "description": "Graphing Linear Inequalities, Shading Regions", "coin_cost": 12, "coin_reward": 20, "difficulty": 2},
		{"id": "9", "title": "Advanced Algebra", "description": "Logarithmic Laws, Inverse Functions, Matrix Multiplication, Cramer's Rule", "coin_cost": 25, "coin_reward": 40, "difficulty": 4},
	}
}

func geometrySubtopics() []fiber.Map {
	return []fiber.Map{
		{"id": "10", "title": "Euclidean Laws", "description": "Parallel Lines & Transversals, Congruent Triangles (SSS, SAS, ASA), Pythagorean Theorem", "coin_cost": 15, "coin_reward": 25, "difficulty": 2},
		{"id": "11", "title": "Circles", "description": "Chord Properties, Tangents, Sector Area, Arc Length", "coin_cost": 15, "coin_reward": 25, "difficulty": 2},
		{"id": "12", "title": "Solid Geometry", "description": "Euler's Formula for Polyhedra (V−E+F=2), Volume of Pyramids and Cones", "coin_cost": 18, "coin_reward": 28, "difficulty": 3},
		{"id": "13", "title": "Trigonometry", "description": "Law of Sines/Cosines, Double Angle Identities, Inverse Trig (Arcsin, Arccos)", "coin_cost": 20, "coin_reward": 32, "difficulty": 3},
	}
}

func precalcSubtopics() []fiber.Map {
	return []fiber.Map{
		{"id": "14", "title": "Functions", "description": "Even vs. Odd functions, Vertical/Horizontal Asymptotes, Piecewise Functions", "coin_cost": 18, "coin_reward": 28, "difficulty": 3},
		{"id": "15", "title": "Sequences", "description": "Arithmetic vs. Geometric Progressions, Sum to Infinity", "coin_cost": 15, "coin_reward": 25, "difficulty": 2},
		{"id": "16", "title": "Limits", "description": "Squeeze Theorem, L'Hôpital's Rule (conceptual intro), Limits at Infinity", "coin_cost": 22, "coin_reward": 35, "difficulty": 4},
	}
}

func differentialSubtopics() []fiber.Map {
	return []fiber.Map{
		{"id": "17", "title": "Fundamental Rules", "description": "Power, Product, Quotient, and Chain Rule", "coin_cost": 20, "coin_reward": 32, "difficulty": 3},
		{"id": "18", "title": "Transcendental Derivatives", "description": "Derivatives of e^x, ln(x), and sin(x)", "coin_cost": 18, "coin_reward": 28, "difficulty": 3},
		{"id": "19", "title": "Applications", "description": "Implicit Differentiation, Mean Value Theorem, First/Second Derivative Tests (for concavity)", "coin_cost": 25, "coin_reward": 40, "difficulty": 4},
	}
}

func integralSubtopics() []fiber.Map {
	return []fiber.Map{
		{"id": "20", "title": "Integration Basics", "description": "Fundamental Theorem of Calculus (Parts I & II), Riemann Sums", "coin_cost": 22, "coin_reward": 35, "difficulty": 4},
		{"id": "21", "title": "Techniques", "description": "U-Substitution, Integration by Parts, Partial Fractions, Trig Substitution", "coin_cost": 25, "coin_reward": 40, "difficulty": 4},
		{"id": "22", "title": "Applications", "description": "Area between two curves, Solids of Revolution (Disk/Washer method)", "coin_cost": 22, "coin_reward": 35, "difficulty": 4},
	}
}

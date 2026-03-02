package lesson

import "github.com/gofiber/fiber/v2"

// curriculum returns the full math curriculum: 6 categories and their subtopics.
func curriculum() []fiber.Map {
	return []fiber.Map{
		{
			"id":        "arithmetic",
			"title":     "Arithmetic & Number Systems",
			"subtopics": arithmeticSubtopics(),
		},
		{
			"id":        "algebra",
			"title":     "Algebra",
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
		{"id": "1", "title": "Sets of Numbers", "description": "Natural numbers (ℕ), Integers (ℤ), and Rational numbers (ℚ).", "coin_cost": 10, "coin_reward": 15, "difficulty": 1},
		{"id": "2", "title": "Fundamental Operations", "description": "The four operations, Powers and their properties, Roots.", "coin_cost": 10, "coin_reward": 15, "difficulty": 1},
		{"id": "3", "title": "Expressions & Order of Operations", "description": "Use of parentheses and PEMDAS/BODMAS.", "coin_cost": 10, "coin_reward": 15, "difficulty": 1},
		{"id": "4", "title": "Divisibility & Prime Numbers", "description": "Multiples, Divisors, GCD (MCD), and LCM (mcm).", "coin_cost": 12, "coin_reward": 18, "difficulty": 2},
		{"id": "5", "title": "Fractions & Ratios", "description": "Equivalent fractions, Operations with fractions, Percentages, and Proportions.", "coin_cost": 12, "coin_reward": 18, "difficulty": 2},
	}
}

func algebraSubtopics() []fiber.Map {
	return []fiber.Map{
		{"id": "6", "title": "Monomials & Polynomials", "description": "Operations, Degree of a polynomial, and Prodotti Notevoli (Special Products like Square of a Binomial).", "coin_cost": 12, "coin_reward": 18, "difficulty": 2},
		{"id": "7", "title": "Factoring Polynomials", "description": "Common factoring (Raccoglimento), Ruffini's Rule, and Difference of Squares.", "coin_cost": 15, "coin_reward": 25, "difficulty": 2},
		{"id": "8", "title": "Linear Equations & Inequalities", "description": "First-degree equations and literal equations.", "coin_cost": 12, "coin_reward": 18, "difficulty": 2},
		{"id": "9", "title": "Quadratic Equations", "description": "Complete and incomplete quadratics, the Discriminant (Δ), and factoring quadratic trinomials.", "coin_cost": 15, "coin_reward": 25, "difficulty": 3},
		{"id": "10", "title": "Systems of Equations", "description": "Substitution, Comparison, and Cramer's method.", "coin_cost": 15, "coin_reward": 25, "difficulty": 3},
	}
}

func geometrySubtopics() []fiber.Map {
	return []fiber.Map{
		{"id": "11", "title": "Plane Geometry", "description": "Segments, Angles, Triangles, Quadrilaterals, and Polygons.", "coin_cost": 12, "coin_reward": 18, "difficulty": 2},
		{"id": "12", "title": "Congruence & Similarity", "description": "Criteria for triangles, Pythagoras' and Euclid's theorems.", "coin_cost": 15, "coin_reward": 25, "difficulty": 2},
		{"id": "13", "title": "Circle & Pi", "description": "Circumference, Area, Tangents, and Secants.", "coin_cost": 12, "coin_reward": 18, "difficulty": 2},
		{"id": "14", "title": "Solid Geometry", "description": "Prisms, Pyramids, Cylinders, Cones, and Spheres (Volume & Surface Area).", "coin_cost": 15, "coin_reward": 25, "difficulty": 3},
		{"id": "15", "title": "Goniometry & Trigonometry", "description": "The Unit Circle, Sine, Cosine, Tangent, and the Law of Sines/Cosines.", "coin_cost": 18, "coin_reward": 28, "difficulty": 3},
	}
}

func precalcSubtopics() []fiber.Map {
	return []fiber.Map{
		{"id": "16", "title": "Functions & Domain", "description": "Real functions of a real variable, Classification, and finding the Domain (Insieme di Definizione).", "coin_cost": 15, "coin_reward": 25, "difficulty": 3},
		{"id": "17", "title": "Properties of Functions", "description": "Symmetries (Even/Odd), Intercepts, and Sign study (Positività).", "coin_cost": 15, "coin_reward": 25, "difficulty": 3},
		{"id": "18", "title": "Exponential & Logarithms", "description": "Equations and inequalities with eˣ and log(x).", "coin_cost": 18, "coin_reward": 28, "difficulty": 3},
		{"id": "19", "title": "Analytic Geometry", "description": "The line, the circle, the parabola, the ellipse, and the hyperbola in the Cartesian plane.", "coin_cost": 20, "coin_reward": 32, "difficulty": 4},
	}
}

func differentialSubtopics() []fiber.Map {
	return []fiber.Map{
		{"id": "20", "title": "Limits & Continuity", "description": "Finite and infinite limits, Indeterminate forms, and Asymptotes.", "coin_cost": 18, "coin_reward": 28, "difficulty": 4},
		{"id": "21", "title": "The Derivative Concept", "description": "Difference quotient (Rapporto incrementale) and geometric meaning.", "coin_cost": 15, "coin_reward": 25, "difficulty": 3},
		{"id": "22", "title": "Differentiation Rules", "description": "Power rule, Product, Quotient, and Chain rule.", "coin_cost": 18, "coin_reward": 28, "difficulty": 4},
		{"id": "23", "title": "Function Study", "description": "Using derivatives to find Maxima, Minima, and Points of Inflection (Flessi).", "coin_cost": 20, "coin_reward": 32, "difficulty": 4},
	}
}

func integralSubtopics() []fiber.Map {
	return []fiber.Map{
		{"id": "24", "title": "Indefinite Integrals", "description": "Primitive functions and immediate integration rules.", "coin_cost": 18, "coin_reward": 28, "difficulty": 4},
		{"id": "25", "title": "Integration Methods", "description": "Integration by substitution and Integration by parts.", "coin_cost": 20, "coin_reward": 32, "difficulty": 4},
		{"id": "26", "title": "Definite Integrals", "description": "Calculating the area under a curve (The Fundamental Theorem of Calculus).", "coin_cost": 20, "coin_reward": 32, "difficulty": 4},
		{"id": "27", "title": "Applications", "description": "Calculation of volumes and areas of plane figures.", "coin_cost": 22, "coin_reward": 35, "difficulty": 4},
	}
}

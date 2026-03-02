package lesson

import "github.com/gofiber/fiber/v2"

// curriculum returns the full math curriculum: 6 categories, each with sections and items (subcategories).
func curriculum() []fiber.Map {
	return []fiber.Map{
		{
			"id":       "arithmetic",
			"title":    "Arithmetic & Number Systems",
			"sections": arithmeticSections(),
		},
		{
			"id":       "algebra",
			"title":    "Algebra",
			"sections": algebraSections(),
		},
		{
			"id":       "geometry",
			"title":    "Geometry & Trigonometry",
			"sections": geometrySections(),
		},
		{
			"id":       "precalc",
			"title":    "Pre-Calculus & Analysis",
			"sections": precalcSections(),
		},
		{
			"id":       "differential",
			"title":    "Differential Calculus",
			"sections": differentialSections(),
		},
		{
			"id":       "integral",
			"title":    "Integral Calculus",
			"sections": integralSections(),
		},
	}
}

// section: title, lesson_id (for navigation), items ([]{ title })
func arithmeticSections() []fiber.Map {
	return []fiber.Map{
		{
			"title":     "Sets of Numbers",
			"lesson_id": "1",
			"items": []fiber.Map{
				{"title": "Natural numbers ℕ"},
				{"title": "Integers ℤ"},
				{"title": "Rational numbers ℚ"},
			},
		},
		{
			"title":     "Fundamental Operations",
			"lesson_id": "2",
			"items": []fiber.Map{
				{"title": "The four operations"},
				{"title": "Powers and their properties"},
				{"title": "Roots"},
			},
		},
		{
			"title":     "Expressions & Order of Operations",
			"lesson_id": "3",
			"items": []fiber.Map{
				{"title": "Use of parentheses and PEMDAS/BODMAS"},
			},
		},
		{
			"title":     "Divisibility & Prime Numbers",
			"lesson_id": "4",
			"items": []fiber.Map{
				{"title": "Multiples"},
				{"title": "Divisors"},
				{"title": "GCD (Greatest Common Divisor)"},
				{"title": "LCM (Least Common Multiple)"},
			},
		},
		{
			"title":     "Fractions & Ratios",
			"lesson_id": "5",
			"items": []fiber.Map{
				{"title": "Equivalent fractions"},
				{"title": "Operations with fractions"},
				{"title": "Percentages"},
				{"title": "Proportions"},
			},
		},
	}
}

func algebraSections() []fiber.Map {
	return []fiber.Map{
		{
			"title":     "Monomials & Polynomials",
			"lesson_id": "6",
			"items": []fiber.Map{
				{"title": "Operations"},
				{"title": "Degree of a polynomial"},
				{"title": "Special products (e.g. square of a binomial)"},
			},
		},
		{
			"title":     "Factoring Polynomials",
			"lesson_id": "7",
			"items": []fiber.Map{
				{"title": "Common factoring"},
				{"title": "Ruffini's Rule"},
				{"title": "Difference of Squares"},
			},
		},
		{
			"title":     "Linear Equations & Inequalities",
			"lesson_id": "8",
			"items": []fiber.Map{
				{"title": "First-degree equations"},
				{"title": "Literal equations"},
			},
		},
		{
			"title":     "Quadratic Equations",
			"lesson_id": "9",
			"items": []fiber.Map{
				{"title": "Complete and incomplete quadratics"},
				{"title": "The Discriminant (Δ)"},
				{"title": "Factoring quadratic trinomials"},
			},
		},
		{
			"title":     "Systems of Equations",
			"lesson_id": "10",
			"items": []fiber.Map{
				{"title": "Substitution"},
				{"title": "Comparison"},
				{"title": "Cramer's method"},
			},
		},
	}
}

func geometrySections() []fiber.Map {
	return []fiber.Map{
		{
			"title":     "Plane Geometry",
			"lesson_id": "11",
			"items": []fiber.Map{
				{"title": "Segments"},
				{"title": "Angles"},
				{"title": "Triangles"},
				{"title": "Quadrilaterals"},
				{"title": "Polygons"},
			},
		},
		{
			"title":     "Congruence & Similarity",
			"lesson_id": "12",
			"items": []fiber.Map{
				{"title": "Criteria for triangles"},
				{"title": "Pythagoras' and Euclid's theorems"},
			},
		},
		{
			"title":     "Circle & Pi",
			"lesson_id": "13",
			"items": []fiber.Map{
				{"title": "Circumference"},
				{"title": "Area"},
				{"title": "Tangents"},
				{"title": "Secants"},
			},
		},
		{
			"title":     "Solid Geometry",
			"lesson_id": "14",
			"items": []fiber.Map{
				{"title": "Prisms"},
				{"title": "Pyramids"},
				{"title": "Cylinders"},
				{"title": "Cones"},
				{"title": "Spheres (Volume & Surface Area)"},
			},
		},
		{
			"title":     "Goniometry & Trigonometry",
			"lesson_id": "15",
			"items": []fiber.Map{
				{"title": "The Unit Circle"},
				{"title": "Sine, Cosine, Tangent"},
				{"title": "Law of Sines/Cosines"},
			},
		},
	}
}

func precalcSections() []fiber.Map {
	return []fiber.Map{
		{
			"title":     "Functions & Domain",
			"lesson_id": "16",
			"items": []fiber.Map{
				{"title": "Real functions of a real variable"},
				{"title": "Classification"},
				{"title": "Finding the domain"},
			},
		},
		{
			"title":     "Properties of Functions",
			"lesson_id": "17",
			"items": []fiber.Map{
				{"title": "Symmetries (Even/Odd)"},
				{"title": "Intercepts"},
				{"title": "Sign study"},
			},
		},
		{
			"title":     "Exponential & Logarithms",
			"lesson_id": "18",
			"items": []fiber.Map{
				{"title": "Equations and inequalities with eˣ and log(x)"},
			},
		},
		{
			"title":     "Analytic Geometry",
			"lesson_id": "19",
			"items": []fiber.Map{
				{"title": "The line"},
				{"title": "The circle"},
				{"title": "The parabola"},
				{"title": "The ellipse"},
				{"title": "The hyperbola in the Cartesian plane"},
			},
		},
	}
}

func differentialSections() []fiber.Map {
	return []fiber.Map{
		{
			"title":     "Limits & Continuity",
			"lesson_id": "20",
			"items": []fiber.Map{
				{"title": "Finite and infinite limits"},
				{"title": "Indeterminate forms"},
				{"title": "Asymptotes"},
			},
		},
		{
			"title":     "The Derivative Concept",
			"lesson_id": "21",
			"items": []fiber.Map{
				{"title": "Difference quotient"},
				{"title": "Geometric meaning"},
			},
		},
		{
			"title":     "Differentiation Rules",
			"lesson_id": "22",
			"items": []fiber.Map{
				{"title": "Power rule"},
				{"title": "Product rule"},
				{"title": "Quotient rule"},
				{"title": "Chain rule"},
			},
		},
		{
			"title":     "Function Study",
			"lesson_id": "23",
			"items": []fiber.Map{
				{"title": "Maxima and Minima"},
				{"title": "Points of inflection"},
			},
		},
	}
}

func integralSections() []fiber.Map {
	return []fiber.Map{
		{
			"title":     "Indefinite Integrals",
			"lesson_id": "24",
			"items": []fiber.Map{
				{"title": "Primitive functions"},
				{"title": "Immediate integration rules"},
			},
		},
		{
			"title":     "Integration Methods",
			"lesson_id": "25",
			"items": []fiber.Map{
				{"title": "Integration by substitution"},
				{"title": "Integration by parts"},
			},
		},
		{
			"title":     "Definite Integrals",
			"lesson_id": "26",
			"items": []fiber.Map{
				{"title": "Calculating the area under a curve"},
				{"title": "The Fundamental Theorem of Calculus"},
			},
		},
		{
			"title":     "Applications",
			"lesson_id": "27",
			"items": []fiber.Map{
				{"title": "Calculation of volumes"},
				{"title": "Areas of plane figures"},
			},
		},
	}
}

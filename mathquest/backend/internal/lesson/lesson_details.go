package lesson

import (
	"github.com/gofiber/fiber/v2"
)

// lessonMeta returns title and category for curriculum lesson ids 1-27.
func lessonMeta(id string) (title, category string) {
	m := map[string][]string{
		"1":  {"Sets of Numbers", "Arithmetic & Number Systems"},
		"2":  {"Fundamental Operations", "Arithmetic & Number Systems"},
		"3":  {"Expressions & Order of Operations", "Arithmetic & Number Systems"},
		"4":  {"Divisibility & Prime Numbers", "Arithmetic & Number Systems"},
		"5":  {"Fractions & Ratios", "Arithmetic & Number Systems"},
		"6":  {"Monomials & Polynomials", "Algebra"},
		"7":  {"Factoring Polynomials", "Algebra"},
		"8":  {"Linear Equations & Inequalities", "Algebra"},
		"9":  {"Quadratic Equations", "Algebra"},
		"10": {"Systems of Equations", "Algebra"},
		"11": {"Plane Geometry", "Geometry & Trigonometry"},
		"12": {"Congruence & Similarity", "Geometry & Trigonometry"},
		"13": {"Circle & Pi", "Geometry & Trigonometry"},
		"14": {"Solid Geometry", "Geometry & Trigonometry"},
		"15": {"Goniometry & Trigonometry", "Geometry & Trigonometry"},
		"16": {"Functions & Domain", "Pre-Calculus & Analysis"},
		"17": {"Properties of Functions", "Pre-Calculus & Analysis"},
		"18": {"Exponential & Logarithms", "Pre-Calculus & Analysis"},
		"19": {"Analytic Geometry", "Pre-Calculus & Analysis"},
		"20": {"Limits & Continuity", "Differential Calculus"},
		"21": {"The Derivative Concept", "Differential Calculus"},
		"22": {"Differentiation Rules", "Differential Calculus"},
		"23": {"Function Study", "Differential Calculus"},
		"24": {"Indefinite Integrals", "Integral Calculus"},
		"25": {"Integration Methods", "Integral Calculus"},
		"26": {"Definite Integrals", "Integral Calculus"},
		"27": {"Applications", "Integral Calculus"},
	}
	if p, ok := m[id]; ok && len(p) == 2 {
		return p[0], p[1]
	}
	return "Lesson", "Math"
}

// getLessonDetail returns lesson content and exercises for the given id (1-27).
func getLessonDetail(id string) (title, category string, content fiber.Map, exercises []fiber.Map) {
	title, category = lessonMeta(id)
	content = fiber.Map{
		"intro": "Study the theory and practice with the exercises. Content for this lesson will be expanded soon.",
	}
	exercises = []fiber.Map{
		{"id": "e1", "question": "Practice exercise 1 (coming soon).", "type": "multiple_choice", "options": []string{"A", "B", "C", "D"}, "correct_answer": "A", "xp_reward": 10},
		{"id": "e2", "question": "Practice exercise 2 (coming soon).", "type": "multiple_choice", "options": []string{"A", "B", "C", "D"}, "correct_answer": "B", "xp_reward": 10},
	}
	return
}

package lesson

import (
	"strconv"
	"strings"
)

type practiceExerciseTemplate struct {
	question string
	correct  string
	options  []string
}

func buildTopicPracticeTemplates(id, baseTitle, baseCategory, lang string) []practiceExerciseTemplate {
	titleKey := normalizePracticeTopic(baseTitle)
	categoryKey := normalizePracticeTopic(baseCategory)

	switch {
	case containsPracticeTopic(titleKey, "sets of numbers"):
		return append(numberSetsTemplates(lang), naturalNumbersTemplates(lang)...)
	case containsPracticeTopic(titleKey, "natural numbers"):
		return naturalNumbersTemplates(lang)
	case containsPracticeTopic(titleKey, "integers"):
		return integersTemplates(lang)
	case containsPracticeTopic(titleKey, "rational numbers"):
		return rationalNumbersTemplates(lang)
	case containsPracticeTopic(titleKey, "fundamental operations"):
		return append(fourOperationsTemplates(lang), powersTemplates(lang)...)
	case containsPracticeTopic(titleKey, "the four operations"):
		return fourOperationsTemplates(lang)
	case containsPracticeTopic(titleKey, "powers and their properties"):
		return powersTemplates(lang)
	case containsPracticeTopic(titleKey, "roots"):
		return rootsTemplates(lang)
	case containsPracticeTopic(titleKey, "order of operations", "pemdas", "bodmas"):
		return orderOfOperationsTemplates(lang)
	case containsPracticeTopic(titleKey, "divisibility", "prime numbers"):
		return append(multiplesTemplates(lang), gcdLcmTemplates(lang)...)
	case containsPracticeTopic(titleKey, "multiples"):
		return multiplesTemplates(lang)
	case containsPracticeTopic(titleKey, "divisors"):
		return divisorsTemplates(lang)
	case containsPracticeTopic(titleKey, "gcd"):
		return gcdTemplates(lang)
	case containsPracticeTopic(titleKey, "lcm"):
		return lcmTemplates(lang)
	case containsPracticeTopic(titleKey, "equivalent fractions"):
		return equivalentFractionsTemplates(lang)
	case containsPracticeTopic(titleKey, "operations with fractions"):
		return fractionOperationsTemplates(lang)
	case containsPracticeTopic(titleKey, "percentages"):
		return percentagesTemplates(lang)
	case containsPracticeTopic(titleKey, "proportions"):
		return proportionsTemplates(lang)
	case containsPracticeTopic(titleKey, "fractions", "ratios"):
		return append(fractionTemplates(lang), percentagesTemplates(lang)...)
	case containsPracticeTopic(titleKey, "monomials", "polynomials"):
		return append(polynomialOperationsTemplates(lang), degreeTemplates(lang)...)
	case containsPracticeTopic(titleKey, "operations"):
		if strings.Contains(categoryKey, "algebra") {
			return polynomialOperationsTemplates(lang)
		}
	case containsPracticeTopic(titleKey, "degree of a polynomial"):
		return degreeTemplates(lang)
	case containsPracticeTopic(titleKey, "special products"):
		return specialProductsTemplates(lang)
	case containsPracticeTopic(titleKey, "factoring polynomials"):
		return append(commonFactoringTemplates(lang), differenceOfSquaresTemplates(lang)...)
	case containsPracticeTopic(titleKey, "common factoring"):
		return commonFactoringTemplates(lang)
	case containsPracticeTopic(titleKey, "ruffini"):
		return ruffiniTemplates(lang)
	case containsPracticeTopic(titleKey, "difference of squares"):
		return differenceOfSquaresTemplates(lang)
	case containsPracticeTopic(titleKey, "linear equations", "inequalities"):
		return append(linearEquationTemplates(lang), literalEquationTemplates(lang)...)
	case containsPracticeTopic(titleKey, "first-degree equations"):
		return linearEquationTemplates(lang)
	case containsPracticeTopic(titleKey, "literal equations"):
		return literalEquationTemplates(lang)
	case containsPracticeTopic(titleKey, "quadratic equations"):
		return append(quadraticTemplates(lang), discriminantTemplates(lang)...)
	case containsPracticeTopic(titleKey, "complete and incomplete quadratics"):
		return quadraticTemplates(lang)
	case containsPracticeTopic(titleKey, "discriminant"):
		return discriminantTemplates(lang)
	case containsPracticeTopic(titleKey, "factoring quadratic trinomials"):
		return factoringQuadraticTemplates(lang)
	case containsPracticeTopic(titleKey, "systems of equations"):
		return append(substitutionTemplates(lang), comparisonTemplates(lang)...)
	case containsPracticeTopic(titleKey, "substitution") && strings.Contains(categoryKey, "algebra"):
		return substitutionTemplates(lang)
	case containsPracticeTopic(titleKey, "comparison") && strings.Contains(categoryKey, "algebra"):
		return comparisonTemplates(lang)
	case containsPracticeTopic(titleKey, "cramer") && strings.Contains(categoryKey, "algebra"):
		return cramerTemplates(lang)
	case containsPracticeTopic(titleKey, "plane geometry"):
		return append(anglesTemplates(lang), trianglesTemplates(lang)...)
	case containsPracticeTopic(titleKey, "segments"):
		return segmentsTemplates(lang)
	case containsPracticeTopic(titleKey, "angles"):
		return anglesTemplates(lang)
	case containsPracticeTopic(titleKey, "triangles"):
		return trianglesTemplates(lang)
	case containsPracticeTopic(titleKey, "quadrilaterals"):
		return quadrilateralsTemplates(lang)
	case containsPracticeTopic(titleKey, "polygons"):
		return polygonsTemplates(lang)
	case containsPracticeTopic(titleKey, "congruence", "similarity", "criteria for triangles"):
		return criteriaTrianglesTemplates(lang)
	case containsPracticeTopic(titleKey, "pythagoras", "euclid"):
		return pythagorasTemplates(lang)
	case containsPracticeTopic(titleKey, "circle & pi"):
		return append(circumferenceTemplates(lang), circleAreaTemplates(lang)...)
	case containsPracticeTopic(titleKey, "circumference"):
		return circumferenceTemplates(lang)
	case containsPracticeTopic(titleKey, "area"):
		if strings.Contains(categoryKey, "geometry") {
			return circleAreaTemplates(lang)
		}
	case containsPracticeTopic(titleKey, "tangents"):
		return tangentsTemplates(lang)
	case containsPracticeTopic(titleKey, "secants"):
		return secantsTemplates(lang)
	case containsPracticeTopic(titleKey, "solid geometry"):
		return append(prismsTemplates(lang), volumeTemplates(lang)...)
	case containsPracticeTopic(titleKey, "prisms"):
		return prismsTemplates(lang)
	case containsPracticeTopic(titleKey, "pyramids"):
		return pyramidsTemplates(lang)
	case containsPracticeTopic(titleKey, "cylinders"):
		return cylindersTemplates(lang)
	case containsPracticeTopic(titleKey, "cones"):
		return conesTemplates(lang)
	case containsPracticeTopic(titleKey, "spheres"):
		return spheresTemplates(lang)
	case containsPracticeTopic(titleKey, "goniometry", "trigonometry"):
		return append(unitCircleTemplates(lang), sineCosineTangentTemplates(lang)...)
	case containsPracticeTopic(titleKey, "unit circle"):
		return unitCircleTemplates(lang)
	case containsPracticeTopic(titleKey, "sine, cosine, tangent"):
		return sineCosineTangentTemplates(lang)
	case containsPracticeTopic(titleKey, "law of sines", "law of cosines"):
		return lawOfSinesCosinesTemplates(lang)
	case containsPracticeTopic(titleKey, "functions & domain"):
		return append(realFunctionsTemplates(lang), domainTemplates(lang)...)
	case containsPracticeTopic(titleKey, "real functions of a real variable"):
		return realFunctionsTemplates(lang)
	case containsPracticeTopic(titleKey, "classification"):
		return classificationTemplates(lang)
	case containsPracticeTopic(titleKey, "finding the domain"):
		return domainTemplates(lang)
	case containsPracticeTopic(titleKey, "properties of functions"):
		return append(symmetryTemplates(lang), interceptsTemplates(lang)...)
	case containsPracticeTopic(titleKey, "symmetries"):
		return symmetryTemplates(lang)
	case containsPracticeTopic(titleKey, "intercepts"):
		return interceptsTemplates(lang)
	case containsPracticeTopic(titleKey, "sign study"):
		return signStudyTemplates(lang)
	case containsPracticeTopic(titleKey, "exponential", "logarithms"):
		return expLogTemplates(lang)
	case containsPracticeTopic(titleKey, "equations and inequalities with e", "log(x)"):
		return expLogTemplates(lang)
	case containsPracticeTopic(titleKey, "analytic geometry"):
		return append(lineTemplates(lang), parabolaTemplates(lang)...)
	case containsPracticeTopic(titleKey, "the line"):
		return lineTemplates(lang)
	case containsPracticeTopic(titleKey, "the circle"):
		return analyticCircleTemplates(lang)
	case containsPracticeTopic(titleKey, "the parabola"):
		return parabolaTemplates(lang)
	case containsPracticeTopic(titleKey, "the ellipse"):
		return ellipseTemplates(lang)
	case containsPracticeTopic(titleKey, "the hyperbola"):
		return hyperbolaTemplates(lang)
	case containsPracticeTopic(titleKey, "limits", "continuity"):
		return append(limitsTemplates(lang), asymptotesTemplates(lang)...)
	case containsPracticeTopic(titleKey, "finite and infinite limits"):
		return limitsTemplates(lang)
	case containsPracticeTopic(titleKey, "indeterminate forms"):
		return indeterminateFormsTemplates(lang)
	case containsPracticeTopic(titleKey, "asymptotes"):
		return asymptotesTemplates(lang)
	case containsPracticeTopic(titleKey, "derivative concept"):
		return append(differenceQuotientTemplates(lang), geometricMeaningTemplates(lang)...)
	case containsPracticeTopic(titleKey, "difference quotient"):
		return differenceQuotientTemplates(lang)
	case containsPracticeTopic(titleKey, "geometric meaning"):
		return geometricMeaningTemplates(lang)
	case containsPracticeTopic(titleKey, "differentiation rules"):
		return append(powerRuleTemplates(lang), productRuleTemplates(lang)...)
	case containsPracticeTopic(titleKey, "power rule"):
		return powerRuleTemplates(lang)
	case containsPracticeTopic(titleKey, "product rule"):
		return productRuleTemplates(lang)
	case containsPracticeTopic(titleKey, "quotient rule"):
		return quotientRuleTemplates(lang)
	case containsPracticeTopic(titleKey, "chain rule"):
		return chainRuleTemplates(lang)
	case containsPracticeTopic(titleKey, "function study"):
		return append(maximaMinimaTemplates(lang), inflectionTemplates(lang)...)
	case containsPracticeTopic(titleKey, "maxima and minima"):
		return maximaMinimaTemplates(lang)
	case containsPracticeTopic(titleKey, "points of inflection"):
		return inflectionTemplates(lang)
	case containsPracticeTopic(titleKey, "indefinite integrals"):
		return append(primitivesTemplates(lang), immediateIntegrationTemplates(lang)...)
	case containsPracticeTopic(titleKey, "primitive functions"):
		return primitivesTemplates(lang)
	case containsPracticeTopic(titleKey, "immediate integration rules"):
		return immediateIntegrationTemplates(lang)
	case containsPracticeTopic(titleKey, "integration methods"):
		return append(substitutionIntegrationTemplates(lang), integrationByPartsTemplates(lang)...)
	case containsPracticeTopic(titleKey, "integration by substitution"):
		return substitutionIntegrationTemplates(lang)
	case containsPracticeTopic(titleKey, "integration by parts"):
		return integrationByPartsTemplates(lang)
	case containsPracticeTopic(titleKey, "definite integrals"):
		return append(areaUnderCurveTemplates(lang), ftcTemplates(lang)...)
	case containsPracticeTopic(titleKey, "calculating the area under a curve"):
		return areaUnderCurveTemplates(lang)
	case containsPracticeTopic(titleKey, "fundamental theorem of calculus"):
		return ftcTemplates(lang)
	case containsPracticeTopic(titleKey, "applications"):
		return append(volumeTemplates(lang), planeAreaTemplates(lang)...)
	case containsPracticeTopic(titleKey, "calculation of volumes"):
		return volumeTemplates(lang)
	case containsPracticeTopic(titleKey, "areas of plane figures"):
		return planeAreaTemplates(lang)
	}

	if strings.Contains(categoryKey, "integral") {
		return append(immediateIntegrationTemplates(lang), areaUnderCurveTemplates(lang)...)
	}
	if strings.Contains(categoryKey, "differential") {
		return append(powerRuleTemplates(lang), limitsTemplates(lang)...)
	}
	if strings.Contains(categoryKey, "geometry") {
		return append(anglesTemplates(lang), trianglesTemplates(lang)...)
	}
	if strings.Contains(categoryKey, "algebra") {
		return append(linearEquationTemplates(lang), polynomialOperationsTemplates(lang)...)
	}
	if strings.Contains(categoryKey, "arithmetic") {
		return append(fourOperationsTemplates(lang), fractionTemplates(lang)...)
	}
	if strings.Contains(categoryKey, "pre calculus") || strings.Contains(categoryKey, "analysis") {
		return append(domainTemplates(lang), symmetryTemplates(lang)...)
	}

	return nil
}

func buildSectionPracticeTemplates(id, lang string) []practiceExerciseTemplate {
	sectionID := id
	if parsedSectionID, _, ok := parseItemID(id); ok {
		sectionID = parsedSectionID
	}

	switch sectionID {
	case "1":
		return append(append(numberSetsTemplates(lang), integersTemplates(lang)...), rationalNumbersTemplates(lang)...)
	case "2":
		return append(append(fourOperationsTemplates(lang), powersTemplates(lang)...), rootsTemplates(lang)...)
	case "3":
		return append(append(orderOfOperationsTemplates(lang), powersTemplates(lang)...), rootsTemplates(lang)...)
	case "4":
		return append(append(multiplesTemplates(lang), divisorsTemplates(lang)...), append(gcdTemplates(lang), lcmTemplates(lang)...)...)
	case "5":
		return append(append(equivalentFractionsTemplates(lang), fractionOperationsTemplates(lang)...), append(percentagesTemplates(lang), proportionsTemplates(lang)...)...)
	case "6":
		return append(append(polynomialOperationsTemplates(lang), degreeTemplates(lang)...), specialProductsTemplates(lang)...)
	case "7":
		return append(append(commonFactoringTemplates(lang), ruffiniTemplates(lang)...), differenceOfSquaresTemplates(lang)...)
	case "8":
		return append(append(linearEquationTemplates(lang), literalEquationTemplates(lang)...), substitutionTemplates(lang)...)
	case "9":
		return append(append(quadraticTemplates(lang), discriminantTemplates(lang)...), factoringQuadraticTemplates(lang)...)
	case "10":
		return append(append(substitutionTemplates(lang), comparisonTemplates(lang)...), cramerTemplates(lang)...)
	case "11":
		return append(append(append(segmentsTemplates(lang), anglesTemplates(lang)...), trianglesTemplates(lang)...), append(quadrilateralsTemplates(lang), polygonsTemplates(lang)...)...)
	case "12":
		return append(append(criteriaTrianglesTemplates(lang), pythagorasTemplates(lang)...), trianglesTemplates(lang)...)
	case "13":
		return append(append(circumferenceTemplates(lang), circleAreaTemplates(lang)...), append(tangentsTemplates(lang), secantsTemplates(lang)...)...)
	case "14":
		return append(append(append(prismsTemplates(lang), pyramidsTemplates(lang)...), append(cylindersTemplates(lang), conesTemplates(lang)...)...), spheresTemplates(lang)...)
	case "15":
		return append(append(unitCircleTemplates(lang), sineCosineTangentTemplates(lang)...), lawOfSinesCosinesTemplates(lang)...)
	case "16":
		return append(append(realFunctionsTemplates(lang), classificationTemplates(lang)...), domainTemplates(lang)...)
	case "17":
		return append(append(symmetryTemplates(lang), interceptsTemplates(lang)...), append(signStudyTemplates(lang), realFunctionsTemplates(lang)...)...)
	case "18":
		return append(append(expLogTemplates(lang), domainTemplates(lang)...), realFunctionsTemplates(lang)...)
	case "19":
		return append(append(append(lineTemplates(lang), analyticCircleTemplates(lang)...), append(parabolaTemplates(lang), ellipseTemplates(lang)...)...), hyperbolaTemplates(lang)...)
	case "20":
		return append(append(limitsTemplates(lang), indeterminateFormsTemplates(lang)...), asymptotesTemplates(lang)...)
	case "21":
		return append(append(differenceQuotientTemplates(lang), geometricMeaningTemplates(lang)...), powerRuleTemplates(lang)...)
	case "22":
		return append(append(powerRuleTemplates(lang), productRuleTemplates(lang)...), append(quotientRuleTemplates(lang), chainRuleTemplates(lang)...)...)
	case "23":
		return append(append(maximaMinimaTemplates(lang), inflectionTemplates(lang)...), signStudyTemplates(lang)...)
	case "24":
		return append(append(primitivesTemplates(lang), immediateIntegrationTemplates(lang)...), substitutionIntegrationTemplates(lang)...)
	case "25":
		return append(append(substitutionIntegrationTemplates(lang), integrationByPartsTemplates(lang)...), immediateIntegrationTemplates(lang)...)
	case "26":
		return append(append(areaUnderCurveTemplates(lang), ftcTemplates(lang)...), immediateIntegrationTemplates(lang)...)
	case "27":
		return append(append(volumeTemplates(lang), planeAreaTemplates(lang)...), areaUnderCurveTemplates(lang)...)
	default:
		return nil
	}
}

func normalizePracticeTopic(s string) string {
	s = strings.ToLower(s)
	replacer := strings.NewReplacer("&", " ", "-", " ", "’", "", "'", "", "(", " ", ")", " ", ",", " ", ".", " ", ":", " ", "ℕ", " natural ", "ℤ", " integers ", "ℚ", " rational ", "Δ", " discriminant ")
	s = replacer.Replace(s)
	return strings.Join(strings.Fields(s), " ")
}

func containsPracticeTopic(haystack string, needles ...string) bool {
	for _, needle := range needles {
		if strings.Contains(haystack, normalizePracticeTopic(needle)) {
			return true
		}
	}
	return false
}

func t(question, correct string, options ...string) practiceExerciseTemplate {
	all := []string{correct}
	for _, option := range options {
		option = strings.TrimSpace(option)
		if option == "" {
			continue
		}
		duplicate := false
		for _, existing := range all {
			if existing == option {
				duplicate = true
				break
			}
		}
		if !duplicate {
			all = append(all, option)
		}
	}
	return practiceExerciseTemplate{
		question: question,
		correct:  correct,
		options:  all,
	}
}

func qCompute(lang, expr string) string       { return shortPrompt(lang, "compute") + " " + expr }
func qSimplify(lang, expr string) string      { return shortPrompt(lang, "simplify") + " " + expr }
func qSolve(lang, expr string) string         { return shortPrompt(lang, "solve") + " " + expr }
func qDifferentiate(lang, expr string) string { return shortPrompt(lang, "differentiate") + " " + expr }
func qIntegrate(lang, expr string) string     { return shortPrompt(lang, "integrate") + " " + expr }
func qEvaluate(lang, expr string) string      { return shortPrompt(lang, "evaluate") + " " + expr }
func qChoose(lang, text string) string        { return shortPrompt(lang, "choose") + " " + text }

func shortPrompt(lang, key string) string {
	switch normalizeLessonLang(lang) {
	case "it":
		switch key {
		case "compute":
			return "Calcola:"
		case "simplify":
			return "Semplifica:"
		case "solve":
			return "Risolvi:"
		case "differentiate":
			return "Deriva:"
		case "integrate":
			return "Integra:"
		case "evaluate":
			return "Valuta:"
		case "choose":
			return "Scegli:"
		}
	case "fr":
		switch key {
		case "compute":
			return "Calcule :"
		case "simplify":
			return "Simplifie :"
		case "solve":
			return "Résous :"
		case "differentiate":
			return "Dérive :"
		case "integrate":
			return "Intègre :"
		case "evaluate":
			return "Évalue :"
		case "choose":
			return "Choisis :"
		}
	case "es":
		switch key {
		case "compute":
			return "Calcula:"
		case "simplify":
			return "Simplifica:"
		case "solve":
			return "Resuelve:"
		case "differentiate":
			return "Deriva:"
		case "integrate":
			return "Integra:"
		case "evaluate":
			return "Evalúa:"
		case "choose":
			return "Elige:"
		}
	case "uz":
		switch key {
		case "compute":
			return "Hisoblang:"
		case "simplify":
			return "Soddalashtiring:"
		case "solve":
			return "Yeching:"
		case "differentiate":
			return "Hosila oling:"
		case "integrate":
			return "Integrallang:"
		case "evaluate":
			return "Qiymatini toping:"
		case "choose":
			return "Tanlang:"
		}
	}

	switch key {
	case "compute":
		return "Compute:"
	case "simplify":
		return "Simplify:"
	case "solve":
		return "Solve:"
	case "differentiate":
		return "Differentiate:"
	case "integrate":
		return "Integrate:"
	case "evaluate":
		return "Evaluate:"
	case "choose":
		return "Choose:"
	default:
		return ""
	}
}

func numberSetsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the smallest set containing 3/4"), "rational numbers", "integers", "natural numbers", "irrational numbers"),
		t(qChoose(lang, "the smallest set containing -5"), "integers", "natural numbers", "rational numbers with nonzero denominator only", "prime numbers"),
		t(qChoose(lang, "the correct inclusion"), "natural numbers ⊆ integers ⊆ rational numbers", "integers ⊆ natural numbers ⊆ rational numbers", "rational numbers ⊆ integers ⊆ natural numbers", "prime numbers ⊆ natural numbers ⊆ integers"),
		t(qChoose(lang, "the number that is not an integer"), "7/2", "-4", "0", "12"),
		t(qChoose(lang, "the number that belongs to natural numbers in this course"), "0", "-1", "1/2", "-3"),
	}
}

func naturalNumbersTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qCompute(lang, "successor of 12"), "13", "11", "14", "10"),
		t(qCompute(lang, "predecessor of 20"), "19", "18", "21", "22"),
		t(qChoose(lang, "the natural number"), "27", "-3", "1/2", "-11"),
		t(qCompute(lang, "8 + 15"), "23", "22", "24", "25"),
		t(qCompute(lang, "6 * 7"), "42", "36", "48", "54"),
	}
}

func integersTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qCompute(lang, "-7 + 12"), "5", "-5", "19", "7"),
		t(qCompute(lang, "4 - 9"), "-5", "5", "-13", "13"),
		t(qCompute(lang, "|-8|"), "8", "-8", "0", "16"),
		t(qCompute(lang, "-3 * 6"), "-18", "18", "-9", "9"),
		t(qChoose(lang, "the correct order"), "-4 < -1 < 3", "-1 < -4 < 3", "3 < -1 < -4", "-4 < 3 < -1"),
	}
}

func rationalNumbersTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the fraction equal to 0.75"), "3/4", "2/3", "1/4", "4/3"),
		t(qSimplify(lang, "18/24"), "3/4", "4/3", "9/12", "6/8"),
		t(qChoose(lang, "the rational number"), "7/9", "sqrt(2)", "pi", "sqrt(5)"),
		t(qCompute(lang, "1/2 + 1/3"), "5/6", "2/5", "3/5", "1/6"),
		t(qChoose(lang, "the decimal that is rational"), "0.125", "non-repeating decimal with no pattern", "pi", "sqrt(3)"),
	}
}

func fourOperationsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qCompute(lang, "27 + 35"), "62", "52", "72", "63"),
		t(qCompute(lang, "90 - 47"), "43", "37", "53", "42"),
		t(qCompute(lang, "8 * 9"), "72", "81", "64", "79"),
		t(qCompute(lang, "84 / 7"), "12", "14", "21", "7"),
		t(qChoose(lang, "the identity element for addition"), "0", "1", "-1", "2"),
	}
}

func powersTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qSimplify(lang, "2^3 * 2^4"), "2^7", "4^7", "2^12", "2^1"),
		t(qSimplify(lang, "(3^2)^3"), "3^6", "9^6", "3^5", "3^9"),
		t(qCompute(lang, "5^2"), "25", "10", "15", "20"),
		t(qSimplify(lang, "x^5 / x^2"), "x^3", "x^7", "x^10", "x^(5/2)"),
		t(qChoose(lang, "the value of 10^0"), "1", "0", "10", "undefined"),
	}
}

func rootsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qCompute(lang, "sqrt(49)"), "7", "14", "6", "8"),
		t(qCompute(lang, "sqrt(81)"), "9", "8", "18", "6"),
		t(qChoose(lang, "the same value as 3^(1/2)"), "sqrt(3)", "3^2", "1/(3^2)", "3"),
		t(qSimplify(lang, "sqrt(16) + sqrt(9)"), "7", "25", "5", "12"),
		t(qChoose(lang, "the square root of x^2 for x >= 0"), "x", "x^2", "2x", "1/x"),
	}
}

func orderOfOperationsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qCompute(lang, "2 + 3 * 4"), "14", "20", "24", "11"),
		t(qCompute(lang, "(2 + 3) * 4"), "20", "14", "10", "9"),
		t(qCompute(lang, "18 / (3 * 2)"), "3", "12", "6", "1"),
		t(qCompute(lang, "2^3 + 5"), "13", "11", "16", "40"),
		t(qChoose(lang, "the first operation in 7 + 2 * (5 - 1)"), "(5 - 1)", "7 + 2", "2 * 5", "7 + 2 * 5"),
	}
}

func multiplesTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "a multiple of 6"), "42", "43", "41", "44"),
		t(qChoose(lang, "the first common multiple of 4 and 6 greater than 0"), "12", "10", "8", "24"),
		t(qChoose(lang, "the number that is a multiple of both 3 and 5"), "30", "18", "25", "14"),
		t(qCompute(lang, "next multiple of 7 after 28"), "35", "34", "36", "42"),
		t(qChoose(lang, "the false statement"), "15 is a multiple of 4", "18 is a multiple of 3", "24 is a multiple of 6", "35 is a multiple of 5"),
	}
}

func divisorsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "a divisor of 24"), "6", "5", "7", "11"),
		t(qChoose(lang, "the number divisible by 9"), "81", "82", "83", "84"),
		t(qChoose(lang, "the false statement"), "7 divides 30", "5 divides 30", "6 divides 30", "10 divides 30"),
		t(qCompute(lang, "24 / 6"), "4", "6", "3", "5"),
		t(qChoose(lang, "the complete divisor pair of 18"), "2 and 9", "4 and 5", "7 and 3", "8 and 2"),
	}
}

func gcdTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "gcd(18, 24)"), "6", "3", "12", "72"),
		t(qChoose(lang, "gcd(12, 20)"), "4", "2", "6", "8"),
		t(qChoose(lang, "gcd(15, 25)"), "5", "10", "15", "1"),
		t(qChoose(lang, "gcd(14, 21)"), "7", "3", "14", "1"),
		t(qChoose(lang, "the pair with gcd 1"), "8 and 15", "12 and 18", "21 and 14", "16 and 20"),
	}
}

func lcmTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "lcm(4, 6)"), "12", "24", "6", "10"),
		t(qChoose(lang, "lcm(8, 12)"), "24", "12", "48", "4"),
		t(qChoose(lang, "lcm(3, 5)"), "15", "8", "30", "5"),
		t(qChoose(lang, "the smallest positive number divisible by 6 and 15"), "30", "60", "15", "90"),
		t(qChoose(lang, "the false statement"), "lcm(4, 6) = 8", "lcm(2, 3) = 6", "lcm(5, 10) = 10", "lcm(3, 4) = 12"),
	}
}

func gcdLcmTemplates(lang string) []practiceExerciseTemplate {
	return append(gcdTemplates(lang), lcmTemplates(lang)...)
}

func fractionTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qSimplify(lang, "12/18"), "2/3", "3/2", "6/9", "4/9"),
		t(qChoose(lang, "the fraction equivalent to 5/8"), "10/16", "15/16", "20/24", "25/32"),
		t(qCompute(lang, "1/4 + 1/2"), "3/4", "2/6", "1/6", "1/2"),
		t(qCompute(lang, "3/5 - 1/5"), "2/5", "2/10", "4/5", "1/5"),
		t(qCompute(lang, "2/3 * 3/4"), "1/2", "6/12", "5/7", "2/12"),
	}
}

func equivalentFractionsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the fraction equivalent to 2/3"), "4/6", "3/4", "6/4", "5/9"),
		t(qChoose(lang, "the fraction equivalent to 3/7"), "6/14", "9/14", "12/18", "10/21"),
		t(qChoose(lang, "the false pair"), "2/5 = 6/10", "1/2 = 3/6", "3/4 = 6/8", "2/3 = 4/6"),
		t(qSimplify(lang, "15/25"), "3/5", "5/3", "6/10", "10/6"),
		t(qChoose(lang, "the multiplier from 3/8 to 12/32"), "4", "3", "2", "8"),
	}
}

func fractionOperationsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qCompute(lang, "2/7 + 3/7"), "5/7", "5/14", "6/7", "1"),
		t(qCompute(lang, "5/6 - 1/3"), "1/2", "4/3", "2/3", "1/3"),
		t(qCompute(lang, "(3/4) / (1/2)"), "3/2", "3/8", "2/3", "5/4"),
		t(qCompute(lang, "4/9 * 3"), "4/3", "12/9", "7/9", "1/3"),
		t(qChoose(lang, "the reciprocal of 5/8"), "8/5", "5/8", "-8/5", "3/8"),
	}
}

func percentagesTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qCompute(lang, "25% of 80"), "20", "25", "40", "16"),
		t(qCompute(lang, "10% of 350"), "35", "3.5", "30", "45"),
		t(qChoose(lang, "the decimal form of 7%"), "0.07", "0.7", "7", "0.007"),
		t(qChoose(lang, "the percentage form of 0.4"), "40%", "4%", "0.4%", "400%"),
		t(qCompute(lang, "increase 50 by 20%"), "60", "55", "70", "65"),
	}
}

func proportionsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qSolve(lang, "3/5 = x/20"), "12", "15", "10", "8"),
		t(qSolve(lang, "2:7 = 6:x"), "21", "14", "18", "24"),
		t(qChoose(lang, "the proportion that is true"), "4/6 = 10/15", "3/5 = 12/25", "2/7 = 8/21", "5/8 = 15/20"),
		t(qSolve(lang, "x/9 = 4/3"), "12", "6", "13", "27"),
		t(qChoose(lang, "the correct cross product for a/b = c/d"), "a*d = b*c", "a*b = c*d", "a+c = b+d", "a*d = b+d"),
	}
}

func polynomialOperationsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qSimplify(lang, "(3x + 2x)"), "5x", "6x", "x", "5x^2"),
		t(qSimplify(lang, "(2x^2 + 3x^2)"), "5x^2", "6x^4", "5x", "x^4"),
		t(qCompute(lang, "(x + 3) + (2x - 1)"), "3x + 2", "3x - 2", "x + 2", "2x + 4"),
		t(qCompute(lang, "2x * 3x^2"), "6x^3", "5x^2", "6x^2", "6x"),
		t(qChoose(lang, "like terms"), "4x and -2x", "x and x^2", "3 and 3x", "y and x"),
	}
}

func degreeTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the degree of 5x^4 - 2x + 1"), "4", "5", "3", "1"),
		t(qChoose(lang, "the degree of 7"), "0", "1", "7", "undefined"),
		t(qChoose(lang, "the degree of 3x^2y^3"), "5", "6", "3", "2"),
		t(qChoose(lang, "the degree of x^5 + x^2"), "5", "7", "3", "2"),
		t(qChoose(lang, "the monomial of degree 3"), "2x^3", "5x", "7", "x^2y^2"),
	}
}

func specialProductsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qCompute(lang, "(a + b)^2"), "a^2 + 2ab + b^2", "a^2 + b^2", "a^2 - 2ab + b^2", "2a + 2b"),
		t(qCompute(lang, "(a - b)^2"), "a^2 - 2ab + b^2", "a^2 + 2ab + b^2", "a^2 - b^2", "a^2 + b^2"),
		t(qCompute(lang, "(a + b)(a - b)"), "a^2 - b^2", "a^2 + b^2", "a^2 - 2ab + b^2", "2a - 2b"),
		t(qCompute(lang, "(x + 4)^2"), "x^2 + 8x + 16", "x^2 + 16", "x^2 + 4x + 16", "x^2 - 8x + 16"),
		t(qCompute(lang, "(2x - 3)^2"), "4x^2 - 12x + 9", "4x^2 + 12x + 9", "2x^2 - 9", "4x^2 - 9"),
	}
}

func commonFactoringTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qSimplify(lang, "6x + 9 ="), "3(2x + 3)", "6(x + 9)", "9(6x + 1)", "3(2x + 9)"),
		t(qSimplify(lang, "8x^2 - 12x ="), "4x(2x - 3)", "2x(4x - 12)", "4(2x^2 - 3x)", "8x(x - 12)"),
		t(qSimplify(lang, "15a + 20 ="), "5(3a + 4)", "5(3a + 20)", "15(a + 20)", "10(1.5a + 2)"),
		t(qChoose(lang, "the greatest common factor of 12x and 18"), "6", "3", "12", "18"),
		t(qChoose(lang, "the greatest common factor of 9x^2 and 6x"), "3x", "3x^2", "6x", "9x"),
	}
}

func ruffiniTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "a root of x^2 - 5x + 6"), "2", "1", "4", "-2"),
		t(qChoose(lang, "another root of x^2 - 5x + 6"), "3", "1", "5", "-3"),
		t(qChoose(lang, "the factor corresponding to root 2"), "(x - 2)", "(x + 2)", "(2x - 1)", "(x - 1)"),
		t(qChoose(lang, "the factorization of x^2 - 5x + 6"), "(x - 2)(x - 3)", "(x + 2)(x + 3)", "(x - 1)(x - 6)", "(x + 1)(x - 6)"),
		t(qChoose(lang, "P(2) for P(x)=x^2-5x+6"), "0", "2", "-2", "6"),
	}
}

func differenceOfSquaresTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qSimplify(lang, "x^2 - 9"), "(x - 3)(x + 3)", "(x - 9)(x + 1)", "(x - 3)^2", "x(x - 9)"),
		t(qSimplify(lang, "4a^2 - b^2"), "(2a - b)(2a + b)", "(4a - b)(a + b)", "(2a - b)^2", "(2a + b)^2"),
		t(qSimplify(lang, "25 - y^2"), "(5 - y)(5 + y)", "(25 - y)(1 + y)", "(5 - y)^2", "(y - 5)^2"),
		t(qChoose(lang, "the expression that is a difference of squares"), "m^2 - 16", "m^2 + 16", "m^2 - 8m + 16", "2m - 16"),
		t(qChoose(lang, "the factorization of 9x^2 - 1"), "(3x - 1)(3x + 1)", "(9x - 1)(x + 1)", "(3x - 1)^2", "(9x + 1)(x - 1)"),
	}
}

func linearEquationTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qSolve(lang, "2x + 5 = 17"), "6", "5", "7", "11"),
		t(qSolve(lang, "3x - 4 = 11"), "5", "3", "7", "15"),
		t(qSolve(lang, "5x = 40"), "8", "5", "10", "35"),
		t(qSolve(lang, "x/4 = 3"), "12", "7", "1", "16"),
		t(qChoose(lang, "the equation with solution x = 2"), "x + 3 = 5", "2x = 8", "x - 4 = 0", "3x = 3"),
	}
}

func literalEquationTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qSolve(lang, "ax = b for x"), "x = b/a", "x = a/b", "x = ab", "x = a - b"),
		t(qSolve(lang, "y = mx + q for x"), "x = (y - q)/m", "x = y - mq", "x = my + q", "x = q/(y - m)"),
		t(qSolve(lang, "A = bh/2 for h"), "h = 2A/b", "h = A/(2b)", "h = b/(2A)", "h = 2b/A"),
		t(qSolve(lang, "P = 2(a + b) for a"), "a = P/2 - b", "a = P - 2b", "a = P/2 + b", "a = 2P - b"),
		t(qChoose(lang, "the correct isolation of r from C = 2pi r"), "r = C/(2pi)", "r = 2pi/C", "r = C*pi/2", "r = C - 2pi"),
	}
}

func quadraticTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qSolve(lang, "x^2 - 9 = 0"), "x = ±3", "x = 3", "x = -3", "x = ±9"),
		t(qSolve(lang, "x^2 - 5x + 6 = 0"), "x = 2 or x = 3", "x = -2 or x = -3", "x = 1 or x = 6", "x = 2 only"),
		t(qChoose(lang, "the roots of x^2 - 4x + 4 = 0"), "x = 2", "x = ±2", "x = 4", "x = 1 and x = 4"),
		t(qChoose(lang, "the quadratic with roots 1 and 2"), "x^2 - 3x + 2", "x^2 + 3x + 2", "x^2 - x - 2", "x^2 - 2x + 1"),
		t(qChoose(lang, "the incomplete quadratic"), "x^2 - 16 = 0", "x^2 + 3x + 2 = 0", "2x^2 - 5x + 1 = 0", "x^2 + x + 1 = 0"),
	}
}

func discriminantTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the discriminant of x^2 - 5x + 6"), "1", "25", "-1", "24"),
		t(qChoose(lang, "the discriminant of x^2 + 2x + 1"), "0", "1", "4", "-4"),
		t(qChoose(lang, "if Δ < 0 then the equation has"), "no real roots", "one real root", "two equal roots", "always integer roots"),
		t(qChoose(lang, "if Δ = 0 then the equation has"), "one double root", "two distinct roots", "no roots", "three roots"),
		t(qChoose(lang, "if Δ > 0 then the equation has"), "two distinct real roots", "one double root", "no real roots", "infinite roots"),
	}
}

func factoringQuadraticTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qSimplify(lang, "x^2 + 5x + 6"), "(x + 2)(x + 3)", "(x - 2)(x - 3)", "(x + 1)(x + 6)", "(x - 1)(x - 6)"),
		t(qSimplify(lang, "x^2 - x - 6"), "(x - 3)(x + 2)", "(x - 2)(x + 3)", "(x + 3)(x + 2)", "(x - 6)(x + 1)"),
		t(qChoose(lang, "the product that expands to x^2 + 7x + 12"), "(x + 3)(x + 4)", "(x - 3)(x - 4)", "(x + 2)(x + 6)", "(x - 2)(x - 6)"),
		t(qChoose(lang, "the numbers whose sum is 5 and product is 6"), "2 and 3", "1 and 6", "-2 and -3", "4 and 1"),
		t(qChoose(lang, "the factorization of x^2 - 9x + 20"), "(x - 4)(x - 5)", "(x + 4)(x + 5)", "(x - 10)(x + 2)", "(x - 2)(x - 7)"),
	}
}

func substitutionTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qSolve(lang, "x + y = 7, y = 2"), "x = 5", "x = 9", "x = 3", "x = 14"),
		t(qSolve(lang, "x = y + 1, x + y = 9"), "x = 5, y = 4", "x = 4, y = 5", "x = 3, y = 6", "x = 6, y = 3"),
		t(qChoose(lang, "the first step in substitution for x + y = 8 and y = 3"), "replace y with 3 in x + y = 8", "multiply the equations", "subtract x from both equations", "compute the determinant"),
		t(qSolve(lang, "x = 4, 2x + y = 11"), "y = 3", "y = 7", "y = 19", "y = -3"),
		t(qChoose(lang, "the system solved by x=2, y=1"), "x + y = 3 and x - y = 1", "x + y = 1 and x - y = 3", "2x + y = 6 and x - y = 0", "x + 2y = 8 and x - y = 2"),
	}
}

func comparisonTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qSolve(lang, "x = 2y and x + y = 12"), "x = 8, y = 4", "x = 6, y = 6", "x = 4, y = 8", "x = 12, y = 0"),
		t(qSolve(lang, "x = y - 3 and x + y = 9"), "x = 3, y = 6", "x = 6, y = 3", "x = 2, y = 7", "x = 1, y = 8"),
		t(qChoose(lang, "comparison method means"), "express the same variable from both equations and compare", "multiply both equations immediately", "always use determinants", "replace with a matrix inverse only"),
		t(qSolve(lang, "x = 5 and x = y + 2"), "y = 3", "y = 7", "y = -3", "y = 2"),
		t(qChoose(lang, "the consistent comparison"), "x = 2y and x = 6 -> y = 3", "x = 2y and x = 6 -> y = 12", "x = y/2 and x = 6 -> y = 3", "x = y + 2 and x = 6 -> y = 8"),
	}
}

func cramerTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the determinant of [[2,1],[1,3]]"), "5", "6", "4", "3"),
		t(qChoose(lang, "Cramer's method applies when"), "the determinant is nonzero", "the determinant is always zero", "there are three variables only", "the system has inequalities"),
		t(qChoose(lang, "if det(A)=0 then Cramer's method"), "cannot give a unique solution", "always gives one unique solution", "always gives x=0 and y=0", "turns every equation into a quadratic"),
		t(qChoose(lang, "the determinant of [[1,2],[3,4]]"), "-2", "2", "10", "-10"),
		t(qChoose(lang, "for a 2x2 system, x is"), "det(Ax) / det(A)", "det(A) / det(Ax)", "det(Ay) / det(A)", "det(A) + det(Ax)"),
	}
}

func segmentsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qCompute(lang, "a segment of length 4 plus a segment of length 7"), "11", "3", "28", "10"),
		t(qChoose(lang, "the midpoint of endpoints 2 and 8"), "5", "4", "6", "10"),
		t(qCompute(lang, "distance between 1 and 9 on a line"), "8", "10", "7", "9"),
		t(qChoose(lang, "the midpoint of endpoints -3 and 5"), "1", "2", "-1", "0"),
		t(qChoose(lang, "the segment half of length 14"), "7", "6", "8", "28"),
	}
}

func anglesTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qCompute(lang, "complement of 35°"), "55°", "145°", "65°", "45°"),
		t(qCompute(lang, "supplement of 120°"), "60°", "120°", "30°", "90°"),
		t(qChoose(lang, "the sum of angles on a straight line"), "180°", "90°", "360°", "270°"),
		t(qChoose(lang, "a right angle"), "90°", "45°", "180°", "60°"),
		t(qCompute(lang, "vertical angle to 70°"), "70°", "110°", "20°", "140°"),
	}
}

func trianglesTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the sum of interior angles of a triangle"), "180°", "360°", "90°", "270°"),
		t(qCompute(lang, "third angle if the first two are 50° and 60°"), "70°", "80°", "90°", "60°"),
		t(qChoose(lang, "an equilateral triangle has"), "all sides equal", "one right angle", "exactly two equal sides", "sum of angles 360°"),
		t(qChoose(lang, "an isosceles triangle has"), "at least two equal sides", "all sides different", "all angles 90°", "sum of angles 90°"),
		t(qCompute(lang, "perimeter of a triangle with sides 3, 4, 5"), "12", "9", "15", "10"),
	}
}

func quadrilateralsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the sum of interior angles of a quadrilateral"), "360°", "180°", "540°", "270°"),
		t(qChoose(lang, "a rectangle has"), "four right angles", "all sides equal and no right angles", "only one pair of parallel sides", "sum of angles 180°"),
		t(qChoose(lang, "a square is"), "a rectangle and a rhombus", "only a rectangle", "only a rhombus", "never a parallelogram"),
		t(qChoose(lang, "a trapezoid has"), "at least one pair of parallel sides", "two pairs of perpendicular sides only", "all sides equal", "sum of angles 180°"),
		t(qCompute(lang, "perimeter of a rectangle 3 by 5"), "16", "15", "8", "30"),
	}
}

func polygonsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the sum of interior angles of a pentagon"), "540°", "360°", "720°", "180°"),
		t(qChoose(lang, "the number of sides of a hexagon"), "6", "5", "7", "8"),
		t(qChoose(lang, "the sum of interior angles of a hexagon"), "720°", "540°", "900°", "360°"),
		t(qChoose(lang, "a polygon with 8 sides"), "octagon", "heptagon", "nonagon", "decagon"),
		t(qChoose(lang, "the number of diagonals from one vertex of a pentagon"), "2", "3", "4", "5"),
	}
}

func criteriaTrianglesTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "a congruence criterion"), "SAS", "AAA only", "one side only", "one angle only"),
		t(qChoose(lang, "two triangles are congruent if"), "their corresponding sides and angles match", "they only have equal area", "they only have one equal side", "they only have one equal angle"),
		t(qChoose(lang, "similar triangles have"), "equal corresponding angles", "equal side lengths only", "always equal perimeters", "always equal areas"),
		t(qChoose(lang, "in similar triangles, corresponding sides are"), "proportional", "equal", "perpendicular", "always integers"),
		t(qChoose(lang, "AAA proves"), "similarity", "congruence", "parallelism only", "orthogonality"),
	}
}

func pythagorasTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qCompute(lang, "hypotenuse of a right triangle with legs 3 and 4"), "5", "6", "7", "4"),
		t(qCompute(lang, "a leg if hypotenuse = 13 and other leg = 5"), "12", "8", "18", "10"),
		t(qChoose(lang, "the Pythagorean relation"), "a^2 + b^2 = c^2", "a + b = c^2", "a^2 + b = c", "2a + 2b = c"),
		t(qChoose(lang, "a Pythagorean triple"), "5, 12, 13", "2, 3, 4", "1, 2, 4", "6, 7, 8"),
		t(qChoose(lang, "Euclid's theorem in right triangles relates"), "legs, hypotenuse and projections", "only angle sums", "only perimeters", "only circle areas"),
	}
}

func circumferenceTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qCompute(lang, "circumference with radius 5"), "10pi", "25pi", "5pi", "20pi"),
		t(qCompute(lang, "circumference with diameter 8"), "8pi", "16pi", "4pi", "64pi"),
		t(qChoose(lang, "the formula for circumference"), "C = 2pi r", "C = pi r^2", "C = d^2", "C = r^2"),
		t(qCompute(lang, "radius if circumference is 12pi"), "6", "12", "3", "24"),
		t(qChoose(lang, "the value of pi is approximately"), "3.14", "2.14", "4.13", "1.34"),
	}
}

func circleAreaTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qCompute(lang, "area of a circle with radius 3"), "9pi", "6pi", "3pi", "18pi"),
		t(qCompute(lang, "area of a circle with diameter 10"), "25pi", "10pi", "100pi", "50pi"),
		t(qChoose(lang, "the formula for area of a circle"), "A = pi r^2", "A = 2pi r", "A = d^2", "A = r^2 / pi"),
		t(qCompute(lang, "radius if area is 16pi"), "4", "8", "16", "2"),
		t(qChoose(lang, "the area of radius 1"), "pi", "2pi", "1", "pi^2"),
	}
}

func tangentsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "a tangent to a circle"), "touches the circle at exactly one point", "cuts the circle at two points", "never meets the circle", "is always a diameter"),
		t(qChoose(lang, "the radius to the point of tangency is"), "perpendicular to the tangent", "parallel to the tangent", "equal to the tangent", "always longer than the tangent"),
		t(qChoose(lang, "from the same external point, tangent segments are"), "equal", "opposite", "perpendicular", "undefined"),
		t(qChoose(lang, "the false statement"), "a tangent intersects the circle at two points", "a tangent can be drawn from an external point", "the tangent is perpendicular to the radius at contact", "two tangent segments from one external point have equal length"),
		t(qChoose(lang, "the line that meets a circle once"), "tangent", "secant", "diameter", "chord"),
	}
}

func secantsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "a secant to a circle"), "cuts the circle at two points", "touches the circle at one point", "never meets the circle", "is always a radius"),
		t(qChoose(lang, "the line segment joining two points of a circle"), "chord", "radius", "tangent", "arc"),
		t(qChoose(lang, "a diameter is"), "a chord through the center", "a tangent through the center", "a radius doubled only outside the circle", "an external secant only"),
		t(qChoose(lang, "the false statement"), "every secant is tangent", "a diameter is a chord", "a secant creates a chord", "a secant meets the circle twice"),
		t(qChoose(lang, "the longest chord of a circle"), "diameter", "radius", "tangent", "arc"),
	}
}

func prismsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "volume of a prism"), "base area * height", "perimeter * height", "base area + height", "2 * base area"),
		t(qCompute(lang, "volume of a prism with base area 12 and height 5"), "60", "17", "120", "48"),
		t(qChoose(lang, "a prism has"), "two parallel congruent bases", "one circular base", "a curved surface only", "always a square base"),
		t(qChoose(lang, "lateral faces of a right prism are"), "rectangles", "circles", "triangles only", "always squares"),
		t(qCompute(lang, "surface area contribution of two bases each area 9"), "18", "9", "81", "27"),
	}
}

func pyramidsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "volume of a pyramid"), "(base area * height) / 3", "base area * height", "2 * base area * height", "base perimeter * height"),
		t(qCompute(lang, "volume of a pyramid with base area 18 and height 6"), "36", "108", "24", "54"),
		t(qChoose(lang, "a pyramid has"), "one base and triangular lateral faces", "two parallel bases", "a curved surface only", "only rectangular faces"),
		t(qChoose(lang, "compared with a prism with same base and height, a pyramid has volume"), "one third", "the same", "double", "three times"),
		t(qChoose(lang, "the apex of a pyramid is"), "the common vertex of lateral faces", "the center of the base only", "a side length", "always below the base"),
	}
}

func cylindersTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "volume of a cylinder"), "pi r^2 h", "2pi r h", "(pi r^2 h) / 3", "pi r h"),
		t(qCompute(lang, "volume of a cylinder with r=2 and h=5"), "20pi", "10pi", "25pi", "40pi"),
		t(qChoose(lang, "lateral area of a cylinder"), "2pi r h", "pi r^2", "2pi r", "pi d^2"),
		t(qCompute(lang, "lateral area with r=3 and h=4"), "24pi", "12pi", "36pi", "48pi"),
		t(qChoose(lang, "a cylinder has"), "two congruent circular bases", "one base only", "triangular faces only", "always height equal to diameter"),
	}
}

func conesTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "volume of a cone"), "(pi r^2 h) / 3", "pi r^2 h", "2pi r h", "pi r h"),
		t(qCompute(lang, "volume of a cone with r=3 and h=6"), "18pi", "54pi", "9pi", "27pi"),
		t(qChoose(lang, "a cone compared with the cylinder of same base and height has volume"), "one third", "the same", "double", "three times"),
		t(qChoose(lang, "a cone has"), "one circular base and one apex", "two circular bases", "only rectangular faces", "two apexes"),
		t(qChoose(lang, "the slant height belongs to"), "the lateral surface of the cone", "the base diameter only", "the volume formula only", "the prism formula"),
	}
}

func spheresTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "volume of a sphere"), "(4/3)pi r^3", "4pi r^2", "pi r^2", "2pi r"),
		t(qChoose(lang, "surface area of a sphere"), "4pi r^2", "(4/3)pi r^3", "2pi r h", "pi r^2"),
		t(qCompute(lang, "surface area of a sphere with r=2"), "16pi", "8pi", "32pi", "4pi"),
		t(qCompute(lang, "volume coefficient for a sphere"), "4/3", "3/4", "2", "1/3"),
		t(qChoose(lang, "if radius doubles, sphere volume scales by"), "8", "2", "4", "16"),
	}
}

func unitCircleTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "sin(0)"), "0", "1", "-1", "undefined"),
		t(qChoose(lang, "cos(0)"), "1", "0", "-1", "undefined"),
		t(qChoose(lang, "sin(pi/2)"), "1", "0", "-1", "undefined"),
		t(qChoose(lang, "cos(pi)"), "-1", "1", "0", "undefined"),
		t(qChoose(lang, "the point at angle 0 on the unit circle"), "(1, 0)", "(0, 1)", "(-1, 0)", "(0, -1)"),
	}
}

func sineCosineTangentTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "tan(45°)"), "1", "0", "sqrt(3)", "undefined"),
		t(qChoose(lang, "sin(30°)"), "1/2", "sqrt(3)/2", "1", "0"),
		t(qChoose(lang, "cos(60°)"), "1/2", "sqrt(3)", "0", "1"),
		t(qChoose(lang, "tan(theta)"), "sin(theta)/cos(theta)", "cos(theta)/sin(theta)", "1/sin(theta)", "sin(theta)*cos(theta)"),
		t(qChoose(lang, "the ratio opposite/hypotenuse"), "sine", "cosine", "tangent", "cotangent"),
	}
}

func lawOfSinesCosinesTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the law of sines"), "a/sin A = b/sin B = c/sin C", "a/cos A = b/cos B", "a+b=c", "a^2+b^2=c^2 for every triangle"),
		t(qChoose(lang, "the law of cosines for side c"), "c^2 = a^2 + b^2 - 2ab cos C", "c = a + b", "c^2 = a^2 - b^2", "c^2 = 2ab cos C"),
		t(qChoose(lang, "the law of cosines reduces to Pythagoras when"), "C = 90°", "A = 0°", "B = 180°", "a = b"),
		t(qChoose(lang, "use the law of sines when"), "you know a side-angle opposite pair", "you only know the perimeter", "you only know one side", "you need a derivative"),
		t(qChoose(lang, "use the law of cosines when"), "you know two sides and the included angle", "you know one angle only", "you only know area", "you only know the median"),
	}
}

func realFunctionsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the output of a real function is"), "one real value for each allowed x", "always two values", "a complex value only", "never depends on x"),
		t(qChoose(lang, "the domain of a function is"), "the set of allowed inputs", "the set of outputs only", "the graph only", "the derivative only"),
		t(qChoose(lang, "the range of a function is"), "the set of attained outputs", "the set of allowed inputs", "the x-axis only", "the slope"),
		t(qChoose(lang, "the graph of y = f(x) consists of points"), "(x, f(x))", "(f(x), x)", "(x, y^2)", "(f(x), f(y))"),
		t(qChoose(lang, "a relation is a function when"), "each x has exactly one image", "each x has at least two images", "there is no domain", "the graph is always a line"),
	}
}

func classificationTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "a polynomial function"), "f(x) = x^2 + 3x + 1", "f(x) = 1/x", "f(x) = sqrt(x - 2)", "f(x) = log x"),
		t(qChoose(lang, "a rational function"), "f(x) = (x + 1)/(x - 2)", "f(x) = x^2", "f(x) = sin x", "f(x) = e^x"),
		t(qChoose(lang, "an exponential function"), "f(x) = 2^x", "f(x) = x^2", "f(x) = 1/x", "f(x) = x + 2"),
		t(qChoose(lang, "a logarithmic function"), "f(x) = log x", "f(x) = x^3", "f(x) = cos x", "f(x) = sqrt(x)"),
		t(qChoose(lang, "a trigonometric function"), "f(x) = sin x", "f(x) = x^2 + 1", "f(x) = e^x", "f(x) = 3x + 4"),
	}
}

func domainTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the domain of 1/(x - 2)"), "all real x except 2", "all real x", "x >= 2", "x > 0"),
		t(qChoose(lang, "the domain of sqrt(x - 3)"), "x >= 3", "x > 3", "all real x", "x <= 3"),
		t(qChoose(lang, "the domain of log(x)"), "x > 0", "x >= 0", "all real x", "x != 0"),
		t(qChoose(lang, "the domain of sqrt(9 - x^2)"), "-3 <= x <= 3", "x >= -3", "x <= 3", "all real x except ±3"),
		t(qChoose(lang, "the domain of 1/sqrt(x - 1)"), "x > 1", "x >= 1", "x < 1", "all real x except 1"),
	}
}

func symmetryTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "an even function satisfies"), "f(-x) = f(x)", "f(-x) = -f(x)", "f(x) = x", "f'(x) = f(x)"),
		t(qChoose(lang, "an odd function satisfies"), "f(-x) = -f(x)", "f(-x) = f(x)", "f(x) > 0", "f'(x) = -f(x)"),
		t(qChoose(lang, "an example of an even function"), "x^2", "x^3", "x + 1", "1/x"),
		t(qChoose(lang, "an example of an odd function"), "x^3", "x^2", "x^2 + 1", "cos x"),
		t(qChoose(lang, "the graph of an even function is symmetric about"), "the y-axis", "the x-axis", "the origin", "the line y = x"),
	}
}

func interceptsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the x-intercept of y = x - 3"), "(3, 0)", "(0, 3)", "(-3, 0)", "(3, 3)"),
		t(qChoose(lang, "the y-intercept of y = 2x + 5"), "(0, 5)", "(5, 0)", "(2, 5)", "(0, 2)"),
		t(qChoose(lang, "the x-intercepts of y = x^2 - 4"), "x = -2 and x = 2", "x = 0 and x = 4", "x = 2 only", "x = -4 and x = 4"),
		t(qChoose(lang, "to find x-intercepts you set"), "y = 0", "x = 0", "f(x) = 1", "the derivative equal to zero"),
		t(qChoose(lang, "to find the y-intercept you set"), "x = 0", "y = 0", "f(x) = 0", "the denominator equal to zero"),
	}
}

func signStudyTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the sign of x - 2 for x > 2"), "positive", "negative", "zero", "undefined"),
		t(qChoose(lang, "the sign of x - 2 for x < 2"), "negative", "positive", "zero", "always undefined"),
		t(qChoose(lang, "the zeros of (x - 3)(x + 1)"), "x = 3 and x = -1", "x = 3 only", "x = -1 only", "x = 1 and x = -3"),
		t(qChoose(lang, "a sign chart changes sign at"), "zeros or points not in the domain", "every integer", "all positive x", "the y-intercept only"),
		t(qChoose(lang, "for (x - 1)^2 the sign is"), "nonnegative", "always negative", "changes sign at x=1", "undefined for x=1"),
	}
}

func expLogTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qSolve(lang, "e^x = e^3"), "x = 3", "x = e^3", "x = 0", "x = ln 3"),
		t(qSolve(lang, "log(x) = 2 (base 10)"), "x = 100", "x = 2", "x = 10", "x = 20"),
		t(qChoose(lang, "ln(e^5)"), "5", "e^5", "1", "0"),
		t(qChoose(lang, "e^(ln 7)"), "7", "ln 7", "e + 7", "1"),
		t(qChoose(lang, "the domain of log(x - 1)"), "x > 1", "x >= 1", "x > 0", "all real x"),
	}
}

func lineTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the slope of y = 2x + 1"), "2", "1", "-2", "0"),
		t(qChoose(lang, "the y-intercept of y = -3x + 4"), "4", "-3", "3", "0"),
		t(qChoose(lang, "the equation of a horizontal line"), "y = k", "x = k", "y = mx + q with m != 0", "x + y = 1"),
		t(qChoose(lang, "parallel lines have"), "the same slope", "slopes that multiply to -1", "the same intercept only", "sum of slopes equal to 0"),
		t(qChoose(lang, "perpendicular slopes satisfy"), "m1 * m2 = -1", "m1 = m2", "m1 + m2 = 1", "m1 - m2 = 0"),
	}
}

func analyticCircleTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the standard form of a circle centered at origin"), "x^2 + y^2 = r^2", "x + y = r", "y = mx + q", "x^2 = y"),
		t(qChoose(lang, "the radius of x^2 + y^2 = 25"), "5", "25", "10", "12.5"),
		t(qChoose(lang, "the center of (x - 2)^2 + (y + 1)^2 = 9"), "(2, -1)", "(-2, 1)", "(2, 1)", "(-1, 2)"),
		t(qChoose(lang, "the radius of (x - 3)^2 + y^2 = 16"), "4", "16", "8", "3"),
		t(qChoose(lang, "a point on x^2 + y^2 = 1"), "(1, 0)", "(2, 0)", "(1, 1)", "(0, 2)"),
	}
}

func parabolaTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the graph of y = x^2 opens"), "upward", "downward", "left", "right"),
		t(qChoose(lang, "the vertex of y = x^2"), "(0, 0)", "(1, 0)", "(0, 1)", "(-1, 0)"),
		t(qChoose(lang, "the axis of symmetry of y = x^2"), "x = 0", "y = 0", "x = 1", "y = 1"),
		t(qChoose(lang, "the vertex of y = (x - 2)^2 + 3"), "(2, 3)", "(-2, 3)", "(2, -3)", "(3, 2)"),
		t(qChoose(lang, "if a < 0 in y = a(x - h)^2 + k, the parabola opens"), "downward", "upward", "left", "right"),
	}
}

func ellipseTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the standard form of an ellipse centered at origin"), "x^2/a^2 + y^2/b^2 = 1", "x^2 + y^2 = r^2", "y = ax^2 + bx + c", "x^2/a^2 - y^2/b^2 = 1"),
		t(qChoose(lang, "an ellipse has"), "two axes of symmetry", "one branch only", "asymptotes", "always equal axes"),
		t(qChoose(lang, "if a > b in x^2/a^2 + y^2/b^2 = 1, the major axis is"), "horizontal", "vertical", "undefined", "oblique"),
		t(qChoose(lang, "a point on x^2/4 + y^2/9 = 1 when x = 0"), "y = ±3", "y = ±2", "y = ±4", "y = 0"),
		t(qChoose(lang, "the ellipse is a"), "closed curve", "pair of lines", "parabola", "hyperbola"),
	}
}

func hyperbolaTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the standard form of a hyperbola centered at origin"), "x^2/a^2 - y^2/b^2 = 1", "x^2/a^2 + y^2/b^2 = 1", "x^2 + y^2 = r^2", "y = ax^2"),
		t(qChoose(lang, "a hyperbola has"), "two branches", "one vertex only", "no asymptotes", "always a bounded region"),
		t(qChoose(lang, "the asymptotes of x^2/a^2 - y^2/b^2 = 1 are"), "y = ±(b/a)x", "y = ±(a/b)x^2", "x = ±a^2", "y = ±b^2"),
		t(qChoose(lang, "the graph of x^2 - y^2 = 1 is"), "a hyperbola", "an ellipse", "a line", "a parabola"),
		t(qChoose(lang, "a hyperbola is"), "an open curve", "a closed curve", "always a circle", "always symmetric only about x-axis"),
	}
}

func limitsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qEvaluate(lang, "lim_{x->2} (x + 3)"), "5", "2", "3", "6"),
		t(qEvaluate(lang, "lim_{x->1} (x^2)"), "1", "2", "0", "undefined"),
		t(qEvaluate(lang, "lim_{x->0} (3x)"), "0", "3", "1", "undefined"),
		t(qChoose(lang, "lim_{x->+infinity} 1/x"), "0", "+infinity", "1", "undefined"),
		t(qChoose(lang, "a finite limit means"), "the function approaches a real number", "the function becomes infinite", "the function has no graph", "the derivative is zero"),
	}
}

func indeterminateFormsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "an indeterminate form"), "0/0", "1/0", "5/0", "infinity + 3"),
		t(qChoose(lang, "another indeterminate form"), "infinity/infinity", "0/5", "4/0", "7 - 2"),
		t(qChoose(lang, "0/0 is called"), "indeterminate", "always zero", "always infinite", "undefined but never a limit issue"),
		t(qChoose(lang, "to resolve 0/0 you often"), "simplify algebraically", "replace it with 0 immediately", "replace it with 1 immediately", "ignore the denominator"),
		t(qChoose(lang, "infinity - infinity is"), "indeterminate", "always zero", "always infinity", "always one"),
	}
}

func asymptotesTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "x = 2 is a vertical asymptote of"), "1/(x - 2)", "x - 2", "x^2 + 2", "sqrt(x - 2)"),
		t(qChoose(lang, "the horizontal asymptote of 1/x"), "y = 0", "x = 0", "y = 1", "x = 1"),
		t(qChoose(lang, "a vertical asymptote occurs when"), "the denominator tends to 0 and values blow up", "the function has slope 0", "the graph crosses the x-axis", "the derivative is constant"),
		t(qChoose(lang, "the line y = 2 is"), "a horizontal asymptote", "a vertical asymptote", "a tangent only", "a secant"),
		t(qChoose(lang, "an oblique asymptote is"), "a slanted line approached by the graph", "a horizontal line only", "a vertical line only", "a circle"),
	}
}

func differenceQuotientTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the difference quotient of f at x"), "(f(x+h)-f(x))/h", "(f(x)-f(h))/x", "f'(x) * h", "f(x+h)+f(x)"),
		t(qChoose(lang, "the derivative is the limit of the difference quotient as"), "h -> 0", "x -> infinity", "h -> infinity", "x -> 1"),
		t(qChoose(lang, "for f(x)=x^2, f(x+h)"), "x^2 + 2xh + h^2", "x^2 + h^2", "2x + h", "x^2 + 2h"),
		t(qChoose(lang, "for f(x)=x^2, the derivative is"), "2x", "x", "x^2", "2"),
		t(qChoose(lang, "the difference quotient measures"), "average rate of change", "area under a curve", "intercepts only", "domain only"),
	}
}

func geometricMeaningTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the derivative at a point is"), "the slope of the tangent line", "the y-intercept", "the area under the curve", "the domain"),
		t(qChoose(lang, "if f'(x) > 0"), "the function is increasing locally", "the function is decreasing", "the function is undefined", "the graph is horizontal"),
		t(qChoose(lang, "if f'(x) = 0"), "the tangent is horizontal", "the function has no tangent", "the graph is vertical", "the function is always constant"),
		t(qChoose(lang, "a negative derivative suggests"), "local decrease", "local increase", "a maximum always", "an asymptote"),
		t(qChoose(lang, "the tangent line touches the curve"), "at the point of tangency with same slope", "at two unrelated points", "only at asymptotes", "never at the graph"),
	}
}

func powerRuleTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qDifferentiate(lang, "x^5"), "5x^4", "x^4", "5x^5", "4x^5"),
		t(qDifferentiate(lang, "x^3"), "3x^2", "x^2", "3x^3", "2x^3"),
		t(qDifferentiate(lang, "7x^2"), "14x", "7x", "14x^2", "2x"),
		t(qDifferentiate(lang, "sqrt(x)"), "1/(2sqrt(x))", "2sqrt(x)", "1/sqrt(x)", "sqrt(x)"),
		t(qChoose(lang, "the derivative of a constant"), "0", "1", "the constant itself", "undefined"),
	}
}

func productRuleTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qDifferentiate(lang, "x * x^2"), "3x^2", "x^3", "2x", "x^2"),
		t(qChoose(lang, "the product rule"), "(uv)' = u'v + uv'", "(uv)' = u'v'", "(uv)' = u/v", "(uv)' = u + v"),
		t(qDifferentiate(lang, "x * e^x"), "e^x + x e^x", "x e^x", "e^x", "x + e^x"),
		t(qDifferentiate(lang, "(x^2)(x^3)"), "5x^4", "6x^5", "x^6", "4x^5"),
		t(qDifferentiate(lang, "x sin x"), "sin x + x cos x", "x cos x", "sin x cos x", "cos x"),
	}
}

func quotientRuleTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the quotient rule"), "(u/v)' = (u'v - uv')/v^2", "(u/v)' = u'/v'", "(u/v)' = (u'v + uv')/v", "(u/v)' = u/v^2"),
		t(qDifferentiate(lang, "1/x"), "-1/x^2", "1/x^2", "-x^2", "0"),
		t(qDifferentiate(lang, "(x^2)/(x)"), "1", "2x", "x", "0"),
		t(qDifferentiate(lang, "(x + 1)/(x - 1)"), "-2/(x - 1)^2", "2/(x - 1)^2", "(2x)/(x - 1)", "1"),
		t(qChoose(lang, "the denominator in the quotient rule becomes"), "v^2", "v", "u^2", "u+v"),
	}
}

func chainRuleTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the chain rule"), "(f(g(x)))' = f'(g(x)) * g'(x)", "(f(g(x)))' = f'(x) + g'(x)", "(f(g(x)))' = f'(x)g(x)", "(f(g(x)))' = f(g'(x))"),
		t(qDifferentiate(lang, "(x^2 + 1)^3"), "6x(x^2 + 1)^2", "3(x^2 + 1)^2", "6x(x^2 + 1)^3", "2x(x^2 + 1)^2"),
		t(qDifferentiate(lang, "sin(3x)"), "3 cos(3x)", "cos(3x)", "3 sin(3x)", "cos x"),
		t(qDifferentiate(lang, "e^(2x)"), "2e^(2x)", "e^(2x)", "2x e^(2x)", "e^x"),
		t(qDifferentiate(lang, "sqrt(5x + 1)"), "5/(2sqrt(5x + 1))", "1/(2sqrt x)", "5sqrt(5x + 1)", "1/sqrt(5x + 1)"),
	}
}

func maximaMinimaTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "a local maximum may occur where"), "f'(x) changes from positive to negative", "f'(x) changes from negative to positive", "f''(x) is always zero", "the function is undefined only"),
		t(qChoose(lang, "a local minimum may occur where"), "f'(x) changes from negative to positive", "f'(x) changes from positive to negative", "the graph crosses the y-axis", "the domain ends"),
		t(qChoose(lang, "critical points are where"), "f'(x)=0 or f' is undefined", "f(x)=0 only", "the intercepts lie", "the asymptotes lie"),
		t(qChoose(lang, "if f''(x0) > 0 at a critical point"), "it suggests a local minimum", "it suggests a local maximum", "it proves a vertical tangent", "it proves no extremum exists"),
		t(qChoose(lang, "if f''(x0) < 0 at a critical point"), "it suggests a local maximum", "it suggests a local minimum", "it proves the function is linear", "it proves an asymptote"),
	}
}

func inflectionTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "an inflection point is where"), "concavity changes", "the function crosses the x-axis only", "the derivative is always zero", "the domain changes"),
		t(qChoose(lang, "you often study inflection points with"), "the second derivative", "only the first derivative", "only intercepts", "only the domain"),
		t(qChoose(lang, "if f'' changes from positive to negative"), "concavity changes and there may be an inflection point", "there is always a maximum", "there is always a minimum", "nothing can be said"),
		t(qChoose(lang, "concave up means"), "f'' > 0", "f'' < 0", "f' < 0", "f = 0"),
		t(qChoose(lang, "concave down means"), "f'' < 0", "f'' > 0", "f' > 0", "f = 1"),
	}
}

func primitivesTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "a primitive of 2x"), "x^2 + C", "2x^2 + C", "x + C", "2 + C"),
		t(qChoose(lang, "a primitive of 3"), "3x + C", "x^3 + C", "3 + C", "1 + C"),
		t(qChoose(lang, "if F'(x) = f(x), then F is"), "a primitive of f", "the quotient of f", "the asymptote of f", "the domain of f"),
		t(qChoose(lang, "primitives of the same function differ by"), "a constant", "a variable", "a root", "a denominator"),
		t(qChoose(lang, "a primitive of x^2"), "\\frac{x^3}{3} + C", "2x + C", "\\frac{x^2}{2} + C", "3x^2 + C"),
	}
}

func immediateIntegrationTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qIntegrate(lang, "x^4 dx"), "\\frac{x^5}{5} + C", "4x^3 + C", "\\frac{x^4}{4} + C", "5x + C"),
		t(qIntegrate(lang, "1/x dx"), "ln|x| + C", "1/(x^2) + C", "x + C", "e^x + C"),
		t(qIntegrate(lang, "e^x dx"), "e^x + C", "xe^x + C", "ln|x| + C", "1/e^x + C"),
		t(qIntegrate(lang, "cos x dx"), "sin x + C", "-sin x + C", "cos x + C", "-cos x + C"),
		t(qIntegrate(lang, "sin x dx"), "-cos x + C", "cos x + C", "sin x + C", "tan x + C"),
	}
}

func substitutionIntegrationTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qIntegrate(lang, "(2x)cos(x^2) dx"), "sin(x^2) + C", "cos(x^2) + C", "x^2 sin(x^2) + C", "tan(x^2) + C"),
		t(qChoose(lang, "a good substitution for integral of 2x(x^2+1)^5 dx"), "u = x^2 + 1", "u = 2x", "u = 5", "u = x"),
		t(qIntegrate(lang, "3e^(3x) dx"), "e^(3x) + C", "3e^(3x) + C", "e^x + C", "x e^(3x) + C"),
		t(qIntegrate(lang, "(1/x) dx"), "ln|x| + C", "1/x^2 + C", "e^x + C", "x + C"),
		t(qChoose(lang, "substitution is useful when"), "an inner function and its derivative both appear", "you only see constants", "the integrand is always a polynomial", "the function has no variable"),
	}
}

func integrationByPartsTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "the integration by parts formula"), "∫u dv = uv - ∫v du", "∫u dv = u/v + C", "∫u dv = du * dv", "∫u dv = uv"),
		t(qChoose(lang, "a good choice for ∫x e^x dx"), "u = x, dv = e^x dx", "u = e^x, dv = x dx", "u = x e^x, dv = dx", "u = 1, dv = x e^x dx"),
		t(qIntegrate(lang, "x e^x dx"), "e^x(x - 1) + C", "x e^x + C", "e^x(x + 1) + C", "e^x + C"),
		t(qChoose(lang, "LIATE helps choose"), "u", "the correct asymptote", "the domain", "the determinant"),
		t(qChoose(lang, "integration by parts comes from"), "the product rule", "the quotient rule", "the chain rule only", "the binomial theorem"),
	}
}

func areaUnderCurveTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "if f(x) >= 0 on [a,b], then ∫_a^b f(x) dx is"), "the geometric area under the curve", "always zero", "always negative", "the slope of the tangent"),
		t(qEvaluate(lang, "∫_0^1 x dx"), "\\frac{1}{2}", "1", "2", "\\frac{1}{3}"),
		t(qEvaluate(lang, "∫_0^1 x^2 dx"), "\\frac{1}{3}", "\\frac{1}{2}", "1", "\\frac{1}{4}"),
		t(qChoose(lang, "a definite integral represents"), "signed area", "only positive area", "always a derivative", "only the domain"),
		t(qChoose(lang, "if the graph is below the x-axis"), "the integral contribution is negative", "the contribution is positive", "the contribution is zero", "the integral is undefined"),
	}
}

func ftcTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "FTC Part 2"), "∫_a^b f(x) dx = F(b) - F(a)", "∫_a^b f(x) dx = F'(b) - F'(a)", "∫_a^b f(x) dx = f(b) - f(a)", "∫_a^b f(x) dx = a - b"),
		t(qChoose(lang, "if F'(x) = f(x), then F is"), "an antiderivative of f", "the quotient of f", "the inverse of f always", "an asymptote of f"),
		t(qEvaluate(lang, "∫_0^2 x dx using FTC"), "2", "1", "4", "3"),
		t(qChoose(lang, "FTC Part 1 states that if F(x)=∫_a^x f(t)dt, then"), "F'(x)=f(x)", "F(x)=f'(x)", "F''(x)=f(x)", "F(x)=a"),
		t(qChoose(lang, "the correct endpoint evaluation for ∫_a^b f(x) dx"), "F(b) - F(a)", "F(a) - F(b)", "F'(b) - F'(a)", "f(b) - f(a)"),
	}
}

func volumeTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "disk method volume"), "V = pi ∫_a^b (f(x))^2 dx", "V = ∫_a^b f(x) dx", "V = 2pi ∫_a^b f(x) dx", "V = pi r^2"),
		t(qChoose(lang, "washer method volume"), "V = pi ∫_a^b (R^2 - r^2) dx", "V = ∫_a^b (R-r) dx", "V = pi(R-r)", "V = 2pi∫_a^b(R+r)dx"),
		t(qChoose(lang, "a disk is obtained by rotating"), "a vertical slice around an axis", "a tangent around a secant", "a derivative around an intercept", "a domain around the y-axis only"),
		t(qChoose(lang, "the radius in the disk method is"), "the distance from the curve to the axis of rotation", "always the x-value", "always the derivative", "the intercept only"),
		t(qChoose(lang, "for solids of revolution about x-axis, the integrand often contains"), "a squared radius", "only a linear term", "a determinant", "a discriminant"),
	}
}

func planeAreaTemplates(lang string) []practiceExerciseTemplate {
	return []practiceExerciseTemplate{
		t(qChoose(lang, "area between y=f(x) and y=g(x) on [a,b] with f>=g"), "∫_a^b (f(x)-g(x)) dx", "∫_a^b (f(x)+g(x)) dx", "f(b)-g(a)", "∫_a^b f(x)g(x) dx"),
		t(qEvaluate(lang, "area between y=x and y=x^2 on [0,1]"), "1/6", "1/3", "1/2", "1"),
		t(qChoose(lang, "if curves cross, you should"), "split the interval at intersection points", "ignore the crossing", "always subtract in any order", "differentiate both curves"),
		t(qChoose(lang, "top minus bottom means"), "higher curve minus lower curve", "left curve minus right curve", "derivative minus function", "domain minus range"),
		t(qChoose(lang, "area is always"), "nonnegative", "always negative", "equal to a derivative", "equal to a slope"),
	}
}

func fmtInt(value int) string {
	return strconv.Itoa(value)
}

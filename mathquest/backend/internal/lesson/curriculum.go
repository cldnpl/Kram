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

// curriculumForLang returns the curriculum with titles translated to the given language.
// Supported languages: "en", "it", "fr", "es", "uz".
func curriculumForLang(lang string) []fiber.Map {
	if lang == "" || lang == "en" {
		return curriculum()
	}

	translations := translationMap(lang)
	if translations == nil {
		return curriculum()
	}

	cats := curriculum()
	for i, cat := range cats {
		if t, ok := translations[cat["title"].(string)]; ok {
			cat["title"] = t
		}
		sections := cat["sections"].([]fiber.Map)
		for j, sec := range sections {
			if t, ok := translations[sec["title"].(string)]; ok {
				sec["title"] = t
			}
			items := sec["items"].([]fiber.Map)
			for k, item := range items {
				if t, ok := translations[item["title"].(string)]; ok {
					item["title"] = t
				}
				items[k] = item
			}
			sections[j] = sec
		}
		cats[i] = cat
	}
	return cats
}

// translationMap returns a map from English title to translated title for the given language.
func translationMap(lang string) map[string]string {
	switch lang {
	case "it":
		return map[string]string{
			// Categories
			"Arithmetic & Number Systems": "Aritmetica e sistemi numerici",
			"Algebra":                     "Algebra",
			"Geometry & Trigonometry":      "Geometria e trigonometria",
			"Pre-Calculus & Analysis":      "Precalcolo e analisi",
			"Differential Calculus":        "Calcolo differenziale",
			"Integral Calculus":            "Calcolo integrale",
			// Arithmetic sections
			"Sets of Numbers":                "Insiemi numerici",
			"Fundamental Operations":         "Operazioni fondamentali",
			"Expressions & Order of Operations": "Espressioni e ordine delle operazioni",
			"Divisibility & Prime Numbers":   "Divisibilità e numeri primi",
			"Fractions & Ratios":             "Frazioni e rapporti",
			// Arithmetic items
			"Natural numbers ℕ":                      "Numeri naturali ℕ",
			"Integers ℤ":                              "Numeri interi ℤ",
			"Rational numbers ℚ":                      "Numeri razionali ℚ",
			"The four operations":                     "Le quattro operazioni",
			"Powers and their properties":             "Potenze e loro proprietà",
			"Roots":                                   "Radici",
			"Use of parentheses and PEMDAS/BODMAS":    "Uso delle parentesi e PEMDAS/BODMAS",
			"Multiples":                               "Multipli",
			"Divisors":                                "Divisori",
			"GCD (Greatest Common Divisor)":           "MCD (Massimo Comune Divisore)",
			"LCM (Least Common Multiple)":             "mcm (minimo comune multiplo)",
			"Equivalent fractions":                    "Frazioni equivalenti",
			"Operations with fractions":               "Operazioni con le frazioni",
			"Percentages":                             "Percentuali",
			"Proportions":                             "Proporzioni",
			// Algebra sections
			"Monomials & Polynomials":       "Monomi e polinomi",
			"Factoring Polynomials":         "Scomposizione dei polinomi",
			"Linear Equations & Inequalities": "Equazioni e disequazioni lineari",
			"Quadratic Equations":           "Equazioni di secondo grado",
			"Systems of Equations":          "Sistemi di equazioni",
			// Algebra items
			"Operations":                                    "Operazioni",
			"Degree of a polynomial":                        "Grado di un polinomio",
			"Special products (e.g. square of a binomial)":  "Prodotti notevoli (es. quadrato di un binomio)",
			"Common factoring":                              "Raccoglimento a fattore comune",
			"Ruffini's Rule":                                "Regola di Ruffini",
			"Difference of Squares":                         "Differenza di quadrati",
			"First-degree equations":                        "Equazioni di primo grado",
			"Literal equations":                             "Equazioni letterali",
			"Complete and incomplete quadratics":            "Equazioni complete e incomplete",
			"The Discriminant (Δ)":                          "Il discriminante (Δ)",
			"Factoring quadratic trinomials":                "Scomposizione di trinomi di secondo grado",
			"Substitution":                                  "Sostituzione",
			"Comparison":                                    "Confronto",
			"Cramer's method":                               "Metodo di Cramer",
			// Geometry sections
			"Plane Geometry":            "Geometria piana",
			"Congruence & Similarity":   "Congruenza e similitudine",
			"Circle & Pi":               "Cerchio e Pi greco",
			"Solid Geometry":            "Geometria solida",
			"Goniometry & Trigonometry": "Goniometria e trigonometria",
			// Geometry items
			"Segments":                            "Segmenti",
			"Angles":                              "Angoli",
			"Triangles":                           "Triangoli",
			"Quadrilaterals":                      "Quadrilateri",
			"Polygons":                            "Poligoni",
			"Criteria for triangles":              "Criteri per i triangoli",
			"Pythagoras' and Euclid's theorems":   "Teoremi di Pitagora e di Euclide",
			"Circumference":                       "Circonferenza",
			"Area":                                "Area",
			"Tangents":                            "Tangenti",
			"Secants":                             "Secanti",
			"Prisms":                              "Prismi",
			"Pyramids":                            "Piramidi",
			"Cylinders":                           "Cilindri",
			"Cones":                               "Coni",
			"Spheres (Volume & Surface Area)":     "Sfere (volume e area superficiale)",
			"The Unit Circle":                     "Il cerchio unitario",
			"Sine, Cosine, Tangent":               "Seno, coseno, tangente",
			"Law of Sines/Cosines":                "Teorema dei seni/coseni",
			// Pre-Calculus sections
			"Functions & Domain":        "Funzioni e dominio",
			"Properties of Functions":   "Proprietà delle funzioni",
			"Exponential & Logarithms":  "Esponenziali e logaritmi",
			"Analytic Geometry":         "Geometria analitica",
			// Pre-Calculus items
			"Real functions of a real variable":               "Funzioni reali di variabile reale",
			"Classification":                                  "Classificazione",
			"Finding the domain":                              "Determinazione del dominio",
			"Symmetries (Even/Odd)":                           "Simmetrie (pari/dispari)",
			"Intercepts":                                      "Intersezioni con gli assi",
			"Sign study":                                      "Studio del segno",
			"Equations and inequalities with eˣ and log(x)":   "Equazioni e disequazioni con eˣ e log(x)",
			"The line":                                        "La retta",
			"The circle":                                      "La circonferenza",
			"The parabola":                                    "La parabola",
			"The ellipse":                                     "L'ellisse",
			"The hyperbola in the Cartesian plane":            "L'iperbole nel piano cartesiano",
			// Differential Calculus sections
			"Limits & Continuity":       "Limiti e continuità",
			"The Derivative Concept":    "Il concetto di derivata",
			"Differentiation Rules":     "Regole di derivazione",
			"Function Study":            "Studio di funzione",
			// Differential Calculus items
			"Finite and infinite limits":  "Limiti finiti e infiniti",
			"Indeterminate forms":         "Forme indeterminate",
			"Asymptotes":                  "Asintoti",
			"Difference quotient":         "Rapporto incrementale",
			"Geometric meaning":           "Significato geometrico",
			"Power rule":                  "Regola della potenza",
			"Product rule":                "Regola del prodotto",
			"Quotient rule":               "Regola del quoziente",
			"Chain rule":                  "Regola della catena",
			"Maxima and Minima":           "Massimi e minimi",
			"Points of inflection":        "Punti di flesso",
			// Integral Calculus sections
			"Indefinite Integrals":  "Integrali indefiniti",
			"Integration Methods":   "Metodi di integrazione",
			"Definite Integrals":    "Integrali definiti",
			"Applications":          "Applicazioni",
			// Integral Calculus items
			"Primitive functions":                      "Funzioni primitive",
			"Immediate integration rules":              "Regole di integrazione immediata",
			"Integration by substitution":              "Integrazione per sostituzione",
			"Integration by parts":                     "Integrazione per parti",
			"Calculating the area under a curve":       "Calcolo dell'area sotto una curva",
			"The Fundamental Theorem of Calculus":      "Il teorema fondamentale del calcolo",
			"Calculation of volumes":                   "Calcolo dei volumi",
			"Areas of plane figures":                   "Aree di figure piane",
		}
	case "fr":
		return map[string]string{
			// Categories
			"Arithmetic & Number Systems": "Arithmétique et systèmes de nombres",
			"Algebra":                     "Algèbre",
			"Geometry & Trigonometry":      "Géométrie et trigonométrie",
			"Pre-Calculus & Analysis":      "Pré-calcul et analyse",
			"Differential Calculus":        "Calcul différentiel",
			"Integral Calculus":            "Calcul intégral",
			// Arithmetic sections
			"Sets of Numbers":                "Ensembles de nombres",
			"Fundamental Operations":         "Opérations fondamentales",
			"Expressions & Order of Operations": "Expressions et ordre des opérations",
			"Divisibility & Prime Numbers":   "Divisibilité et nombres premiers",
			"Fractions & Ratios":             "Fractions et rapports",
			// Arithmetic items
			"Natural numbers ℕ":                      "Nombres naturels ℕ",
			"Integers ℤ":                              "Nombres entiers ℤ",
			"Rational numbers ℚ":                      "Nombres rationnels ℚ",
			"The four operations":                     "Les quatre opérations",
			"Powers and their properties":             "Puissances et leurs propriétés",
			"Roots":                                   "Racines",
			"Use of parentheses and PEMDAS/BODMAS":    "Utilisation des parenthèses et PEMDAS/BODMAS",
			"Multiples":                               "Multiples",
			"Divisors":                                "Diviseurs",
			"GCD (Greatest Common Divisor)":           "PGCD (Plus Grand Commun Diviseur)",
			"LCM (Least Common Multiple)":             "PPCM (Plus Petit Commun Multiple)",
			"Equivalent fractions":                    "Fractions équivalentes",
			"Operations with fractions":               "Opérations avec les fractions",
			"Percentages":                             "Pourcentages",
			"Proportions":                             "Proportions",
			// Algebra sections
			"Monomials & Polynomials":       "Monômes et polynômes",
			"Factoring Polynomials":         "Factorisation des polynômes",
			"Linear Equations & Inequalities": "Équations et inéquations linéaires",
			"Quadratic Equations":           "Équations du second degré",
			"Systems of Equations":          "Systèmes d'équations",
			// Algebra items
			"Operations":                                    "Opérations",
			"Degree of a polynomial":                        "Degré d'un polynôme",
			"Special products (e.g. square of a binomial)":  "Produits remarquables (ex. carré d'un binôme)",
			"Common factoring":                              "Mise en facteur commun",
			"Ruffini's Rule":                                "Règle de Ruffini",
			"Difference of Squares":                         "Différence de carrés",
			"First-degree equations":                        "Équations du premier degré",
			"Literal equations":                             "Équations littérales",
			"Complete and incomplete quadratics":            "Équations complètes et incomplètes",
			"The Discriminant (Δ)":                          "Le discriminant (Δ)",
			"Factoring quadratic trinomials":                "Factorisation de trinômes du second degré",
			"Substitution":                                  "Substitution",
			"Comparison":                                    "Comparaison",
			"Cramer's method":                               "Méthode de Cramer",
			// Geometry sections
			"Plane Geometry":            "Géométrie plane",
			"Congruence & Similarity":   "Congruence et similitude",
			"Circle & Pi":               "Cercle et Pi",
			"Solid Geometry":            "Géométrie dans l'espace",
			"Goniometry & Trigonometry": "Goniométrie et trigonométrie",
			// Geometry items
			"Segments":                            "Segments",
			"Angles":                              "Angles",
			"Triangles":                           "Triangles",
			"Quadrilaterals":                      "Quadrilatères",
			"Polygons":                            "Polygones",
			"Criteria for triangles":              "Critères pour les triangles",
			"Pythagoras' and Euclid's theorems":   "Théorèmes de Pythagore et d'Euclide",
			"Circumference":                       "Circonférence",
			"Area":                                "Aire",
			"Tangents":                            "Tangentes",
			"Secants":                             "Sécantes",
			"Prisms":                              "Prismes",
			"Pyramids":                            "Pyramides",
			"Cylinders":                           "Cylindres",
			"Cones":                               "Cônes",
			"Spheres (Volume & Surface Area)":     "Sphères (volume et aire)",
			"The Unit Circle":                     "Le cercle trigonométrique",
			"Sine, Cosine, Tangent":               "Sinus, cosinus, tangente",
			"Law of Sines/Cosines":                "Loi des sinus/cosinus",
			// Pre-Calculus sections
			"Functions & Domain":        "Fonctions et domaine",
			"Properties of Functions":   "Propriétés des fonctions",
			"Exponential & Logarithms":  "Exponentielles et logarithmes",
			"Analytic Geometry":         "Géométrie analytique",
			// Pre-Calculus items
			"Real functions of a real variable":               "Fonctions réelles d'une variable réelle",
			"Classification":                                  "Classification",
			"Finding the domain":                              "Détermination du domaine",
			"Symmetries (Even/Odd)":                           "Symétries (paire/impaire)",
			"Intercepts":                                      "Intersections avec les axes",
			"Sign study":                                      "Étude du signe",
			"Equations and inequalities with eˣ and log(x)":   "Équations et inéquations avec eˣ et log(x)",
			"The line":                                        "La droite",
			"The circle":                                      "Le cercle",
			"The parabola":                                    "La parabole",
			"The ellipse":                                     "L'ellipse",
			"The hyperbola in the Cartesian plane":            "L'hyperbole dans le plan cartésien",
			// Differential Calculus sections
			"Limits & Continuity":       "Limites et continuité",
			"The Derivative Concept":    "Le concept de dérivée",
			"Differentiation Rules":     "Règles de dérivation",
			"Function Study":            "Étude de fonction",
			// Differential Calculus items
			"Finite and infinite limits":  "Limites finies et infinies",
			"Indeterminate forms":         "Formes indéterminées",
			"Asymptotes":                  "Asymptotes",
			"Difference quotient":         "Taux d'accroissement",
			"Geometric meaning":           "Signification géométrique",
			"Power rule":                  "Règle de la puissance",
			"Product rule":                "Règle du produit",
			"Quotient rule":               "Règle du quotient",
			"Chain rule":                  "Règle de la chaîne",
			"Maxima and Minima":           "Maxima et minima",
			"Points of inflection":        "Points d'inflexion",
			// Integral Calculus sections
			"Indefinite Integrals":  "Intégrales indéfinies",
			"Integration Methods":   "Méthodes d'intégration",
			"Definite Integrals":    "Intégrales définies",
			"Applications":          "Applications",
			// Integral Calculus items
			"Primitive functions":                      "Fonctions primitives",
			"Immediate integration rules":              "Règles d'intégration immédiate",
			"Integration by substitution":              "Intégration par substitution",
			"Integration by parts":                     "Intégration par parties",
			"Calculating the area under a curve":       "Calcul de l'aire sous une courbe",
			"The Fundamental Theorem of Calculus":      "Le théorème fondamental du calcul",
			"Calculation of volumes":                   "Calcul des volumes",
			"Areas of plane figures":                   "Aires de figures planes",
		}
	case "es":
		return map[string]string{
			// Categories
			"Arithmetic & Number Systems": "Aritmética y sistemas numéricos",
			"Algebra":                     "Álgebra",
			"Geometry & Trigonometry":      "Geometría y trigonometría",
			"Pre-Calculus & Analysis":      "Precálculo y análisis",
			"Differential Calculus":        "Cálculo diferencial",
			"Integral Calculus":            "Cálculo integral",
			// Arithmetic sections
			"Sets of Numbers":                "Conjuntos de números",
			"Fundamental Operations":         "Operaciones fundamentales",
			"Expressions & Order of Operations": "Expresiones y orden de operaciones",
			"Divisibility & Prime Numbers":   "Divisibilidad y números primos",
			"Fractions & Ratios":             "Fracciones y razones",
			// Arithmetic items
			"Natural numbers ℕ":                      "Números naturales ℕ",
			"Integers ℤ":                              "Números enteros ℤ",
			"Rational numbers ℚ":                      "Números racionales ℚ",
			"The four operations":                     "Las cuatro operaciones",
			"Powers and their properties":             "Potencias y sus propiedades",
			"Roots":                                   "Raíces",
			"Use of parentheses and PEMDAS/BODMAS":    "Uso de paréntesis y PEMDAS/BODMAS",
			"Multiples":                               "Múltiplos",
			"Divisors":                                "Divisores",
			"GCD (Greatest Common Divisor)":           "MCD (Máximo Común Divisor)",
			"LCM (Least Common Multiple)":             "mcm (mínimo común múltiplo)",
			"Equivalent fractions":                    "Fracciones equivalentes",
			"Operations with fractions":               "Operaciones con fracciones",
			"Percentages":                             "Porcentajes",
			"Proportions":                             "Proporciones",
			// Algebra sections
			"Monomials & Polynomials":       "Monomios y polinomios",
			"Factoring Polynomials":         "Factorización de polinomios",
			"Linear Equations & Inequalities": "Ecuaciones e inecuaciones lineales",
			"Quadratic Equations":           "Ecuaciones de segundo grado",
			"Systems of Equations":          "Sistemas de ecuaciones",
			// Algebra items
			"Operations":                                    "Operaciones",
			"Degree of a polynomial":                        "Grado de un polinomio",
			"Special products (e.g. square of a binomial)":  "Productos notables (ej. cuadrado de un binomio)",
			"Common factoring":                              "Factor común",
			"Ruffini's Rule":                                "Regla de Ruffini",
			"Difference of Squares":                         "Diferencia de cuadrados",
			"First-degree equations":                        "Ecuaciones de primer grado",
			"Literal equations":                             "Ecuaciones literales",
			"Complete and incomplete quadratics":            "Ecuaciones completas e incompletas",
			"The Discriminant (Δ)":                          "El discriminante (Δ)",
			"Factoring quadratic trinomials":                "Factorización de trinomios de segundo grado",
			"Substitution":                                  "Sustitución",
			"Comparison":                                    "Comparación",
			"Cramer's method":                               "Método de Cramer",
			// Geometry sections
			"Plane Geometry":            "Geometría plana",
			"Congruence & Similarity":   "Congruencia y semejanza",
			"Circle & Pi":               "Círculo y Pi",
			"Solid Geometry":            "Geometría del espacio",
			"Goniometry & Trigonometry": "Goniometría y trigonometría",
			// Geometry items
			"Segments":                            "Segmentos",
			"Angles":                              "Ángulos",
			"Triangles":                           "Triángulos",
			"Quadrilaterals":                      "Cuadriláteros",
			"Polygons":                            "Polígonos",
			"Criteria for triangles":              "Criterios para triángulos",
			"Pythagoras' and Euclid's theorems":   "Teoremas de Pitágoras y de Euclides",
			"Circumference":                       "Circunferencia",
			"Area":                                "Área",
			"Tangents":                            "Tangentes",
			"Secants":                             "Secantes",
			"Prisms":                              "Prismas",
			"Pyramids":                            "Pirámides",
			"Cylinders":                           "Cilindros",
			"Cones":                               "Conos",
			"Spheres (Volume & Surface Area)":     "Esferas (volumen y área superficial)",
			"The Unit Circle":                     "El círculo unitario",
			"Sine, Cosine, Tangent":               "Seno, coseno, tangente",
			"Law of Sines/Cosines":                "Ley de senos/cosenos",
			// Pre-Calculus sections
			"Functions & Domain":        "Funciones y dominio",
			"Properties of Functions":   "Propiedades de las funciones",
			"Exponential & Logarithms":  "Exponenciales y logaritmos",
			"Analytic Geometry":         "Geometría analítica",
			// Pre-Calculus items
			"Real functions of a real variable":               "Funciones reales de variable real",
			"Classification":                                  "Clasificación",
			"Finding the domain":                              "Determinación del dominio",
			"Symmetries (Even/Odd)":                           "Simetrías (par/impar)",
			"Intercepts":                                      "Intersecciones con los ejes",
			"Sign study":                                      "Estudio del signo",
			"Equations and inequalities with eˣ and log(x)":   "Ecuaciones e inecuaciones con eˣ y log(x)",
			"The line":                                        "La recta",
			"The circle":                                      "La circunferencia",
			"The parabola":                                    "La parábola",
			"The ellipse":                                     "La elipse",
			"The hyperbola in the Cartesian plane":            "La hipérbola en el plano cartesiano",
			// Differential Calculus sections
			"Limits & Continuity":       "Límites y continuidad",
			"The Derivative Concept":    "El concepto de derivada",
			"Differentiation Rules":     "Reglas de derivación",
			"Function Study":            "Estudio de funciones",
			// Differential Calculus items
			"Finite and infinite limits":  "Límites finitos e infinitos",
			"Indeterminate forms":         "Formas indeterminadas",
			"Asymptotes":                  "Asíntotas",
			"Difference quotient":         "Cociente de diferencias",
			"Geometric meaning":           "Significado geométrico",
			"Power rule":                  "Regla de la potencia",
			"Product rule":                "Regla del producto",
			"Quotient rule":               "Regla del cociente",
			"Chain rule":                  "Regla de la cadena",
			"Maxima and Minima":           "Máximos y mínimos",
			"Points of inflection":        "Puntos de inflexión",
			// Integral Calculus sections
			"Indefinite Integrals":  "Integrales indefinidas",
			"Integration Methods":   "Métodos de integración",
			"Definite Integrals":    "Integrales definidas",
			"Applications":          "Aplicaciones",
			// Integral Calculus items
			"Primitive functions":                      "Funciones primitivas",
			"Immediate integration rules":              "Reglas de integración inmediata",
			"Integration by substitution":              "Integración por sustitución",
			"Integration by parts":                     "Integración por partes",
			"Calculating the area under a curve":       "Cálculo del área bajo una curva",
			"The Fundamental Theorem of Calculus":      "El teorema fundamental del cálculo",
			"Calculation of volumes":                   "Cálculo de volúmenes",
			"Areas of plane figures":                   "Áreas de figuras planas",
		}
	case "uz":
		return map[string]string{
			// Categories
			"Arithmetic & Number Systems": "Arifmetika va sonlar tizimlari",
			"Algebra":                     "Algebra",
			"Geometry & Trigonometry":      "Geometriya va trigonometriya",
			"Pre-Calculus & Analysis":      "Oldindan hisoblash va tahlil",
			"Differential Calculus":        "Differensial hisoblash",
			"Integral Calculus":            "Integral hisoblash",
			// Arithmetic sections
			"Sets of Numbers":                "Sonlar to'plamlari",
			"Fundamental Operations":         "Asosiy amallar",
			"Expressions & Order of Operations": "Ifodalar va amallar tartibi",
			"Divisibility & Prime Numbers":   "Bo'linish va tub sonlar",
			"Fractions & Ratios":             "Kasrlar va nisbatlar",
			// Arithmetic items
			"Natural numbers ℕ":                      "Natural sonlar ℕ",
			"Integers ℤ":                              "Butun sonlar ℤ",
			"Rational numbers ℚ":                      "Ratsional sonlar ℚ",
			"The four operations":                     "To'rtta amal",
			"Powers and their properties":             "Darajalar va ularning xossalari",
			"Roots":                                   "Ildizlar",
			"Use of parentheses and PEMDAS/BODMAS":    "Qavslardan foydalanish va PEMDAS/BODMAS",
			"Multiples":                               "Karralilar",
			"Divisors":                                "Bo'luvchilar",
			"GCD (Greatest Common Divisor)":           "EKUB (Eng Katta Umumiy Bo'luvchi)",
			"LCM (Least Common Multiple)":             "EKUK (Eng Kichik Umumiy Karrali)",
			"Equivalent fractions":                    "Teng kasrlar",
			"Operations with fractions":               "Kasrlar bilan amallar",
			"Percentages":                             "Foizlar",
			"Proportions":                             "Proportsiyalar",
			// Algebra sections
			"Monomials & Polynomials":       "Monomlar va polinomlar",
			"Factoring Polynomials":         "Polinomlarni ko'paytuvchilarga ajratish",
			"Linear Equations & Inequalities": "Chiziqli tenglamalar va tengsizliklar",
			"Quadratic Equations":           "Kvadrat tenglamalar",
			"Systems of Equations":          "Tenglamalar sistemasi",
			// Algebra items
			"Operations":                                    "Amallar",
			"Degree of a polynomial":                        "Polinom darajasi",
			"Special products (e.g. square of a binomial)":  "Maxsus ko'paytmalar (mas. binom kvadrati)",
			"Common factoring":                              "Umumiy ko'paytuvchiga ajratish",
			"Ruffini's Rule":                                "Ruffini qoidasi",
			"Difference of Squares":                         "Kvadratlar ayirmasi",
			"First-degree equations":                        "Birinchi darajali tenglamalar",
			"Literal equations":                             "Harfli tenglamalar",
			"Complete and incomplete quadratics":            "To'liq va to'liqsiz kvadrat tenglamalar",
			"The Discriminant (Δ)":                          "Diskriminant (Δ)",
			"Factoring quadratic trinomials":                "Kvadrat uchhadni ko'paytuvchilarga ajratish",
			"Substitution":                                  "O'rniga qo'yish",
			"Comparison":                                    "Taqqoslash",
			"Cramer's method":                               "Kramer usuli",
			// Geometry sections
			"Plane Geometry":            "Tekislik geometriyasi",
			"Congruence & Similarity":   "Kongruentlik va o'xshashlik",
			"Circle & Pi":               "Aylana va Pi",
			"Solid Geometry":            "Fazoviy geometriya",
			"Goniometry & Trigonometry": "Goniometriya va trigonometriya",
			// Geometry items
			"Segments":                            "Kesmalar",
			"Angles":                              "Burchaklar",
			"Triangles":                           "Uchburchaklar",
			"Quadrilaterals":                      "To'rtburchaklar",
			"Polygons":                            "Ko'pburchaklar",
			"Criteria for triangles":              "Uchburchaklar uchun mezonlar",
			"Pythagoras' and Euclid's theorems":   "Pifagor va Evklid teoremalari",
			"Circumference":                       "Aylana uzunligi",
			"Area":                                "Yuza",
			"Tangents":                            "Urinmalar",
			"Secants":                             "Kesuvchilar",
			"Prisms":                              "Prizmalar",
			"Pyramids":                            "Piramidalar",
			"Cylinders":                           "Silindrlar",
			"Cones":                               "Konuslar",
			"Spheres (Volume & Surface Area)":     "Sharlar (hajm va sirt yuzi)",
			"The Unit Circle":                     "Birlik aylana",
			"Sine, Cosine, Tangent":               "Sinus, kosinus, tangens",
			"Law of Sines/Cosines":                "Sinuslar/kosinuslar qonuni",
			// Pre-Calculus sections
			"Functions & Domain":        "Funksiyalar va aniqlanish sohasi",
			"Properties of Functions":   "Funksiyalar xossalari",
			"Exponential & Logarithms":  "Ko'rsatkichli va logarifmik",
			"Analytic Geometry":         "Analitik geometriya",
			// Pre-Calculus items
			"Real functions of a real variable":               "Haqiqiy o'zgaruvchining haqiqiy funksiyalari",
			"Classification":                                  "Tasniflash",
			"Finding the domain":                              "Aniqlanish sohasini topish",
			"Symmetries (Even/Odd)":                           "Simmetriyalar (juft/toq)",
			"Intercepts":                                      "O'qlar bilan kesishish",
			"Sign study":                                      "Ishorani o'rganish",
			"Equations and inequalities with eˣ and log(x)":   "eˣ va log(x) bilan tenglamalar va tengsizliklar",
			"The line":                                        "To'g'ri chiziq",
			"The circle":                                      "Aylana",
			"The parabola":                                    "Parabola",
			"The ellipse":                                     "Ellips",
			"The hyperbola in the Cartesian plane":            "Dekart tekisligida giperbola",
			// Differential Calculus sections
			"Limits & Continuity":       "Limitlar va uzluksizlik",
			"The Derivative Concept":    "Hosila tushunchasi",
			"Differentiation Rules":     "Differensiallash qoidalari",
			"Function Study":            "Funksiyani tadqiq qilish",
			// Differential Calculus items
			"Finite and infinite limits":  "Chekli va cheksiz limitlar",
			"Indeterminate forms":         "Aniqlanmagan shakllar",
			"Asymptotes":                  "Asimptotalar",
			"Difference quotient":         "Ayirma bo'linmasi",
			"Geometric meaning":           "Geometrik ma'no",
			"Power rule":                  "Daraja qoidasi",
			"Product rule":                "Ko'paytma qoidasi",
			"Quotient rule":               "Bo'linma qoidasi",
			"Chain rule":                  "Zanjir qoidasi",
			"Maxima and Minima":           "Maksimum va minimum",
			"Points of inflection":        "Burilish nuqtalari",
			// Integral Calculus sections
			"Indefinite Integrals":  "Aniqlanmagan integrallar",
			"Integration Methods":   "Integrallash usullari",
			"Definite Integrals":    "Aniq integrallar",
			"Applications":          "Qo'llanmalar",
			// Integral Calculus items
			"Primitive functions":                      "Boshlang'ich funksiyalar",
			"Immediate integration rules":              "Bevosita integrallash qoidalari",
			"Integration by substitution":              "O'rniga qo'yish usuli bilan integrallash",
			"Integration by parts":                     "Bo'laklab integrallash",
			"Calculating the area under a curve":       "Egri chiziq ostidagi yuzani hisoblash",
			"The Fundamental Theorem of Calculus":      "Hisoblashning asosiy teoremasi",
			"Calculation of volumes":                   "Hajmlarni hisoblash",
			"Areas of plane figures":                   "Tekis figuralar yuzalari",
		}
	default:
		return nil
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

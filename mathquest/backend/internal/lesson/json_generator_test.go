package lesson

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"testing"
)

func TestGenerateLessonJSONFiles(t *testing.T) {
	if os.Getenv("GENERATE_LESSON_JSON") != "1" {
		t.Skip("set GENERATE_LESSON_JSON=1 to generate lesson json files")
	}

	languages := []string{"en", "it", "fr", "es", "uz"}
	ids := sortedLessonIDs()
	if len(ids) == 0 {
		t.Fatal("no lessons found in lessonContentByID")
	}

	for _, lang := range languages {
		t.Logf("generating %s lessons json (%d entries)", lang, len(ids))
		lessons := make([]lessonJSONItem, 0, len(ids))

		for _, id := range ids {
			base, ok := lessonContentByID[id]
			if !ok {
				continue
			}

			title := base.Title
			category := base.Category
			intro := base.Intro

			if lang != "en" {
				tr := translationMap(lang)
				if v, ok := tr[title]; ok {
					title = v
				}
				if v, ok := tr[category]; ok {
					category = v
				}
				intro = localizeLessonIntro(id, base.Intro, lang)
			}

			intro = normalizeLessonIntro(intro)
			exercises := buildExercisesForLesson(id, title, category, intro, lang)
			lessons = append(lessons, lessonJSONItem{
				ID:        id,
				Title:     title,
				Category:  category,
				Intro:     intro,
				Exercises: exercises,
			})
		}

		bundle := lessonJSONBundle{
			Language: lang,
			Lessons:  lessons,
		}

		b, err := json.MarshalIndent(bundle, "", "  ")
		if err != nil {
			t.Fatalf("marshal %s json: %v", lang, err)
		}

		path := filepath.Join("data", lang+".json")
		if err := os.WriteFile(path, b, 0o644); err != nil {
			t.Fatalf("write %s: %v", path, err)
		}
	}
}

func sortedLessonIDs() []string {
	ids := make([]string, 0, len(lessonContentByID))
	for id := range lessonContentByID {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool {
		return compareLessonID(ids[i], ids[j]) < 0
	})
	return ids
}

func compareLessonID(a, b string) int {
	as, ai, aItem := parseSortableLessonID(a)
	bs, bi, bItem := parseSortableLessonID(b)

	if as != bs {
		if as < bs {
			return -1
		}
		return 1
	}

	if aItem != bItem {
		if !aItem {
			return -1
		}
		return 1
	}

	if ai != bi {
		if ai < bi {
			return -1
		}
		return 1
	}

	if a < b {
		return -1
	}
	if a > b {
		return 1
	}
	return 0
}

func parseSortableLessonID(id string) (section, item int, isItem bool) {
	section = 9999
	item = 9999
	if s, i, ok := parseItemID(id); ok {
		isItem = true
		section, _ = strconv.Atoi(s)
		item = i
		return
	}
	section, _ = strconv.Atoi(id)
	return
}

func buildExercisesForLesson(id, title, category, intro, lang string) []lessonJSONExercise {
	p := promptPackForLang(lang)
	first := firstSentence(intro)
	if first == "" {
		first = title
	}
	baseTitle := title
	baseCategory := category
	if base, ok := lessonContentByID[id]; ok {
		baseTitle = base.Title
		baseCategory = base.Category
	}

	goal := fmt.Sprintf(p.goalTemplate, title)

	var exercises []lessonJSONExercise
	seen := map[string]struct{}{}
	appendExercise := func(question string, options []string, correct string) {
		question = strings.TrimSpace(question)
		correct = strings.TrimSpace(correct)
		if question == "" || correct == "" {
			return
		}
		filteredOptions := make([]string, 0, len(options)+1)
		for _, option := range append([]string{correct}, options...) {
			option = strings.TrimSpace(option)
			if option == "" {
				continue
			}
			duplicate := false
			for _, existing := range filteredOptions {
				if existing == option {
					duplicate = true
					break
				}
			}
			if !duplicate {
				filteredOptions = append(filteredOptions, option)
			}
		}
		if len(filteredOptions) < 2 {
			return
		}
		key := question + "\n" + correct
		if _, ok := seen[key]; ok {
			return
		}
		seen[key] = struct{}{}
		exercises = append(exercises, lessonJSONExercise{
			ID:            fmt.Sprintf("%s-e%d", id, len(exercises)+1),
			Question:      question,
			Type:          "multiple_choice",
			Options:       filteredOptions,
			CorrectAnswer: correct,
			XPReward:      10,
		})
	}

	for _, template := range buildTopicPracticeTemplates(id, baseTitle, baseCategory, lang) {
		appendExercise(template.question, template.options, template.correct)
	}

	facts := extractLessonFacts(intro)
	if len(facts) == 0 {
		facts = []lessonExerciseFact{
			{text: first, isFormula: looksLikeExerciseFormula(first)},
			{text: goal, isFormula: false},
			{text: title, isFormula: false},
		}
	}
	factTexts := make([]string, 0, len(facts))
	for _, fact := range facts {
		factTexts = append(factTexts, fact.text)
	}
	for _, template := range buildDerivedPracticeTemplates(factTexts, lang) {
		appendExercise(template.question, template.options, template.correct)
	}

	return exercises
}

type lessonExerciseFact struct {
	text      string
	isFormula bool
}

var exerciseWhitespace = regexp.MustCompile(`\s+`)

func extractLessonFacts(intro string) []lessonExerciseFact {
	lines := strings.Split(normalizeLessonIntro(intro), "\n")
	seen := map[string]struct{}{}
	var facts []lessonExerciseFact

	for _, rawLine := range lines {
		line := strings.TrimSpace(rawLine)
		if line == "" || line == "[BOX]" || line == "[/BOX]" {
			continue
		}
		if (strings.HasPrefix(line, "[DIAGRAM:") || strings.HasPrefix(line, "[IMAGE:")) && strings.HasSuffix(line, "]") {
			continue
		}

		for _, fragment := range splitLessonExerciseFragments(line) {
			normalized := sanitizeExerciseFragment(fragment)
			if !isUsableExerciseFact(normalized) {
				continue
			}
			if _, ok := seen[normalized]; ok {
				continue
			}
			seen[normalized] = struct{}{}
			facts = append(facts, lessonExerciseFact{
				text:      normalized,
				isFormula: looksLikeExerciseFormula(normalized),
			})
		}
	}

	return facts
}

func splitLessonExerciseFragments(line string) []string {
	var out []string
	var current strings.Builder

	flush := func() {
		part := strings.TrimSpace(current.String())
		if part != "" {
			out = append(out, part)
		}
		current.Reset()
	}

	for i, r := range line {
		current.WriteRune(r)
		if r != '.' && r != '!' && r != '?' && r != ';' {
			continue
		}

		remaining := strings.TrimLeft(line[i+len(string(r)):], " ")
		if remaining == "" {
			flush()
			continue
		}
		if strings.HasSuffix(current.String(), "e.g.") || strings.HasSuffix(current.String(), "i.e.") {
			continue
		}
		first := rune(remaining[0])
		if r == ';' || first == '(' || first == '[' || strings.ToUpper(string(first)) == string(first) {
			flush()
		}
	}

	flush()
	return out
}

func sanitizeExerciseFragment(fragment string) string {
	fragment = strings.TrimSpace(strings.ReplaceAll(fragment, "**", ""))
	fragment = exerciseWhitespace.ReplaceAllString(fragment, " ")
	fragment = strings.Trim(fragment, " -•")
	if fragment == "" {
		return ""
	}
	if len(fragment) > 140 {
		fragment = strings.TrimSpace(fragment[:140]) + "..."
	}
	return fragment
}

func isUsableExerciseFact(fragment string) bool {
	if fragment == "" || len(fragment) < 18 {
		return false
	}
	if strings.HasSuffix(fragment, "e.g.") || strings.HasSuffix(fragment, "i.e.") {
		return false
	}
	if strings.Count(fragment, "(") != strings.Count(fragment, ")") {
		return false
	}
	return true
}

func looksLikeExerciseFormula(text string) bool {
	lower := strings.ToLower(text)
	return strings.ContainsAny(text, "=^√∫≤≥≠±∞") ||
		strings.Contains(lower, "lim") ||
		strings.Contains(lower, "sin") ||
		strings.Contains(lower, "cos") ||
		strings.Contains(lower, "tan") ||
		strings.Contains(lower, "log") ||
		strings.Contains(lower, "ln")
}

func buildExerciseOptions(correct string, wrongFacts []string, seed int) []string {
	options := []string{correct}
	for i := 0; len(options) < 4 && i < len(wrongFacts); i++ {
		candidate := wrongFacts[(seed+i)%len(wrongFacts)]
		if candidate == correct {
			continue
		}
		duplicate := false
		for _, existing := range options {
			if existing == candidate {
				duplicate = true
				break
			}
		}
		if !duplicate {
			options = append(options, candidate)
		}
	}
	return options
}

func firstSentence(intro string) string {
	s := strings.TrimSpace(intro)
	if s == "" {
		return ""
	}
	lines := strings.Split(s, "\n")
	filtered := make([]string, 0, len(lines))
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		if line == "[BOX]" || line == "[/BOX]" {
			continue
		}
		if (strings.HasPrefix(line, "[DIAGRAM:") || strings.HasPrefix(line, "[IMAGE:")) && strings.HasSuffix(line, "]") {
			continue
		}
		filtered = append(filtered, line)
	}
	if len(filtered) == 0 {
		return ""
	}

	text := normalizeLessonIntro(strings.Join(filtered, " "))
	text = strings.ReplaceAll(text, "**", "")
	if idx := strings.Index(text, ". "); idx > 0 {
		return strings.TrimSpace(text[:idx+1])
	}
	if len(text) > 160 {
		return strings.TrimSpace(text[:160]) + "..."
	}
	return strings.TrimSpace(text)
}

type exercisePromptPack struct {
	topicQuestion    string
	summaryQuestion  string
	goalQuestion     string
	categoryQuestion string
	factQuestion     string
	formulaQuestion  string
	goalTemplate     string
	summaryWrong1    string
	summaryWrong2    string
	summaryWrong3    string
	categoryWrong1   string
	categoryWrong2   string
	categoryWrong3   string
	wrongFacts       []string
}

func promptPackForLang(lang string) exercisePromptPack {
	switch normalizeLessonLang(lang) {
	case "it":
		return exercisePromptPack{
			topicQuestion:    "Qual è l'argomento principale di questa lezione?",
			summaryQuestion:  "Quale frase descrive meglio questa lezione?",
			goalQuestion:     "Qual è l'obiettivo principale di questa lezione?",
			categoryQuestion: "A quale categoria appartiene questa lezione?",
			factQuestion:     "Quale fatto compare davvero in questa lezione?",
			formulaQuestion:  "Quale formula o regola è presentata in questa lezione?",
			goalTemplate:     "Capire e applicare: %s",
			summaryWrong1:    "Questa lezione parla principalmente di storia generale.",
			summaryWrong2:    "Questa lezione riguarda principalmente biologia e chimica.",
			summaryWrong3:    "Questa lezione parla di geografia mondiale moderna.",
			categoryWrong1:   "Letteratura e linguistica",
			categoryWrong2:   "Scienze naturali",
			categoryWrong3:   "Storia contemporanea",
			wrongFacts: []string{
				"Questa lezione parla soprattutto di letteratura antica.",
				"Questa lezione descrive un fenomeno biologico.",
				"Questa lezione analizza eventi storici moderni.",
				"Questa lezione riguarda la geografia dei continenti.",
				"Questa lezione spiega regole grammaticali di una lingua.",
				"Questa lezione tratta argomenti di chimica sperimentale.",
			},
		}
	case "fr":
		return exercisePromptPack{
			topicQuestion:    "Quel est le sujet principal de cette leçon ?",
			summaryQuestion:  "Quelle phrase décrit le mieux cette leçon ?",
			goalQuestion:     "Quel est l'objectif principal de cette leçon ?",
			categoryQuestion: "À quelle catégorie appartient cette leçon ?",
			factQuestion:     "Quel fait apparaît vraiment dans cette leçon ?",
			formulaQuestion:  "Quelle formule ou règle est présentée dans cette leçon ?",
			goalTemplate:     "Comprendre et appliquer : %s",
			summaryWrong1:    "Cette leçon parle surtout d'histoire générale.",
			summaryWrong2:    "Cette leçon concerne surtout la biologie et la chimie.",
			summaryWrong3:    "Cette leçon traite de géographie mondiale moderne.",
			categoryWrong1:   "Littérature et linguistique",
			categoryWrong2:   "Sciences naturelles",
			categoryWrong3:   "Histoire contemporaine",
			wrongFacts: []string{
				"Cette leçon parle surtout de littérature ancienne.",
				"Cette leçon décrit un phénomène biologique.",
				"Cette leçon analyse des événements historiques modernes.",
				"Cette leçon concerne la géographie des continents.",
				"Cette leçon explique des règles grammaticales.",
				"Cette leçon traite de chimie expérimentale.",
			},
		}
	case "es":
		return exercisePromptPack{
			topicQuestion:    "¿Cuál es el tema principal de esta lección?",
			summaryQuestion:  "¿Qué frase describe mejor esta lección?",
			goalQuestion:     "¿Cuál es el objetivo principal de esta lección?",
			categoryQuestion: "¿A qué categoría pertenece esta lección?",
			factQuestion:     "¿Qué hecho aparece realmente en esta lección?",
			formulaQuestion:  "¿Qué fórmula o regla se presenta en esta lección?",
			goalTemplate:     "Comprender y aplicar: %s",
			summaryWrong1:    "Esta lección trata principalmente de historia general.",
			summaryWrong2:    "Esta lección trata principalmente de biología y química.",
			summaryWrong3:    "Esta lección trata de geografía mundial moderna.",
			categoryWrong1:   "Literatura y lingüística",
			categoryWrong2:   "Ciencias naturales",
			categoryWrong3:   "Historia contemporánea",
			wrongFacts: []string{
				"Esta lección trata sobre literatura antigua.",
				"Esta lección describe un fenómeno biológico.",
				"Esta lección analiza hechos históricos modernos.",
				"Esta lección trata la geografía de los continentes.",
				"Esta lección explica reglas gramaticales.",
				"Esta lección trata de química experimental.",
			},
		}
	case "uz":
		return exercisePromptPack{
			topicQuestion:    "Ushbu darsning asosiy mavzusi nima?",
			summaryQuestion:  "Qaysi gap ushbu darsni eng yaxshi ifodalaydi?",
			goalQuestion:     "Ushbu darsning asosiy maqsadi nima?",
			categoryQuestion: "Ushbu dars qaysi toifaga kiradi?",
			factQuestion:     "Quyidagilardan qaysi biri aynan shu darsda uchraydi?",
			formulaQuestion:  "Quyidagi qaysi formula yoki qoida shu darsda berilgan?",
			goalTemplate:     "Tushunish va qo'llash: %s",
			summaryWrong1:    "Bu dars asosan umumiy tarix haqida.",
			summaryWrong2:    "Bu dars asosan biologiya va kimyo haqida.",
			summaryWrong3:    "Bu dars zamonaviy dunyo geografiyasi haqida.",
			categoryWrong1:   "Adabiyot va tilshunoslik",
			categoryWrong2:   "Tabiiy fanlar",
			categoryWrong3:   "Zamonaviy tarix",
			wrongFacts: []string{
				"Bu dars qadimgi adabiyot haqida.",
				"Bu dars biologik hodisani tasvirlaydi.",
				"Bu dars zamonaviy tarixiy voqealarni tahlil qiladi.",
				"Bu dars qit'alar geografiyasini tushuntiradi.",
				"Bu dars grammatika qoidalarini bayon qiladi.",
				"Bu dars tajribaviy kimyo haqida.",
			},
		}
	default:
		return exercisePromptPack{
			topicQuestion:    "What is the main topic of this lesson?",
			summaryQuestion:  "Which sentence best describes this lesson?",
			goalQuestion:     "What is the main goal of this lesson?",
			categoryQuestion: "Which category does this lesson belong to?",
			factQuestion:     "Which fact really appears in this lesson?",
			formulaQuestion:  "Which formula or rule is presented in this lesson?",
			goalTemplate:     "Understand and apply: %s",
			summaryWrong1:    "This lesson is mainly about general world history.",
			summaryWrong2:    "This lesson is mainly about biology and chemistry.",
			summaryWrong3:    "This lesson is mainly about modern world geography.",
			categoryWrong1:   "Literature and linguistics",
			categoryWrong2:   "Natural sciences",
			categoryWrong3:   "Contemporary history",
			wrongFacts: []string{
				"This lesson is about ancient literature.",
				"This lesson describes a biological phenomenon.",
				"This lesson analyzes modern historical events.",
				"This lesson focuses on continental geography.",
				"This lesson explains grammar rules.",
				"This lesson covers experimental chemistry.",
			},
		}
	}
}

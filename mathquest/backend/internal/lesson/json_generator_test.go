package lesson

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
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

	goal := fmt.Sprintf(p.goalTemplate, title)
	summaryWrong1 := p.summaryWrong1
	summaryWrong2 := p.summaryWrong2
	summaryWrong3 := p.summaryWrong3

	categoryWrong1 := p.categoryWrong1
	categoryWrong2 := p.categoryWrong2
	categoryWrong3 := p.categoryWrong3

	return []lessonJSONExercise{
		{
			ID:            id + "-e1",
			Question:      p.topicQuestion,
			Type:          "multiple_choice",
			Options:       []string{title, summaryWrong1, summaryWrong2, summaryWrong3},
			CorrectAnswer: title,
			XPReward:      10,
		},
		{
			ID:            id + "-e2",
			Question:      p.summaryQuestion,
			Type:          "multiple_choice",
			Options:       []string{first, summaryWrong1, summaryWrong2, summaryWrong3},
			CorrectAnswer: first,
			XPReward:      10,
		},
		{
			ID:            id + "-e3",
			Question:      p.goalQuestion,
			Type:          "multiple_choice",
			Options:       []string{goal, categoryWrong1, categoryWrong2, categoryWrong3, category},
			CorrectAnswer: goal,
			XPReward:      10,
		},
		{
			ID:            id + "-e4",
			Question:      p.categoryQuestion,
			Type:          "multiple_choice",
			Options:       []string{category, categoryWrong1, categoryWrong2, categoryWrong3},
			CorrectAnswer: category,
			XPReward:      10,
		},
	}
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
		if strings.HasPrefix(line, "[DIAGRAM:") && strings.HasSuffix(line, "]") {
			continue
		}
		filtered = append(filtered, line)
	}
	if len(filtered) == 0 {
		return ""
	}

	text := strings.Join(filtered, " ")
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
	goalTemplate     string
	summaryWrong1    string
	summaryWrong2    string
	summaryWrong3    string
	categoryWrong1   string
	categoryWrong2   string
	categoryWrong3   string
}

func promptPackForLang(lang string) exercisePromptPack {
	switch normalizeLessonLang(lang) {
	case "it":
		return exercisePromptPack{
			topicQuestion:    "Qual è l'argomento principale di questa lezione?",
			summaryQuestion:  "Quale frase descrive meglio questa lezione?",
			goalQuestion:     "Qual è l'obiettivo principale di questa lezione?",
			categoryQuestion: "A quale categoria appartiene questa lezione?",
			goalTemplate:     "Capire e applicare: %s",
			summaryWrong1:    "Questa lezione parla principalmente di storia generale.",
			summaryWrong2:    "Questa lezione riguarda principalmente biologia e chimica.",
			summaryWrong3:    "Questa lezione parla di geografia mondiale moderna.",
			categoryWrong1:   "Letteratura e linguistica",
			categoryWrong2:   "Scienze naturali",
			categoryWrong3:   "Storia contemporanea",
		}
	case "fr":
		return exercisePromptPack{
			topicQuestion:    "Quel est le sujet principal de cette leçon ?",
			summaryQuestion:  "Quelle phrase décrit le mieux cette leçon ?",
			goalQuestion:     "Quel est l'objectif principal de cette leçon ?",
			categoryQuestion: "À quelle catégorie appartient cette leçon ?",
			goalTemplate:     "Comprendre et appliquer : %s",
			summaryWrong1:    "Cette leçon parle surtout d'histoire générale.",
			summaryWrong2:    "Cette leçon concerne surtout la biologie et la chimie.",
			summaryWrong3:    "Cette leçon traite de géographie mondiale moderne.",
			categoryWrong1:   "Littérature et linguistique",
			categoryWrong2:   "Sciences naturelles",
			categoryWrong3:   "Histoire contemporaine",
		}
	case "es":
		return exercisePromptPack{
			topicQuestion:    "¿Cuál es el tema principal de esta lección?",
			summaryQuestion:  "¿Qué frase describe mejor esta lección?",
			goalQuestion:     "¿Cuál es el objetivo principal de esta lección?",
			categoryQuestion: "¿A qué categoría pertenece esta lección?",
			goalTemplate:     "Comprender y aplicar: %s",
			summaryWrong1:    "Esta lección trata principalmente de historia general.",
			summaryWrong2:    "Esta lección trata principalmente de biología y química.",
			summaryWrong3:    "Esta lección trata de geografía mundial moderna.",
			categoryWrong1:   "Literatura y lingüística",
			categoryWrong2:   "Ciencias naturales",
			categoryWrong3:   "Historia contemporánea",
		}
	case "uz":
		return exercisePromptPack{
			topicQuestion:    "Ushbu darsning asosiy mavzusi nima?",
			summaryQuestion:  "Qaysi gap ushbu darsni eng yaxshi ifodalaydi?",
			goalQuestion:     "Ushbu darsning asosiy maqsadi nima?",
			categoryQuestion: "Ushbu dars qaysi toifaga kiradi?",
			goalTemplate:     "Tushunish va qo'llash: %s",
			summaryWrong1:    "Bu dars asosan umumiy tarix haqida.",
			summaryWrong2:    "Bu dars asosan biologiya va kimyo haqida.",
			summaryWrong3:    "Bu dars zamonaviy dunyo geografiyasi haqida.",
			categoryWrong1:   "Adabiyot va tilshunoslik",
			categoryWrong2:   "Tabiiy fanlar",
			categoryWrong3:   "Zamonaviy tarix",
		}
	default:
		return exercisePromptPack{
			topicQuestion:    "What is the main topic of this lesson?",
			summaryQuestion:  "Which sentence best describes this lesson?",
			goalQuestion:     "What is the main goal of this lesson?",
			categoryQuestion: "Which category does this lesson belong to?",
			goalTemplate:     "Understand and apply: %s",
			summaryWrong1:    "This lesson is mainly about general world history.",
			summaryWrong2:    "This lesson is mainly about biology and chemistry.",
			summaryWrong3:    "This lesson is mainly about modern world geography.",
			categoryWrong1:   "Literature and linguistics",
			categoryWrong2:   "Natural sciences",
			categoryWrong3:   "Contemporary history",
		}
	}
}

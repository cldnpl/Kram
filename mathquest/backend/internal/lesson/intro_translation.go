package lesson

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
)

var introTranslationCache sync.Map
var exerciseTranslationCache sync.Map

var introTranslatorHTTPClient = &http.Client{
	Timeout: 8 * time.Second,
}

func localizeLessonIntro(id, intro, lang string) string {
	normalizedLang := normalizeLessonLang(lang)
	if normalizedLang == "en" {
		return intro
	}

	trimmedIntro := strings.TrimSpace(intro)
	if trimmedIntro == "" {
		return intro
	}

	cacheKey := fmt.Sprintf("%s|%s|%d", normalizedLang, id, len(intro))
	if cached, ok := introTranslationCache.Load(cacheKey); ok {
		if translated, ok := cached.(string); ok && translated != "" {
			return translated
		}
	}

	translated := translateIntroStructured(trimmedIntro, normalizedLang)
	if strings.TrimSpace(translated) == "" {
		translated = intro
	}

	introTranslationCache.Store(cacheKey, translated)
	return translated
}

func localizeLessonExercises(id string, sourceExercises, fallbackExercises []lessonJSONExercise, lang string) []lessonJSONExercise {
	normalizedLang := normalizeLessonLang(lang)
	if normalizedLang == "en" || len(sourceExercises) == 0 {
		return sourceExercises
	}

	localized := make([]lessonJSONExercise, 0, len(sourceExercises))
	for exIdx, source := range sourceExercises {
		fallback := lessonJSONExercise{}
		if exIdx < len(fallbackExercises) {
			fallback = fallbackExercises[exIdx]
		}

		out := source
		out.Question = localizeExerciseField(id, source.ID, "q", source.Question, normalizedLang, fallback.Question)

		out.Options = make([]string, 0, len(source.Options))
		for optIdx, option := range source.Options {
			fallbackOpt := ""
			if optIdx < len(fallback.Options) {
				fallbackOpt = fallback.Options[optIdx]
			}
			out.Options = append(out.Options, localizeExerciseField(id, source.ID, fmt.Sprintf("o%d", optIdx), option, normalizedLang, fallbackOpt))
		}

		correctIndex := -1
		for i, option := range source.Options {
			if strings.TrimSpace(option) == strings.TrimSpace(source.CorrectAnswer) {
				correctIndex = i
				break
			}
		}
		if correctIndex >= 0 && correctIndex < len(out.Options) {
			out.CorrectAnswer = out.Options[correctIndex]
		} else {
			out.CorrectAnswer = localizeExerciseField(id, source.ID, "a", source.CorrectAnswer, normalizedLang, fallback.CorrectAnswer)
		}

		localized = append(localized, out)
	}

	return localized
}

func localizeExerciseField(lessonID, exerciseID, fieldID, text, lang, fallback string) string {
	trimmed := strings.TrimSpace(text)
	if trimmed == "" {
		return text
	}

	cacheKey := fmt.Sprintf("%s|%s|%s|%s|%d", lang, lessonID, exerciseID, fieldID, len(trimmed))
	if cached, ok := exerciseTranslationCache.Load(cacheKey); ok {
		if translated, ok := cached.(string); ok && strings.TrimSpace(translated) != "" {
			return translated
		}
	}

	translated, err := translateTextBlock(trimmed, lang)
	if err != nil || strings.TrimSpace(translated) == "" {
		if strings.TrimSpace(fallback) != "" {
			exerciseTranslationCache.Store(cacheKey, fallback)
			return fallback
		}
		exerciseTranslationCache.Store(cacheKey, text)
		return text
	}

	exerciseTranslationCache.Store(cacheKey, translated)
	return translated
}

func translateIntroStructured(intro, targetLang string) string {
	lines := strings.Split(intro, "\n")
	if len(lines) == 0 {
		return intro
	}

	var out []string
	var chunk []string

	flushChunk := func() {
		if len(chunk) == 0 {
			return
		}
		block := strings.Join(chunk, "\n")
		translated, err := translateTextBlock(block, targetLang)
		if err != nil || strings.TrimSpace(translated) == "" {
			out = append(out, chunk...)
		} else {
			out = append(out, strings.Split(translated, "\n")...)
		}
		chunk = chunk[:0]
	}

	for _, line := range lines {
		if shouldKeepLineAsIs(line) {
			flushChunk()
			out = append(out, line)
			continue
		}
		chunk = append(chunk, line)
	}

	flushChunk()
	return strings.Join(out, "\n")
}

func shouldKeepLineAsIs(line string) bool {
	trimmed := strings.TrimSpace(line)
	if trimmed == "" {
		return true
	}
	if trimmed == "[BOX]" || trimmed == "[/BOX]" {
		return true
	}
	if strings.HasPrefix(trimmed, "[DIAGRAM:") && strings.HasSuffix(trimmed, "]") {
		return true
	}
	if strings.HasPrefix(trimmed, "[IMAGE:") && strings.HasSuffix(trimmed, "]") {
		return true
	}
	return false
}

func translateTextBlock(text, targetLang string) (string, error) {
	if strings.TrimSpace(text) == "" {
		return text, nil
	}

	escapedText := url.QueryEscape(text)
	u := "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=" + targetLang + "&dt=t&q=" + escapedText

	req, err := http.NewRequest(http.MethodGet, u, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", "KramBackend/1.0")

	resp, err := introTranslatorHTTPClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("translator http status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	translated, err := parseGoogleTranslateResponse(body)
	if err != nil {
		return "", err
	}
	return translated, nil
}

func parseGoogleTranslateResponse(payload []byte) (string, error) {
	var raw any
	if err := json.Unmarshal(payload, &raw); err != nil {
		return "", err
	}

	top, ok := raw.([]any)
	if !ok || len(top) == 0 {
		return "", fmt.Errorf("invalid translator payload")
	}

	segments, ok := top[0].([]any)
	if !ok {
		return "", fmt.Errorf("invalid translator segments")
	}

	var b strings.Builder
	for _, seg := range segments {
		arr, ok := seg.([]any)
		if !ok || len(arr) == 0 {
			continue
		}
		part, ok := arr[0].(string)
		if !ok {
			continue
		}
		b.WriteString(part)
	}

	out := b.String()
	if strings.TrimSpace(out) == "" {
		return "", fmt.Errorf("empty translated output")
	}
	return out, nil
}

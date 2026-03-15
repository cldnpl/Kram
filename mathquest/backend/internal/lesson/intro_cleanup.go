package lesson

import (
	"regexp"
	"strings"
)

var (
	literalBoxStartPattern = regexp.MustCompile(`(?im)^\s*\(box\)\s*$`)
	literalBoxEndPattern   = regexp.MustCompile(`(?im)^\s*\((?:/box|box/)\)\s*$`)
	markerSpacingPattern   = regexp.MustCompile(`(?m)[ \t]*(\[(?:/?BOX|(?:IMAGE|DIAGRAM):[^\]]+)\])[ \t]*`)
	blankLinesPattern      = regexp.MustCompile(`\n{3,}`)
)

func normalizeLessonIntro(intro string) string {
	value := strings.ReplaceAll(intro, "\r\n", "\n")
	value = literalBoxStartPattern.ReplaceAllString(value, "[BOX]")
	value = literalBoxEndPattern.ReplaceAllString(value, "[/BOX]")
	value = normalizeLiteralNewlineTokens(value)
	value = markerSpacingPattern.ReplaceAllString(value, "\n$1\n")
	value = strings.ReplaceAll(value, "\n \n", "\n\n")
	value = blankLinesPattern.ReplaceAllString(value, "\n\n")
	return strings.TrimSpace(value)
}

func normalizeLiteralNewlineTokens(value string) string {
	lines := strings.Split(value, "\n")
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == `\n` || trimmed == "/n" {
			lines[i] = ""
		}
	}
	return strings.Join(lines, "\n")
}

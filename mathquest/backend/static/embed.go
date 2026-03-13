package static

import "embed"

//go:embed diagrams/*.svg
var Diagrams embed.FS

//go:embed imagesLessons/*.png imagesLessons/*.jpg imagesLessons/*.jpeg imagesLessons/*.svg imagesLessons/*.gif imagesLessons/*.webp imagesLessons/*.avif
var LessonImages embed.FS

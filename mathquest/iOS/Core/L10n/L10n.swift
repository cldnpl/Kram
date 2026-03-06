import Foundation

/// Lingua dell'app (impostata in Settings). Chiave: settings_language in UserDefaults.
enum L10n {
    private static let key = "settings_language"

    static var currentLanguage: String {
        UserDefaults.standard.string(forKey: key) ?? "en"
    }

    private static func string(_ key: String) -> String {
        let table: [String: [String: String]] = [
            "settings_title": [
                "it": "Impostazioni", "en": "Settings", "fr": "Paramètres",
                "es": "Ajustes", "uz": "Sozlamalar"
            ],
            "profile": [
                "it": "Profilo", "en": "Profile", "fr": "Profil",
                "es": "Perfil", "uz": "Profil"
            ],
            "name": [
                "it": "Nome", "en": "Name", "fr": "Nom",
                "es": "Nombre", "uz": "Ism"
            ],
            "study_preferences": [
                "it": "Preferenze di Studio", "en": "Study Preferences", "fr": "Préférences d'étude",
                "es": "Preferencias de estudio", "uz": "O'qish sozlamalari"
            ],
            "difficulty": [
                "it": "Difficoltà", "en": "Difficulty", "fr": "Difficulté",
                "es": "Dificultad", "uz": "Qiyinlik"
            ],
            "difficulty_easy": [
                "it": "Facile", "en": "Easy", "fr": "Facile",
                "es": "Fácil", "uz": "Oson"
            ],
            "difficulty_medium": [
                "it": "Medio", "en": "Medium", "fr": "Moyen",
                "es": "Medio", "uz": "O'rta"
            ],
            "difficulty_hard": [
                "it": "Difficile", "en": "Hard", "fr": "Difficile",
                "es": "Difícil", "uz": "Qiyin"
            ],
            "study_reminder": [
                "it": "Promemoria studio", "en": "Study reminders", "fr": "Rappels d'étude",
                "es": "Recordatorios de estudio", "uz": "O'qish eslatmalari"
            ],
            "sounds": [
                "it": "Suoni", "en": "Sounds", "fr": "Sons",
                "es": "Sonidos", "uz": "Ovozlar"
            ],
            "interface": [
                "it": "Interfaccia", "en": "Interface", "fr": "Interface",
                "es": "Interfaz", "uz": "Interfeys"
            ],
            "dark_theme": [
                "it": "Tema scuro", "en": "Dark theme", "fr": "Thème sombre",
                "es": "Tema oscuro", "uz": "Qorong'u mavzu"
            ],
            "account_language": [
                "it": "Account e lingua", "en": "Account & language", "fr": "Compte et langue",
                "es": "Cuenta e idioma", "uz": "Hisob va til"
            ],
            "language": [
                "it": "Lingua", "en": "Language", "fr": "Langue",
                "es": "Idioma", "uz": "Til"
            ],
            "language_italian": ["it": "Italiano", "en": "Italian", "fr": "Italien", "es": "Italiano", "uz": "Italyancha"],
            "language_english": ["it": "English", "en": "English", "fr": "Anglais", "es": "Inglés", "uz": "Inglizcha"],
            "language_french": ["it": "Francese", "en": "French", "fr": "Français", "es": "Francés", "uz": "Fransuzcha"],
            "language_spanish": ["it": "Spagnolo", "en": "Spanish", "fr": "Espagnol", "es": "Español", "uz": "Ispancha"],
            "language_uzbek": ["it": "Uzbeko", "en": "Uzbek", "fr": "Ouzbek", "es": "Uzbeko", "uz": "O'zbekcha"],
            "lessons": ["it": "Lezioni", "en": "Lessons", "fr": "Leçons", "es": "Lecciones", "uz": "Darslar"],
            "camera": ["it": "Camera", "en": "Camera", "fr": "Appareil photo", "es": "Cámara", "uz": "Kamera"],
            "profile_tab": ["it": "Profilo", "en": "Profile", "fr": "Profil", "es": "Perfil", "uz": "Profil"],
            "hi_there": ["it": "there", "en": "there", "fr": "toi", "es": "allí", "uz": "siz"],
            "loading": ["it": "Caricamento...", "en": "Loading...", "fr": "Chargement...", "es": "Cargando...", "uz": "Yuklanmoqda..."],
            "error": ["it": "Errore", "en": "Error", "fr": "Erreur", "es": "Error", "uz": "Xato"],
            "retry": ["it": "Riprova", "en": "Retry", "fr": "Réessayer", "es": "Reintentar", "uz": "Qayta urinish"],
            "sign_in_required": ["it": "Accesso richiesto", "en": "Sign in required", "fr": "Connexion requise", "es": "Inicio de sesión requerido", "uz": "Kirish talab qilinadi"],
            "sign_in_camera": ["it": "Accedi per usare la camera.", "en": "Sign in to use camera solving.", "fr": "Connectez-vous pour utiliser l'appareil photo.", "es": "Inicia sesión para usar la cámara.", "uz": "Kameradan foydalanish uchun kiring."],
            "sign_in": ["it": "Accedi", "en": "Sign In", "fr": "Se connecter", "es": "Iniciar sesión", "uz": "Kirish"],
            "sign_out": ["it": "Esci", "en": "Sign Out", "fr": "Déconnexion", "es": "Cerrar sesión", "uz": "Chiqish"],
            "not_now": ["it": "Non ora", "en": "Not now", "fr": "Plus tard", "es": "Ahora no", "uz": "Keyinroq"],
            "guest_lesson_message": ["it": "Gli ospiti possono aprire una lezione. Accedi per continuare con tutte.", "en": "Guests can open one lesson. Sign in to continue all lessons.", "fr": "Les invités peuvent ouvrir une leçon. Connectez-vous pour continuer.", "es": "Los invitados pueden abrir una lección. Inicia sesión para continuar.", "uz": "Mehmonlar bitta dars ochishi mumkin. Barcha darslar uchun kiring."],
            "lesson": ["it": "Lezione", "en": "Lesson", "fr": "Leçon", "es": "Lección", "uz": "Dars"],
            "lesson_cost_format": ["it": "Costo lezione: %d coin", "en": "Lesson cost: %d coins", "fr": "Coût de la leçon : %d pièces", "es": "Costo de la lección: %d monedas", "uz": "Dars narxi: %d tanga"],
            "plan_label": ["it": "Piano", "en": "Plan", "fr": "Forfait", "es": "Plan", "uz": "Reja"],
            "completion_reward_format": ["it": "Ricompensa completamento: fino a %d coin", "en": "Completion reward: up to %d coins", "fr": "Récompense : jusqu'à %d pièces", "es": "Recompensa al completar: hasta %d monedas", "uz": "Yakunlash mukofoti: %d tangagacha"],
            "completing": ["it": "Completamento...", "en": "Completing...", "fr": "En cours...", "es": "Completando...", "uz": "Yakunlanmoqda..."],
            "complete_lesson_format": ["it": "Completa lezione (+%d max)", "en": "Complete Lesson (+%d max)", "fr": "Terminer la leçon (+%d max)", "es": "Completar lección (+%d máx.)", "uz": "Darsni tugatish (+%d max)"],
            "content_not_available": ["it": "Contenuto non disponibile", "en": "Content not available", "fr": "Contenu indisponible", "es": "Contenido no disponible", "uz": "Mazmun mavjud emas"],
            "server_retry_message": ["it": "Assicurati che il server sia avviato e riprova.", "en": "Make sure the server is running and try again.", "fr": "Vérifiez que le serveur est démarré et réessayez.", "es": "Asegúrate de que el servidor esté en ejecución e inténtalo de nuevo.", "uz": "Server ishlayotganiga ishonch hosil qiling va qayta urinib ko'ring."],
            "ok": ["it": "OK", "en": "OK", "fr": "OK", "es": "OK", "uz": "OK"],
            "diagram_not_available": ["it": "Diagramma non disponibile", "en": "Diagram not available", "fr": "Diagramme non disponible", "es": "Diagrama no disponible", "uz": "Diagramma mavjud emas"],
            "dont_have_account": ["it": "Non hai un account?", "en": "Don't have an account?", "fr": "Pas encore de compte?", "es": "¿No tienes cuenta?", "uz": "Hisobingiz yo'qmi?"],
            "register": ["it": "Registrati", "en": "Register", "fr": "S'inscrire", "es": "Registrarse", "uz": "Ro'yxatdan o'tish"],
            "already_have_account": ["it": "Hai già un account?", "en": "Already have an account?", "fr": "Déjà un compte?", "es": "¿Ya tienes cuenta?", "uz": "Allaqachon hisobingiz bormi?"],
            "create_one": ["it": "Creane uno", "en": "Create one", "fr": "Créer un compte", "es": "Crear una", "uz": "Yaratish"],
            "login": ["it": "Accedi", "en": "Login", "fr": "Connexion", "es": "Iniciar sesión", "uz": "Kirish"],
        ]
        let lang = currentLanguage
        let dict = table[key] ?? [:]
        return dict[lang] ?? dict["en"] ?? dict["it"] ?? key
    }

    static var settingsTitle: String { string("settings_title") }
    static var profile: String { string("profile") }
    static var name: String { string("name") }
    static var studyPreferences: String { string("study_preferences") }
    static var difficulty: String { string("difficulty") }
    static var difficultyEasy: String { string("difficulty_easy") }
    static var difficultyMedium: String { string("difficulty_medium") }
    static var difficultyHard: String { string("difficulty_hard") }
    static var studyReminder: String { string("study_reminder") }
    static var sounds: String { string("sounds") }
    static var interface: String { string("interface") }
    static var darkTheme: String { string("dark_theme") }
    static var accountLanguage: String { string("account_language") }
    static var language: String { string("language") }
    static var languageItalian: String { string("language_italian") }
    static var languageEnglish: String { string("language_english") }
    static var languageFrench: String { string("language_french") }
    static var languageSpanish: String { string("language_spanish") }
    static var languageUzbek: String { string("language_uzbek") }
    static var lessons: String { string("lessons") }
    static var camera: String { string("camera") }
    static var profileTab: String { string("profile_tab") }
    static var hiThere: String { string("hi_there") }
    static var loading: String { string("loading") }
    static var error: String { string("error") }
    static var retry: String { string("retry") }
    static var signInRequired: String { string("sign_in_required") }
    static var signInCamera: String { string("sign_in_camera") }
    static var signIn: String { string("sign_in") }
    static var signOut: String { string("sign_out") }
    static var notNow: String { string("not_now") }
    static var guestLessonMessage: String { string("guest_lesson_message") }
    static var lesson: String { string("lesson") }
    static func lessonCost(_ n: Int) -> String { String(format: string("lesson_cost_format"), n) }
    static var planLabel: String { string("plan_label") }
    static func completionReward(_ n: Int) -> String { String(format: string("completion_reward_format"), n) }
    static var completing: String { string("completing") }
    static func completeLessonBtn(_ n: Int) -> String { String(format: string("complete_lesson_format"), n) }
    static var contentNotAvailable: String { string("content_not_available") }
    static var serverRetryMessage: String { string("server_retry_message") }
    static var ok: String { string("ok") }
    static var diagramNotAvailable: String { string("diagram_not_available") }
    static var dontHaveAccount: String { string("dont_have_account") }
    static var register: String { string("register") }
    static var alreadyHaveAccount: String { string("already_have_account") }
    static var createOne: String { string("create_one") }
    static var login: String { string("login") }
}

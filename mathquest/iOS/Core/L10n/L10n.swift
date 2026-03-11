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
            "age": [
                "it": "Età", "en": "Age", "fr": "Âge",
                "es": "Edad", "uz": "Yosh"
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
            "greeting_prefix": ["it": "Ciao", "en": "Hi", "fr": "Salut", "es": "Hola", "uz": "Salom"],
            "hi_there": ["it": "there", "en": "there", "fr": "toi", "es": "allí", "uz": "siz"],
            "loading": ["it": "Caricamento...", "en": "Loading...", "fr": "Chargement...", "es": "Cargando...", "uz": "Yuklanmoqda..."],
            "error": ["it": "Errore", "en": "Error", "fr": "Erreur", "es": "Error", "uz": "Xato"],
            "retry": ["it": "Riprova", "en": "Retry", "fr": "Réessayer", "es": "Reintentar", "uz": "Qayta urinish"],
            "sign_in_required": ["it": "Accesso richiesto", "en": "Sign in required", "fr": "Connexion requise", "es": "Inicio de sesión requerido", "uz": "Kirish talab qilinadi"],
            "sign_in_camera": ["it": "Accedi per usare la camera.", "en": "Sign in to use camera solving.", "fr": "Connectez-vous pour utiliser l'appareil photo.", "es": "Inicia sesión para usar la cámara.", "uz": "Kameradan foydalanish uchun kiring."],
            "sign_in": ["it": "Accedi", "en": "Sign In", "fr": "Se connecter", "es": "Iniciar sesión", "uz": "Kirish"],
            "sign_out": ["it": "Esci", "en": "Sign Out", "fr": "Déconnexion", "es": "Cerrar sesión", "uz": "Chiqish"],
            "not_now": ["it": "Non ora", "en": "Not now", "fr": "Plus tard", "es": "Ahora no", "uz": "Keyinroq"],
            "maybe_later": ["it": "Forse dopo", "en": "Maybe Later", "fr": "Peut-être plus tard", "es": "Quizás luego", "uz": "Keyinroq balki"],
            "login_prompt_title": ["it": "Accedi per più scansioni", "en": "Sign In for More Scans", "fr": "Connectez-vous pour plus de scans", "es": "Inicia sesión para más escaneos", "uz": "Ko'proq skan uchun kiring"],
            "login_prompt_subtitle": ["it": "Crea un account gratuito per sbloccare 3 scansioni al giorno e altre funzionalità.", "en": "Create a free account to unlock 3 scans per day and more features.", "fr": "Créez un compte gratuit pour débloquer 3 scans par jour et plus.", "es": "Crea una cuenta gratuita para desbloquear 3 escaneos al día y más.", "uz": "Kuniga 3 ta skan va boshqa imkoniyatlarni ochish uchun bepul hisob yarating."],
            "login_prompt_more_scans": ["it": "3 scansioni camera gratuite al giorno", "en": "3 free camera scans per day", "fr": "3 scans caméra gratuits par jour", "es": "3 escaneos de cámara gratis al día", "uz": "Kuniga 3 ta bepul kamera skani"],
            "login_prompt_history": ["it": "Salva e rivedi le soluzioni", "en": "Save and review your solutions", "fr": "Sauvegardez et révisez vos solutions", "es": "Guarda y revisa tus soluciones", "uz": "Yechimlarni saqlang va ko'rib chiqing"],
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
            "cancel": ["it": "Annulla", "en": "Cancel", "fr": "Annuler", "es": "Cancelar", "uz": "Bekor qilish"],
            "save": ["it": "Salva", "en": "Save", "fr": "Enregistrer", "es": "Guardar", "uz": "Saqlash"],
            "dont_have_account": ["it": "Non hai un account?", "en": "Don't have an account?", "fr": "Pas encore de compte?", "es": "¿No tienes cuenta?", "uz": "Hisobingiz yo'qmi?"],
            "register": ["it": "Registrati", "en": "Register", "fr": "S'inscrire", "es": "Registrarse", "uz": "Ro'yxatdan o'tish"],
            "already_have_account": ["it": "Hai già un account?", "en": "Already have an account?", "fr": "Déjà un compte?", "es": "¿Ya tienes cuenta?", "uz": "Allaqachon hisobingiz bormi?"],
            "create_one": ["it": "Creane uno", "en": "Create one", "fr": "Créer un compte", "es": "Crear una", "uz": "Yaratish"],
            "login": ["it": "Accedi", "en": "Login", "fr": "Connexion", "es": "Iniciar sesión", "uz": "Kirish"],
            "username_label": ["it": "Username", "en": "Username", "fr": "Nom d'utilisateur", "es": "Nombre de usuario", "uz": "Foydalanuvchi nomi"],
            "password_label": ["it": "Password", "en": "Password", "fr": "Mot de passe", "es": "Contraseña", "uz": "Parol"],
            "confirm_password": ["it": "Conferma password", "en": "Confirm password", "fr": "Confirmer le mot de passe", "es": "Confirmar contraseña", "uz": "Parolni tasdiqlang"],
            "insert_username": ["it": "Inserisci username", "en": "Insert username", "fr": "Entrez le nom d'utilisateur", "es": "Introduce el usuario", "uz": "Foydalanuvchi nomini kiriting"],
            "insert_password": ["it": "Inserisci password", "en": "Insert password", "fr": "Entrez le mot de passe", "es": "Introduce la contraseña", "uz": "Parolni kiriting"],
            "master_tagline": ["it": "Domina la matematica, un passo alla volta", "en": "Master math, one step at a time", "fr": "Maîtrisez les maths, étape par étape", "es": "Domina las matemáticas, paso a paso", "uz": "Matematikani bosqichma-bosqich egallang"],
            "continue_username": ["it": "Continua con username", "en": "Continue with username", "fr": "Continuer avec un nom d'utilisateur", "es": "Continuar con nombre de usuario", "uz": "Foydalanuvchi nomi bilan davom etish"],
            "continue_google": ["it": "Continua con Google", "en": "Continue with Google", "fr": "Continuer avec Google", "es": "Continuar con Google", "uz": "Google bilan davom etish"],
            "continue_guest": ["it": "Continua come ospite", "en": "Continue as guest", "fr": "Continuer en tant qu'invité", "es": "Continuar como invitado", "uz": "Mehmon sifatida davom etish"],
            "view_onboarding_again": ["it": "Rivedi onboarding", "en": "View onboarding again", "fr": "Revoir l'onboarding", "es": "Ver onboarding de nuevo", "uz": "Onboardingni qayta ko'rish"],
            "user_fallback": ["it": "Utente", "en": "User", "fr": "Utilisateur", "es": "Usuario", "uz": "Foydalanuvchi"],
            "day_streak": ["it": "Serie Giornaliera", "en": "Day Streak", "fr": "Série quotidienne", "es": "Racha diaria", "uz": "Kunlik seriya"],
            "help_support": ["it": "Aiuto e supporto", "en": "Help & Support", "fr": "Aide et support", "es": "Ayuda y soporte", "uz": "Yordam va qo'llab-quvvatlash"],
            "rate_app": ["it": "Valuta l'app", "en": "Rate the App", "fr": "Noter l'app", "es": "Califica la app", "uz": "Ilovani baholash"],
            "math_level": ["it": "Livello di matematica", "en": "Math Level", "fr": "Niveau de maths", "es": "Nivel de matemáticas", "uz": "Matematika darajasi"],
            "account": ["it": "Account", "en": "Account", "fr": "Compte", "es": "Cuenta", "uz": "Hisob"],
            "delete_account": ["it": "Elimina account", "en": "Delete Account", "fr": "Supprimer le compte", "es": "Eliminar cuenta", "uz": "Hisobni o'chirish"],
            "delete_account_message": ["it": "Questo eliminerà definitivamente il tuo account e tutti i dati. L'azione non può essere annullata.", "en": "This will permanently delete your account and all data. This action cannot be undone.", "fr": "Cela supprimera définitivement votre compte et toutes les données. Cette action est irréversible.", "es": "Esto eliminará permanentemente tu cuenta y todos los datos. Esta acción no se puede deshacer.", "uz": "Bu hisobingiz va barcha ma'lumotlarni butunlay o'chiradi. Bu amalni ortga qaytarib bo'lmaydi."],
            "store_unlock_title": ["it": "Sblocca tutto il tuo potenziale", "en": "Unlock Your Full Potential", "fr": "Libérez tout votre potentiel", "es": "Desbloquea todo tu potencial", "uz": "To'liq salohiyatingizni oching"],
            "store_unlock_subtitle": ["it": "Scegli il piano adatto ai tuoi obiettivi di studio", "en": "Choose the plan that fits your learning goals", "fr": "Choisissez le plan adapté à vos objectifs", "es": "Elige el plan que se adapta a tus objetivos", "uz": "Maqsadlaringizga mos rejani tanlang"],
            "store_whats_included": ["it": "Cosa include", "en": "What's included", "fr": "Ce qui est inclus", "es": "Qué incluye", "uz": "Nimalar kiritilgan"],
            "store_current_plan": ["it": "Piano attuale", "en": "Current Plan", "fr": "Plan actuel", "es": "Plan actual", "uz": "Joriy reja"],
            "store_switch_free": ["it": "Passa a Free", "en": "Switch to Free", "fr": "Passer à Free", "es": "Cambiar a Free", "uz": "Free rejaga o'tish"],
            "store_subscribe_format": ["it": "Abbonati a %@", "en": "Subscribe to %@", "fr": "S'abonner à %@", "es": "Suscribirse a %@", "uz": "%@ ga obuna bo'lish"],
            "store_restore": ["it": "Ripristina acquisti", "en": "Restore Purchases", "fr": "Restaurer les achats", "es": "Restaurar compras", "uz": "Xaridlarni tiklash"],
            "store_note": ["it": "Gli abbonamenti si rinnovano mensilmente. Annulla in qualsiasi momento in Impostazioni.", "en": "Subscriptions renew monthly. Cancel anytime in Settings.", "fr": "Les abonnements se renouvellent chaque mois. Annulez à tout moment dans Réglages.", "es": "Las suscripciones se renuevan mensualmente. Cancela cuando quieras en Ajustes.", "uz": "Obunalar har oy yangilanadi. Istalgan payt sozlamalarda bekor qilishingiz mumkin."],
            "store_badge_current": ["it": "ATTUALE", "en": "CURRENT", "fr": "ACTUEL", "es": "ACTUAL", "uz": "JORIY"],
            "store_badge_best": ["it": "MIGLIORE", "en": "BEST", "fr": "MEILLEUR", "es": "MEJOR", "uz": "ENG YAXSHI"],
            "store_per_month": ["it": "/mese", "en": "/month", "fr": "/mois", "es": "/mes", "uz": "/oy"],
            "store_feature_camera_scans": ["it": "Scansioni camera", "en": "Camera Scans", "fr": "Scans caméra", "es": "Escaneos de cámara", "uz": "Kamera skanlari"],
            "store_feature_lesson_rewards": ["it": "Ricompense lezioni", "en": "Lesson Rewards", "fr": "Récompenses des leçons", "es": "Recompensas de lecciones", "uz": "Dars mukofotlari"],
            "store_feature_lesson_refunds": ["it": "Rimborso lezioni", "en": "Lesson Refunds", "fr": "Remboursements des leçons", "es": "Reembolso de lecciones", "uz": "Dars qaytarimlari"],
            "store_value_5_day": ["it": "5/giorno", "en": "5/day", "fr": "5/jour", "es": "5/día", "uz": "5/kun"],
            "store_value_10_day": ["it": "10/giorno", "en": "10/day", "fr": "10/jour", "es": "10/día", "uz": "10/kun"],
            "store_value_unlimited": ["it": "Illimitate", "en": "Unlimited", "fr": "Illimité", "es": "Ilimitado", "uz": "Cheksiz"],
            "store_value_full": ["it": "Completo", "en": "Full", "fr": "Complet", "es": "Completo", "uz": "To'liq"],
            "store_free": ["it": "Gratis", "en": "Free", "fr": "Gratuit", "es": "Gratis", "uz": "Bepul"],
            "store_pro": ["it": "Pro", "en": "Pro", "fr": "Pro", "es": "Pro", "uz": "Pro"],
            "store_max": ["it": "Max", "en": "Max", "fr": "Max", "es": "Max", "uz": "Max"],
            "store_summary_free": ["it": "3 scansioni camera/giorno e ricompense standard", "en": "3 camera scans/day and standard lesson rewards", "fr": "3 scans caméra/jour et récompenses standard", "es": "3 escaneos de cámara/día y recompensas estándar", "uz": "Kuniga 3 ta kamera skani va standart mukofotlar"],
            "store_summary_pro": ["it": "10 scansioni camera/giorno e ricompense aumentate", "en": "10 camera scans/day and boosted lesson rewards", "fr": "10 scans caméra/jour et récompenses augmentées", "es": "10 escaneos de cámara/día y recompensas mejoradas", "uz": "Kuniga 10 ta kamera skani va oshirilgan mukofotlar"],
            "store_summary_max": ["it": "Scansioni camera illimitate e rimborso completo lezioni", "en": "Unlimited camera scans and full lesson refunds", "fr": "Scans caméra illimités et remboursement complet", "es": "Escaneos ilimitados y reembolso completo", "uz": "Cheksiz kamera skanlari va to'liq qaytarim"],
            "setup_profile_title": ["it": "Configura il tuo profilo", "en": "Set up your profile", "fr": "Configurez votre profil", "es": "Configura tu perfil", "uz": "Profilingizni sozlang"],
            "setup_profile_subtitle": ["it": "Dicci qualcosa su di te per personalizzare l'esperienza", "en": "Tell us a bit about yourself so we can personalize your learning experience", "fr": "Parlez-nous de vous pour personnaliser l'expérience", "es": "Cuéntanos sobre ti para personalizar tu experiencia", "uz": "Tajriba shaxsiylashishi uchun o'zingiz haqida ayting"],
            "your_name": ["it": "Il tuo nome", "en": "Your Name", "fr": "Votre nom", "es": "Tu nombre", "uz": "Ismingiz"],
            "enter_name": ["it": "Inserisci il tuo nome", "en": "Enter your name", "fr": "Entrez votre nom", "es": "Introduce tu nombre", "uz": "Ismingizni kiriting"],
            "choose_username": ["it": "Scegli uno username", "en": "Choose a username", "fr": "Choisissez un nom d'utilisateur", "es": "Elige un nombre de usuario", "uz": "Foydalanuvchi nomini tanlang"],
            "username_taken": ["it": "Username già in uso", "en": "Username is already taken", "fr": "Nom d'utilisateur déjà pris", "es": "El usuario ya está en uso", "uz": "Foydalanuvchi nomi band"],
            "continue": ["it": "Continua", "en": "Continue", "fr": "Continuer", "es": "Continuar", "uz": "Davom etish"],
            "skip": ["it": "Salta", "en": "Skip", "fr": "Passer", "es": "Saltar", "uz": "O'tkazib yuborish"],
            "next": ["it": "Avanti", "en": "Next", "fr": "Suivant", "es": "Siguiente", "uz": "Keyingi"],
            "get_started": ["it": "Inizia", "en": "Get Started", "fr": "Commencer", "es": "Comenzar", "uz": "Boshlash"],
            "onboarding_title_1": ["it": "Scansiona matematica in pochi secondi", "en": "Scan math in seconds", "fr": "Scannez les maths en quelques secondes", "es": "Escanea matemáticas en segundos", "uz": "Matematikani soniyalarda skan qiling"],
            "onboarding_subtitle_1": ["it": "Cattura equazioni con la camera e ottieni soluzioni guidate.", "en": "Capture equations with your camera and get guided solutions instantly.", "fr": "Capturez des équations avec la caméra et obtenez des solutions guidées.", "es": "Captura ecuaciones con tu cámara y obtén soluciones guiadas.", "uz": "Kamera bilan tenglamalarni tutib, yo'naltirilgan yechim oling."],
            "onboarding_title_2": ["it": "Impara passo dopo passo", "en": "Learn step by step", "fr": "Apprenez pas à pas", "es": "Aprende paso a paso", "uz": "Bosqichma-bosqich o'rganing"],
            "onboarding_subtitle_2": ["it": "Segui lezioni strutturate dal base all'avanzato.", "en": "Follow structured lessons from beginner concepts to advanced topics.", "fr": "Suivez des leçons structurées du débutant à l'avancé.", "es": "Sigue lecciones estructuradas de básico a avanzado.", "uz": "Boshlang'ichdan ilg'orgacha tuzilgan darslarni o'ting."],
            "onboarding_title_3": ["it": "Costruisci serie e progressi", "en": "Build streaks and progress", "fr": "Construisez des séries et progressez", "es": "Crea rachas y progreso", "uz": "Seriya yarating va o'sing"],
            "onboarding_subtitle_3": ["it": "Tieni traccia della costanza, completa lezioni e migliora ogni giorno.", "en": "Track consistency, complete lessons, and improve daily.", "fr": "Suivez votre régularité, terminez des leçons et progressez.", "es": "Sigue tu constancia, completa lecciones y mejora a diario.", "uz": "Doimiylikni kuzating, darslarni tugating va har kuni yaxshilang."],
            "sign_in_not_connected": ["it": "Accesso non ancora collegato. Usa Google o Apple per ora.", "en": "Sign in not yet connected. Use Google or Apple for now.", "fr": "Connexion non encore configurée. Utilisez Google ou Apple pour l'instant.", "es": "Inicio de sesión aún no conectado. Usa Google o Apple por ahora.", "uz": "Kirish hali ulanmagan. Hozircha Google yoki Apple dan foydalaning."],
            "register_not_connected": ["it": "Registrazione non ancora collegata. Usa Google o Apple per ora.", "en": "Registration not yet connected. Use Google or Apple for now.", "fr": "Inscription non encore configurée. Utilisez Google ou Apple pour l'instant.", "es": "Registro aún no conectado. Usa Google o Apple por ahora.", "uz": "Ro'yxatdan o'tish hali ulanmagan. Hozircha Google yoki Apple dan foydalaning."],
            "passwords_not_match": ["it": "Le password non corrispondono.", "en": "Passwords do not match.", "fr": "Les mots de passe ne correspondent pas.", "es": "Las contraseñas no coinciden.", "uz": "Parollar mos emas."],
            "lessons_completed": ["it": "Lezioni", "en": "Lessons", "fr": "Leçons", "es": "Lecciones", "uz": "Darslar"],
            "level_beginner": ["it": "Principiante", "en": "Beginner", "fr": "Débutant", "es": "Principiante", "uz": "Boshlang'ich"],
            "level_intermediate": ["it": "Intermedio", "en": "Intermediate", "fr": "Intermédiaire", "es": "Intermedio", "uz": "O'rta"],
            "level_advanced": ["it": "Avanzato", "en": "Advanced", "fr": "Avancé", "es": "Avanzado", "uz": "Yuqori"],
            "level_desc_beginner": ["it": "Aritmetica di base, frazioni, decimali", "en": "Basic arithmetic, fractions, decimals", "fr": "Arithmétique de base, fractions, décimales", "es": "Aritmética básica, fracciones, decimales", "uz": "Asosiy arifmetika, kasrlar, o'nliklar"],
            "level_desc_intermediate": ["it": "Algebra, geometria, equazioni di base", "en": "Algebra, geometry, basic equations", "fr": "Algèbre, géométrie, équations de base", "es": "Álgebra, geometría, ecuaciones básicas", "uz": "Algebra, geometriya, asosiy tenglamalar"],
            "level_desc_advanced": ["it": "Calcolo, trigonometria, algebra avanzata", "en": "Calculus, trigonometry, advanced algebra", "fr": "Calcul, trigonométrie, algèbre avancée", "es": "Cálculo, trigonometría, álgebra avanzada", "uz": "Hisoblash, trigonometriya, ilg'or algebra"],
            "community_title": ["it": "Community", "en": "Community", "fr": "Communauté", "es": "Comunidad", "uz": "Hamjamiyat"],
            "community_add_friend": ["it": "Aggiungi un amico", "en": "Add a friend", "fr": "Ajouter un ami", "es": "Agregar un amigo", "uz": "Do'st qo'shish"],
            "community_global_arena": ["it": "Arena globale", "en": "Global arena", "fr": "Arène mondiale", "es": "Arena global", "uz": "Global arena"],
            "community_challenge_friend": ["it": "Sfida un amico", "en": "Challenge a friend", "fr": "Défier un ami", "es": "Desafía a un amigo", "uz": "Do'stingizni chaqiring"],
            "community_pending_title": ["it": "In sospeso", "en": "Pending", "fr": "En attente", "es": "Pendiente", "uz": "Kutilmoqda"],
            "community_pending_status": ["it": "In sospeso", "en": "Pending", "fr": "En attente", "es": "Pendiente", "uz": "Kutilmoqda"],
            "community_pending_request_format": ["it": "Richiesta di amicizia a @%@ in sospeso.", "en": "Friend request to @%@ is pending.", "fr": "Demande d'ami à @%@ en attente.", "es": "La solicitud de amistad a @%@ está pendiente.", "uz": "@%@ ga do'stlik so'rovi kutilmoqda."],
            "history_title": ["it": "Cronologia", "en": "History", "fr": "Historique", "es": "Historial", "uz": "Tarix"],
            "done": ["it": "Fatto", "en": "Done", "fr": "Terminé", "es": "Hecho", "uz": "Bajarildi"],
            "history_example_header": ["it": "Esempio", "en": "Example", "fr": "Exemple", "es": "Ejemplo", "uz": "Namuna"],
            "history_empty_title": ["it": "Nessuna cronologia", "en": "No History Yet", "fr": "Pas encore d'historique", "es": "Sin historial aún", "uz": "Hali tarix yo'q"],
            "history_empty_subtitle": ["it": "I problemi risolti appariranno qui", "en": "Your solved math problems will appear here", "fr": "Vos problèmes résolus apparaîtront ici", "es": "Tus problemas resueltos aparecerán aquí", "uz": "Yechilgan masalalaringiz shu yerda ko'rinadi"],
            "problem": ["it": "Problema", "en": "Problem", "fr": "Problème", "es": "Problema", "uz": "Masala"],
            "solution_steps": ["it": "Passaggi della soluzione", "en": "Solution Steps", "fr": "Étapes de solution", "es": "Pasos de solución", "uz": "Yechim bosqichlari"],
            "solution": ["it": "Soluzione", "en": "Solution", "fr": "Solution", "es": "Solución", "uz": "Yechim"],
            "solved": ["it": "Risolto", "en": "Solved", "fr": "Résolu", "es": "Resuelto", "uz": "Yechildi"],
            "answer": ["it": "Risposta", "en": "Answer", "fr": "Réponse", "es": "Respuesta", "uz": "Javob"],
            "steps": ["it": "Passaggi", "en": "Steps", "fr": "Étapes", "es": "Pasos", "uz": "Bosqichlar"],
            "solving": ["it": "Risoluzione...", "en": "Solving...", "fr": "Résolution...", "es": "Resolviendo...", "uz": "Yechilmoqda..."],
            "camera_access_required": ["it": "Accesso fotocamera richiesto", "en": "Camera access required", "fr": "Accès caméra requis", "es": "Se requiere acceso a la cámara", "uz": "Kameraga ruxsat kerak"],
            "open_settings": ["it": "Apri impostazioni", "en": "Open Settings", "fr": "Ouvrir les réglages", "es": "Abrir ajustes", "uz": "Sozlamalarni ochish"],
            "try_again": ["it": "Riprova", "en": "Try Again", "fr": "Réessayer", "es": "Intentar de nuevo", "uz": "Qayta urinib ko'ring"],
            "camera_unlimited": ["it": "Catture illimitate disponibili oggi", "en": "Unlimited captures available today", "fr": "Captures illimitées disponibles aujourd'hui", "es": "Capturas ilimitadas disponibles hoy", "uz": "Bugun cheksiz suratga olish mavjud"],
            "camera_uses_remaining_format": ["it": "%d di %d utilizzi disponibili oggi", "en": "%d of %d uses remaining today", "fr": "%d sur %d utilisations restantes aujourd'hui", "es": "%d de %d usos restantes hoy", "uz": "Bugun %d tadan %d tasi qoldi"],
            "gallery": ["it": "Galleria", "en": "Gallery", "fr": "Galerie", "es": "Galería", "uz": "Galereya"],
            "camera_permission_title": ["it": "Usa la fotocamera per la scansione matematica", "en": "Use Camera for Math Scanning", "fr": "Utilisez la caméra pour scanner les maths", "es": "Usa la cámara para escanear matemáticas", "uz": "Matematikani skan qilish uchun kameradan foydalaning"],
            "camera_permission_subtitle": ["it": "Consenti l'accesso alla fotocamera per scansionare problemi e rilevare testo in tempo reale.", "en": "Allow camera access so Kram can scan problems and also detect text live while you point the camera.", "fr": "Autorisez la caméra pour scanner des problèmes et détecter du texte en direct.", "es": "Permite el acceso a la cámara para escanear problemas y detectar texto en vivo.", "uz": "Masalalarni skan qilish va matnni jonli aniqlash uchun kameraga ruxsat bering."],
            "camera_permission_capture_label": ["it": "Cattura problemi scritti a mano o stampati", "en": "Capture handwritten or printed math problems", "fr": "Capturez des problèmes manuscrits ou imprimés", "es": "Captura problemas matemáticos escritos o impresos", "uz": "Qo'lda yoki bosma matematik masalalarni suratga oling"],
            "camera_permission_preview_label": ["it": "Anteprima del testo riconosciuto prima della foto", "en": "Preview recognized text before taking a photo", "fr": "Prévisualisez le texte reconnu avant la photo", "es": "Vista previa del texto reconocido antes de la foto", "uz": "Rasmga olishdan oldin aniqlangan matnni ko'ring"],
            "crop": ["it": "Ritaglia", "en": "Crop", "fr": "Recadrer", "es": "Recortar", "uz": "Kesish"],
            "drag_move_crop": ["it": "Trascina per spostare il ritaglio. Pizzica per ridimensionare.", "en": "Drag to move crop. Pinch to resize.", "fr": "Faites glisser pour déplacer le cadre. Pincez pour redimensionner.", "es": "Arrastra para mover el recorte. Pellizca para cambiar tamaño.", "uz": "Kesmani ko'chirish uchun torting. O'lchamni o'zgartirish uchun chimchilang."],
            "use_crop": ["it": "Usa ritaglio", "en": "Use Crop", "fr": "Utiliser le recadrage", "es": "Usar recorte", "uz": "Kesmani ishlatish"],
            "failed_load_image": ["it": "Impossibile caricare l'immagine selezionata", "en": "Failed to load selected image", "fr": "Impossible de charger l'image sélectionnée", "es": "No se pudo cargar la imagen seleccionada", "uz": "Tanlangan rasmni yuklab bo'lmadi"],
            "solution_language_title": ["it": "Scegli la lingua della spiegazione", "en": "Choose explanation language", "fr": "Choisissez la langue de l'explication", "es": "Elige el idioma de la explicación", "uz": "Tushuntirish tilini tanlang"],
            "solution_language_subtitle_format": ["it": "Questo problema sembra essere in %@. In quale lingua vuoi la spiegazione?", "en": "This problem appears to be in %@. Which language should I use for the explanation?", "fr": "Ce problème semble être en %@. Quelle langue dois-je utiliser pour l'explication ?", "es": "Este problema parece estar en %@. ¿Qué idioma debo usar para la explicación?", "uz": "Bu masala %@ tilida ko'rinadi. Tushuntirish uchun qaysi tildan foydalanay?"],
            "solution_language_problem_label": ["it": "Lingua del problema", "en": "Problem language", "fr": "Langue du problème", "es": "Idioma del problema", "uz": "Masala tili"],
            "solution_language_app_label": ["it": "Lingua dell'app", "en": "App language", "fr": "Langue de l'app", "es": "Idioma de la app", "uz": "Ilova tili"],
            "difficulty_elementary": ["it": "Elementare", "en": "Elementary", "fr": "Élémentaire", "es": "Elemental", "uz": "Boshlang'ich"],
            "difficulty_middle_school": ["it": "Scuola media", "en": "Middle School", "fr": "Collège", "es": "Secundaria", "uz": "O'rta maktab"],
            "difficulty_high_school": ["it": "Scuola superiore", "en": "High School", "fr": "Lycée", "es": "Bachillerato", "uz": "Yuqori sinf"],
            "difficulty_college": ["it": "Università", "en": "College", "fr": "Université", "es": "Universidad", "uz": "Universitet"],
            "streak_title": ["it": "Serie", "en": "Streak", "fr": "Série", "es": "Racha", "uz": "Seriya"],
            "active_today": ["it": "Attivo oggi", "en": "Active today", "fr": "Actif aujourd'hui", "es": "Activo hoy", "uz": "Bugun faol"],
            "not_active_today": ["it": "Non ancora attivo oggi", "en": "Not active yet today", "fr": "Pas encore actif aujourd'hui", "es": "Aún no activo hoy", "uz": "Bugun hali faol emas"],
            "this_month": ["it": "Questo mese", "en": "This Month", "fr": "Ce mois-ci", "es": "Este mes", "uz": "Bu oy"],
            "active_days": ["it": "giorni attivi", "en": "active days", "fr": "jours actifs", "es": "días activos", "uz": "faol kunlar"],
            "best_streak": ["it": "Miglior serie", "en": "Best Streak", "fr": "Meilleure série", "es": "Mejor racha", "uz": "Eng yaxshi seriya"],
            "days": ["it": "giorni", "en": "days", "fr": "jours", "es": "días", "uz": "kun"],
            "test_dynamic_island": ["it": "Test Dynamic Island", "en": "Test Dynamic Island", "fr": "Tester Dynamic Island", "es": "Probar Dynamic Island", "uz": "Dynamic Island testi"],
            "stop_live_activity": ["it": "Ferma Live Activity", "en": "Stop Live Activity", "fr": "Arrêter l'activité live", "es": "Detener actividad en vivo", "uz": "Live Activity ni to'xtatish"],
            "rewards_title": ["it": "Task e ricompense", "en": "Tasks and rewards", "fr": "Tâches et récompenses", "es": "Tareas y recompensas", "uz": "Vazifalar va mukofotlar"],
            "rewards_nav_title": ["it": "Ricompense", "en": "Rewards", "fr": "Récompenses", "es": "Recompensas", "uz": "Mukofotlar"],

            // MARK: - Solve Review Sheet
            "review_title": ["it": "Com'è stata l'esperienza?", "en": "How was your experience?", "fr": "Comment était votre expérience ?", "es": "¿Cómo fue tu experiencia?", "uz": "Tajribangiz qanday bo'ldi?"],
            "review_thanks": ["it": "Grazie per il tuo feedback!", "en": "Thanks for your feedback!", "fr": "Merci pour votre avis !", "es": "¡Gracias por tu opinión!", "uz": "Fikr-mulohazangiz uchun rahmat!"],
            "review_what_liked": ["it": "Cosa ti è piaciuto di più?", "en": "What did you like most?", "fr": "Qu'avez-vous le plus aimé ?", "es": "¿Qué te gustó más?", "uz": "Sizga nima ko'proq yoqdi?"],
            "review_what_wrong": ["it": "Cosa è andato storto?", "en": "What went wrong?", "fr": "Qu'est-ce qui n'a pas fonctionné ?", "es": "¿Qué salió mal?", "uz": "Nima noto'g'ri bo'ldi?"],
            "review_what_better": ["it": "Cosa potrebbe migliorare?", "en": "What could be better?", "fr": "Que pourrait-on améliorer ?", "es": "¿Qué podría mejorar?", "uz": "Nimani yaxshilash mumkin?"],
            // 5-star categories
            "review_cat_capturing": ["it": "Cattura (riconoscimento camera)", "en": "Capturing (camera recognition)", "fr": "Capture (reconnaissance caméra)", "es": "Captura (reconocimiento de cámara)", "uz": "Suratga olish (kamera aniqlash)"],
            "review_cat_solution_accuracy": ["it": "Accuratezza della soluzione", "en": "Solution accuracy", "fr": "Précision de la solution", "es": "Precisión de la solución", "uz": "Yechim aniqligi"],
            "review_cat_step_by_step": ["it": "Spiegazione passo passo", "en": "Step-by-step explanation", "fr": "Explication étape par étape", "es": "Explicación paso a paso", "uz": "Bosqichma-bosqich tushuntirish"],
            "review_cat_speed": ["it": "Velocità", "en": "Speed", "fr": "Vitesse", "es": "Velocidad", "uz": "Tezlik"],
            // 1-2 star categories
            "review_cat_camera_failed": ["it": "La camera non ha catturato bene", "en": "Camera didn't capture correctly", "fr": "La caméra n'a pas bien capturé", "es": "La cámara no capturó bien", "uz": "Kamera to'g'ri suratga olmadi"],
            "review_cat_wrong_solution": ["it": "Soluzione/risposta sbagliata", "en": "Wrong solution/answer", "fr": "Mauvaise solution/réponse", "es": "Solución/respuesta incorrecta", "uz": "Noto'g'ri yechim/javob"],
            "review_cat_unclear_steps": ["it": "I passaggi non erano chiari", "en": "Steps were unclear", "fr": "Les étapes n'étaient pas claires", "es": "Los pasos no estaban claros", "uz": "Bosqichlar tushunarsiz edi"],
            "review_cat_slow_buggy": ["it": "App lenta/con bug", "en": "App was slow/buggy", "fr": "L'app était lente/buguée", "es": "La app fue lenta/con errores", "uz": "Ilova sekin/xatoli edi"],
            // 3-4 star categories
            "review_cat_camera_accuracy": ["it": "Precisione della camera", "en": "Camera accuracy", "fr": "Précision de la caméra", "es": "Precisión de la cámara", "uz": "Kamera aniqligi"],
            "review_cat_solution_quality": ["it": "Qualità della soluzione", "en": "Solution quality", "fr": "Qualité de la solution", "es": "Calidad de la solución", "uz": "Yechim sifati"],
            "review_cat_explanation_clarity": ["it": "Chiarezza della spiegazione", "en": "Explanation clarity", "fr": "Clarté de l'explication", "es": "Claridad de la explicación", "uz": "Tushuntirish ravshanlighi"],
            "review_cat_speed_mid": ["it": "Velocità", "en": "Speed", "fr": "Vitesse", "es": "Velocidad", "uz": "Tezlik"],
            // 5-star details
            "review_detail_recognized_perfect": ["it": "Ha riconosciuto la scrittura perfettamente", "en": "Recognized handwriting perfectly", "fr": "A reconnu l'écriture parfaitement", "es": "Reconoció la escritura perfectamente", "uz": "Qo'lyozmani mukammal aniqladi"],
            "review_detail_fast_accurate": ["it": "Veloce e preciso", "en": "Fast and accurate", "fr": "Rapide et précis", "es": "Rápido y preciso", "uz": "Tez va aniq"],
            "review_detail_completely_correct": ["it": "Completamente corretto", "en": "Completely correct", "fr": "Totalement correct", "es": "Completamente correcto", "uz": "To'liq to'g'ri"],
            "review_detail_great_format": ["it": "Ottimo formato di spiegazione", "en": "Great explanation format", "fr": "Excellent format d'explication", "es": "Excelente formato de explicación", "uz": "Ajoyib tushuntirish formati"],
            "review_detail_easy_follow": ["it": "Facile da seguire", "en": "Easy to follow", "fr": "Facile à suivre", "es": "Fácil de seguir", "uz": "Kuzatish oson"],
            "review_detail_learned_new": ["it": "Ho imparato qualcosa di nuovo", "en": "Learned something new", "fr": "J'ai appris quelque chose de nouveau", "es": "Aprendí algo nuevo", "uz": "Yangi narsa o'rgandim"],
            "review_detail_lightning_fast": ["it": "Velocissimo", "en": "Lightning fast", "fr": "Ultra rapide", "es": "Rapidísimo", "uz": "Chaqmoqdek tez"],
            "review_detail_no_waiting": ["it": "Nessuna attesa", "en": "No waiting", "fr": "Aucune attente", "es": "Sin espera", "uz": "Kutish yo'q"],
            // 1-2 star details
            "review_detail_no_recognize": ["it": "Non ha riconosciuto la mia scrittura", "en": "Didn't recognize my writing", "fr": "N'a pas reconnu mon écriture", "es": "No reconoció mi escritura", "uz": "Yozuvimni aniqlamadi"],
            "review_detail_wrong_area": ["it": "Ha catturato l'area sbagliata", "en": "Captured wrong area", "fr": "A capturé la mauvaise zone", "es": "Capturó el área equivocada", "uz": "Noto'g'ri joyni suratga oldi"],
            "review_detail_took_long": ["it": "Ci ha messo troppo", "en": "Took too long", "fr": "A pris trop de temps", "es": "Tardó demasiado", "uz": "Juda uzoq vaqt oldi"],
            "review_detail_answer_wrong": ["it": "La risposta era sbagliata", "en": "Answer was wrong", "fr": "La réponse était fausse", "es": "La respuesta fue incorrecta", "uz": "Javob noto'g'ri edi"],
            "review_detail_missing_steps": ["it": "Passaggi mancanti", "en": "Missing steps", "fr": "Étapes manquantes", "es": "Faltan pasos", "uz": "Bosqichlar yetishmayapti"],
            "review_detail_incorrect_method": ["it": "Metodo non corretto", "en": "Incorrect method", "fr": "Méthode incorrecte", "es": "Método incorrecto", "uz": "Noto'g'ri usul"],
            "review_detail_steps_confusing": ["it": "I passaggi erano confusi", "en": "Steps were confusing", "fr": "Les étapes étaient confuses", "es": "Los pasos eran confusos", "uz": "Bosqichlar chalkash edi"],
            "review_detail_skipped_steps": ["it": "Ha saltato passaggi importanti", "en": "Skipped important steps", "fr": "A sauté des étapes importantes", "es": "Saltó pasos importantes", "uz": "Muhim bosqichlar tashlab ketildi"],
            "review_detail_too_slow": ["it": "Troppo lento", "en": "Too slow", "fr": "Trop lent", "es": "Demasiado lento", "uz": "Juda sekin"],
            "review_detail_got_stuck": ["it": "Si è bloccato nell'elaborazione", "en": "Got stuck processing", "fr": "Bloqué lors du traitement", "es": "Se quedó procesando", "uz": "Qayta ishlashda qotib qoldi"],
        ]
        let lang = currentLanguage
        let dict = table[key] ?? [:]
        return dict[lang] ?? dict["en"] ?? dict["it"] ?? key
    }

    static var settingsTitle: String { string("settings_title") }
    static var profile: String { string("profile") }
    static var name: String { string("name") }
    static var age: String { string("age") }
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
    static var greetingPrefix: String { string("greeting_prefix") }
    static var hiThere: String { string("hi_there") }
    static var loading: String { string("loading") }
    static var error: String { string("error") }
    static var retry: String { string("retry") }
    static var signInRequired: String { string("sign_in_required") }
    static var signInCamera: String { string("sign_in_camera") }
    static var signIn: String { string("sign_in") }
    static var signOut: String { string("sign_out") }
    static var notNow: String { string("not_now") }
    static var maybeLater: String { string("maybe_later") }
    static var loginPromptTitle: String { string("login_prompt_title") }
    static var loginPromptSubtitle: String { string("login_prompt_subtitle") }
    static var loginPromptMoreScans: String { string("login_prompt_more_scans") }
    static var loginPromptHistory: String { string("login_prompt_history") }
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
    static var cancel: String { string("cancel") }
    static var save: String { string("save") }
    static var dontHaveAccount: String { string("dont_have_account") }
    static var register: String { string("register") }
    static var alreadyHaveAccount: String { string("already_have_account") }
    static var createOne: String { string("create_one") }
    static var login: String { string("login") }
    static var usernameLabel: String { string("username_label") }
    static var passwordLabel: String { string("password_label") }
    static var confirmPassword: String { string("confirm_password") }
    static var insertUsername: String { string("insert_username") }
    static var insertPassword: String { string("insert_password") }
    static var masterTagline: String { string("master_tagline") }
    static var continueUsername: String { string("continue_username") }
    static var continueGoogle: String { string("continue_google") }
    static var continueGuest: String { string("continue_guest") }
    static var viewOnboardingAgain: String { string("view_onboarding_again") }
    static var userFallback: String { string("user_fallback") }
    static var dayStreak: String { string("day_streak") }
    static var helpSupport: String { string("help_support") }
    static var rateApp: String { string("rate_app") }
    static var mathLevel: String { string("math_level") }
    static var account: String { string("account") }
    static var deleteAccount: String { string("delete_account") }
    static var deleteAccountMessage: String { string("delete_account_message") }
    static var storeUnlockTitle: String { string("store_unlock_title") }
    static var storeUnlockSubtitle: String { string("store_unlock_subtitle") }
    static var storeWhatsIncluded: String { string("store_whats_included") }
    static var storeCurrentPlan: String { string("store_current_plan") }
    static var storeSwitchFree: String { string("store_switch_free") }
    static func storeSubscribeTo(_ plan: String) -> String { String(format: string("store_subscribe_format"), plan) }
    static var storeRestorePurchases: String { string("store_restore") }
    static var storeRenewNote: String { string("store_note") }
    static var storeBadgeCurrent: String { string("store_badge_current") }
    static var storeBadgeBest: String { string("store_badge_best") }
    static var storePerMonth: String { string("store_per_month") }
    static var storeFeatureCameraScans: String { string("store_feature_camera_scans") }
    static var storeFeatureLessonRewards: String { string("store_feature_lesson_rewards") }
    static var storeFeatureLessonRefunds: String { string("store_feature_lesson_refunds") }
    static var storeValue5Day: String { string("store_value_5_day") }
    static var storeValue10Day: String { string("store_value_10_day") }
    static var storeValueUnlimited: String { string("store_value_unlimited") }
    static var storeValueFull: String { string("store_value_full") }
    static var storeFree: String { string("store_free") }
    static var storePro: String { string("store_pro") }
    static var storeMax: String { string("store_max") }
    static var storeSummaryFree: String { string("store_summary_free") }
    static var storeSummaryPro: String { string("store_summary_pro") }
    static var storeSummaryMax: String { string("store_summary_max") }
    static var setupProfileTitle: String { string("setup_profile_title") }
    static var setupProfileSubtitle: String { string("setup_profile_subtitle") }
    static var yourName: String { string("your_name") }
    static var enterName: String { string("enter_name") }
    static var chooseUsername: String { string("choose_username") }
    static var usernameTaken: String { string("username_taken") }
    static var `continue`: String { string("continue") }
    static var skip: String { string("skip") }
    static var next: String { string("next") }
    static var getStarted: String { string("get_started") }
    static var onboardingTitle1: String { string("onboarding_title_1") }
    static var onboardingSubtitle1: String { string("onboarding_subtitle_1") }
    static var onboardingTitle2: String { string("onboarding_title_2") }
    static var onboardingSubtitle2: String { string("onboarding_subtitle_2") }
    static var onboardingTitle3: String { string("onboarding_title_3") }
    static var onboardingSubtitle3: String { string("onboarding_subtitle_3") }
    static var signInNotConnected: String { string("sign_in_not_connected") }
    static var registerNotConnected: String { string("register_not_connected") }
    static var passwordsNotMatch: String { string("passwords_not_match") }
    static var lessonsCompleted: String { string("lessons_completed") }
    static var levelBeginner: String { string("level_beginner") }
    static var levelIntermediate: String { string("level_intermediate") }
    static var levelAdvanced: String { string("level_advanced") }
    static var levelDescBeginner: String { string("level_desc_beginner") }
    static var levelDescIntermediate: String { string("level_desc_intermediate") }
    static var levelDescAdvanced: String { string("level_desc_advanced") }
    static var communityTitle: String { string("community_title") }
    static var communityAddFriend: String { string("community_add_friend") }
    static var communityGlobalArena: String { string("community_global_arena") }
    static var communityChallengeFriend: String { string("community_challenge_friend") }
    static var communityPendingTitle: String { string("community_pending_title") }
    static var communityPendingStatus: String { string("community_pending_status") }
    static func communityPendingRequest(_ username: String) -> String { String(format: string("community_pending_request_format"), username) }
    static var historyTitle: String { string("history_title") }
    static var done: String { string("done") }
    static var historyExampleHeader: String { string("history_example_header") }
    static var historyEmptyTitle: String { string("history_empty_title") }
    static var historyEmptySubtitle: String { string("history_empty_subtitle") }
    static var problem: String { string("problem") }
    static var solutionSteps: String { string("solution_steps") }
    static var solution: String { string("solution") }
    static var solved: String { string("solved") }
    static var answer: String { string("answer") }
    static var steps: String { string("steps") }
    static var solving: String { string("solving") }
    static var cameraAccessRequired: String { string("camera_access_required") }
    static var openSettings: String { string("open_settings") }
    static var tryAgain: String { string("try_again") }
    static var cameraUnlimited: String { string("camera_unlimited") }
    static func cameraUsesRemaining(_ remaining: Int, _ total: Int) -> String { String(format: string("camera_uses_remaining_format"), remaining, total) }
    static var gallery: String { string("gallery") }
    static var cameraPermissionTitle: String { string("camera_permission_title") }
    static var cameraPermissionSubtitle: String { string("camera_permission_subtitle") }
    static var cameraPermissionCaptureLabel: String { string("camera_permission_capture_label") }
    static var cameraPermissionPreviewLabel: String { string("camera_permission_preview_label") }
    static var crop: String { string("crop") }
    static var dragMoveCrop: String { string("drag_move_crop") }
    static var useCrop: String { string("use_crop") }
    static var failedLoadImage: String { string("failed_load_image") }
    static var solutionLanguageTitle: String { string("solution_language_title") }
    static func solutionLanguageSubtitle(_ language: String) -> String { String(format: string("solution_language_subtitle_format"), language) }
    static var solutionLanguageProblemLabel: String { string("solution_language_problem_label") }
    static var solutionLanguageAppLabel: String { string("solution_language_app_label") }
    static var difficultyElementary: String { string("difficulty_elementary") }
    static var difficultyMiddleSchool: String { string("difficulty_middle_school") }
    static var difficultyHighSchool: String { string("difficulty_high_school") }
    static var difficultyCollege: String { string("difficulty_college") }
    static var streakTitle: String { string("streak_title") }
    static var activeToday: String { string("active_today") }
    static var notActiveToday: String { string("not_active_today") }
    static var thisMonth: String { string("this_month") }
    static var activeDays: String { string("active_days") }
    static var bestStreak: String { string("best_streak") }
    static var days: String { string("days") }
    static var testDynamicIsland: String { string("test_dynamic_island") }
    static var stopLiveActivity: String { string("stop_live_activity") }
    static var rewardsTitle: String { string("rewards_title") }
    static var rewardsNavTitle: String { string("rewards_nav_title") }

    // MARK: - Solve Review Sheet
    static var reviewTitle: String { string("review_title") }
    static var reviewThanks: String { string("review_thanks") }
    static var reviewWhatLiked: String { string("review_what_liked") }
    static var reviewWhatWrong: String { string("review_what_wrong") }
    static var reviewWhatBetter: String { string("review_what_better") }
    static var reviewCatCapturing: String { string("review_cat_capturing") }
    static var reviewCatSolutionAccuracy: String { string("review_cat_solution_accuracy") }
    static var reviewCatStepByStep: String { string("review_cat_step_by_step") }
    static var reviewCatSpeed: String { string("review_cat_speed") }
    static var reviewCatCameraFailed: String { string("review_cat_camera_failed") }
    static var reviewCatWrongSolution: String { string("review_cat_wrong_solution") }
    static var reviewCatUnclearSteps: String { string("review_cat_unclear_steps") }
    static var reviewCatSlowBuggy: String { string("review_cat_slow_buggy") }
    static var reviewCatCameraAccuracy: String { string("review_cat_camera_accuracy") }
    static var reviewCatSolutionQuality: String { string("review_cat_solution_quality") }
    static var reviewCatExplanationClarity: String { string("review_cat_explanation_clarity") }
    static var reviewCatSpeedMid: String { string("review_cat_speed_mid") }
    static var reviewDetailRecognizedPerfect: String { string("review_detail_recognized_perfect") }
    static var reviewDetailFastAccurate: String { string("review_detail_fast_accurate") }
    static var reviewDetailCompletelyCorrect: String { string("review_detail_completely_correct") }
    static var reviewDetailGreatFormat: String { string("review_detail_great_format") }
    static var reviewDetailEasyFollow: String { string("review_detail_easy_follow") }
    static var reviewDetailLearnedNew: String { string("review_detail_learned_new") }
    static var reviewDetailLightningFast: String { string("review_detail_lightning_fast") }
    static var reviewDetailNoWaiting: String { string("review_detail_no_waiting") }
    static var reviewDetailNoRecognize: String { string("review_detail_no_recognize") }
    static var reviewDetailWrongArea: String { string("review_detail_wrong_area") }
    static var reviewDetailTookLong: String { string("review_detail_took_long") }
    static var reviewDetailAnswerWrong: String { string("review_detail_answer_wrong") }
    static var reviewDetailMissingSteps: String { string("review_detail_missing_steps") }
    static var reviewDetailIncorrectMethod: String { string("review_detail_incorrect_method") }
    static var reviewDetailStepsConfusing: String { string("review_detail_steps_confusing") }
    static var reviewDetailSkippedSteps: String { string("review_detail_skipped_steps") }
    static var reviewDetailTooSlow: String { string("review_detail_too_slow") }
    static var reviewDetailGotStuck: String { string("review_detail_got_stuck") }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lingua dell'app. Aggiornare con [setLocale] quando l'utente cambia lingua in Settings.
/// Usare [localeNotifier] in ValueListenableBuilder per far ricostruire l'app.
class AppLocale {
  static const _key = 'settings_language';
  static final ValueNotifier<String> localeNotifier = ValueNotifier<String>('en');

  static String get current => localeNotifier.value;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    localeNotifier.value = prefs.getString(_key) ?? 'en';
  }

  static Future<void> setLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    localeNotifier.value = code;
  }

  static String tr(String key) {
    final lang = localeNotifier.value;
    final dict = _strings[key];
    if ( dict == null ) return key;
    return dict[lang] ?? dict['en'] ?? dict['it'] ?? key;
  }

  static String trFormat(String key, List<Object> args) {
    String s = tr(key);
    for (final a in args) {
      s = s.replaceFirst(RegExp(r'%d'), a.toString());
      s = s.replaceFirst(RegExp(r'%@'), a.toString());
    }
    return s;
  }

  static String lessonCost(int n) => trFormat('lesson_cost_format', [n]);
  static String completionReward(int n) => trFormat('completion_reward_format', [n]);
  static String completeLessonBtn(int n) => trFormat('complete_lesson_format', [n]);

  static final Map<String, Map<String, String>> _strings = {
    'settings_title': {'it': 'Impostazioni', 'en': 'Settings', 'fr': 'Paramètres', 'es': 'Ajustes', 'uz': 'Sozlamalar'},
    'profile': {'it': 'Profilo', 'en': 'Profile', 'fr': 'Profil', 'es': 'Perfil', 'uz': 'Profil'},
    'name': {'it': 'Nome', 'en': 'Name', 'fr': 'Nom', 'es': 'Nombre', 'uz': 'Ism'},
    'age': {'it': 'Età', 'en': 'Age', 'fr': 'Âge', 'es': 'Edad', 'uz': 'Yosh'},
    'study_preferences': {'it': 'Preferenze di Studio', 'en': 'Study Preferences', 'fr': "Préférences d'étude", 'es': 'Preferencias de estudio', 'uz': "O'qish sozlamalari"},
    'difficulty': {'it': 'Difficoltà', 'en': 'Difficulty', 'fr': 'Difficulté', 'es': 'Dificultad', 'uz': 'Qiyinlik'},
    'difficulty_easy': {'it': 'Facile', 'en': 'Easy', 'fr': 'Facile', 'es': 'Fácil', 'uz': 'Oson'},
    'difficulty_medium': {'it': 'Medio', 'en': 'Medium', 'fr': 'Moyen', 'es': 'Medio', 'uz': "O'rta"},
    'difficulty_hard': {'it': 'Difficile', 'en': 'Hard', 'fr': 'Difficile', 'es': 'Difícil', 'uz': 'Qiyin'},
    'study_reminder': {'it': 'Promemoria studio', 'en': 'Study reminders', 'fr': "Rappels d'étude", 'es': 'Recordatorios de estudio', 'uz': "O'qish eslatmalari"},
    'sounds': {'it': 'Suoni', 'en': 'Sounds', 'fr': 'Sons', 'es': 'Sonidos', 'uz': 'Ovozlar'},
    'interface': {'it': 'Interfaccia', 'en': 'Interface', 'fr': 'Interface', 'es': 'Interfaz', 'uz': 'Interfeys'},
    'dark_theme': {'it': 'Tema scuro', 'en': 'Dark theme', 'fr': 'Thème sombre', 'es': 'Tema oscuro', 'uz': "Qorong'u mavzu"},
    'account_language': {'it': 'Account e lingua', 'en': 'Account & language', 'fr': 'Compte et langue', 'es': 'Cuenta e idioma', 'uz': 'Hisob va til'},
    'language': {'it': 'Lingua', 'en': 'Language', 'fr': 'Langue', 'es': 'Idioma', 'uz': 'Til'},
    'language_italian': {'it': 'Italiano', 'en': 'Italian', 'fr': 'Italien', 'es': 'Italiano', 'uz': 'Italyancha'},
    'language_english': {'it': 'English', 'en': 'English', 'fr': 'Anglais', 'es': 'Inglés', 'uz': 'Inglizcha'},
    'language_french': {'it': 'Francese', 'en': 'French', 'fr': 'Français', 'es': 'Francés', 'uz': 'Fransuzcha'},
    'language_spanish': {'it': 'Spagnolo', 'en': 'Spanish', 'fr': 'Espagnol', 'es': 'Español', 'uz': 'Ispancha'},
    'language_uzbek': {'it': 'Uzbeko', 'en': 'Uzbek', 'fr': 'Ouzbek', 'es': 'Uzbeko', 'uz': "O'zbekcha"},
    'lessons': {'it': 'Lezioni', 'en': 'Lessons', 'fr': 'Leçons', 'es': 'Lecciones', 'uz': 'Darslar'},
    'camera': {'it': 'Camera', 'en': 'Camera', 'fr': 'Appareil photo', 'es': 'Cámara', 'uz': 'Kamera'},
    'profile_tab': {'it': 'Profilo', 'en': 'Profile', 'fr': 'Profil', 'es': 'Perfil', 'uz': 'Profil'},
    'greeting_prefix': {'it': 'Ciao', 'en': 'Hi', 'fr': 'Salut', 'es': 'Hola', 'uz': 'Salom'},
    'hi_there': {'it': 'there', 'en': 'there', 'fr': 'toi', 'es': 'allí', 'uz': 'siz'},
    'loading': {'it': 'Caricamento...', 'en': 'Loading...', 'fr': 'Chargement...', 'es': 'Cargando...', 'uz': 'Yuklanmoqda...'},
    'error': {'it': 'Errore', 'en': 'Error', 'fr': 'Erreur', 'es': 'Error', 'uz': 'Xato'},
    'retry': {'it': 'Riprova', 'en': 'Retry', 'fr': 'Réessayer', 'es': 'Reintentar', 'uz': 'Qayta urinish'},
    'sign_in_required': {'it': 'Accesso richiesto', 'en': 'Sign in required', 'fr': 'Connexion requise', 'es': 'Inicio de sesión requerido', 'uz': 'Kirish talab qilinadi'},
    'sign_in_camera': {'it': 'Accedi per usare la camera.', 'en': 'Sign in to use camera solving.', 'fr': "Connectez-vous pour utiliser l'appareil photo.", 'es': 'Inicia sesión para usar la cámara.', 'uz': 'Kameradan foydalanish uchun kiring.'},
    'sign_in': {'it': 'Accedi', 'en': 'Sign In', 'fr': 'Se connecter', 'es': 'Iniciar sesión', 'uz': 'Kirish'},
    'sign_out': {'it': 'Esci', 'en': 'Sign Out', 'fr': 'Déconnexion', 'es': 'Cerrar sesión', 'uz': 'Chiqish'},
    'not_now': {'it': 'Non ora', 'en': 'Not now', 'fr': 'Plus tard', 'es': 'Ahora no', 'uz': 'Keyinroq'},
    'guest_lesson_message': {'it': 'Gli ospiti possono aprire una lezione. Accedi per continuare con tutte.', 'en': 'Guests can open one lesson. Sign in to continue all lessons.', 'fr': "Les invités peuvent ouvrir une leçon. Connectez-vous pour continuer.", 'es': 'Los invitados pueden abrir una lección. Inicia sesión para continuar.', 'uz': "Mehmonlar bitta dars ochishi mumkin. Barcha darslar uchun kiring."},
    'lesson': {'it': 'Lezione', 'en': 'Lesson', 'fr': 'Leçon', 'es': 'Lección', 'uz': 'Dars'},
    'lesson_cost_format': {'it': 'Costo lezione: %d coin', 'en': 'Lesson cost: %d coins', 'fr': 'Coût de la leçon : %d pièces', 'es': 'Costo de la lección: %d monedas', 'uz': 'Dars narxi: %d tanga'},
    'plan_label': {'it': 'Piano', 'en': 'Plan', 'fr': 'Forfait', 'es': 'Plan', 'uz': 'Reja'},
    'completion_reward_format': {'it': 'Ricompensa completamento: fino a %d coin', 'en': 'Completion reward: up to %d coins', 'fr': "Récompense : jusqu'à %d pièces", 'es': 'Recompensa al completar: hasta %d monedas', 'uz': 'Yakunlash mukofoti: %d tangagacha'},
    'completing': {'it': 'Completamento...', 'en': 'Completing...', 'fr': 'En cours...', 'es': 'Completando...', 'uz': 'Yakunlanmoqda...'},
    'complete_lesson_format': {'it': 'Completa lezione (+%d max)', 'en': 'Complete Lesson (+%d max)', 'fr': 'Terminer la leçon (+%d max)', 'es': 'Completar lección (+%d máx.)', 'uz': 'Darsni tugatish (+%d max)'},
    'content_not_available': {'it': 'Contenuto non disponibile', 'en': 'Content not available', 'fr': 'Contenu indisponible', 'es': 'Contenido no disponible', 'uz': 'Mazmun mavjud emas'},
    'server_retry_message': {'it': 'Assicurati che il server sia avviato e riprova.', 'en': 'Make sure the server is running and try again.', 'fr': 'Vérifiez que le serveur est démarré et réessayez.', 'es': 'Asegúrate de que el servidor esté en ejecución e inténtalo de nuevo.', 'uz': "Server ishlayotganiga ishonch hosil qiling va qayta urinib ko'ring."},
    'ok': {'it': 'OK', 'en': 'OK', 'fr': 'OK', 'es': 'OK', 'uz': 'OK'},
    'diagram_not_available': {'it': 'Diagramma non disponibile', 'en': 'Diagram not available', 'fr': 'Diagramme non disponible', 'es': 'Diagrama no disponible', 'uz': 'Diagramma mavjud emas'},
    'history_title': {'it': 'Cronologia', 'en': 'History', 'fr': 'Historique', 'es': 'Historial', 'uz': 'Tarix'},
    'done': {'it': 'Fatto', 'en': 'Done', 'fr': 'Terminé', 'es': 'Hecho', 'uz': 'Bajarildi'},
    'history_empty_title': {'it': 'Nessuna cronologia', 'en': 'No History Yet', 'fr': "Pas encore d'historique", 'es': 'Sin historial aún', 'uz': "Hali tarix yo'q"},
    'history_empty_subtitle': {'it': 'I problemi risolti appariranno qui', 'en': 'Your solved math problems will appear here', 'fr': 'Vos problèmes résolus apparaîtront ici', 'es': 'Tus problemas resueltos aparecerán aquí', 'uz': "Yechilgan masalalaringiz shu yerda ko'rinadi"},
    'problem': {'it': 'Problema', 'en': 'Problem', 'fr': 'Problème', 'es': 'Problema', 'uz': 'Masala'},
    'solution_steps': {'it': 'Passaggi della soluzione', 'en': 'Solution Steps', 'fr': 'Étapes de solution', 'es': 'Pasos de solución', 'uz': 'Yechim bosqichlari'},
    'solution': {'it': 'Soluzione', 'en': 'Solution', 'fr': 'Solution', 'es': 'Solución', 'uz': 'Yechim'},
    'solving': {'it': 'Risoluzione...', 'en': 'Solving...', 'fr': 'Résolution...', 'es': 'Resolviendo...', 'uz': 'Yechilmoqda...'},
    'try_again': {'it': 'Riprova', 'en': 'Try Again', 'fr': 'Réessayer', 'es': 'Intentar de nuevo', 'uz': "Qayta urinib ko'ring"},
    'camera_uses_remaining_format': {'it': '%d di %d utilizzi disponibili oggi', 'en': '%d of %d uses remaining today', 'fr': "%d sur %d utilisations restantes aujourd'hui", 'es': '%d de %d usos restantes hoy', 'uz': 'Bugun %d tadan %d tasi qoldi'},
    'generic_error': {'it': 'Si è verificato un errore', 'en': 'An error occurred', 'fr': "Une erreur s'est produite", 'es': 'Ocurrió un error', 'uz': 'Xatolik yuz berdi'},
    'no_content': {'it': 'Nessun contenuto', 'en': 'No content', 'fr': 'Aucun contenu', 'es': 'Sin contenido', 'uz': 'Mazmun yo\'q'},
    'practice': {'it': 'Esercitati', 'en': 'Practice', 'fr': 'Pratique', 'es': 'Practicar', 'uz': 'Mashq qilish'},
    'cancel': {'it': 'Annulla', 'en': 'Cancel', 'fr': 'Annuler', 'es': 'Cancelar', 'uz': 'Bekor qilish'},
    'save': {'it': 'Salva', 'en': 'Save', 'fr': 'Enregistrer', 'es': 'Guardar', 'uz': 'Saqlash'},
    'dont_have_account': {'it': 'Non hai un account?', 'en': "Don't have an account?", 'fr': 'Pas encore de compte?', 'es': '¿No tienes cuenta?', 'uz': "Hisobingiz yo'qmi?"},
    'create_one': {'it': 'Creane uno', 'en': 'Create one', 'fr': 'Créer un compte', 'es': 'Crear una', 'uz': 'Yaratish'},
    'already_have_account': {'it': 'Hai già un account?', 'en': 'Already have an account?', 'fr': 'Déjà un compte?', 'es': '¿Ya tienes cuenta?', 'uz': "Allaqachon hisobingiz bormi?"},
    'register': {'it': 'Registrati', 'en': 'Register', 'fr': "S'inscrire", 'es': 'Registrarse', 'uz': "Ro'yxatdan o'tish"},
    'login': {'it': 'Accedi', 'en': 'Login', 'fr': 'Connexion', 'es': 'Iniciar sesión', 'uz': 'Kirish'},
    'username_label': {'it': 'Username', 'en': 'Username', 'fr': "Nom d'utilisateur", 'es': 'Nombre de usuario', 'uz': 'Foydalanuvchi nomi'},
    'password_label': {'it': 'Password', 'en': 'Password', 'fr': 'Mot de passe', 'es': 'Contraseña', 'uz': 'Parol'},
    'confirm_password': {'it': 'Conferma password', 'en': 'Confirm password', 'fr': 'Confirmer le mot de passe', 'es': 'Confirmar contraseña', 'uz': 'Parolni tasdiqlang'},
    'insert_username': {'it': 'Inserisci username', 'en': 'Insert username', 'fr': "Entrez le nom d'utilisateur", 'es': 'Introduce el usuario', 'uz': 'Foydalanuvchi nomini kiriting'},
    'insert_password': {'it': 'Inserisci password', 'en': 'Insert password', 'fr': 'Entrez le mot de passe', 'es': 'Introduce la contraseña', 'uz': 'Parolni kiriting'},
    'master_tagline': {'it': 'Domina la matematica, un passo alla volta', 'en': 'Master math, one step at a time', 'fr': 'Maîtrisez les maths, étape par étape', 'es': 'Domina las matemáticas, paso a paso', 'uz': "Matematikani bosqichma-bosqich egallang"},
    'continue_username': {'it': 'Continua con username', 'en': 'Continue with username', 'fr': "Continuer avec un nom d'utilisateur", 'es': 'Continuar con nombre de usuario', 'uz': "Foydalanuvchi nomi bilan davom etish"},
    'continue_google': {'it': 'Continua con Google', 'en': 'Continue with Google', 'fr': 'Continuer avec Google', 'es': 'Continuar con Google', 'uz': 'Google bilan davom etish'},
    'continue_guest': {'it': 'Continua come ospite', 'en': 'Continue as guest', 'fr': "Continuer en tant qu'invité", 'es': 'Continuar como invitado', 'uz': 'Mehmon sifatida davom etish'},
    'view_onboarding_again': {'it': 'Rivedi onboarding', 'en': 'View onboarding again', 'fr': "Revoir l'onboarding", 'es': 'Ver onboarding de nuevo', 'uz': "Onboardingni qayta ko'rish"},
    'user_fallback': {'it': 'Utente', 'en': 'User', 'fr': 'Utilisateur', 'es': 'Usuario', 'uz': 'Foydalanuvchi'},
    'day_streak': {'it': 'Serie Giornaliera', 'en': 'Day Streak', 'fr': 'Série quotidienne', 'es': 'Racha diaria', 'uz': 'Kunlik seriya'},
    'help_support': {'it': 'Aiuto e supporto', 'en': 'Help & Support', 'fr': 'Aide et support', 'es': 'Ayuda y soporte', 'uz': "Yordam va qo'llab-quvvatlash"},
    'rate_app': {'it': "Valuta l'app", 'en': 'Rate the App', 'fr': "Noter l'app", 'es': 'Califica la app', 'uz': 'Ilovani baholash'},
    'math_level': {'it': 'Livello di matematica', 'en': 'Math Level', 'fr': 'Niveau de maths', 'es': 'Nivel de matemáticas', 'uz': 'Matematika darajasi'},
    'account': {'it': 'Account', 'en': 'Account', 'fr': 'Compte', 'es': 'Cuenta', 'uz': 'Hisob'},
    'delete_account': {'it': 'Elimina account', 'en': 'Delete Account', 'fr': 'Supprimer le compte', 'es': 'Eliminar cuenta', 'uz': "Hisobni o'chirish"},
    'delete_account_message': {'it': "Questo eliminerà definitivamente il tuo account e tutti i dati. L'azione non può essere annullata.", 'en': 'This will permanently delete your account and all data. This action cannot be undone.', 'fr': "Cela supprimera définitivement votre compte et toutes les données. Cette action est irréversible.", 'es': 'Esto eliminará permanentemente tu cuenta y todos los datos. Esta acción no se puede deshacer.', 'uz': "Bu hisobingiz va barcha ma'lumotlarni butunlay o'chiradi. Bu amalni ortga qaytarib bo'lmaydi."},
    'store_unlock_title': {'it': 'Sblocca tutto il tuo potenziale', 'en': 'Unlock Your Full Potential', 'fr': 'Libérez tout votre potentiel', 'es': 'Desbloquea todo tu potencial', 'uz': "To'liq salohiyatingizni oching"},
    'store_unlock_subtitle': {'it': 'Scegli il piano adatto ai tuoi obiettivi di studio', 'en': 'Choose the plan that fits your learning goals', 'fr': 'Choisissez le plan adapté à vos objectifs', 'es': 'Elige el plan que se adapta a tus objetivos', 'uz': 'Maqsadlaringizga mos rejani tanlang'},
    'store_whats_included': {'it': 'Cosa include', 'en': "What's included", 'fr': 'Ce qui est inclus', 'es': 'Qué incluye', 'uz': 'Nimalar kiritilgan'},
    'store_current_plan': {'it': 'Piano attuale', 'en': 'Current Plan', 'fr': 'Plan actuel', 'es': 'Plan actual', 'uz': 'Joriy reja'},
    'store_switch_free': {'it': 'Passa a Free', 'en': 'Switch to Free', 'fr': 'Passer à Free', 'es': 'Cambiar a Free', 'uz': "Free rejaga o'tish"},
    'store_subscribe_format': {'it': 'Abbonati a %@', 'en': 'Subscribe to %@', 'fr': "S'abonner à %@", 'es': 'Suscribirse a %@', 'uz': "%@ ga obuna bo'lish"},
    'store_restore': {'it': 'Ripristina acquisti', 'en': 'Restore Purchases', 'fr': 'Restaurer les achats', 'es': 'Restaurar compras', 'uz': 'Xaridlarni tiklash'},
    'store_note': {'it': 'Gli abbonamenti si rinnovano mensilmente. Annulla in qualsiasi momento in Impostazioni.', 'en': 'Subscriptions renew monthly. Cancel anytime in Settings.', 'fr': 'Les abonnements se renouvellent chaque mois. Annulez à tout moment dans Réglages.', 'es': 'Las suscripciones se renuevan mensualmente. Cancela cuando quieras en Ajustes.', 'uz': "Obunalar har oy yangilanadi. Istalgan payt sozlamalarda bekor qilishingiz mumkin."},
    'store_badge_current': {'it': 'ATTUALE', 'en': 'CURRENT', 'fr': 'ACTUEL', 'es': 'ACTUAL', 'uz': 'JORIY'},
    'store_badge_best': {'it': 'MIGLIORE', 'en': 'BEST', 'fr': 'MEILLEUR', 'es': 'MEJOR', 'uz': 'ENG YAXSHI'},
    'store_per_month': {'it': '/mese', 'en': '/month', 'fr': '/mois', 'es': '/mes', 'uz': '/oy'},
    'store_feature_camera_scans': {'it': 'Scansioni camera', 'en': 'Camera Scans', 'fr': 'Scans caméra', 'es': 'Escaneos de cámara', 'uz': 'Kamera skanlari'},
    'store_feature_lesson_rewards': {'it': 'Ricompense lezioni', 'en': 'Lesson Rewards', 'fr': 'Récompenses des leçons', 'es': 'Recompensas de lecciones', 'uz': 'Dars mukofotlari'},
    'store_feature_lesson_refunds': {'it': 'Rimborso lezioni', 'en': 'Lesson Refunds', 'fr': 'Remboursements des leçons', 'es': 'Reembolso de lecciones', 'uz': 'Dars qaytarimlari'},
    'store_value_5_day': {'it': '5/giorno', 'en': '5/day', 'fr': '5/jour', 'es': '5/día', 'uz': '5/kun'},
    'store_value_10_day': {'it': '10/giorno', 'en': '10/day', 'fr': '10/jour', 'es': '10/día', 'uz': '10/kun'},
    'store_value_unlimited': {'it': 'Illimitate', 'en': 'Unlimited', 'fr': 'Illimité', 'es': 'Ilimitado', 'uz': 'Cheksiz'},
    'store_value_full': {'it': 'Completo', 'en': 'Full', 'fr': 'Complet', 'es': 'Completo', 'uz': "To'liq"},
    'store_free': {'it': 'Gratis', 'en': 'Free', 'fr': 'Gratuit', 'es': 'Gratis', 'uz': 'Bepul'},
    'store_pro': {'it': 'Pro', 'en': 'Pro', 'fr': 'Pro', 'es': 'Pro', 'uz': 'Pro'},
    'store_max': {'it': 'Max', 'en': 'Max', 'fr': 'Max', 'es': 'Max', 'uz': 'Max'},
    'store_summary_free': {'it': '5 scansioni camera/giorno e ricompense standard', 'en': '5 camera scans/day and standard lesson rewards', 'fr': '5 scans caméra/jour et récompenses standard', 'es': '5 escaneos de cámara/día y recompensas estándar', 'uz': "Kuniga 5 ta kamera skani va standart mukofotlar"},
    'store_summary_pro': {'it': '10 scansioni camera/giorno e ricompense aumentate', 'en': '10 camera scans/day and boosted lesson rewards', 'fr': '10 scans caméra/jour et récompenses augmentées', 'es': '10 escaneos de cámara/día y recompensas mejoradas', 'uz': "Kuniga 10 ta kamera skani va oshirilgan mukofotlar"},
    'store_summary_max': {'it': 'Scansioni camera illimitate e rimborso completo lezioni', 'en': 'Unlimited camera scans and full lesson refunds', 'fr': 'Scans caméra illimités et remboursement complet', 'es': 'Escaneos ilimitados y reembolso completo', 'uz': "Cheksiz kamera skanlari va to'liq qaytarim"},
    'setup_profile_title': {'it': 'Configura il tuo profilo', 'en': 'Set up your profile', 'fr': 'Configurez votre profil', 'es': 'Configura tu perfil', 'uz': 'Profilingizni sozlang'},
    'setup_profile_subtitle': {'it': 'Dicci qualcosa su di te per personalizzare l\'esperienza', 'en': 'Tell us a bit about yourself so we can personalize your learning experience', 'fr': "Parlez-nous de vous pour personnaliser l'expérience", 'es': 'Cuéntanos sobre ti para personalizar tu experiencia', 'uz': "Tajriba shaxsiylashishi uchun o'zingiz haqida ayting"},
    'your_name': {'it': 'Il tuo nome', 'en': 'Your Name', 'fr': 'Votre nom', 'es': 'Tu nombre', 'uz': 'Ismingiz'},
    'enter_name': {'it': 'Inserisci il tuo nome', 'en': 'Enter your name', 'fr': 'Entrez votre nom', 'es': 'Introduce tu nombre', 'uz': 'Ismingizni kiriting'},
    'choose_username': {'it': 'Scegli uno username', 'en': 'Choose a username', 'fr': "Choisissez un nom d'utilisateur", 'es': 'Elige un nombre de usuario', 'uz': 'Foydalanuvchi nomini tanlang'},
    'username_taken': {'it': 'Username già in uso', 'en': 'Username is already taken', 'fr': "Nom d'utilisateur déjà pris", 'es': 'El usuario ya está en uso', 'uz': 'Foydalanuvchi nomi band'},
    'continue': {'it': 'Continua', 'en': 'Continue', 'fr': 'Continuer', 'es': 'Continuar', 'uz': 'Davom etish'},
    'skip': {'it': 'Salta', 'en': 'Skip', 'fr': 'Passer', 'es': 'Saltar', 'uz': "O'tkazib yuborish"},
    'next': {'it': 'Avanti', 'en': 'Next', 'fr': 'Suivant', 'es': 'Siguiente', 'uz': 'Keyingi'},
    'get_started': {'it': 'Inizia', 'en': 'Get Started', 'fr': 'Commencer', 'es': 'Comenzar', 'uz': 'Boshlash'},
    'onboarding_title_1': {'it': 'Scansiona matematica in pochi secondi', 'en': 'Scan math in seconds', 'fr': 'Scannez les maths en quelques secondes', 'es': 'Escanea matemáticas en segundos', 'uz': "Matematikani soniyalarda skan qiling"},
    'onboarding_subtitle_1': {'it': 'Cattura equazioni con la camera e ottieni soluzioni guidate.', 'en': 'Capture equations with your camera and get guided solutions instantly.', 'fr': 'Capturez des équations avec la caméra et obtenez des solutions guidées.', 'es': 'Captura ecuaciones con tu cámara y obtén soluciones guiadas.', 'uz': "Kamera bilan tenglamalarni tutib, yo'naltirilgan yechim oling."},
    'onboarding_title_2': {'it': 'Impara passo dopo passo', 'en': 'Learn step by step', 'fr': 'Apprenez pas à pas', 'es': 'Aprende paso a paso', 'uz': "Bosqichma-bosqich o'rganing"},
    'onboarding_subtitle_2': {'it': "Segui lezioni strutturate dal base all'avanzato.", 'en': 'Follow structured lessons from beginner concepts to advanced topics.', 'fr': "Suivez des leçons structurées du débutant à l'avancé.", 'es': 'Sigue lecciones estructuradas de básico a avanzado.', 'uz': "Boshlang'ichdan ilg'orgacha tuzilgan darslarni o'ting."},
    'onboarding_title_3': {'it': 'Costruisci serie e progressi', 'en': 'Build streaks and progress', 'fr': 'Construisez des séries et progressez', 'es': 'Crea rachas y progreso', 'uz': "Seriya yarating va o'sing"},
    'onboarding_subtitle_3': {'it': 'Tieni traccia della costanza, completa lezioni e migliora ogni giorno.', 'en': 'Track consistency, complete lessons, and improve daily.', 'fr': 'Suivez votre régularité, terminez des leçons et progressez.', 'es': 'Sigue tu constancia, completa lecciones y mejora a diario.', 'uz': "Doimiylikni kuzating, darslarni tugating va har kuni yaxshilang."},
    'sign_in_not_connected': {'it': 'Accesso non ancora collegato. Usa Google o Apple per ora.', 'en': 'Sign in not yet connected. Use Google or Apple for now.', 'fr': "Connexion non encore configurée. Utilisez Google ou Apple pour l'instant.", 'es': 'Inicio de sesión aún no conectado. Usa Google o Apple por ahora.', 'uz': "Kirish hali ulanmagan. Hozircha Google yoki Apple dan foydalaning."},
    'register_not_connected': {'it': 'Registrazione non ancora collegata. Usa Google o Apple per ora.', 'en': 'Registration not yet connected. Use Google or Apple for now.', 'fr': "Inscription non encore configurée. Utilisez Google ou Apple pour l'instant.", 'es': 'Registro aún no conectado. Usa Google o Apple por ahora.', 'uz': "Ro'yxatdan o'tish hali ulanmagan. Hozircha Google yoki Apple dan foydalaning."},
    'passwords_not_match': {'it': 'Le password non corrispondono.', 'en': 'Passwords do not match.', 'fr': 'Les mots de passe ne correspondent pas.', 'es': 'Las contraseñas no coinciden.', 'uz': 'Parollar mos emas.'},
    'lessons_completed': {'it': 'Lezioni', 'en': 'Lessons', 'fr': 'Leçons', 'es': 'Lecciones', 'uz': 'Darslar'},
    'level_beginner': {'it': 'Principiante', 'en': 'Beginner', 'fr': 'Débutant', 'es': 'Principiante', 'uz': "Boshlang'ich"},
    'level_intermediate': {'it': 'Intermedio', 'en': 'Intermediate', 'fr': 'Intermédiaire', 'es': 'Intermedio', 'uz': "O'rta"},
    'level_advanced': {'it': 'Avanzato', 'en': 'Advanced', 'fr': 'Avancé', 'es': 'Avanzado', 'uz': 'Yuqori'},
    'level_desc_beginner': {'it': 'Aritmetica di base, frazioni, decimali', 'en': 'Basic arithmetic, fractions, decimals', 'fr': 'Arithmétique de base, fractions, décimales', 'es': 'Aritmética básica, fracciones, decimales', 'uz': "Asosiy arifmetika, kasrlar, o'nliklar"},
    'level_desc_intermediate': {'it': 'Algebra, geometria, equazioni di base', 'en': 'Algebra, geometry, basic equations', 'fr': 'Algèbre, géométrie, équations de base', 'es': 'Álgebra, geometría, ecuaciones básicas', 'uz': 'Algebra, geometriya, asosiy tenglamalar'},
    'level_desc_advanced': {'it': 'Calcolo, trigonometria, algebra avanzata', 'en': 'Calculus, trigonometry, advanced algebra', 'fr': 'Calcul, trigonométrie, algèbre avancée', 'es': 'Cálculo, trigonometría, álgebra avanzada', 'uz': "Hisoblash, trigonometriya, ilg'or algebra"},
    'field_value': {'it': 'Valore', 'en': 'Value', 'fr': 'Valeur', 'es': 'Valor', 'uz': 'Qiymat'},
    'username_exists': {'it': 'Nome utente già esistente', 'en': 'Username already exists', 'fr': "Nom d'utilisateur déjà utilisé", 'es': 'Nombre de usuario ya existe', 'uz': 'Foydalanuvchi nomi band'},
    'network_retry': {'it': 'Errore di rete. Riprova.', 'en': 'Network error. Please retry.', 'fr': 'Erreur réseau. Réessayez.', 'es': 'Error de red. Inténtalo de nuevo.', 'uz': "Tarmoq xatosi. Qayta urinib ko'ring."},
    'profile_setup_required': {'it': 'Inserisci nome, username e livello.', 'en': 'Please enter your name, username, and select a level.', 'fr': 'Veuillez saisir votre nom, votre nom utilisateur et un niveau.', 'es': 'Ingresa tu nombre, usuario y selecciona un nivel.', 'uz': 'Ism, foydalanuvchi nomi va darajani kiriting.'},
    'username_taken_detailed': {'it': 'Username già in uso. Scegline un altro.', 'en': 'Username is already taken. Please choose another.', 'fr': "Nom d'utilisateur déjà pris. Choisissez-en un autre.", 'es': 'El usuario ya está en uso. Elige otro.', 'uz': 'Foydalanuvchi nomi band. Boshqasini tanlang.'},
    'register_failed': {'it': 'Registrazione username non riuscita.', 'en': 'Failed to register username.', 'fr': "Échec de l'inscription du nom utilisateur.", 'es': 'No se pudo registrar el usuario.', 'uz': "Foydalanuvchi nomini ro'yxatdan o'tkazib bo'lmadi."},
    'setup': {'it': 'Setup', 'en': 'Setup', 'fr': 'Configuration', 'es': 'Configuración', 'uz': 'Sozlash'},
    'streak_title': {'it': 'Serie', 'en': 'Streak', 'fr': 'Série', 'es': 'Racha', 'uz': 'Seriya'},
    'active_today': {'it': 'Attivo oggi', 'en': 'Active today', 'fr': "Actif aujourd'hui", 'es': 'Activo hoy', 'uz': 'Bugun faol'},
    'not_active_today': {'it': 'Non ancora attivo oggi', 'en': 'Not active yet today', 'fr': "Pas encore actif aujourd'hui", 'es': 'Aún no activo hoy', 'uz': 'Bugun hali faol emas'},
    'this_month': {'it': 'Questo mese', 'en': 'This Month', 'fr': 'Ce mois-ci', 'es': 'Este mes', 'uz': 'Bu oy'},
    'active_days': {'it': 'giorni attivi', 'en': 'active days', 'fr': 'jours actifs', 'es': 'días activos', 'uz': 'faol kunlar'},
    'best_streak': {'it': 'Miglior serie', 'en': 'Best Streak', 'fr': 'Meilleure série', 'es': 'Mejor racha', 'uz': 'Eng yaxshi seriya'},
    'days': {'it': 'giorni', 'en': 'days', 'fr': 'jours', 'es': 'días', 'uz': 'kun'},
    'rewards_title': {'it': 'Task e ricompense', 'en': 'Tasks and rewards', 'fr': 'Tâches et récompenses', 'es': 'Tareas y recompensas', 'uz': 'Vazifalar va mukofotlar'},
    'rewards_nav_title': {'it': 'Ricompense', 'en': 'Rewards', 'fr': 'Récompenses', 'es': 'Recompensas', 'uz': 'Mukofotlar'},
  };
}

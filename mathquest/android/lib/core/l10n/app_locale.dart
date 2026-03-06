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
    'no_content': {'it': 'Nessun contenuto', 'en': 'No content', 'fr': 'Aucun contenu', 'es': 'Sin contenido', 'uz': 'Mazmun yo\'q'},
    'practice': {'it': 'Esercitati', 'en': 'Practice', 'fr': 'Pratique', 'es': 'Practicar', 'uz': 'Mashq qilish'},
<<<<<<< HEAD
    'cancel': {'it': 'Annulla', 'en': 'Cancel', 'fr': 'Annuler', 'es': 'Cancelar', 'uz': 'Bekor qilish'},
    'save': {'it': 'Salva', 'en': 'Save', 'fr': 'Enregistrer', 'es': 'Guardar', 'uz': 'Saqlash'},
=======
    'dont_have_account': {'it': 'Non hai un account?', 'en': "Don't have an account?", 'fr': 'Pas encore de compte?', 'es': '¿No tienes cuenta?', 'uz': "Hisobingiz yo'qmi?"},
    'create_one': {'it': 'Creane uno', 'en': 'Create one', 'fr': 'Créer un compte', 'es': 'Crear una', 'uz': 'Yaratish'},
    'already_have_account': {'it': 'Hai già un account?', 'en': 'Already have an account?', 'fr': 'Déjà un compte?', 'es': '¿Ya tienes cuenta?', 'uz': "Allaqachon hisobingiz bormi?"},
    'register': {'it': 'Registrati', 'en': 'Register', 'fr': "S'inscrire", 'es': 'Registrarse', 'uz': "Ro'yxatdan o'tish"},
    'login': {'it': 'Accedi', 'en': 'Login', 'fr': 'Connexion', 'es': 'Iniciar sesión', 'uz': 'Kirish'},
>>>>>>> 5c98b591af9cb2ac601d5e8e91219daddfd31737
  };
}

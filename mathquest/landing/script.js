const menuToggle = document.querySelector(".menu-toggle");
const siteNav = document.querySelector(".site-nav");
const hero = document.querySelector(".hero");
const cursorGlow = document.querySelector(".cursor-glow");
const toast = document.querySelector(".study-toast");
const languageSelect = document.querySelector("#language-select");
const metaDescription = document.querySelector('meta[name="description"]');

const translations = {
  en: {
    pageTitle: "Kram | Learn math with guided scans, lessons, and streaks",
    metaDescription: "Kram helps students scan math problems, follow structured lessons, and build daily progress with streaks and rewards.",
    menu: "Menu",
    languageLabel: "Language",
    navFeatures: "Features",
    navProgress: "Progress",
    navScreens: "Screens",
    navPrivacy: "Privacy",
    navTerms: "Terms",
    heroEyebrow: "Math practice that keeps moving",
    heroTitle: "Scan the problem. Follow the lesson. Keep the streak.",
    heroCopy: "Kram turns math study into a daily rhythm with camera solving, structured lessons, rewards, and progress you can see.",
    featuresEyebrow: "Why students use it",
    featuresTitle: "Fast help for today, steady practice for tomorrow.",
    feature1Title: "Scan math in seconds",
    feature1Copy: "Capture handwritten or printed problems and open guided solutions when you need a push.",
    feature2Title: "Learn with lessons",
    feature2Copy: "Move from beginner concepts to advanced topics through short, structured lesson paths.",
    feature3Title: "Stay motivated",
    feature3Copy: "Track streaks, complete lessons, collect coins, and keep your daily study habit visible.",
    progressEyebrow: "Progress that feels clear",
    progressTitle: "Lessons, camera help, and rewards stay in one place.",
    progressCopy: "Open a topic, check your lesson count, review your streak, and return to camera solving when a problem slows you down.",
    progressItem1: "Free daily camera scans with an account",
    progressItem2: "Lessons are always available",
    progressItem3: "Profile stats keep consistency visible",
    today: "Today",
    lessonSummaryTitle: "Trigonometry practice",
    lessonSummaryMeta: "Guided lesson + streak progress",
    screensEyebrow: "Screens and study flow",
    screensTitle: "Built around the student workflow.",
    screen1Title: "Lesson dashboard",
    screen1Copy: "Choose a math topic and keep track of completion.",
    screen2Title: "Guided start",
    screen2Copy: "Begin with camera solving, lessons, and streaks as the core loop.",
    screen3Title: "Lesson topics",
    screen3Copy: "Use visual topic material while moving from basics to advanced math.",
    downloadEyebrow: "Start with one problem",
    downloadTitle: "Open Kram when homework needs a clearer next step.",
    privacyPolicy: "Privacy Policy",
    termsOfUse: "Terms of Use",
    toast: "500 students are practicing Trigonometry right now 📚",
    appStoreAlt: "Download Kram on the App Store",
    privacyPageTitle: "Privacy Policy | Kram",
    privacyMetaDescription: "Privacy Policy for the Kram math learning app.",
    termsPageTitle: "Terms of Use | Kram",
    termsMetaDescription: "Terms of Use for the Kram math learning app.",
    legalEffectiveDate: "Effective April 13, 2026",
    privacyTitle: "Privacy Policy",
    privacyIntro: "Kram helps students learn math with camera scans, lessons, accounts, progress tracking, and subscriptions. This policy explains what information is handled and how it is used.",
    privacyInfoTitle: "Information We Collect",
    privacyInfoCopy: "Kram may collect account details such as name, username, email address, profile photo, sign-in identifiers, math level, and subscription status. The app may also process math problems, captured images, typed inputs, generated solution steps, lesson activity, streaks, coin balance, settings, support requests, and basic diagnostic data.",
    privacyCameraTitle: "Camera And Photo Use",
    privacyCameraCopy: "Camera and photo library access are used to scan or select math problem images. Images and recognized problem text may be processed to generate explanations, solution steps, history entries, and share links when you choose to use those features.",
    privacyUseTitle: "How Information Is Used",
    privacyUseCopy: "Information is used to provide lessons, solve math problems, save progress, manage accounts, maintain streaks and rewards, process subscriptions, respond to support requests, improve reliability, prevent abuse, and keep the app secure.",
    privacyServicesTitle: "Third-Party Services",
    privacyServicesCopy: "Kram may use services such as Firebase, Google Sign-In, Apple Sign-In, StoreKit, analytics, hosting, and payment infrastructure. These services process information under their own privacy and security terms.",
    privacySharingTitle: "Sharing",
    privacySharingCopy: "Personal information is not sold. Information may be shared with service providers that operate the app, comply with law, protect users, process purchases, or deliver a feature requested by the user, such as a shared solution link.",
    privacyRetentionTitle: "Retention",
    privacyRetentionCopy: "Information is kept for as long as needed to provide the app, maintain security, comply with legal obligations, or support account and subscription records. Users may request deletion where applicable.",
    privacyChoicesTitle: "Choices",
    privacyChoicesCopy: "Device permissions for camera and photo library can be managed in system settings. Account and profile information can be updated in the app. Subscription settings are managed through the App Store.",
    privacyChildrenTitle: "Children",
    privacyChildrenCopy: "Kram is intended for students and learners. Users should use the app with parent or guardian involvement when required by local law.",
    privacyContactTitle: "Contact",
    privacyContactCopy: "For privacy requests or questions, contact the Kram team through the support channel in the app or the project owner's published support contact.",
    termsTitle: "Terms of Use",
    termsIntro: "These terms govern use of Kram, a math learning app with lessons, camera solving, progress tracking, rewards, accounts, and optional subscriptions.",
    termsUseTitle: "Use Of Kram",
    termsUseCopy: "Kram is provided for learning and study support. Users are responsible for how they use the app and for following school, exam, and academic integrity rules.",
    termsAccountsTitle: "Accounts",
    termsAccountsCopy: "Some features require an account. Account information must be accurate enough to operate the service, and users are responsible for activity under their account.",
    termsSolutionsTitle: "Math Solutions",
    termsSolutionsCopy: "Camera scans and generated solution steps are study aids. Results may be incomplete or incorrect, especially when images are blurry, cropped, handwritten unclearly, or contain ambiguous notation. Users should review results before relying on them.",
    termsPurchasesTitle: "Subscriptions And Purchases",
    termsPurchasesCopy: "Optional paid features may be offered through the App Store. Purchases, renewals, cancellation, refunds, and billing are handled by Apple according to App Store terms.",
    termsContentTitle: "User Content",
    termsContentCopy: "Users may submit math problem images, typed problems, profile details, and support content. Users must not submit unlawful, harmful, infringing, or private third-party information without permission.",
    termsAcceptableTitle: "Acceptable Use",
    termsAcceptableCopy: "Users may not misuse the service, attempt to disrupt the app or backend, reverse engineer restricted parts of the service, bypass limits, automate abuse, or use Kram to violate laws or third-party rights.",
    termsChangesTitle: "Service Changes",
    termsChangesCopy: "Features, limits, rewards, lesson content, subscriptions, and availability may change over time. Kram may be updated, paused, or discontinued as needed.",
    termsWarrantyTitle: "No Warranty",
    termsWarrantyCopy: "Kram is provided as available. To the maximum extent allowed by law, no guarantee is made that the app will always be available, error-free, or suitable for a particular learning outcome.",
    termsContactTitle: "Contact",
    termsContactCopy: "For questions about these terms, contact the Kram team through the support channel in the app or the project owner's published support contact.",
  },
  it: {
    pageTitle: "Kram | Impara matematica con scansioni, lezioni e serie",
    metaDescription: "Kram aiuta gli studenti a scansionare problemi di matematica, seguire lezioni strutturate e costruire progressi quotidiani con serie e ricompense.",
    menu: "Menu",
    languageLabel: "Lingua",
    navFeatures: "Funzioni",
    navProgress: "Progressi",
    navScreens: "Schermate",
    navPrivacy: "Privacy",
    navTerms: "Termini",
    heroEyebrow: "Pratica matematica che ti segue",
    heroTitle: "Scansiona il problema. Segui la lezione. Mantieni la serie.",
    heroCopy: "Kram trasforma lo studio della matematica in un ritmo quotidiano con soluzioni da camera, lezioni strutturate, ricompense e progressi visibili.",
    featuresEyebrow: "Perche gli studenti la usano",
    featuresTitle: "Aiuto rapido oggi, pratica costante domani.",
    feature1Title: "Scansiona la matematica in pochi secondi",
    feature1Copy: "Cattura problemi scritti a mano o stampati e apri soluzioni guidate quando ti serve una spinta.",
    feature2Title: "Impara con le lezioni",
    feature2Copy: "Passa dai concetti base agli argomenti avanzati con percorsi brevi e strutturati.",
    feature3Title: "Resta motivato",
    feature3Copy: "Tieni traccia delle serie, completa lezioni, raccogli monete e rendi visibile la tua abitudine di studio.",
    progressEyebrow: "Progressi chiari",
    progressTitle: "Lezioni, aiuto con la camera e ricompense restano nello stesso posto.",
    progressCopy: "Apri un argomento, controlla le lezioni, rivedi la tua serie e torna alla camera quando un problema ti rallenta.",
    progressItem1: "Scansioni camera gratuite ogni giorno con un account",
    progressItem2: "Le lezioni sono sempre disponibili",
    progressItem3: "Le statistiche del profilo mostrano la costanza",
    today: "Oggi",
    lessonSummaryTitle: "Pratica di trigonometria",
    lessonSummaryMeta: "Lezione guidata + progresso della serie",
    screensEyebrow: "Schermate e flusso di studio",
    screensTitle: "Pensata intorno al modo in cui studia uno studente.",
    screen1Title: "Dashboard lezioni",
    screen1Copy: "Scegli un argomento di matematica e segui il completamento.",
    screen2Title: "Inizio guidato",
    screen2Copy: "Parti da camera, lezioni e serie come routine principale.",
    screen3Title: "Argomenti delle lezioni",
    screen3Copy: "Usa materiali visivi mentre passi dalle basi alla matematica avanzata.",
    downloadEyebrow: "Inizia con un problema",
    downloadTitle: "Apri Kram quando i compiti hanno bisogno del prossimo passo chiaro.",
    privacyPolicy: "Privacy Policy",
    termsOfUse: "Termini di utilizzo",
    toast: "500 studenti stanno studiando Trigonometria proprio ora 📚",
    appStoreAlt: "Scarica Kram su App Store",
    privacyPageTitle: "Privacy Policy | Kram",
    privacyMetaDescription: "Privacy Policy per l'app Kram.",
    termsPageTitle: "Termini di utilizzo | Kram",
    termsMetaDescription: "Termini di utilizzo per l'app Kram.",
    legalEffectiveDate: "In vigore dal 13 aprile 2026",
    privacyTitle: "Privacy Policy",
    privacyIntro: "Kram aiuta gli studenti a imparare matematica con scansioni dalla camera, lezioni, account, monitoraggio dei progressi e abbonamenti. Questa policy spiega quali informazioni vengono gestite e come vengono usate.",
    privacyInfoTitle: "Informazioni raccolte",
    privacyInfoCopy: "Kram puo raccogliere dettagli dell'account come nome, username, indirizzo email, foto profilo, identificativi di accesso, livello di matematica e stato dell'abbonamento. L'app puo anche elaborare problemi di matematica, immagini acquisite, input digitati, passaggi di soluzione generati, attivita nelle lezioni, serie, saldo monete, impostazioni, richieste di supporto e dati diagnostici di base.",
    privacyCameraTitle: "Uso di camera e foto",
    privacyCameraCopy: "L'accesso alla camera e alla libreria foto serve per scansionare o selezionare immagini di problemi matematici. Le immagini e il testo riconosciuto possono essere elaborati per generare spiegazioni, passaggi di soluzione, cronologia e link condivisibili quando scegli di usare queste funzioni.",
    privacyUseTitle: "Come vengono usate le informazioni",
    privacyUseCopy: "Le informazioni vengono usate per fornire lezioni, risolvere problemi di matematica, salvare i progressi, gestire account, mantenere serie e ricompense, elaborare abbonamenti, rispondere al supporto, migliorare l'affidabilita, prevenire abusi e mantenere l'app sicura.",
    privacyServicesTitle: "Servizi di terze parti",
    privacyServicesCopy: "Kram puo usare servizi come Firebase, Google Sign-In, Apple Sign-In, StoreKit, analytics, hosting e infrastruttura di pagamento. Questi servizi trattano le informazioni secondo i propri termini di privacy e sicurezza.",
    privacySharingTitle: "Condivisione",
    privacySharingCopy: "Le informazioni personali non vengono vendute. Le informazioni possono essere condivise con fornitori che gestiscono l'app, rispettano la legge, proteggono gli utenti, elaborano acquisti o forniscono una funzione richiesta dall'utente, come un link di soluzione condiviso.",
    privacyRetentionTitle: "Conservazione",
    privacyRetentionCopy: "Le informazioni vengono conservate per il tempo necessario a fornire l'app, mantenere la sicurezza, rispettare obblighi legali o supportare account e registri degli abbonamenti. Gli utenti possono richiedere la cancellazione dove applicabile.",
    privacyChoicesTitle: "Scelte",
    privacyChoicesCopy: "I permessi del dispositivo per camera e libreria foto possono essere gestiti nelle impostazioni di sistema. Le informazioni di account e profilo possono essere aggiornate nell'app. Le impostazioni dell'abbonamento sono gestite tramite App Store.",
    privacyChildrenTitle: "Minori",
    privacyChildrenCopy: "Kram e pensata per studenti e persone che imparano. Gli utenti dovrebbero usare l'app con il coinvolgimento di un genitore o tutore quando richiesto dalla legge locale.",
    privacyContactTitle: "Contatti",
    privacyContactCopy: "Per richieste o domande sulla privacy, contatta il team Kram tramite il canale di supporto nell'app o il contatto pubblico del proprietario del progetto.",
    termsTitle: "Termini di utilizzo",
    termsIntro: "Questi termini regolano l'uso di Kram, un'app per imparare matematica con lezioni, soluzioni dalla camera, monitoraggio dei progressi, ricompense, account e abbonamenti opzionali.",
    termsUseTitle: "Uso di Kram",
    termsUseCopy: "Kram viene fornita per apprendimento e supporto allo studio. Gli utenti sono responsabili di come usano l'app e del rispetto delle regole scolastiche, d'esame e di integrita accademica.",
    termsAccountsTitle: "Account",
    termsAccountsCopy: "Alcune funzioni richiedono un account. Le informazioni dell'account devono essere abbastanza accurate per gestire il servizio e gli utenti sono responsabili dell'attivita svolta con il proprio account.",
    termsSolutionsTitle: "Soluzioni matematiche",
    termsSolutionsCopy: "Le scansioni dalla camera e i passaggi di soluzione generati sono strumenti di studio. I risultati possono essere incompleti o errati, soprattutto quando le immagini sono sfocate, tagliate, scritte a mano in modo poco chiaro o contengono notazioni ambigue. Gli utenti dovrebbero rivedere i risultati prima di farvi affidamento.",
    termsPurchasesTitle: "Abbonamenti e acquisti",
    termsPurchasesCopy: "Funzioni opzionali a pagamento possono essere offerte tramite App Store. Acquisti, rinnovi, cancellazioni, rimborsi e fatturazione sono gestiti da Apple secondo i termini dell'App Store.",
    termsContentTitle: "Contenuti degli utenti",
    termsContentCopy: "Gli utenti possono inviare immagini di problemi matematici, problemi digitati, dettagli del profilo e contenuti di supporto. Gli utenti non devono inviare informazioni illegali, dannose, in violazione di diritti o private di terzi senza permesso.",
    termsAcceptableTitle: "Uso accettabile",
    termsAcceptableCopy: "Gli utenti non possono abusare del servizio, tentare di interrompere l'app o il backend, fare reverse engineering di parti riservate del servizio, aggirare limiti, automatizzare abusi o usare Kram per violare leggi o diritti di terzi.",
    termsChangesTitle: "Modifiche al servizio",
    termsChangesCopy: "Funzioni, limiti, ricompense, contenuti delle lezioni, abbonamenti e disponibilita possono cambiare nel tempo. Kram puo essere aggiornata, sospesa o interrotta quando necessario.",
    termsWarrantyTitle: "Nessuna garanzia",
    termsWarrantyCopy: "Kram viene fornita cosi com'e disponibile. Nei limiti massimi consentiti dalla legge, non viene garantito che l'app sia sempre disponibile, priva di errori o adatta a un particolare risultato di apprendimento.",
    termsContactTitle: "Contatti",
    termsContactCopy: "Per domande su questi termini, contatta il team Kram tramite il canale di supporto nell'app o il contatto pubblico del proprietario del progetto.",
  },
  sp: {
    pageTitle: "Kram | Aprende matematicas con escaneos, lecciones y rachas",
    metaDescription: "Kram ayuda a los estudiantes a escanear problemas de matematicas, seguir lecciones estructuradas y crear progreso diario con rachas y recompensas.",
    menu: "Menu",
    languageLabel: "Idioma",
    navFeatures: "Funciones",
    navProgress: "Progreso",
    navScreens: "Pantallas",
    navPrivacy: "Privacidad",
    navTerms: "Terminos",
    heroEyebrow: "Practica de matematicas en movimiento",
    heroTitle: "Escanea el problema. Sigue la leccion. Mantén la racha.",
    heroCopy: "Kram convierte el estudio de matematicas en un ritmo diario con soluciones por camara, lecciones estructuradas, recompensas y progreso visible.",
    featuresEyebrow: "Por que la usan los estudiantes",
    featuresTitle: "Ayuda rapida para hoy, practica constante para manana.",
    feature1Title: "Escanea matematicas en segundos",
    feature1Copy: "Captura problemas escritos a mano o impresos y abre soluciones guiadas cuando necesitas un empujon.",
    feature2Title: "Aprende con lecciones",
    feature2Copy: "Avanza desde conceptos basicos hasta temas avanzados con rutas cortas y estructuradas.",
    feature3Title: "Mantén la motivacion",
    feature3Copy: "Sigue tus rachas, completa lecciones, gana monedas y mantén visible tu habito de estudio.",
    progressEyebrow: "Progreso claro",
    progressTitle: "Lecciones, ayuda con camara y recompensas en un solo lugar.",
    progressCopy: "Abre un tema, revisa tus lecciones, mira tu racha y vuelve a la camara cuando un problema te frena.",
    progressItem1: "Escaneos diarios gratis con una cuenta",
    progressItem2: "Las lecciones siempre estan disponibles",
    progressItem3: "Las estadisticas del perfil muestran tu constancia",
    today: "Hoy",
    lessonSummaryTitle: "Practica de trigonometria",
    lessonSummaryMeta: "Leccion guiada + progreso de racha",
    screensEyebrow: "Pantallas y flujo de estudio",
    screensTitle: "Pensada para el flujo real de un estudiante.",
    screen1Title: "Panel de lecciones",
    screen1Copy: "Elige un tema de matematicas y controla tu avance.",
    screen2Title: "Inicio guiado",
    screen2Copy: "Empieza con camara, lecciones y rachas como rutina principal.",
    screen3Title: "Temas de leccion",
    screen3Copy: "Usa material visual mientras avanzas desde lo basico hasta matematicas avanzadas.",
    downloadEyebrow: "Empieza con un problema",
    downloadTitle: "Abre Kram cuando la tarea necesita un siguiente paso mas claro.",
    privacyPolicy: "Politica de privacidad",
    termsOfUse: "Terminos de uso",
    toast: "500 estudiantes estan practicando Trigonometria ahora mismo 📚",
    appStoreAlt: "Descarga Kram en App Store",
    privacyPageTitle: "Politica de privacidad | Kram",
    privacyMetaDescription: "Politica de privacidad para la app Kram.",
    termsPageTitle: "Terminos de uso | Kram",
    termsMetaDescription: "Terminos de uso para la app Kram.",
    legalEffectiveDate: "Vigente desde el 13 de abril de 2026",
    privacyTitle: "Politica de privacidad",
    privacyIntro: "Kram ayuda a los estudiantes a aprender matematicas con escaneos de camara, lecciones, cuentas, seguimiento de progreso y suscripciones. Esta politica explica que informacion se gestiona y como se usa.",
    privacyInfoTitle: "Informacion que recopilamos",
    privacyInfoCopy: "Kram puede recopilar datos de cuenta como nombre, nombre de usuario, correo electronico, foto de perfil, identificadores de inicio de sesion, nivel de matematicas y estado de suscripcion. La app tambien puede procesar problemas de matematicas, imagenes capturadas, entradas escritas, pasos de solucion generados, actividad de lecciones, rachas, saldo de monedas, ajustes, solicitudes de soporte y datos diagnosticos basicos.",
    privacyCameraTitle: "Uso de camara y fotos",
    privacyCameraCopy: "El acceso a la camara y a la biblioteca de fotos se usa para escanear o seleccionar imagenes de problemas matematicos. Las imagenes y el texto reconocido pueden procesarse para generar explicaciones, pasos de solucion, historial y enlaces compartidos cuando decides usar esas funciones.",
    privacyUseTitle: "Como se usa la informacion",
    privacyUseCopy: "La informacion se usa para ofrecer lecciones, resolver problemas de matematicas, guardar progreso, gestionar cuentas, mantener rachas y recompensas, procesar suscripciones, responder al soporte, mejorar la fiabilidad, prevenir abusos y mantener segura la app.",
    privacyServicesTitle: "Servicios de terceros",
    privacyServicesCopy: "Kram puede usar servicios como Firebase, Google Sign-In, Apple Sign-In, StoreKit, analytics, hosting e infraestructura de pago. Estos servicios procesan informacion segun sus propios terminos de privacidad y seguridad.",
    privacySharingTitle: "Compartir informacion",
    privacySharingCopy: "La informacion personal no se vende. La informacion puede compartirse con proveedores que operan la app, cumplen la ley, protegen a los usuarios, procesan compras o entregan una funcion solicitada por el usuario, como un enlace de solucion compartido.",
    privacyRetentionTitle: "Conservacion",
    privacyRetentionCopy: "La informacion se conserva durante el tiempo necesario para ofrecer la app, mantener la seguridad, cumplir obligaciones legales o respaldar registros de cuenta y suscripcion. Los usuarios pueden solicitar la eliminacion cuando corresponda.",
    privacyChoicesTitle: "Opciones",
    privacyChoicesCopy: "Los permisos del dispositivo para camara y biblioteca de fotos pueden gestionarse en los ajustes del sistema. La informacion de cuenta y perfil puede actualizarse en la app. Los ajustes de suscripcion se gestionan mediante App Store.",
    privacyChildrenTitle: "Menores",
    privacyChildrenCopy: "Kram esta pensada para estudiantes y personas que aprenden. Los usuarios deben usar la app con participacion de un padre, madre o tutor cuando lo exija la ley local.",
    privacyContactTitle: "Contacto",
    privacyContactCopy: "Para solicitudes o preguntas de privacidad, contacta con el equipo de Kram mediante el canal de soporte de la app o el contacto publico del propietario del proyecto.",
    termsTitle: "Terminos de uso",
    termsIntro: "Estos terminos regulan el uso de Kram, una app de aprendizaje de matematicas con lecciones, resolucion por camara, seguimiento de progreso, recompensas, cuentas y suscripciones opcionales.",
    termsUseTitle: "Uso de Kram",
    termsUseCopy: "Kram se ofrece para aprendizaje y apoyo al estudio. Los usuarios son responsables de como usan la app y de seguir las reglas escolares, de examenes y de integridad academica.",
    termsAccountsTitle: "Cuentas",
    termsAccountsCopy: "Algunas funciones requieren una cuenta. La informacion de la cuenta debe ser suficientemente precisa para operar el servicio, y los usuarios son responsables de la actividad realizada con su cuenta.",
    termsSolutionsTitle: "Soluciones matematicas",
    termsSolutionsCopy: "Los escaneos de camara y los pasos de solucion generados son ayudas de estudio. Los resultados pueden ser incompletos o incorrectos, especialmente cuando las imagenes estan borrosas, recortadas, escritas a mano de forma poco clara o contienen notacion ambigua. Los usuarios deben revisar los resultados antes de confiar en ellos.",
    termsPurchasesTitle: "Suscripciones y compras",
    termsPurchasesCopy: "Pueden ofrecerse funciones opcionales de pago mediante App Store. Compras, renovaciones, cancelaciones, reembolsos y facturacion son gestionados por Apple segun los terminos de App Store.",
    termsContentTitle: "Contenido del usuario",
    termsContentCopy: "Los usuarios pueden enviar imagenes de problemas matematicos, problemas escritos, detalles de perfil y contenido de soporte. Los usuarios no deben enviar informacion ilegal, danina, infractora o informacion privada de terceros sin permiso.",
    termsAcceptableTitle: "Uso aceptable",
    termsAcceptableCopy: "Los usuarios no pueden abusar del servicio, intentar interrumpir la app o el backend, aplicar ingenieria inversa a partes restringidas del servicio, eludir limites, automatizar abusos o usar Kram para violar leyes o derechos de terceros.",
    termsChangesTitle: "Cambios del servicio",
    termsChangesCopy: "Funciones, limites, recompensas, contenido de lecciones, suscripciones y disponibilidad pueden cambiar con el tiempo. Kram puede actualizarse, pausarse o discontinuarse cuando sea necesario.",
    termsWarrantyTitle: "Sin garantia",
    termsWarrantyCopy: "Kram se proporciona tal como esta disponible. En la maxima medida permitida por la ley, no se garantiza que la app este siempre disponible, sin errores o sea adecuada para un resultado de aprendizaje concreto.",
    termsContactTitle: "Contacto",
    termsContactCopy: "Para preguntas sobre estos terminos, contacta con el equipo de Kram mediante el canal de soporte de la app o el contacto publico del propietario del proyecto.",
  },
  fr: {
    pageTitle: "Kram | Apprendre les maths avec scans, lecons et series",
    metaDescription: "Kram aide les eleves a scanner des problemes de maths, suivre des lecons structurees et construire des progres quotidiens avec des series et recompenses.",
    menu: "Menu",
    languageLabel: "Langue",
    navFeatures: "Fonctions",
    navProgress: "Progres",
    navScreens: "Ecrans",
    navPrivacy: "Confidentialite",
    navTerms: "Conditions",
    heroEyebrow: "Pratique des maths qui avance",
    heroTitle: "Scanne le probleme. Suis la lecon. Garde la serie.",
    heroCopy: "Kram transforme l'etude des maths en rythme quotidien avec resolution par camera, lecons structurees, recompenses et progres visibles.",
    featuresEyebrow: "Pourquoi les eleves l'utilisent",
    featuresTitle: "Une aide rapide aujourd'hui, une pratique reguliere demain.",
    feature1Title: "Scanne les maths en quelques secondes",
    feature1Copy: "Capture des problemes manuscrits ou imprimes et ouvre des solutions guidees quand tu as besoin d'aide.",
    feature2Title: "Apprends avec des lecons",
    feature2Copy: "Passe des notions de base aux sujets avances avec des parcours courts et structures.",
    feature3Title: "Reste motive",
    feature3Copy: "Suis tes series, termine des lecons, gagne des pieces et garde ton habitude de travail visible.",
    progressEyebrow: "Des progres lisibles",
    progressTitle: "Lecons, aide camera et recompenses au meme endroit.",
    progressCopy: "Ouvre un sujet, verifie tes lecons, consulte ta serie et reviens a la camera quand un probleme te bloque.",
    progressItem1: "Scans camera gratuits chaque jour avec un compte",
    progressItem2: "Les lecons restent toujours disponibles",
    progressItem3: "Les stats du profil rendent la regularite visible",
    today: "Aujourd'hui",
    lessonSummaryTitle: "Pratique de trigonometrie",
    lessonSummaryMeta: "Lecon guidee + progression de serie",
    screensEyebrow: "Ecrans et parcours d'etude",
    screensTitle: "Concu autour du vrai flux de travail d'un eleve.",
    screen1Title: "Tableau des lecons",
    screen1Copy: "Choisis un sujet de maths et suis ton avancement.",
    screen2Title: "Depart guide",
    screen2Copy: "Commence avec camera, lecons et series comme boucle principale.",
    screen3Title: "Sujets de lecons",
    screen3Copy: "Utilise des supports visuels en passant des bases aux maths avancees.",
    downloadEyebrow: "Commence par un probleme",
    downloadTitle: "Ouvre Kram quand les devoirs ont besoin d'une etape plus claire.",
    privacyPolicy: "Politique de confidentialite",
    termsOfUse: "Conditions d'utilisation",
    toast: "500 eleves travaillent la trigonometrie en ce moment 📚",
    appStoreAlt: "Telecharger Kram sur l'App Store",
    privacyPageTitle: "Politique de confidentialite | Kram",
    privacyMetaDescription: "Politique de confidentialite pour l'app Kram.",
    termsPageTitle: "Conditions d'utilisation | Kram",
    termsMetaDescription: "Conditions d'utilisation pour l'app Kram.",
    legalEffectiveDate: "En vigueur le 13 avril 2026",
    privacyTitle: "Politique de confidentialite",
    privacyIntro: "Kram aide les eleves a apprendre les maths avec des scans camera, des lecons, des comptes, le suivi des progres et des abonnements. Cette politique explique quelles informations sont traitees et comment elles sont utilisees.",
    privacyInfoTitle: "Informations collectees",
    privacyInfoCopy: "Kram peut collecter des details de compte comme le nom, le nom d'utilisateur, l'adresse e-mail, la photo de profil, les identifiants de connexion, le niveau de maths et le statut d'abonnement. L'app peut aussi traiter des problemes de maths, des images capturees, des saisies tapees, des etapes de solution generees, l'activite des lecons, les series, le solde de pieces, les reglages, les demandes de support et des donnees de diagnostic de base.",
    privacyCameraTitle: "Utilisation de la camera et des photos",
    privacyCameraCopy: "L'acces a la camera et a la phototheque sert a scanner ou selectionner des images de problemes de maths. Les images et le texte reconnu peuvent etre traites pour generer des explications, des etapes de solution, des entrees d'historique et des liens partageables lorsque tu choisis d'utiliser ces fonctions.",
    privacyUseTitle: "Utilisation des informations",
    privacyUseCopy: "Les informations sont utilisees pour fournir les lecons, resoudre des problemes de maths, sauvegarder les progres, gerer les comptes, maintenir les series et recompenses, traiter les abonnements, repondre au support, ameliorer la fiabilite, prevenir les abus et securiser l'app.",
    privacyServicesTitle: "Services tiers",
    privacyServicesCopy: "Kram peut utiliser des services comme Firebase, Google Sign-In, Apple Sign-In, StoreKit, analytics, hosting et infrastructure de paiement. Ces services traitent les informations selon leurs propres conditions de confidentialite et de securite.",
    privacySharingTitle: "Partage",
    privacySharingCopy: "Les informations personnelles ne sont pas vendues. Les informations peuvent etre partagees avec des prestataires qui exploitent l'app, respectent la loi, protegent les utilisateurs, traitent les achats ou fournissent une fonction demandee par l'utilisateur, comme un lien de solution partage.",
    privacyRetentionTitle: "Conservation",
    privacyRetentionCopy: "Les informations sont conservees aussi longtemps que necessaire pour fournir l'app, maintenir la securite, respecter les obligations legales ou prendre en charge les dossiers de compte et d'abonnement. Les utilisateurs peuvent demander la suppression lorsque cela s'applique.",
    privacyChoicesTitle: "Choix",
    privacyChoicesCopy: "Les autorisations de l'appareil pour la camera et la phototheque peuvent etre gerees dans les reglages systeme. Les informations de compte et de profil peuvent etre mises a jour dans l'app. Les reglages d'abonnement sont geres via l'App Store.",
    privacyChildrenTitle: "Enfants",
    privacyChildrenCopy: "Kram est concu pour les eleves et les personnes qui apprennent. Les utilisateurs doivent utiliser l'app avec l'accompagnement d'un parent ou tuteur lorsque la loi locale l'exige.",
    privacyContactTitle: "Contact",
    privacyContactCopy: "Pour les demandes ou questions de confidentialite, contacte l'equipe Kram via le canal de support dans l'app ou le contact public du proprietaire du projet.",
    termsTitle: "Conditions d'utilisation",
    termsIntro: "Ces conditions regissent l'utilisation de Kram, une app d'apprentissage des maths avec lecons, resolution par camera, suivi des progres, recompenses, comptes et abonnements optionnels.",
    termsUseTitle: "Utilisation de Kram",
    termsUseCopy: "Kram est fourni pour l'apprentissage et le soutien a l'etude. Les utilisateurs sont responsables de leur utilisation de l'app et du respect des regles scolaires, d'examen et d'integrite academique.",
    termsAccountsTitle: "Comptes",
    termsAccountsCopy: "Certaines fonctions necessitent un compte. Les informations du compte doivent etre assez exactes pour faire fonctionner le service, et les utilisateurs sont responsables de l'activite de leur compte.",
    termsSolutionsTitle: "Solutions de maths",
    termsSolutionsCopy: "Les scans camera et les etapes de solution generees sont des aides a l'etude. Les resultats peuvent etre incomplets ou incorrects, surtout lorsque les images sont floues, recadrees, manuscrites de facon peu claire ou contiennent une notation ambigue. Les utilisateurs doivent verifier les resultats avant de s'y fier.",
    termsPurchasesTitle: "Abonnements et achats",
    termsPurchasesCopy: "Des fonctions payantes optionnelles peuvent etre proposees via l'App Store. Les achats, renouvellements, annulations, remboursements et la facturation sont geres par Apple selon les conditions de l'App Store.",
    termsContentTitle: "Contenu utilisateur",
    termsContentCopy: "Les utilisateurs peuvent envoyer des images de problemes de maths, des problemes tapes, des details de profil et du contenu de support. Les utilisateurs ne doivent pas envoyer d'informations illegales, nuisibles, contrefaisantes ou privees de tiers sans autorisation.",
    termsAcceptableTitle: "Utilisation acceptable",
    termsAcceptableCopy: "Les utilisateurs ne peuvent pas abuser du service, tenter de perturber l'app ou le backend, faire de l'ingenierie inverse sur des parties restreintes du service, contourner des limites, automatiser des abus ou utiliser Kram pour enfreindre des lois ou des droits de tiers.",
    termsChangesTitle: "Modifications du service",
    termsChangesCopy: "Les fonctions, limites, recompenses, contenus de lecon, abonnements et disponibilite peuvent changer avec le temps. Kram peut etre mis a jour, suspendu ou arrete si necessaire.",
    termsWarrantyTitle: "Aucune garantie",
    termsWarrantyCopy: "Kram est fourni tel que disponible. Dans la mesure maximale permise par la loi, aucune garantie n'est donnee que l'app sera toujours disponible, sans erreur ou adaptee a un resultat d'apprentissage particulier.",
    termsContactTitle: "Contact",
    termsContactCopy: "Pour toute question sur ces conditions, contacte l'equipe Kram via le canal de support dans l'app ou le contact public du proprietaire du projet.",
  },
  uz: {
    pageTitle: "Kram | Skanlar, darslar va seriyalar bilan matematika organing",
    metaDescription: "Kram oquvchilarga matematika masalalarini skan qilish, tuzilgan darslarni otish va kunlik yutuqlarni seriyalar hamda mukofotlar bilan kuzatishga yordam beradi.",
    menu: "Menyu",
    languageLabel: "Til",
    navFeatures: "Imkoniyatlar",
    navProgress: "Rivojlanish",
    navScreens: "Ekranlar",
    navPrivacy: "Maxfiylik",
    navTerms: "Shartlar",
    heroEyebrow: "Har kuni davom etadigan matematika mashqi",
    heroTitle: "Masalani skan qiling. Darsni kuzating. Seriyani saqlang.",
    heroCopy: "Kram kamerada yechish, tuzilgan darslar, mukofotlar va korinadigan rivojlanish orqali matematikani kunlik odatga aylantiradi.",
    featuresEyebrow: "Nega oquvchilar undan foydalanadi",
    featuresTitle: "Bugun tez yordam, ertaga barqaror mashq.",
    feature1Title: "Matematikani soniyalarda skan qiling",
    feature1Copy: "Qo'lda yozilgan yoki chop etilgan masalalarni suratga oling va kerak paytda bosqichma-bosqich yechimni oching.",
    feature2Title: "Darslar orqali organing",
    feature2Copy: "Asosiy tushunchalardan murakkab mavzulargacha qisqa va tartibli yo'llar bilan o'ting.",
    feature3Title: "Motivatsiyani saqlang",
    feature3Copy: "Seriyalarni kuzating, darslarni yakunlang, tangalar to'plang va o'qish odatingizni ko'rinadigan qiling.",
    progressEyebrow: "Aniq rivojlanish",
    progressTitle: "Darslar, kamera yordami va mukofotlar bitta joyda.",
    progressCopy: "Mavzuni oching, darslar sonini tekshiring, seriyangizni ko'ring va masala qiyinlashsa kameraga qayting.",
    progressItem1: "Account bilan har kuni bepul kamera skanlari",
    progressItem2: "Darslar doim mavjud",
    progressItem3: "Profil statistikasi muntazamlikni ko'rsatadi",
    today: "Bugun",
    lessonSummaryTitle: "Trigonometriya mashqi",
    lessonSummaryMeta: "Yo'naltirilgan dars + seriya rivoji",
    screensEyebrow: "Ekranlar va o'qish jarayoni",
    screensTitle: "O'quvchining haqiqiy ish jarayoni atrofida qurilgan.",
    screen1Title: "Darslar paneli",
    screen1Copy: "Matematika mavzusini tanlang va yakunlanishni kuzating.",
    screen2Title: "Yo'naltirilgan start",
    screen2Copy: "Kamera, darslar va seriyalar asosiy odat sifatida boshlanadi.",
    screen3Title: "Dars mavzulari",
    screen3Copy: "Asoslardan yuqori matematikagacha o'tishda vizual materiallardan foydalaning.",
    downloadEyebrow: "Bitta masaladan boshlang",
    downloadTitle: "Uy vazifasi aniqroq keyingi qadam talab qilganda Kramni oching.",
    privacyPolicy: "Maxfiylik siyosati",
    termsOfUse: "Foydalanish shartlari",
    toast: "500 oquvchi hozir Trigonometriya mashq qilmoqda 📚",
    appStoreAlt: "Kramni App Store'dan yuklab oling",
    privacyPageTitle: "Maxfiylik siyosati | Kram",
    privacyMetaDescription: "Kram ilovasi uchun maxfiylik siyosati.",
    termsPageTitle: "Foydalanish shartlari | Kram",
    termsMetaDescription: "Kram ilovasi uchun foydalanish shartlari.",
    legalEffectiveDate: "2026-yil 13-apreldan amal qiladi",
    privacyTitle: "Maxfiylik siyosati",
    privacyIntro: "Kram oquvchilarga kamera skanlari, darslar, accountlar, rivojlanish kuzatuvi va obunalar orqali matematika organishga yordam beradi. Bu siyosat qaysi malumotlar ishlanishi va ular qanday ishlatilishini tushuntiradi.",
    privacyInfoTitle: "Biz yig'adigan malumotlar",
    privacyInfoCopy: "Kram ism, username, email manzil, profil rasmi, kirish identifikatorlari, matematika darajasi va obuna holati kabi account malumotlarini yig'ishi mumkin. Ilova matematika masalalari, olingan rasmlar, kiritilgan matnlar, yaratilgan yechim qadamlari, dars faolligi, seriyalar, tanga balansi, sozlamalar, support so'rovlari va asosiy diagnostika malumotlarini ham qayta ishlashi mumkin.",
    privacyCameraTitle: "Kamera va rasmlardan foydalanish",
    privacyCameraCopy: "Kamera va foto kutubxonasiga kirish matematika masalalari rasmlarini skan qilish yoki tanlash uchun ishlatiladi. Rasmlar va tanib olingan matn tushuntirishlar, yechim qadamlari, tarix yozuvlari va ulashish havolalarini yaratish uchun qayta ishlanishi mumkin.",
    privacyUseTitle: "Malumotlar qanday ishlatiladi",
    privacyUseCopy: "Malumotlar darslarni taqdim etish, matematika masalalarini yechish, rivojlanishni saqlash, accountlarni boshqarish, seriyalar va mukofotlarni yuritish, obunalarni qayta ishlash, support so'rovlariga javob berish, ishonchlilikni yaxshilash, suiiste'molni oldini olish va ilovani xavfsiz saqlash uchun ishlatiladi.",
    privacyServicesTitle: "Uchinchi tomon xizmatlari",
    privacyServicesCopy: "Kram Firebase, Google Sign-In, Apple Sign-In, StoreKit, analytics, hosting va to'lov infratuzilmasi kabi xizmatlardan foydalanishi mumkin. Bu xizmatlar malumotlarni o'z maxfiylik va xavfsizlik shartlari asosida qayta ishlaydi.",
    privacySharingTitle: "Ulashish",
    privacySharingCopy: "Shaxsiy malumotlar sotilmaydi. Malumotlar ilovani yuritadigan, qonunga rioya qiladigan, foydalanuvchilarni himoya qiladigan, xaridlarni qayta ishlaydigan yoki foydalanuvchi so'ragan funksiyani yetkazadigan xizmat ko'rsatuvchilar bilan ulashilishi mumkin.",
    privacyRetentionTitle: "Saqlash",
    privacyRetentionCopy: "Malumotlar ilovani taqdim etish, xavfsizlikni saqlash, huquqiy majburiyatlarga rioya qilish yoki account va obuna yozuvlarini qo'llab-quvvatlash uchun kerak bo'lgan muddat davomida saqlanadi. Foydalanuvchilar tegishli hollarda o'chirishni so'rashi mumkin.",
    privacyChoicesTitle: "Tanlovlar",
    privacyChoicesCopy: "Kamera va foto kutubxonasi uchun qurilma ruxsatlarini tizim sozlamalarida boshqarish mumkin. Account va profil malumotlarini ilova ichida yangilash mumkin. Obuna sozlamalari App Store orqali boshqariladi.",
    privacyChildrenTitle: "Bolalar",
    privacyChildrenCopy: "Kram oquvchilar va organuvchilar uchun mo'ljallangan. Mahalliy qonun talab qilganda foydalanuvchilar ilovadan ota-ona yoki vasiy ishtirokida foydalanishi kerak.",
    privacyContactTitle: "Aloqa",
    privacyContactCopy: "Maxfiylik bo'yicha so'rovlar yoki savollar uchun ilovadagi support kanali yoki loyiha egasining ochiq aloqa manzili orqali Kram jamoasiga murojaat qiling.",
    termsTitle: "Foydalanish shartlari",
    termsIntro: "Ushbu shartlar darslar, kamera orqali yechish, rivojlanish kuzatuvi, mukofotlar, accountlar va ixtiyoriy obunalarni o'z ichiga olgan Kram matematika o'quv ilovasidan foydalanishni tartibga soladi.",
    termsUseTitle: "Kramdan foydalanish",
    termsUseCopy: "Kram o'rganish va o'qishga yordam berish uchun taqdim etiladi. Foydalanuvchilar ilovadan qanday foydalanishi hamda maktab, imtihon va akademik halollik qoidalariga rioya qilishi uchun javobgardir.",
    termsAccountsTitle: "Accountlar",
    termsAccountsCopy: "Ba'zi funksiyalar account talab qiladi. Account malumotlari xizmatni yuritish uchun yetarlicha aniq bo'lishi kerak, foydalanuvchilar esa o'z accountidagi faollik uchun javobgardir.",
    termsSolutionsTitle: "Matematik yechimlar",
    termsSolutionsCopy: "Kamera skanlari va yaratilgan yechim qadamlari o'qishga yordamchi vositalardir. Natijalar to'liq bo'lmasligi yoki noto'g'ri bo'lishi mumkin, ayniqsa rasmlar xira, kesilgan, qo'lda noaniq yozilgan yoki noaniq belgilarni o'z ichiga olgan bo'lsa. Foydalanuvchilar natijalarga tayanishdan oldin ularni tekshirishi kerak.",
    termsPurchasesTitle: "Obunalar va xaridlar",
    termsPurchasesCopy: "Ixtiyoriy pullik funksiyalar App Store orqali taklif qilinishi mumkin. Xaridlar, yangilanishlar, bekor qilish, pul qaytarish va hisob-kitoblar Apple tomonidan App Store shartlariga muvofiq boshqariladi.",
    termsContentTitle: "Foydalanuvchi kontenti",
    termsContentCopy: "Foydalanuvchilar matematika masalalari rasmlari, kiritilgan masalalar, profil tafsilotlari va support kontentini yuborishi mumkin. Foydalanuvchilar noqonuniy, zararli, huquqni buzuvchi yoki uchinchi shaxslarning shaxsiy malumotlarini ruxsatsiz yubormasligi kerak.",
    termsAcceptableTitle: "Maqbul foydalanish",
    termsAcceptableCopy: "Foydalanuvchilar xizmatni suiiste'mol qilmasligi, ilova yoki backend ishini buzishga urinmasligi, xizmatning cheklangan qismlarini reverse engineer qilmasligi, limitlarni aylanib o'tmasligi, suiiste'molni avtomatlashtirmasligi yoki Kramdan qonunlar yoki uchinchi tomon huquqlarini buzish uchun foydalanmasligi kerak.",
    termsChangesTitle: "Xizmatdagi o'zgarishlar",
    termsChangesCopy: "Funksiyalar, limitlar, mukofotlar, dars kontenti, obunalar va mavjudlik vaqt o'tishi bilan o'zgarishi mumkin. Kram kerak bo'lganda yangilanishi, vaqtincha to'xtatilishi yoki tugatilishi mumkin.",
    termsWarrantyTitle: "Kafolat yo'q",
    termsWarrantyCopy: "Kram mavjud holatida taqdim etiladi. Qonun ruxsat bergan maksimal darajada ilova har doim mavjud, xatosiz yoki muayyan o'quv natijasiga mos bo'lishi kafolatlanmaydi.",
    termsContactTitle: "Aloqa",
    termsContactCopy: "Ushbu shartlar bo'yicha savollar uchun ilovadagi support kanali yoki loyiha egasining ochiq aloqa manzili orqali Kram jamoasiga murojaat qiling.",
  },
  ru: {
    pageTitle: "Kram | Учите математику со сканами, уроками и сериями",
    metaDescription: "Kram помогает ученикам сканировать задачи по математике, проходить структурированные уроки и видеть ежедневный прогресс через серии и награды.",
    menu: "Меню",
    languageLabel: "Язык",
    navFeatures: "Функции",
    navProgress: "Прогресс",
    navScreens: "Экраны",
    navPrivacy: "Privacy",
    navTerms: "Условия",
    heroEyebrow: "Практика математики каждый день",
    heroTitle: "Сканируй задачу. Следуй уроку. Держи серию.",
    heroCopy: "Kram превращает изучение математики в ежедневный ритм: решения с камеры, структурированные уроки, награды и видимый прогресс.",
    featuresEyebrow: "Почему ученики выбирают Kram",
    featuresTitle: "Быстрая помощь сегодня, стабильная практика завтра.",
    feature1Title: "Сканируй математику за секунды",
    feature1Copy: "Снимай рукописные или печатные задачи и открывай пошаговые решения, когда нужна подсказка.",
    feature2Title: "Учись по урокам",
    feature2Copy: "Проходи путь от базовых понятий до продвинутых тем через короткие структурированные уроки.",
    feature3Title: "Сохраняй мотивацию",
    feature3Copy: "Отслеживай серии, завершай уроки, собирай монеты и держи учебную привычку на виду.",
    progressEyebrow: "Понятный прогресс",
    progressTitle: "Уроки, помощь камеры и награды в одном месте.",
    progressCopy: "Открывай тему, проверяй количество уроков, смотри серию и возвращайся к камере, когда задача тормозит.",
    progressItem1: "Бесплатные ежедневные сканы с аккаунтом",
    progressItem2: "Уроки доступны всегда",
    progressItem3: "Статистика профиля показывает регулярность",
    today: "Сегодня",
    lessonSummaryTitle: "Практика тригонометрии",
    lessonSummaryMeta: "Урок с подсказками + прогресс серии",
    screensEyebrow: "Экраны и процесс обучения",
    screensTitle: "Создано вокруг реального учебного сценария.",
    screen1Title: "Панель уроков",
    screen1Copy: "Выбирай тему по математике и отслеживай завершение.",
    screen2Title: "Понятный старт",
    screen2Copy: "Начни с камеры, уроков и серий как основного цикла.",
    screen3Title: "Темы уроков",
    screen3Copy: "Используй визуальные материалы на пути от основ к продвинутой математике.",
    downloadEyebrow: "Начни с одной задачи",
    downloadTitle: "Открывай Kram, когда домашней работе нужен более понятный следующий шаг.",
    privacyPolicy: "Политика конфиденциальности",
    termsOfUse: "Условия использования",
    toast: "500 учеников прямо сейчас практикуют тригонометрию 📚",
    appStoreAlt: "Скачать Kram в App Store",
    privacyPageTitle: "Политика конфиденциальности | Kram",
    privacyMetaDescription: "Политика конфиденциальности для приложения Kram.",
    termsPageTitle: "Условия использования | Kram",
    termsMetaDescription: "Условия использования для приложения Kram.",
    legalEffectiveDate: "Действует с 13 апреля 2026 года",
    privacyTitle: "Политика конфиденциальности",
    privacyIntro: "Kram помогает ученикам изучать математику с помощью сканов камеры, уроков, аккаунтов, отслеживания прогресса и подписок. Эта политика объясняет, какие данные обрабатываются и как они используются.",
    privacyInfoTitle: "Какие данные мы собираем",
    privacyInfoCopy: "Kram может собирать данные аккаунта, такие как имя, имя пользователя, адрес электронной почты, фото профиля, идентификаторы входа, уровень математики и статус подписки. Приложение также может обрабатывать математические задачи, сделанные изображения, введенный текст, созданные шаги решения, активность в уроках, серии, баланс монет, настройки, обращения в поддержку и базовые диагностические данные.",
    privacyCameraTitle: "Использование камеры и фото",
    privacyCameraCopy: "Доступ к камере и фотобиблиотеке используется для сканирования или выбора изображений математических задач. Изображения и распознанный текст могут обрабатываться для создания объяснений, шагов решения, записей истории и ссылок для обмена, когда вы выбираете эти функции.",
    privacyUseTitle: "Как используются данные",
    privacyUseCopy: "Данные используются для предоставления уроков, решения математических задач, сохранения прогресса, управления аккаунтами, поддержки серий и наград, обработки подписок, ответа на обращения в поддержку, повышения надежности, предотвращения злоупотреблений и защиты приложения.",
    privacyServicesTitle: "Сторонние сервисы",
    privacyServicesCopy: "Kram может использовать сервисы, такие как Firebase, Google Sign-In, Apple Sign-In, StoreKit, аналитика, хостинг и платежная инфраструктура. Эти сервисы обрабатывают данные согласно собственным условиям конфиденциальности и безопасности.",
    privacySharingTitle: "Передача данных",
    privacySharingCopy: "Персональная информация не продается. Данные могут передаваться поставщикам услуг, которые обеспечивают работу приложения, соблюдают закон, защищают пользователей, обрабатывают покупки или предоставляют функцию, запрошенную пользователем, например ссылку на решение.",
    privacyRetentionTitle: "Хранение",
    privacyRetentionCopy: "Данные хранятся столько, сколько необходимо для предоставления приложения, поддержания безопасности, соблюдения юридических обязательств или ведения записей аккаунтов и подписок. Пользователи могут запросить удаление, когда это применимо.",
    privacyChoicesTitle: "Выбор пользователя",
    privacyChoicesCopy: "Разрешения устройства для камеры и фотобиблиотеки можно управлять в системных настройках. Данные аккаунта и профиля можно обновлять в приложении. Настройки подписки управляются через App Store.",
    privacyChildrenTitle: "Дети",
    privacyChildrenCopy: "Kram предназначен для учеников и людей, которые учатся. Пользователи должны использовать приложение с участием родителя или опекуна, когда это требуется местным законом.",
    privacyContactTitle: "Контакты",
    privacyContactCopy: "По вопросам конфиденциальности свяжитесь с командой Kram через канал поддержки в приложении или опубликованный контакт владельца проекта.",
    termsTitle: "Условия использования",
    termsIntro: "Эти условия регулируют использование Kram, приложения для изучения математики с уроками, решением через камеру, отслеживанием прогресса, наградами, аккаунтами и дополнительными подписками.",
    termsUseTitle: "Использование Kram",
    termsUseCopy: "Kram предоставляется для обучения и помощи в учебе. Пользователи отвечают за то, как используют приложение, и за соблюдение школьных, экзаменационных правил и правил академической честности.",
    termsAccountsTitle: "Аккаунты",
    termsAccountsCopy: "Для некоторых функций требуется аккаунт. Данные аккаунта должны быть достаточно точными для работы сервиса, а пользователи отвечают за активность в своем аккаунте.",
    termsSolutionsTitle: "Математические решения",
    termsSolutionsCopy: "Сканы камеры и созданные шаги решения являются учебными подсказками. Результаты могут быть неполными или неверными, особенно если изображения размыты, обрезаны, написаны от руки нечетко или содержат неоднозначную запись. Пользователи должны проверять результаты, прежде чем полагаться на них.",
    termsPurchasesTitle: "Подписки и покупки",
    termsPurchasesCopy: "Дополнительные платные функции могут предлагаться через App Store. Покупки, продления, отмена, возвраты и выставление счетов обрабатываются Apple согласно условиям App Store.",
    termsContentTitle: "Пользовательский контент",
    termsContentCopy: "Пользователи могут отправлять изображения математических задач, введенные задачи, данные профиля и материалы поддержки. Пользователи не должны отправлять незаконную, вредоносную, нарушающую права или частную информацию третьих лиц без разрешения.",
    termsAcceptableTitle: "Допустимое использование",
    termsAcceptableCopy: "Пользователи не могут злоупотреблять сервисом, пытаться нарушить работу приложения или backend, выполнять обратную разработку закрытых частей сервиса, обходить лимиты, автоматизировать злоупотребления или использовать Kram для нарушения законов или прав третьих лиц.",
    termsChangesTitle: "Изменения сервиса",
    termsChangesCopy: "Функции, лимиты, награды, содержание уроков, подписки и доступность могут меняться со временем. Kram может обновляться, приостанавливаться или прекращаться при необходимости.",
    termsWarrantyTitle: "Без гарантии",
    termsWarrantyCopy: "Kram предоставляется в доступном виде. В максимально допустимой законом степени не гарантируется, что приложение всегда будет доступно, без ошибок или подходит для конкретного учебного результата.",
    termsContactTitle: "Контакты",
    termsContactCopy: "По вопросам об этих условиях свяжитесь с командой Kram через канал поддержки в приложении или опубликованный контакт владельца проекта.",
  },
};

const appStoreBadges = {
  en: "assets/app/app-store-en.svg",
  it: "assets/app/app-store-it.svg",
  sp: "assets/app/app-store-sp.svg",
  fr: "assets/app/app-store-fr.svg",
  uz: "assets/app/app-store-uz.svg",
  ru: "assets/app/app-store-ru.svg",
};

const htmlLang = {
  en: "en",
  it: "it",
  sp: "es",
  fr: "fr",
  uz: "uz",
  ru: "ru",
};

const pageTitleKeys = {
  home: "pageTitle",
  privacy: "privacyPageTitle",
  terms: "termsPageTitle",
};

const metaDescriptionKeys = {
  home: "metaDescription",
  privacy: "privacyMetaDescription",
  terms: "termsMetaDescription",
};

const readStoredLanguage = () => {
  try {
    return window.localStorage.getItem("kramLandingLanguage");
  } catch {
    return null;
  }
};

const writeStoredLanguage = (language) => {
  try {
    window.localStorage.setItem("kramLandingLanguage", language);
  } catch {}
};

const resolveInitialLanguage = () => {
  const stored = readStoredLanguage();
  if (stored && translations[stored]) {
    return stored;
  }

  const browserLanguage = (navigator.language || "en").toLowerCase();
  if (browserLanguage.startsWith("it")) return "it";
  if (browserLanguage.startsWith("es")) return "sp";
  if (browserLanguage.startsWith("fr")) return "fr";
  if (browserLanguage.startsWith("uz")) return "uz";
  if (browserLanguage.startsWith("ru")) return "ru";
  return "en";
};

const applyLanguage = (language) => {
  const nextLanguage = translations[language] ? language : "en";
  const dictionary = translations[nextLanguage];
  const page = document.body?.dataset.page || "home";
  const titleKey = pageTitleKeys[page] || pageTitleKeys.home;
  const descriptionKey = metaDescriptionKeys[page] || metaDescriptionKeys.home;

  document.documentElement.lang = htmlLang[nextLanguage];
  document.title = dictionary[titleKey] || dictionary.pageTitle;
  metaDescription?.setAttribute("content", dictionary[descriptionKey] || dictionary.metaDescription);

  document.querySelectorAll("[data-i18n]").forEach((element) => {
    const key = element.getAttribute("data-i18n");
    if (key && dictionary[key]) {
      element.textContent = dictionary[key];
    }
  });

  document.querySelectorAll(".app-store-button").forEach((button) => {
    button.setAttribute("aria-label", dictionary.appStoreAlt);
  });

  document.querySelectorAll("[data-app-store-badge]").forEach((badge) => {
    badge.setAttribute("src", appStoreBadges[nextLanguage]);
    badge.setAttribute("alt", dictionary.appStoreAlt);
  });

  if (languageSelect) {
    languageSelect.value = nextLanguage;
  }

  writeStoredLanguage(nextLanguage);
};

if (languageSelect) {
  ["change", "input"].forEach((eventName) => {
    languageSelect.addEventListener(eventName, () => {
      applyLanguage(languageSelect.value);
    });
  });
}

document.addEventListener("change", (event) => {
  if (event.target === languageSelect) {
    applyLanguage(languageSelect.value);
  }
});

window.KramLanding = {
  setLanguage: applyLanguage,
};

applyLanguage(resolveInitialLanguage());

const revealItems = document.querySelectorAll(
  ".section-heading, .feature-card, .showcase-copy, .lesson-panel, .screen-card, .download-band > *"
);

if (menuToggle && siteNav) {
  menuToggle.addEventListener("click", () => {
    const isOpen = menuToggle.getAttribute("aria-expanded") === "true";
    menuToggle.setAttribute("aria-expanded", String(!isOpen));
    siteNav.classList.toggle("is-open", !isOpen);
  });

  siteNav.addEventListener("click", (event) => {
    if (event.target instanceof HTMLAnchorElement) {
      menuToggle.setAttribute("aria-expanded", "false");
      siteNav.classList.remove("is-open");
    }
  });
}

if ("IntersectionObserver" in window) {
  const revealObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          revealObserver.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.16 }
  );

  revealItems.forEach((item, index) => {
    item.classList.add("reveal");
    item.style.setProperty("--reveal-delay", `${(index % 4) * 90}ms`);
    revealObserver.observe(item);
  });
} else {
  revealItems.forEach((item) => item.classList.add("is-visible"));
}

if (hero) {
  hero.addEventListener("pointermove", (event) => {
    const rect = hero.getBoundingClientRect();
    const x = (event.clientX - rect.left) / rect.width - 0.5;
    const y = (event.clientY - rect.top) / rect.height - 0.5;
    hero.style.setProperty("--parallax-x", (x * 34).toFixed(2));
    hero.style.setProperty("--parallax-y", (y * 28).toFixed(2));
  });

  hero.addEventListener("pointerleave", () => {
    hero.style.setProperty("--parallax-x", "0");
    hero.style.setProperty("--parallax-y", "0");
  });
}

if (toast) {
  window.setTimeout(() => {
    toast.classList.add("is-visible");
  }, 3000);

  window.setTimeout(() => {
    toast.classList.remove("is-visible");
  }, 12000);
}

if (cursorGlow && window.matchMedia("(pointer: fine)").matches) {
  let cursorX = -50;
  let cursorY = -50;
  let glowX = -50;
  let glowY = -50;

  window.addEventListener("pointermove", (event) => {
    cursorX = event.clientX;
    cursorY = event.clientY;
  });

  document.addEventListener("pointerover", (event) => {
    const target = event.target;
    const isInteractive = target instanceof Element && target.closest("a, button, .feature-card, .screen-card");
    cursorGlow.classList.toggle("is-active", Boolean(isInteractive));
  });

  const renderCursor = () => {
    glowX += (cursorX - glowX) * 0.16;
    glowY += (cursorY - glowY) * 0.16;
    cursorGlow.style.transform = `translate3d(${glowX - 13}px, ${glowY - 13}px, 0)`;
    window.requestAnimationFrame(renderCursor);
  };

  renderCursor();
}

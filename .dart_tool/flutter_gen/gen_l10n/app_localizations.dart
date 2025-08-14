import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Delf App'**
  String get appTitle;

  /// Etiqueta para aceptar
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get accept;

  /// Etiqueta para la fecha de nacimiento
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento:'**
  String get birthDate;

  /// Etiqueta para el botón de llamada
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get callButton;

  /// Etiqueta para el tono de llamada
  ///
  /// In es, this message translates to:
  /// **'Tono de llamada:'**
  String get callTone;

  /// Etiqueta para cancelar
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// Título para la sección de chat
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Etiqueta para documento adjunto simulado en chat
  ///
  /// In es, this message translates to:
  /// **'Documento adjunto (simulado)'**
  String get chatAttachDoc;

  /// Opción para adjuntar documento en chat
  ///
  /// In es, this message translates to:
  /// **'Doc'**
  String get chatAttachOptionDoc;

  /// Opción para adjuntar foto en chat
  ///
  /// In es, this message translates to:
  /// **'Foto'**
  String get chatAttachOptionPhoto;

  /// Opción para adjuntar video en chat
  ///
  /// In es, this message translates to:
  /// **'Video'**
  String get chatAttachOptionVideo;

  /// Mensaje de foto adjunta con nombre de archivo en chat
  ///
  /// In es, this message translates to:
  /// **'Foto adjunta: {filename}'**
  String chatAttachPhoto(String filename);

  /// Mensaje de video adjunto con nombre de archivo en chat
  ///
  /// In es, this message translates to:
  /// **'Video adjunto: {filename}'**
  String chatAttachVideo(String filename);

  /// Mensaje para audio enviado simulado en chat
  ///
  /// In es, this message translates to:
  /// **'Audio enviado (simulado)'**
  String get chatAudioSim;

  /// Mensaje para foto tomada con cámara en chat
  ///
  /// In es, this message translates to:
  /// **'Foto con cámara: {filename}'**
  String chatCameraPhoto(String filename);

  /// Mensaje para video tomado con cámara en chat
  ///
  /// In es, this message translates to:
  /// **'Video con cámara: {filename}'**
  String chatCameraVideo(String filename);

  /// Notificación de inicio de llamada en chat
  ///
  /// In es, this message translates to:
  /// **'Llamada iniciada'**
  String get chatCallStarted;

  /// Etiqueta para cancelar acción en chat
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get chatCancel;

  /// Formato de fecha para el chat
  ///
  /// In es, this message translates to:
  /// **'dd/MM/yyyy'**
  String get chatDateFormat;

  /// Mensaje para documento adjunto simulado en chat
  ///
  /// In es, this message translates to:
  /// **'Documento adjunto (simulado)'**
  String get chatDocSim;

  /// Advertencia de edición expirada en chat
  ///
  /// In es, this message translates to:
  /// **'El mensaje ya no se puede editar.'**
  String get chatEditExpired;

  /// Sugerencia para editar mensaje en chat
  ///
  /// In es, this message translates to:
  /// **'Nuevo mensaje'**
  String get chatEditHint;

  /// Botón para guardar edición de mensaje en chat
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get chatEditSave;

  /// Título para la edición de mensaje en chat
  ///
  /// In es, this message translates to:
  /// **'Editar mensaje'**
  String get chatEditTitle;

  /// Texto de sugerencia en el campo de chat
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get chatHintText;

  /// Mensaje al acceder a la configuración desde chat
  ///
  /// In es, this message translates to:
  /// **'Accediendo a configuración'**
  String get chatOpenSettings;

  /// Botón para guardar mensaje en chat
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get chatSave;

  /// Texto de sugerencia en búsqueda de mensajes en chat
  ///
  /// In es, this message translates to:
  /// **'Buscar mensajes...'**
  String get chatSearchHint;

  /// Botón para enviar mensaje en chat
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get chatSend;

  /// Formato de hora para el chat
  ///
  /// In es, this message translates to:
  /// **'HH:mm'**
  String get chatTimeFormat;

  /// Notificación de traducción en chat con texto traducido
  ///
  /// In es, this message translates to:
  /// **'Traducción: {translatedText}'**
  String chatTranslationToast(String translatedText);

  /// Notificación de inicio de videollamada en chat
  ///
  /// In es, this message translates to:
  /// **'Videollamada iniciada'**
  String get chatVideoCallStarted;

  /// Etiqueta para comentarios pendientes
  ///
  /// In es, this message translates to:
  /// **'Comentarios (pendiente)'**
  String get commentsPending;

  /// Mensaje de confirmación para cerrar sesión
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cerrar sesión?'**
  String get confirmLogoutMessage;

  /// Etiqueta para crear un nuevo grupo
  ///
  /// In es, this message translates to:
  /// **'Crear Grupo'**
  String get createGroup;

  /// Opción para activar el tema oscuro
  ///
  /// In es, this message translates to:
  /// **'Tema oscuro'**
  String get darkMode;

  /// Etiqueta para el nombre completo
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get fullName;

  /// Enlace o mensaje para recuperar contraseña olvidada
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// Título para la sección de grupos
  ///
  /// In es, this message translates to:
  /// **'Grupos'**
  String get groups;

  /// Etiqueta para modo incógnito de pago
  ///
  /// In es, this message translates to:
  /// **'Modo incógnito (requiere pago)'**
  String get incognitoPaidLabel;

  /// Mensaje para solicitar pago del modo incógnito
  ///
  /// In es, this message translates to:
  /// **'Debes pagar para activar el Modo Incógnito. ¿Deseas continuar?'**
  String get incognitoPaymentPrompt;

  /// Mensaje de éxito al activar modo incógnito tras el pago
  ///
  /// In es, this message translates to:
  /// **'Pago exitoso. Modo Incógnito activado.'**
  String get incognitoPaymentSuccess;

  /// Etiqueta para seleccionar el idioma
  ///
  /// In es, this message translates to:
  /// **'Idioma:'**
  String get languageLabel;

  /// Botón para iniciar sesión
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginButton;

  /// Opción para cerrar sesión
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// Opción para iniciar una llamada de audio
  ///
  /// In es, this message translates to:
  /// **'Realizar llamada'**
  String get makeAudioCall;

  /// Opción para iniciar una videollamada
  ///
  /// In es, this message translates to:
  /// **'Realizar videollamada'**
  String get makeVideoCall;

  /// Etiqueta para seleccionar el tono de mensaje
  ///
  /// In es, this message translates to:
  /// **'Tono de mensaje:'**
  String get messageTone;

  /// Etiqueta para crear un nuevo grupo
  ///
  /// In es, this message translates to:
  /// **'Nuevo Grupo'**
  String get newGroup;

  /// Etiqueta para marcar contenido como nuevo
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get newLabel;

  /// Etiqueta para mostrar participantes en un grupo
  ///
  /// In es, this message translates to:
  /// **'Participantes:'**
  String get participantsLabel;

  /// Mensaje de error para contraseña vacía
  ///
  /// In es, this message translates to:
  /// **'Ingrese la contraseña'**
  String get passwordEmptyError;

  /// Etiqueta para el campo de contraseña
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// Mensaje de error por contraseña muy corta
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get passwordTooShortError;

  /// Etiqueta para el teléfono
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get phone;

  /// Etiqueta para el número de teléfono
  ///
  /// In es, this message translates to:
  /// **'Teléfono:'**
  String get phoneNumber;

  /// Título para la sección de perfil
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// Tooltip para acceso rápido en modo temporal
  ///
  /// In es, this message translates to:
  /// **'Acceso rápido (temporal, eliminar en producción)'**
  String get quickAccessTooltip;

  /// Mensaje indicando que un reel fue eliminado
  ///
  /// In es, this message translates to:
  /// **'Reel eliminado'**
  String get reelDeleted;

  /// Título para la sección de reels
  ///
  /// In es, this message translates to:
  /// **'Reels'**
  String get reels;

  /// Etiqueta para la fecha de nacimiento en registro
  ///
  /// In es, this message translates to:
  /// **'Fecha de Nacimiento'**
  String get registerBirthdate;

  /// Botón para registrarse
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get registerButton;

  /// Etiqueta para confirmar la contraseña en registro
  ///
  /// In es, this message translates to:
  /// **'Confirmar Contraseña'**
  String get registerConfirmPassword;

  /// Indicador para confirmar la contraseña
  ///
  /// In es, this message translates to:
  /// **'Confirme su contraseña'**
  String get registerEnterConfirmation;

  /// Indicador para ingresar el nombre en registro
  ///
  /// In es, this message translates to:
  /// **'Ingrese su nombre'**
  String get registerEnterName;

  /// Indicador para ingresar la contraseña en registro
  ///
  /// In es, this message translates to:
  /// **'Ingrese la contraseña'**
  String get registerEnterPassword;

  /// Indicador para ingresar un número de teléfono válido
  ///
  /// In es, this message translates to:
  /// **'Ingrese un número válido'**
  String get registerEnterPhone;

  /// Etiqueta para el nombre completo en registro
  ///
  /// In es, this message translates to:
  /// **'Nombre Completo'**
  String get registerFullName;

  /// Etiqueta para la contraseña en registro
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get registerPassword;

  /// Mensaje de error por contraseña demasiado corta en registro
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get registerPasswordTooShort;

  /// Mensaje de error cuando las contraseñas no coinciden en registro
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get registerPasswordsDontMatch;

  /// Etiqueta para el teléfono en registro
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get registerPhone;

  /// Mensaje de error por teléfono ya registrado en registro
  ///
  /// In es, this message translates to:
  /// **'El número de teléfono ya está registrado'**
  String get registerPhoneAlreadyUsed;

  /// Indicador para seleccionar la fecha de nacimiento en registro
  ///
  /// In es, this message translates to:
  /// **'Seleccione su fecha de nacimiento'**
  String get registerSelectBirthdate;

  /// Título de la pantalla de registro
  ///
  /// In es, this message translates to:
  /// **'Registro'**
  String get registerTitle;

  /// Mensaje indicando que se envió un código de verificación simulado en registro
  ///
  /// In es, this message translates to:
  /// **'Código de verificación enviado (simulado: 123456)'**
  String get registerVerificationSent;

  /// Llamado a la acción para registrarse
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get registerNow;

  /// Mensaje de ejemplo en chat 1
  ///
  /// In es, this message translates to:
  /// **'¡Hola! ¿Cómo estás?'**
  String get sampleChatMessage1;

  /// Mensaje de ejemplo en chat 2
  ///
  /// In es, this message translates to:
  /// **'Nos vemos luego.'**
  String get sampleChatMessage2;

  /// Mensaje de ejemplo en chat 3
  ///
  /// In es, this message translates to:
  /// **'Mensaje de prueba'**
  String get sampleChatMessage3;

  /// Descripción de ejemplo 1
  ///
  /// In es, this message translates to:
  /// **'Disfrutando del atardecer #relax'**
  String get sampleDescription1;

  /// Descripción de ejemplo 2
  ///
  /// In es, this message translates to:
  /// **'Momentos increíbles #aventura'**
  String get sampleDescription2;

  /// Mensaje de ejemplo 1
  ///
  /// In es, this message translates to:
  /// **'Nos vemos en la cena.'**
  String get sampleMessage1;

  /// Mensaje de ejemplo 2
  ///
  /// In es, this message translates to:
  /// **'Reunión a las 3 PM'**
  String get sampleMessage2;

  /// Hora de ejemplo 1
  ///
  /// In es, this message translates to:
  /// **'10:30 AM'**
  String get sampleTime1;

  /// Hora de ejemplo 2
  ///
  /// In es, this message translates to:
  /// **'09:15 AM'**
  String get sampleTime2;

  /// Título para la pantalla de configuración
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings;

  /// Mensaje indicando que la acción de compartir está pendiente
  ///
  /// In es, this message translates to:
  /// **'Compartir (pendiente)'**
  String get sharePending;

  /// Opción para mostrar la última vez en línea
  ///
  /// In es, this message translates to:
  /// **'Mostrar última vez en línea'**
  String get showLastSeen;

  /// Etiqueta para valor desconocido
  ///
  /// In es, this message translates to:
  /// **'Desconocido'**
  String get unknown;

  /// Mensaje indicando que la función de subir reel está pendiente
  ///
  /// In es, this message translates to:
  /// **'Subir nuevo reel (función pendiente)'**
  String get uploadReelPending;

  /// Texto para indicar ayer
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get yesterday;

  /// Título de la sección de configuración
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get configTitle;

  /// Botón para guardar los cambios
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChanges;

  /// Título para la sección de notificaciones
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notifications;

  /// Título para la sección de privacidad
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get privacy;

  /// Sección para configurar idioma y tema
  ///
  /// In es, this message translates to:
  /// **'Idioma y Tema'**
  String get languageAndTheme;

  /// Título para la sección de cuenta
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get account;

  /// Mensaje de confirmación de cambios guardados
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados exitosamente'**
  String get successSave;

  /// Botón para seleccionar una foto de perfil
  ///
  /// In es, this message translates to:
  /// **'Seleccionar foto de perfil'**
  String get selectProfilePhoto;

  /// Título para la pantalla de inicio de sesión
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginTitle;

  /// Mensaje de error por credenciales inválidas en inicio de sesión
  ///
  /// In es, this message translates to:
  /// **'Número de teléfono o contraseña incorrectos.'**
  String get loginInvalidCredentials;

  /// Mensaje de error genérico en inicio de sesión
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un error. Intenta de nuevo.'**
  String get loginErrorGeneric;

  /// Título para la pantalla de agregar contacto
  ///
  /// In es, this message translates to:
  /// **'Agregar contacto'**
  String get addContact;

  /// Etiqueta para el modo incógnito
  ///
  /// In es, this message translates to:
  /// **'Modo incógnito'**
  String get incognitoMode;

  /// Título de la pantalla de verificación SMS
  ///
  /// In es, this message translates to:
  /// **'Verificar SMS'**
  String get verifySmsTitle;

  /// Instrucción para introducir el código de verificación SMS
  ///
  /// In es, this message translates to:
  /// **'Ingresa el código SMS que recibiste en el número {phone}'**
  String verifySmsInstruction(String phone);

  /// Etiqueta para el campo del código SMS
  ///
  /// In es, this message translates to:
  /// **'Código de Verificación'**
  String get verifyCodeLabel;

  /// Texto del botón para verificar el código
  ///
  /// In es, this message translates to:
  /// **'Verificar Código'**
  String get verifyCodeButton;

  /// Mensaje cuando el código ingresado no es válido
  ///
  /// In es, this message translates to:
  /// **'Código de verificación incorrecto'**
  String get verifyCodeInvalid;

  /// Mensaje indicando que el código se reenviará
  ///
  /// In es, this message translates to:
  /// **'Nuevo código enviado (simulado: 123456)'**
  String get verifyCodeResent;

  /// Mensaje para esperar el reenviado del código
  ///
  /// In es, this message translates to:
  /// **'Puedes reenviar el código en {seconds} segundos'**
  String verifyCodeRetryIn(int seconds);

  /// Texto para botón de reenviar código
  ///
  /// In es, this message translates to:
  /// **'Reenviar Código'**
  String get verifyCodeResend;

  /// Mensaje cuando no se pudo registrar el usuario
  ///
  /// In es, this message translates to:
  /// **'Error al registrar usuario'**
  String get verifyUserCreationError;

  /// Texto para la pestaña Reels en la barra de navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Reels'**
  String get bottomNavReels;

  /// Texto para la pestaña Teléfono en la barra de navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get bottomNavPhone;

  /// Texto para la pestaña Chat en la barra de navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get bottomNavChat;

  /// Texto para la pestaña Grupos en la barra de navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Grupos'**
  String get bottomNavGroups;

  /// Texto para la pestaña Configuración en la barra de navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get bottomNavSettings;

  /// Campo para ingresar nueva contraseña en recuperación
  ///
  /// In es, this message translates to:
  /// **'Nueva Contraseña'**
  String get recoveryNewPassword;

  /// Campo para confirmar la nueva contraseña
  ///
  /// In es, this message translates to:
  /// **'Confirmar Nueva Contraseña'**
  String get recoveryConfirmPassword;

  /// Botón para enviar la nueva contraseña
  ///
  /// In es, this message translates to:
  /// **'Recuperar Contraseña'**
  String get recoveryButton;

  /// Etiqueta para el campo de nombre completo
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get fullNameLabel;

  /// Etiqueta para mostrar la fecha de nacimiento del usuario
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get birthDateLabel;

  /// Etiqueta para mostrar el número de teléfono del usuario
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get phoneLabel;

  /// Etiqueta para seleccionar el tono de mensaje
  ///
  /// In es, this message translates to:
  /// **'Tono de mensaje'**
  String get messageToneLabel;

  /// Etiqueta para seleccionar el tono de llamada
  ///
  /// In es, this message translates to:
  /// **'Tono de llamada'**
  String get callToneLabel;

  /// Opción para mostrar la última vez en línea
  ///
  /// In es, this message translates to:
  /// **'Mostrar última vez en línea'**
  String get lastSeenLabel;

  /// Etiqueta del interruptor para activar el modo incógnito
  ///
  /// In es, this message translates to:
  /// **'Modo incógnito (requiere pago)'**
  String get incognitoModeLabel;

  /// Texto del diálogo que solicita confirmación de pago para modo incógnito
  ///
  /// In es, this message translates to:
  /// **'Debes pagar para activar el Modo Incógnito. ¿Deseas continuar?'**
  String get incognitoDialogText;

  /// Mensaje que indica que el pago fue exitoso
  ///
  /// In es, this message translates to:
  /// **'Pago exitoso. Modo Incógnito activado.'**
  String get paymentSuccess;

  /// Opción para usar el idioma por defecto del sistema
  ///
  /// In es, this message translates to:
  /// **'Usar idioma del sistema'**
  String get languageSystem;

  /// Etiqueta para activar o desactivar el tema oscuro
  ///
  /// In es, this message translates to:
  /// **'Tema oscuro'**
  String get darkThemeLabel;

  /// Texto del botón para cerrar sesión
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logoutLabel;

  /// Título del cuadro de confirmación para cerrar sesión
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logoutTitle;

  /// Mensaje del cuadro de diálogo de confirmación de cierre de sesión
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cerrar sesión?'**
  String get logoutConfirm;

  /// Etiqueta del botón de navegación a Reels
  ///
  /// In es, this message translates to:
  /// **'Reels'**
  String get navReels;

  /// Etiqueta del botón de navegación a Teléfono
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get navPhone;

  /// Etiqueta del botón de navegación a Perfil
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// Etiqueta del botón de navegación a Grupos
  ///
  /// In es, this message translates to:
  /// **'Grupos'**
  String get navGroups;

  /// Etiqueta del botón de navegación a Configuración
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get navSettings;

  /// Nombre del tono clásico
  ///
  /// In es, this message translates to:
  /// **'Clásico'**
  String get toneClassic;

  /// Nombre del tono digital
  ///
  /// In es, this message translates to:
  /// **'Digital'**
  String get toneDigital;

  /// Nombre del tono moderno
  ///
  /// In es, this message translates to:
  /// **'Moderno'**
  String get toneModern;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

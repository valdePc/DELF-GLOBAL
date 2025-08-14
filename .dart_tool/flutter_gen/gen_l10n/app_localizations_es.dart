// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Delf App';

  @override
  String get accept => 'Aceptar';

  @override
  String get birthDate => 'Fecha de nacimiento:';

  @override
  String get callButton => 'Llamar';

  @override
  String get callTone => 'Tono de llamada:';

  @override
  String get cancel => 'Cancelar';

  @override
  String get chat => 'Chat';

  @override
  String get chatAttachDoc => 'Documento adjunto (simulado)';

  @override
  String get chatAttachOptionDoc => 'Doc';

  @override
  String get chatAttachOptionPhoto => 'Foto';

  @override
  String get chatAttachOptionVideo => 'Video';

  @override
  String chatAttachPhoto(String filename) {
    return 'Foto adjunta: $filename';
  }

  @override
  String chatAttachVideo(String filename) {
    return 'Video adjunto: $filename';
  }

  @override
  String get chatAudioSim => 'Audio enviado (simulado)';

  @override
  String chatCameraPhoto(String filename) {
    return 'Foto con cámara: $filename';
  }

  @override
  String chatCameraVideo(String filename) {
    return 'Video con cámara: $filename';
  }

  @override
  String get chatCallStarted => 'Llamada iniciada';

  @override
  String get chatCancel => 'Cancelar';

  @override
  String get chatDateFormat => 'dd/MM/yyyy';

  @override
  String get chatDocSim => 'Documento adjunto (simulado)';

  @override
  String get chatEditExpired => 'El mensaje ya no se puede editar.';

  @override
  String get chatEditHint => 'Nuevo mensaje';

  @override
  String get chatEditSave => 'Guardar';

  @override
  String get chatEditTitle => 'Editar mensaje';

  @override
  String get chatHintText => 'Escribe un mensaje...';

  @override
  String get chatOpenSettings => 'Accediendo a configuración';

  @override
  String get chatSave => 'Guardar';

  @override
  String get chatSearchHint => 'Buscar mensajes...';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatTimeFormat => 'HH:mm';

  @override
  String chatTranslationToast(String translatedText) {
    return 'Traducción: $translatedText';
  }

  @override
  String get chatVideoCallStarted => 'Videollamada iniciada';

  @override
  String get commentsPending => 'Comentarios (pendiente)';

  @override
  String get confirmLogoutMessage => '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get createGroup => 'Crear Grupo';

  @override
  String get darkMode => 'Tema oscuro';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get groups => 'Grupos';

  @override
  String get incognitoPaidLabel => 'Modo incógnito (requiere pago)';

  @override
  String get incognitoPaymentPrompt => 'Debes pagar para activar el Modo Incógnito. ¿Deseas continuar?';

  @override
  String get incognitoPaymentSuccess => 'Pago exitoso. Modo Incógnito activado.';

  @override
  String get languageLabel => 'Idioma:';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get makeAudioCall => 'Realizar llamada';

  @override
  String get makeVideoCall => 'Realizar videollamada';

  @override
  String get messageTone => 'Tono de mensaje:';

  @override
  String get newGroup => 'Nuevo Grupo';

  @override
  String get newLabel => 'Nuevo';

  @override
  String get participantsLabel => 'Participantes:';

  @override
  String get passwordEmptyError => 'Ingrese la contraseña';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordTooShortError => 'La contraseña debe tener al menos 6 caracteres';

  @override
  String get phone => 'Teléfono';

  @override
  String get phoneNumber => 'Teléfono:';

  @override
  String get profile => 'Perfil';

  @override
  String get quickAccessTooltip => 'Acceso rápido (temporal, eliminar en producción)';

  @override
  String get reelDeleted => 'Reel eliminado';

  @override
  String get reels => 'Reels';

  @override
  String get registerBirthdate => 'Fecha de Nacimiento';

  @override
  String get registerButton => 'Registrarse';

  @override
  String get registerConfirmPassword => 'Confirmar Contraseña';

  @override
  String get registerEnterConfirmation => 'Confirme su contraseña';

  @override
  String get registerEnterName => 'Ingrese su nombre';

  @override
  String get registerEnterPassword => 'Ingrese la contraseña';

  @override
  String get registerEnterPhone => 'Ingrese un número válido';

  @override
  String get registerFullName => 'Nombre Completo';

  @override
  String get registerPassword => 'Contraseña';

  @override
  String get registerPasswordTooShort => 'La contraseña debe tener al menos 6 caracteres';

  @override
  String get registerPasswordsDontMatch => 'Las contraseñas no coinciden';

  @override
  String get registerPhone => 'Teléfono';

  @override
  String get registerPhoneAlreadyUsed => 'El número de teléfono ya está registrado';

  @override
  String get registerSelectBirthdate => 'Seleccione su fecha de nacimiento';

  @override
  String get registerTitle => 'Registro';

  @override
  String get registerVerificationSent => 'Código de verificación enviado (simulado: 123456)';

  @override
  String get registerNow => '¿No tienes cuenta? Regístrate';

  @override
  String get sampleChatMessage1 => '¡Hola! ¿Cómo estás?';

  @override
  String get sampleChatMessage2 => 'Nos vemos luego.';

  @override
  String get sampleChatMessage3 => 'Mensaje de prueba';

  @override
  String get sampleDescription1 => 'Disfrutando del atardecer #relax';

  @override
  String get sampleDescription2 => 'Momentos increíbles #aventura';

  @override
  String get sampleMessage1 => 'Nos vemos en la cena.';

  @override
  String get sampleMessage2 => 'Reunión a las 3 PM';

  @override
  String get sampleTime1 => '10:30 AM';

  @override
  String get sampleTime2 => '09:15 AM';

  @override
  String get settings => 'Configuración';

  @override
  String get sharePending => 'Compartir (pendiente)';

  @override
  String get showLastSeen => 'Mostrar última vez en línea';

  @override
  String get unknown => 'Desconocido';

  @override
  String get uploadReelPending => 'Subir nuevo reel (función pendiente)';

  @override
  String get yesterday => 'Ayer';

  @override
  String get configTitle => 'Configuración';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get privacy => 'Privacidad';

  @override
  String get languageAndTheme => 'Idioma y Tema';

  @override
  String get account => 'Cuenta';

  @override
  String get successSave => 'Cambios guardados exitosamente';

  @override
  String get selectProfilePhoto => 'Seleccionar foto de perfil';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginInvalidCredentials => 'Número de teléfono o contraseña incorrectos.';

  @override
  String get loginErrorGeneric => 'Ha ocurrido un error. Intenta de nuevo.';

  @override
  String get addContact => 'Agregar contacto';

  @override
  String get incognitoMode => 'Modo incógnito';

  @override
  String get verifySmsTitle => 'Verificar SMS';

  @override
  String verifySmsInstruction(String phone) {
    return 'Ingresa el código SMS que recibiste en el número $phone';
  }

  @override
  String get verifyCodeLabel => 'Código de Verificación';

  @override
  String get verifyCodeButton => 'Verificar Código';

  @override
  String get verifyCodeInvalid => 'Código de verificación incorrecto';

  @override
  String get verifyCodeResent => 'Nuevo código enviado (simulado: 123456)';

  @override
  String verifyCodeRetryIn(int seconds) {
    return 'Puedes reenviar el código en $seconds segundos';
  }

  @override
  String get verifyCodeResend => 'Reenviar Código';

  @override
  String get verifyUserCreationError => 'Error al registrar usuario';

  @override
  String get bottomNavReels => 'Reels';

  @override
  String get bottomNavPhone => 'Teléfono';

  @override
  String get bottomNavChat => 'Chat';

  @override
  String get bottomNavGroups => 'Grupos';

  @override
  String get bottomNavSettings => 'Configuración';

  @override
  String get recoveryNewPassword => 'Nueva Contraseña';

  @override
  String get recoveryConfirmPassword => 'Confirmar Nueva Contraseña';

  @override
  String get recoveryButton => 'Recuperar Contraseña';

  @override
  String get fullNameLabel => 'Nombre completo';

  @override
  String get birthDateLabel => 'Fecha de nacimiento';

  @override
  String get phoneLabel => 'Teléfono';

  @override
  String get messageToneLabel => 'Tono de mensaje';

  @override
  String get callToneLabel => 'Tono de llamada';

  @override
  String get lastSeenLabel => 'Mostrar última vez en línea';

  @override
  String get incognitoModeLabel => 'Modo incógnito (requiere pago)';

  @override
  String get incognitoDialogText => 'Debes pagar para activar el Modo Incógnito. ¿Deseas continuar?';

  @override
  String get paymentSuccess => 'Pago exitoso. Modo Incógnito activado.';

  @override
  String get languageSystem => 'Usar idioma del sistema';

  @override
  String get darkThemeLabel => 'Tema oscuro';

  @override
  String get logoutLabel => 'Cerrar sesión';

  @override
  String get logoutTitle => 'Cerrar sesión';

  @override
  String get logoutConfirm => '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get navReels => 'Reels';

  @override
  String get navPhone => 'Teléfono';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navGroups => 'Grupos';

  @override
  String get navSettings => 'Configuración';

  @override
  String get toneClassic => 'Clásico';

  @override
  String get toneDigital => 'Digital';

  @override
  String get toneModern => 'Moderno';
}

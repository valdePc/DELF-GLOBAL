// lib/services/user_directory.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDirectory {
  static final _users = FirebaseFirestore.instance.collection('users');

  // -------------------------
  // Normalizadores
  // -------------------------

  /// Email a minúsculas y sin espacios.
  static String? _normalizeEmail(String? email) {
    final e = (email ?? '').trim().toLowerCase();
    return e.isEmpty ? null : e;
  }

  /// Teléfono "E.164-ish": quita espacios/guiones/paréntesis y asegura prefijo '+'.
  /// No adivina país; asume que si no trae '+' se lo agregamos.
  static String? _normalizePhoneE164(String? phone) {
    final raw = (phone ?? '').trim();
    if (raw.isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (digits.isEmpty) return null;
    return digits.startsWith('+') ? digits : '+$digits';
  }

  /// Compat legacy: solo dígitos y '+' (antiguo "phoneNorm")
  static String? _normalizePhoneLegacy(String? phone) {
    final p = (phone ?? '').replaceAll(RegExp(r'[^0-9\+]'), '').trim();
    return p.isEmpty ? null : p;
  }

  // -------------------------
  // Búsquedas
  // -------------------------

  /// Devuelve el uid si encuentra por emailLower o phoneE164.
  /// Fallbacks: email / phoneNorm / phone (compat con datos antiguos).
  static Future<String?> resolveUidByHandle({
    String? phone,
    String? email,
  }) async {
    final emailLower = _normalizeEmail(email);
    final phoneE164 = _normalizePhoneE164(phone);
    final phoneLegacy = _normalizePhoneLegacy(phone);

    // 1) emailLower (nuevo campo canónico)
    if (emailLower != null) {
      final q = await _users.where('emailLower', isEqualTo: emailLower).limit(1).get();
      if (q.docs.isNotEmpty) return q.docs.first.id;
    }

    // 2) phoneE164 (nuevo campo canónico)
    if (phoneE164 != null) {
      final q = await _users.where('phoneE164', isEqualTo: phoneE164).limit(1).get();
      if (q.docs.isNotEmpty) return q.docs.first.id;
    }

    // ---- Fallbacks (legacy) ----

    // 3) email exacto (por si aún guardaste sin lower)
    if (emailLower != null) {
      final q = await _users.where('email', isEqualTo: emailLower).limit(1).get();
      if (q.docs.isNotEmpty) return q.docs.first.id;
    }

    // 4) phoneNorm (legacy)
    if (phoneLegacy != null) {
      final q = await _users.where('phoneNorm', isEqualTo: phoneLegacy).limit(1).get();
      if (q.docs.isNotEmpty) return q.docs.first.id;
    }

    // 5) phone (raw)
    if (phone != null && phone.trim().isNotEmpty) {
      final q = await _users.where('phone', isEqualTo: phone.trim()).limit(1).get();
      if (q.docs.isNotEmpty) return q.docs.first.id;
    }

    return null;
  }

  // -------------------------
  // Escrituras
  // -------------------------

  /// Crea/actualiza tu documento en /users/{uid} con campos normalizados
  /// para que otros puedan encontrarte por correo/teléfono.
  static Future<void> ensureCurrentUserMapping({
    String? phone,
    String? email,
    String? fullName,
    String? photoUrl,
  }) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final docRef = _users.doc(u.uid);
    final existing = await docRef.get();

    final normalizedEmailLower = _normalizeEmail(email ?? u.email);
    final normalizedPhoneE164 = _normalizePhoneE164(phone ?? u.phoneNumber);
    final legacyPhoneNorm = _normalizePhoneLegacy(phone ?? u.phoneNumber);

    final data = <String, dynamic>{
      'uid': u.uid,
      'fullName': fullName ?? u.displayName,
      'photoUrl': photoUrl ?? u.photoURL,
      'email': email ?? u.email,
      'emailLower': normalizedEmailLower,
      'phone': phone ?? u.phoneNumber,
      if (normalizedPhoneE164 != null) 'phoneE164': normalizedPhoneE164,
      if (legacyPhoneNorm != null) 'phoneNorm': legacyPhoneNorm, // compat
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    };

    // Elimina nulls para no ensuciar el doc
    data.removeWhere((_, v) => v == null);

    await docRef.set(data, SetOptions(merge: true));
  }

  // -------------------------
  // Lecturas públicas
  // -------------------------

  /// Datos públicos mínimos para cabecera de chat / perfiles.
  static Future<Map<String, dynamic>?> getUserPublic(String uid) async {
    final d = await _users.doc(uid).get();
    if (!d.exists) return null;
    return d.data();
  }
}

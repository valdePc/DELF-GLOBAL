// airtable_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:delf_global/screens/constants.dart';


class AirtableService {
  static final String baseUrl = 'https://api.airtable.com/v0/$airtableBaseId';

  // Buscar usuario por teléfono y contraseña (para login)
  static Future<Map<String, dynamic>?> getUser(String phone, String password) async {
    final url = '$baseUrl/$usersTable?filterByFormula=AND({phone}="$phone", {password}="$password")';
    final response = await http.get(Uri.parse(url), headers: airtableHeaders);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['records'] != null && data['records'].length > 0) {
        return data['records'][0]; // Retorna el primer registro encontrado
      }
    }
    return null;
  }

  // Verificar si un teléfono ya está registrado
  static Future<bool> isPhoneRegistered(String phone) async {
    final url = '$baseUrl/$usersTable?filterByFormula={phone}="$phone"';
    final response = await http.get(Uri.parse(url), headers: airtableHeaders);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['records'] != null && data['records'].length > 0) {
        return true;
      }
    }
    return false;
  }

  // Crear un nuevo usuario
  static Future<bool> createUser(String name, String phone, String birthdate, String password, String fx) async {
    final url = '$baseUrl/$usersTable';
    final body = json.encode({
      'fields': {
        'name': name,
        'phone': phone,
        'birthdate': birthdate,
        'password': password,
        'fx': fx,
      }
    });
    final response = await http.post(Uri.parse(url), headers: airtableHeaders, body: body);
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // Actualizar la contraseña de un usuario (para recuperación)
  static Future<bool> updatePassword(String phone, String newPassword) async {
    // Primero, buscar el registro del usuario por teléfono
    final searchUrl = '$baseUrl/$usersTable?filterByFormula={phone}="$phone"';
    final searchResponse = await http.get(Uri.parse(searchUrl), headers: airtableHeaders);
    if (searchResponse.statusCode == 200) {
      final data = json.decode(searchResponse.body);
      if (data['records'] != null && data['records'].length > 0) {
        final recordId = data['records'][0]['id'];
        final updateUrl = '$baseUrl/$usersTable/$recordId';
        final body = json.encode({
          'fields': {
            'password': newPassword,
          }
        });
        final updateResponse = await http.patch(Uri.parse(updateUrl), headers: airtableHeaders, body: body);
        return updateResponse.statusCode == 200;
      }
    }
    return false;
  }

  // Obtener el logo de la app (columna 'logo' en la tabla 'Users')
  static Future<String?> getAppLogo() async {
    final url = '$baseUrl/$usersTable?maxRecords=1';
    final response = await http.get(Uri.parse(url), headers: airtableHeaders);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['records'] != null && data['records'].length > 0) {
        final fields = data['records'][0]['fields'];
        // Si 'logo' es un array de attachments
        if (fields['logo'] != null && fields['logo'].length > 0) {
          return fields['logo'][0]['url'];
        }
      }
    }
    return null; // Retorna null si no se encuentra o hay error
  }
}

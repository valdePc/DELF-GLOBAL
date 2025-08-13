// constants.dart
const String airtableApiKey = 'patygcsH0vq1IXBGs.2ba9bfa1d43b68cd1b2c95d0d799e97038e80ab9388d6f87e071efbe6ec18bd4';
const String airtableBaseId = 'appx4eD3f7NlNswZW';
const String usersTable = 'Users';
const String contacts_table = 'Contacts';

final Map<String, String> airtableHeaders = {
  'Authorization': 'Bearer $airtableApiKey',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

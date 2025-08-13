import 'models/usuario.dart';

void main() {
  final usuario = Usuario(nombre: "Valde", edad: 25);
  print(usuario.toJson());
}

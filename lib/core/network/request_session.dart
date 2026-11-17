/// Contrato minimo de autenticacion para el transporte HTTP.
/// El cliente no depende de pantallas, controladores ni repositorios.
abstract interface class RequestSession {
  String? get authorization;
  void signOut();
}

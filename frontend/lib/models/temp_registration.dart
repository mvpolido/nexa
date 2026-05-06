class TempRegistration {
  static final TempRegistration _instance = TempRegistration._internal();

  factory TempRegistration() => _instance;

  TempRegistration._internal();

  String nomeExibicao = '';
  String email = '';
  String password = '';
  String cpf = '';
  String institution = '';
  String course = '';
  List<String> skills = [];
  String address = '';
  String logradouro = '';
  String cep = '';
  String numero = '';
  String bairro = '';
  String cidade = '';
  String estado = '';
  double? latitude;
  double? longitude;
  String urlCurriculo = '';
  String fotoPerfil = '';
}
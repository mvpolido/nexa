class Validators {
  /// Valida CPF (11 dígitos com algoritmo de checksum)
  static bool isValidCPF(String cpf) {
    // Remove caracteres especiais
    cpf = cpf.replaceAll(RegExp(r'\D'), '');

    // Verifica tamanho
    if (cpf.length != 11) {
      return false;
    }

    // Rejeita sequências repetidas (111.111.111-11, etc)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return false;
    }

    // Calcula primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int firstDigit = 11 - (sum % 11);
    if (firstDigit >= 10) {
      firstDigit = 0;
    }

    // Calcula segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int secondDigit = 11 - (sum % 11);
    if (secondDigit >= 10) {
      secondDigit = 0;
    }

    // Verifica se os dígitos verificadores conferem
    return int.parse(cpf[9]) == firstDigit && int.parse(cpf[10]) == secondDigit;
  }

  /// Valida CNPJ (14 dígitos com algoritmo de checksum)
  static bool isValidCNPJ(String cnpj) {
    // Remove caracteres especiais
    cnpj = cnpj.replaceAll(RegExp(r'\D'), '');

    // Verifica tamanho
    if (cnpj.length != 14) {
      return false;
    }

    // Rejeita sequências repetidas (11.111.111/1111-11, etc)
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) {
      return false;
    }

    // Calcula primeiro dígito verificador
    int size = cnpj.length - 2;
    String numbers = cnpj.substring(0, size);
    String digits = cnpj.substring(size);
    int sum = 0;
    int pos = size - 7;

    for (int i = size; i >= 1; i--) {
      sum += int.parse(numbers[size - i]) * pos--;
      if (pos < 2) pos = 9;
    }

    int result = sum % 11 < 2 ? 0 : 11 - (sum % 11);
    if (result != int.parse(digits[0])) {
      return false;
    }

    // Calcula segundo dígito verificador
    size = cnpj.length - 1;
    numbers = cnpj.substring(0, size);
    sum = 0;
    pos = size - 7;

    for (int i = size; i >= 1; i--) {
      sum += int.parse(numbers[size - i]) * pos--;
      if (pos < 2) pos = 9;
    }

    result = sum % 11 < 2 ? 0 : 11 - (sum % 11);
    return result == int.parse(digits[1]);
  }

  /// Formata CPF para exibição (XXX.XXX.XXX-XX)
  static String formatCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }

  /// Formata CNPJ para exibição (XX.XXX.XXX/XXXX-XX)
  static String formatCNPJ(String cnpj) {
    cnpj = cnpj.replaceAll(RegExp(r'\D'), '');
    if (cnpj.length != 14) return cnpj;
    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12)}';
  }
}

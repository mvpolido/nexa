const List<String> cursosPadronizados = [
  'Administração',
  'Agronomia',
  'Análise e Desenvolvimento de Sistemas',
  'Arquitetura e Urbanismo',
  'Biomedicina',
  'Ciência da Computação',
  'Ciências Biológicas',
  'Ciências Contábeis',
  'Comunicação Social',
  'Design',
  'Design Gráfico',
  'Direito',
  'Economia',
  'Educação Física',
  'Enfermagem',
  'Engenharia Ambiental',
  'Engenharia Civil',
  'Engenharia da Computação',
  'Engenharia de Alimentos',
  'Engenharia de Controle e Automação',
  'Engenharia de Produção',
  'Engenharia de Software',
  'Engenharia Elétrica',
  'Engenharia Eletrônica',
  'Engenharia Mecânica',
  'Engenharia Química',
  'Farmácia',
  'Física',
  'Fisioterapia',
  'Gestão da Tecnologia da Informação',
  'Jornalismo',
  'Letras',
  'Logística',
  'Marketing',
  'Matemática',
  'Medicina Veterinária',
  'Nutrição',
  'Pedagogia',
  'Psicologia',
  'Publicidade e Propaganda',
  'Química',
  'Recursos Humanos',
  'Relações Internacionais',
  'Sistemas de Informação',
  'Técnico em Administração',
  'Técnico em Desenvolvimento de Sistemas',
  'Técnico em Edificações',
  'Técnico em Eletrotécnica',
  'Técnico em Informática',
  'Técnico em Mecânica',
  'Técnico em Química',
];

String normalizarCursoBusca(String value) {
  return value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}

String? canonicalizarCurso(String value) {
  final aliases = {
    'ads': 'Análise e Desenvolvimento de Sistemas',
    'cc': 'Ciência da Computação',
    'ciencia da computacao': 'Ciência da Computação',
    'eng software': 'Engenharia de Software',
    'engenharia software': 'Engenharia de Software',
    'eng eletronica': 'Engenharia Eletrônica',
    'engenharia eletronica': 'Engenharia Eletrônica',
    'sistemas': 'Sistemas de Informação',
  };

  final normalized = normalizarCursoBusca(value);
  if (aliases.containsKey(normalized)) return aliases[normalized];

  for (final curso in cursosPadronizados) {
    if (normalizarCursoBusca(curso) == normalized) return curso;
  }

  return null;
}

import "reflect-metadata";
import { AppDataSource } from "./data-source";
import { Usuario, UsuarioPerfil } from "./entities/Usuario";
import { Aluno } from "./entities/Aluno";
import { Empresa } from "./entities/Empresa";

async function runSeed() {
  try {
    await AppDataSource.initialize();
    console.log("✅ Conectado ao banco de dados para seed");

    const usuarioRepository = AppDataSource.getRepository(Usuario);
    const alunoRepository = AppDataSource.getRepository(Aluno);
    const empresaRepository = AppDataSource.getRepository(Empresa);

    // Limpar dados anteriores (opcional - comentar para não deletar)
    // await usuarioRepository.delete({});

    console.log("\n📝 Criando usuários de teste...");

    // Criar 2 usuários ALUNO
    const aluno1 = new Usuario();
    aluno1.email = "joao@example.com";
    aluno1.senha_hash = "hashed_password_1"; // Em produção, usar bcrypt
    aluno1.nome_exibicao = "João Silva";
    aluno1.perfil = UsuarioPerfil.ALUNO;
    await usuarioRepository.save(aluno1);
    console.log(`✓ Aluno criado: ${aluno1.email}`);

    const aluno2 = new Usuario();
    aluno2.email = "maria@example.com";
    aluno2.senha_hash = "hashed_password_2";
    aluno2.nome_exibicao = "Maria Santos";
    aluno2.perfil = UsuarioPerfil.ALUNO;
    await usuarioRepository.save(aluno2);
    console.log(`✓ Aluno criado: ${aluno2.email}`);

    // Criar 2 usuários EMPRESA
    const empresa1User = new Usuario();
    empresa1User.email = "rh@techcorp.com";
    empresa1User.senha_hash = "hashed_password_3";
    empresa1User.nome_exibicao = "TechCorp RH";
    empresa1User.perfil = UsuarioPerfil.EMPRESA;
    await usuarioRepository.save(empresa1User);
    console.log(`✓ Empresa criada: ${empresa1User.email}`);

    const empresa2User = new Usuario();
    empresa2User.email = "contato@startup.com";
    empresa2User.senha_hash = "hashed_password_4";
    empresa2User.nome_exibicao = "StartupXYZ";
    empresa2User.perfil = UsuarioPerfil.EMPRESA;
    await usuarioRepository.save(empresa2User);
    console.log(`✓ Empresa criada: ${empresa2User.email}`);

    console.log("\n📚 Criando registros de ALUNO...");

    // Criar 2 registros Aluno (relacionados aos usuários ALUNO)
    const alunoData1 = new Aluno();
    alunoData1.id = aluno1.id;
    alunoData1.cpf = "12345678900";
    alunoData1.curso = "Engenharia de Software";
    alunoData1.url_curriculo = "https://example.com/joao-cv.pdf";
    alunoData1.latitude = -23.5505;
    alunoData1.longitude = -46.6333;
    await alunoRepository.save(alunoData1);
    console.log(`✓ Aluno #1 populado: ${aluno1.nome_exibicao}`);

    const alunoData2 = new Aluno();
    alunoData2.id = aluno2.id;
    alunoData2.cpf = "98765432100";
    alunoData2.curso = "Ciência da Computação";
    alunoData2.url_curriculo = "https://example.com/maria-cv.pdf";
    alunoData2.latitude = -23.5489;
    alunoData2.longitude = -46.6388;
    await alunoRepository.save(alunoData2);
    console.log(`✓ Aluno #2 populado: ${aluno2.nome_exibicao}`);

    console.log("\n🏢 Criando registros de EMPRESA...");

    // Criar 2 registros Empresa (relacionados aos usuários EMPRESA)
    const empresaData1 = new Empresa();
    empresaData1.id = empresa1User.id;
    empresaData1.cnpj = "12345678000199";
    empresaData1.descricao = "Empresa de tecnologia focada em desenvolvimento de software";
    empresaData1.latitude = -23.5505;
    empresaData1.longitude = -46.6333;
    await empresaRepository.save(empresaData1);
    console.log(`✓ Empresa #1 populada: ${empresa1User.nome_exibicao}`);

    const empresaData2 = new Empresa();
    empresaData2.id = empresa2User.id;
    empresaData2.cnpj = "98765432000111";
    empresaData2.descricao = "Startup inovadora no setor de inteligência artificial";
    empresaData2.latitude = -23.5489;
    empresaData2.longitude = -46.6388;
    await empresaRepository.save(empresaData2);
    console.log(`✓ Empresa #2 populada: ${empresa2User.nome_exibicao}`);

    console.log("\n✨ Seed concluído com sucesso!");
    console.log("\n📊 Resumo:");
    console.log(`   - Usuários criados: 4 (2 alunos + 2 empresas)`);
    console.log(`   - Registros Aluno: 2`);
    console.log(`   - Registros Empresa: 2`);

    await AppDataSource.destroy();
  } catch (error) {
    console.error("❌ Erro ao executar seed:", error);
    process.exit(1);
  }
}

runSeed();

import "reflect-metadata";
import bcrypt from "bcrypt";
import { AppDataSource } from "./data-source";
import { Usuario, UsuarioPerfil } from "./entities/Usuario";
import { Aluno } from "./entities/Aluno";
import { Empresa } from "./entities/Empresa";
import { Habilidade } from "./entities/Habilidade";
import { Vaga, VagaModalidade } from "./entities/Vaga";
import { Candidatura, CandidaturaStatus } from "./entities/Candidatura";
import { Mensagem } from "./entities/Mensagem";
import { Avaliacao } from "./entities/Avaliacao";
import { AlunoHabilidade } from "./entities/AlunoHabilidade";
import { VagaHabilidade } from "./entities/VagaHabilidade";

async function runSeed() {
  try {
    await AppDataSource.initialize();
    console.log("✅ Conectado ao banco de dados para seed");

    const usuarioRepository    = AppDataSource.getRepository(Usuario);
    const alunoRepository      = AppDataSource.getRepository(Aluno);
    const empresaRepository    = AppDataSource.getRepository(Empresa);
    const habilidadeRepository = AppDataSource.getRepository(Habilidade);
    const vagaRepository       = AppDataSource.getRepository(Vaga);
    const candidaturaRepository= AppDataSource.getRepository(Candidatura);
    const mensagemRepository   = AppDataSource.getRepository(Mensagem);
    const avaliacaoRepository  = AppDataSource.getRepository(Avaliacao);
    const alunoHabRepository   = AppDataSource.getRepository(AlunoHabilidade);
    const vagaHabRepository    = AppDataSource.getRepository(VagaHabilidade);

    // Limpar dados anteriores (opcional - comentar para não deletar)
    // await usuarioRepository.delete({});

    // ─── USUÁRIOS ────────────────────────────────────────────────────────────
    console.log("\n📝 Criando usuários de teste...");

    const aluno1 = new Usuario();
    aluno1.email = "aluno@gmail.com";
    aluno1.senha_hash = await bcrypt.hash("123456", 10);
    aluno1.nome_exibicao = "Aluno Silva";
    aluno1.perfil = UsuarioPerfil.ALUNO;
    await usuarioRepository.save(aluno1);
    console.log(`✓ Aluno criado: ${aluno1.email}`);

    const aluno2 = new Usuario();
    aluno2.email = "maria@example.com";
    aluno2.senha_hash = await bcrypt.hash("senha123", 10);
    aluno2.nome_exibicao = "Maria Santos";
    aluno2.perfil = UsuarioPerfil.ALUNO;
    await usuarioRepository.save(aluno2);
    console.log(`✓ Aluno criado: ${aluno2.email}`);

    const empresa1User = new Usuario();
    empresa1User.email = "empresa@gmail.com";
    empresa1User.senha_hash = await bcrypt.hash("123456", 10);
    empresa1User.nome_exibicao = "TechCorp RH";
    empresa1User.perfil = UsuarioPerfil.EMPRESA;
    await usuarioRepository.save(empresa1User);
    console.log(`✓ Empresa criada: ${empresa1User.email}`);

    const empresa2User = new Usuario();
    empresa2User.email = "contato@startup.com";
    empresa2User.senha_hash = await bcrypt.hash("senha123", 10);
    empresa2User.nome_exibicao = "StartupXYZ";
    empresa2User.perfil = UsuarioPerfil.EMPRESA;
    await usuarioRepository.save(empresa2User);
    console.log(`✓ Empresa criada: ${empresa2User.email}`);

    // ─── ALUNOS ───────────────────────────────────────────────────────────────
    console.log("\n📚 Criando registros de ALUNO...");

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

    // ─── EMPRESAS ─────────────────────────────────────────────────────────────
    console.log("\n🏢 Criando registros de EMPRESA...");

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

    // ─── HABILIDADES ──────────────────────────────────────────────────────────
    console.log("\n🛠️  Criando HABILIDADES...");

    const hab1 = new Habilidade();
    hab1.nome = "TypeScript";
    await habilidadeRepository.save(hab1);
    console.log(`✓ Habilidade criada: ${hab1.nome}`);

    const hab2 = new Habilidade();
    hab2.nome = "Node.js";
    await habilidadeRepository.save(hab2);
    console.log(`✓ Habilidade criada: ${hab2.nome}`);

    const hab3 = new Habilidade();
    hab3.nome = "Flutter";
    await habilidadeRepository.save(hab3);
    console.log(`✓ Habilidade criada: ${hab3.nome}`);

    const hab4 = new Habilidade();
    hab4.nome = "PostgreSQL";
    await habilidadeRepository.save(hab4);
    console.log(`✓ Habilidade criada: ${hab4.nome}`);

    // ─── ALUNO_HABILIDADE ─────────────────────────────────────────────────────
    console.log("\n🔗 Associando habilidades aos ALUNOS...");

    const alunoHab1 = new AlunoHabilidade();
    alunoHab1.aluno_id = alunoData1.id;
    alunoHab1.habilidade_id = hab1.id;
    await alunoHabRepository.save(alunoHab1);

    const alunoHab2 = new AlunoHabilidade();
    alunoHab2.aluno_id = alunoData1.id;
    alunoHab2.habilidade_id = hab2.id;
    await alunoHabRepository.save(alunoHab2);

    const alunoHab3 = new AlunoHabilidade();
    alunoHab3.aluno_id = alunoData2.id;
    alunoHab3.habilidade_id = hab3.id;
    await alunoHabRepository.save(alunoHab3);

    const alunoHab4 = new AlunoHabilidade();
    alunoHab4.aluno_id = alunoData2.id;
    alunoHab4.habilidade_id = hab4.id;
    await alunoHabRepository.save(alunoHab4);
    console.log(`✓ 4 associações aluno↔habilidade criadas`);

    // ─── VAGAS ────────────────────────────────────────────────────────────────
    console.log("\n💼 Criando VAGAS...");

    const vaga1 = new Vaga();
    vaga1.empresa_id = empresaData1.id;
    vaga1.titulo = "Desenvolvedor Back-end Node.js";
    vaga1.descricao = "Vaga para desenvolvedor back-end com experiência em Node.js e TypeScript.";
    vaga1.requisitos = "Mínimo 1 ano de experiência com Node.js";
    vaga1.modalidade = VagaModalidade.HIBRIDO;
    vaga1.latitude = -23.5505;
    vaga1.longitude = -46.6333;
    vaga1.ativo = 1;
    await vagaRepository.save(vaga1);
    console.log(`✓ Vaga criada: ${vaga1.titulo}`);

    const vaga2 = new Vaga();
    vaga2.empresa_id = empresaData2.id;
    vaga2.titulo = "Desenvolvedor Mobile Flutter";
    vaga2.descricao = "Startup busca desenvolvedor Flutter para aplicativo de IA.";
    vaga2.requisitos = "Conhecimento em Flutter e Dart";
    vaga2.modalidade = VagaModalidade.REMOTO;
    vaga2.ativo = 1;
    await vagaRepository.save(vaga2);
    console.log(`✓ Vaga criada: ${vaga2.titulo}`);

    // ─── VAGA_HABILIDADE ──────────────────────────────────────────────────────
    console.log("\n🔗 Associando habilidades às VAGAS...");

    const vagaHab1 = new VagaHabilidade();
    vagaHab1.vaga_id = vaga1.id;
    vagaHab1.habilidade_id = hab1.id;
    await vagaHabRepository.save(vagaHab1);

    const vagaHab2 = new VagaHabilidade();
    vagaHab2.vaga_id = vaga1.id;
    vagaHab2.habilidade_id = hab2.id;
    await vagaHabRepository.save(vagaHab2);

    const vagaHab3 = new VagaHabilidade();
    vagaHab3.vaga_id = vaga2.id;
    vagaHab3.habilidade_id = hab3.id;
    await vagaHabRepository.save(vagaHab3);

    const vagaHab4 = new VagaHabilidade();
    vagaHab4.vaga_id = vaga2.id;
    vagaHab4.habilidade_id = hab4.id;
    await vagaHabRepository.save(vagaHab4);
    console.log(`✓ 4 associações vaga↔habilidade criadas`);

    // ─── CANDIDATURAS ─────────────────────────────────────────────────────────
    console.log("\n📨 Criando CANDIDATURAS...");

    const cand1 = new Candidatura();
    cand1.aluno_id = alunoData1.id;
    cand1.vaga_id = vaga1.id;
    cand1.status = CandidaturaStatus.PENDENTE;
    cand1.pontuacao_compatibilidade = 85.50;
    await candidaturaRepository.save(cand1);
    console.log(`✓ Candidatura criada: ${aluno1.nome_exibicao} → ${vaga1.titulo}`);

    const cand2 = new Candidatura();
    cand2.aluno_id = alunoData2.id;
    cand2.vaga_id = vaga2.id;
    cand2.status = CandidaturaStatus.ACEITA;
    cand2.pontuacao_compatibilidade = 100.00;
    await candidaturaRepository.save(cand2);
    console.log(`✓ Candidatura criada: ${aluno2.nome_exibicao} → ${vaga2.titulo}`);

    const cand3 = new Candidatura();
    cand3.aluno_id = alunoData1.id;
    cand3.vaga_id = vaga2.id;
    cand3.status = CandidaturaStatus.REJEITADA;
    cand3.pontuacao_compatibilidade = 42.00;
    await candidaturaRepository.save(cand3);
    console.log(`✓ Candidatura criada: ${aluno1.nome_exibicao} → ${vaga2.titulo}`);

    // ─── MENSAGENS ────────────────────────────────────────────────────────────
    console.log("\n💬 Criando MENSAGENS...");

    const msg1 = new Mensagem();
    msg1.candidatura_id = cand1.id;
    msg1.remetente_id = aluno1.id;
    msg1.conteudo = "Olá, tenho interesse na vaga de Node.js!";
    await mensagemRepository.save(msg1);
    console.log(`✓ Mensagem #1 criada`);

    const msg2 = new Mensagem();
    msg2.candidatura_id = cand1.id;
    msg2.remetente_id = empresa1User.id;
    msg2.conteudo = "Olá João, vamos agendar uma entrevista?";
    await mensagemRepository.save(msg2);
    console.log(`✓ Mensagem #2 criada`);

    const msg3 = new Mensagem();
    msg3.candidatura_id = cand2.id;
    msg3.remetente_id = empresa2User.id;
    msg3.conteudo = "Parabéns Maria, sua candidatura foi aceita!";
    await mensagemRepository.save(msg3);
    console.log(`✓ Mensagem #3 criada`);

    const msg4 = new Mensagem();
    msg4.candidatura_id = cand2.id;
    msg4.remetente_id = aluno2.id;
    msg4.conteudo = "Muito obrigada, quando início?";
    await mensagemRepository.save(msg4);
    console.log(`✓ Mensagem #4 criada`);

    // ─── AVALIAÇÕES ───────────────────────────────────────────────────────────
    console.log("\n⭐ Criando AVALIAÇÕES...");

    const aval1 = new Avaliacao();
    aval1.aluno_id = alunoData1.id;
    aval1.empresa_id = empresaData1.id;
    aval1.nota = 5;
    aval1.comentario = "Ótimo processo seletivo, muito transparente e organizado.";
    await avaliacaoRepository.save(aval1);
    console.log(`✓ Avaliação criada: ${aluno1.nome_exibicao} → ${empresa1User.nome_exibicao} (nota ${aval1.nota})`);

    const aval2 = new Avaliacao();
    aval2.aluno_id = alunoData2.id;
    aval2.empresa_id = empresaData2.id;
    aval2.nota = 4;
    aval2.comentario = "Empresa inovadora, boa comunicação durante o processo.";
    await avaliacaoRepository.save(aval2);
    console.log(`✓ Avaliação criada: ${aluno2.nome_exibicao} → ${empresa2User.nome_exibicao} (nota ${aval2.nota})`);

    // ─── RESUMO ───────────────────────────────────────────────────────────────
    console.log("\n✨ Seed concluído com sucesso!");
    console.log("\n📊 Resumo:");
    console.log(`   - Usuários:          4 (2 alunos + 2 empresas)`);
    console.log(`   - Alunos:            2`);
    console.log(`   - Empresas:          2`);
    console.log(`   - Habilidades:       4`);
    console.log(`   - Vagas:             2`);
    console.log(`   - Candidaturas:      3`);
    console.log(`   - Mensagens:         4`);
    console.log(`   - Avaliações:        2`);
    console.log(`   - Aluno↔Habilidade:  4`);
    console.log(`   - Vaga↔Habilidade:   4`);

    await AppDataSource.destroy();
  } catch (error) {
    console.error("❌ Erro ao executar seed:", error);
    process.exit(1);
  }
}

runSeed();


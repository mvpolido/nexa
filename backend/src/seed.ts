import "reflect-metadata";
import bcrypt from "bcrypt";
import { AppDataSource } from "./data-source";
import { Usuario, UsuarioPerfil } from "./entities/Usuario";
import { Aluno } from "./entities/Aluno";
import { Empresa } from "./entities/Empresa";
import { Habilidade } from "./entities/Habilidade";
import { Vaga, VagaModalidade } from "./entities/Vaga";
import { Candidatura, CandidaturaStatus } from "./entities/Candidatura";
import { AlunoHabilidade } from "./entities/AlunoHabilidade";
import { VagaHabilidade } from "./entities/VagaHabilidade";

const TEST_PASSWORD = "123456";

const habilidadesIniciais = [
  "Flutter",
  "Dart",
  "React",
  "Node.js",
  "TypeScript",
  "Git",
  "Docker",
  "PostgreSQL",
  "APIs REST",
  "Comunicação",
];

async function runSeed() {
  try {
    await AppDataSource.initialize();
    console.log("Conectado ao banco de dados para seed");

    const usuarioRepository = AppDataSource.getRepository(Usuario);
    const alunoRepository = AppDataSource.getRepository(Aluno);
    const empresaRepository = AppDataSource.getRepository(Empresa);
    const habilidadeRepository = AppDataSource.getRepository(Habilidade);
    const vagaRepository = AppDataSource.getRepository(Vaga);
    const candidaturaRepository = AppDataSource.getRepository(Candidatura);
    const alunoHabRepository = AppDataSource.getRepository(AlunoHabilidade);
    const vagaHabRepository = AppDataSource.getRepository(VagaHabilidade);

    const getOrCreateUsuario = async (
      email: string,
      nome_exibicao: string,
      perfil: UsuarioPerfil
    ) => {
      let usuario = await usuarioRepository.findOne({ where: { email } });

      if (!usuario) {
        usuario = usuarioRepository.create({ email });
      }

      usuario.nome_exibicao = nome_exibicao;
      usuario.perfil = perfil;
      usuario.senha_hash = await bcrypt.hash(TEST_PASSWORD, 10);

      return usuarioRepository.save(usuario);
    };

    const getOrCreateAluno = async (usuario: Usuario) => {
      const cpf = "11122233344";
      let aluno = await alunoRepository.findOne({ where: { id: usuario.id } });

      if (!aluno) {
        aluno = await alunoRepository.findOne({ where: { cpf } });
      }

      if (!aluno) {
        aluno = alunoRepository.create({ id: usuario.id });
      }

      aluno.id = usuario.id;
      aluno.cpf = cpf;
      aluno.curso = "Engenharia de Software";
      aluno.url_curriculo = "https://example.com/aluno-teste-cv.pdf";
      aluno.latitude = -23.5505;
      aluno.longitude = -46.6333;

      return alunoRepository.save(aluno);
    };

    const getOrCreateEmpresa = async (usuario: Usuario) => {
      const cnpj = "11222333000144";
      let empresa = await empresaRepository.findOne({ where: { id: usuario.id } });

      if (!empresa) {
        empresa = await empresaRepository.findOne({ where: { cnpj } });
      }

      if (!empresa) {
        empresa = empresaRepository.create({ id: usuario.id });
      }

      empresa.id = usuario.id;
      empresa.cnpj = cnpj;
      empresa.descricao = "Empresa de tecnologia para testes da sprint";
      empresa.latitude = -23.5505;
      empresa.longitude = -46.6333;

      return empresaRepository.save(empresa);
    };

    const getOrCreateHabilidade = async (nome: string) => {
      let habilidade = await habilidadeRepository.findOne({ where: { nome } });

      if (!habilidade) {
        habilidade = habilidadeRepository.create({ nome });
        habilidade = await habilidadeRepository.save(habilidade);
      }

      return habilidade;
    };

    const getOrCreateAlunoHabilidade = async (
      aluno_id: number,
      habilidade_id: number
    ) => {
      let alunoHabilidade = await alunoHabRepository.findOne({
        where: { aluno_id, habilidade_id },
      });

      if (!alunoHabilidade) {
        alunoHabilidade = alunoHabRepository.create({ aluno_id, habilidade_id });
        alunoHabilidade = await alunoHabRepository.save(alunoHabilidade);
      }

      return alunoHabilidade;
    };

    const getOrCreateVaga = async (dados: {
      empresa_id: number;
      titulo: string;
      descricao: string;
      requisitos: string;
      modalidade: VagaModalidade;
      latitude?: number;
      longitude?: number;
      habilidades: string[];
    }) => {
      let vaga = await vagaRepository.findOne({
        where: { empresa_id: dados.empresa_id, titulo: dados.titulo },
      });

      if (!vaga) {
        vaga = vagaRepository.create({
          empresa_id: dados.empresa_id,
          titulo: dados.titulo,
        });
      }

      vaga.descricao = dados.descricao;
      vaga.requisitos = dados.requisitos;
      vaga.modalidade = dados.modalidade;
      vaga.latitude = dados.latitude;
      vaga.longitude = dados.longitude;
      vaga.habilidades = dados.habilidades;
      vaga.ativo = 1;

      return vagaRepository.save(vaga);
    };

    const getOrCreateVagaHabilidade = async (
      vaga_id: number,
      habilidade_id: number
    ) => {
      let vagaHabilidade = await vagaHabRepository.findOne({
        where: { vaga_id, habilidade_id },
      });

      if (!vagaHabilidade) {
        vagaHabilidade = vagaHabRepository.create({ vaga_id, habilidade_id });
        vagaHabilidade = await vagaHabRepository.save(vagaHabilidade);
      }

      return vagaHabilidade;
    };

    const getOrCreateCandidatura = async (aluno_id: number, vaga_id: number) => {
      let candidatura = await candidaturaRepository.findOne({
        where: { aluno_id, vaga_id },
      });

      if (!candidatura) {
        candidatura = candidaturaRepository.create({ aluno_id, vaga_id });
      }

      candidatura.status = CandidaturaStatus.PENDENTE;
      candidatura.pontuacao_compatibilidade = 90;

      return candidaturaRepository.save(candidatura);
    };

    console.log("\nCriando ou reutilizando usuários e perfis...");
    const alunoUser = await getOrCreateUsuario(
      "aluno@nexa.com",
      "Aluno Teste",
      UsuarioPerfil.ALUNO
    );
    const empresaUser = await getOrCreateUsuario(
      "empresa@nexa.com",
      "Empresa Teste",
      UsuarioPerfil.EMPRESA
    );
    const adminUser = await getOrCreateUsuario(
      "admin@nexa.com",
      "Administrador Nexa",
      UsuarioPerfil.ADMIN
    );

    const aluno = await getOrCreateAluno(alunoUser);
    const empresa = await getOrCreateEmpresa(empresaUser);

    console.log("Criando ou reutilizando habilidades...");
    const habilidades = new Map<string, Habilidade>();
    for (const nome of habilidadesIniciais) {
      const habilidade = await getOrCreateHabilidade(nome);
      habilidades.set(nome, habilidade);
    }

    console.log("Criando ou reutilizando vínculos aluno-habilidade...");
    for (const habilidade of habilidades.values()) {
      await getOrCreateAlunoHabilidade(aluno.id, habilidade.id);
    }

    console.log("Criando ou reutilizando vagas e vínculos vaga-habilidade...");
    const vagasSeed = [
      {
        titulo: "Desenvolvedor Mobile Flutter",
        descricao: "Vaga de estágio para atuar no desenvolvimento de aplicativos mobile.",
        requisitos: "Conhecimento em Flutter, Dart, Git e APIs REST.",
        modalidade: VagaModalidade.REMOTO,
        habilidades: ["Flutter", "Dart", "Git", "APIs REST", "Comunicação"],
      },
      {
        titulo: "Desenvolvedor Back-end Node.js",
        descricao: "Vaga de estágio para apoiar o desenvolvimento de APIs e integrações.",
        requisitos: "Conhecimento em Node.js, TypeScript, Docker e PostgreSQL.",
        modalidade: VagaModalidade.HIBRIDO,
        latitude: -23.5505,
        longitude: -46.6333,
        habilidades: ["Node.js", "TypeScript", "Docker", "PostgreSQL", "APIs REST"],
      },
    ];

    const vagas: Vaga[] = [];
    for (const vagaSeed of vagasSeed) {
      const vaga = await getOrCreateVaga({
        empresa_id: empresa.id,
        ...vagaSeed,
      });
      vagas.push(vaga);

      for (const nomeHabilidade of vagaSeed.habilidades) {
        const habilidade = habilidades.get(nomeHabilidade);
        if (habilidade) {
          await getOrCreateVagaHabilidade(vaga.id, habilidade.id);
        }
      }
    }

    console.log("Criando ou reutilizando candidatura...");
    await getOrCreateCandidatura(aluno.id, vagas[0].id);

    console.log("\nSeed concluído com sucesso!");
    console.log("\nCredenciais de teste:");
    console.log(`Aluno:   ${alunoUser.email} / ${TEST_PASSWORD}`);
    console.log(`Empresa: ${empresaUser.email} / ${TEST_PASSWORD}`);
    console.log(`Admin:   ${adminUser.email} / ${TEST_PASSWORD}`);
  } catch (error) {
    console.error("Erro ao executar seed:", error);
    process.exitCode = 1;
  } finally {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
  }
}

runSeed();

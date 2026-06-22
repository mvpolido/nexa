import "reflect-metadata";
import { AppDataSource } from "../data-source";
import { Aluno } from "../entities/Aluno";
import { Vaga, VagaModalidade } from "../entities/Vaga";
import { coordenadasValidas } from "../utils/distance";
import { geocodificarEndereco } from "../utils/geocoding";

type Options = {
  alunoId?: number;
  vagaId?: number;
  force: boolean;
};

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function parseOptions(): Options {
  const options: Options = { force: false };

  for (const arg of process.argv.slice(2)) {
    if (arg === "--force") {
      options.force = true;
      continue;
    }

    const [key, value] = arg.split("=");
    const id = Number(value);
    if (!Number.isInteger(id) || id <= 0) {
      throw new Error(`Opção inválida: ${arg}`);
    }

    if (key === "--aluno-id") options.alunoId = id;
    else if (key === "--vaga-id") options.vagaId = id;
    else throw new Error(`Opção desconhecida: ${key}`);
  }

  return options;
}

function formatCoord(latitude: unknown, longitude: unknown) {
  if (!coordenadasValidas(latitude, longitude)) return "inválida";
  return `${Number(latitude).toFixed(8)}, ${Number(longitude).toFixed(8)}`;
}

async function processarAluno(aluno: Aluno, force: boolean) {
  if (!force && coordenadasValidas(aluno.latitude, aluno.longitude)) {
    return "ignorado";
  }

  const antiga = formatCoord(aluno.latitude, aluno.longitude);
  const endereco = `${aluno.cep ?? ""} | ${aluno.endereco ?? ""} | ${
    aluno.numero ?? ""
  }`;
  const coordenadas = await geocodificarEndereco({
    cep: aluno.cep,
    endereco: aluno.endereco,
    numero: aluno.numero,
  });

  if (!coordenadas) {
    console.warn(`Aluno ${aluno.id} falhou: ${endereco}`);
    return "falha";
  }

  aluno.latitude = coordenadas.latitude;
  aluno.longitude = coordenadas.longitude;
  await AppDataSource.getRepository(Aluno).save(aluno);
  console.log(
    `Aluno ${aluno.id}: ${endereco} | ${antiga} -> ${formatCoord(
      aluno.latitude,
      aluno.longitude
    )}`
  );
  return "corrigido";
}

async function processarVaga(vaga: Vaga, force: boolean) {
  if (vaga.modalidade === VagaModalidade.REMOTO) {
    console.log(`Vaga ${vaga.id} ignorada: remota.`);
    return "ignorado";
  }

  if (!force && coordenadasValidas(vaga.latitude, vaga.longitude)) {
    return "ignorado";
  }

  const antiga = formatCoord(vaga.latitude, vaga.longitude);
  const endereco = `${vaga.cep ?? ""} | ${vaga.endereco ?? ""} | ${
    vaga.numero ?? ""
  } | ${vaga.cidade ?? ""}/${vaga.estado ?? ""}`;
  const coordenadas = await geocodificarEndereco({
    cep: vaga.cep,
    endereco: vaga.endereco,
    numero: vaga.numero,
    cidade: vaga.cidade,
    estado: vaga.estado,
  });

  if (!coordenadas) {
    console.warn(`Vaga ${vaga.id} falhou: ${endereco}`);
    return "falha";
  }

  vaga.latitude = coordenadas.latitude;
  vaga.longitude = coordenadas.longitude;
  await AppDataSource.getRepository(Vaga).save(vaga);
  console.log(
    `Vaga ${vaga.id}: ${endereco} | ${antiga} -> ${formatCoord(
      vaga.latitude,
      vaga.longitude
    )}`
  );
  return "corrigido";
}

async function run() {
  const options = parseOptions();
  await AppDataSource.initialize();

  const alunoRepository = AppDataSource.getRepository(Aluno);
  const vagaRepository = AppDataSource.getRepository(Vaga);
  const stats = {
    alunosCorrigidos: 0,
    alunosFalharam: 0,
    vagasCorrigidas: 0,
    vagasFalharam: 0,
  };

  const alunos = options.alunoId
    ? await alunoRepository.find({ where: { id: options.alunoId } })
    : options.vagaId
      ? []
      : await alunoRepository.find();

  const vagas = options.vagaId
    ? await vagaRepository.find({ where: { id: options.vagaId } })
    : options.alunoId
      ? []
      : await vagaRepository.find();

  for (const aluno of alunos) {
    const result = await processarAluno(aluno, options.force);
    if (result === "corrigido") stats.alunosCorrigidos++;
    if (result === "falha") stats.alunosFalharam++;
    await sleep(1000);
  }

  for (const vaga of vagas) {
    const result = await processarVaga(vaga, options.force);
    if (result === "corrigido") stats.vagasCorrigidas++;
    if (result === "falha") stats.vagasFalharam++;
    await sleep(1000);
  }

  console.log("Backfill de coordenadas concluído.");
  console.log(`Alunos corrigidos: ${stats.alunosCorrigidos}`);
  console.log(`Alunos com falha: ${stats.alunosFalharam}`);
  console.log(`Vagas corrigidas: ${stats.vagasCorrigidas}`);
  console.log(`Vagas com falha: ${stats.vagasFalharam}`);

  await AppDataSource.destroy();
}

run().catch(async (error) => {
  console.error("Erro ao recalcular coordenadas:", error);
  if (AppDataSource.isInitialized) await AppDataSource.destroy();
  process.exit(1);
});

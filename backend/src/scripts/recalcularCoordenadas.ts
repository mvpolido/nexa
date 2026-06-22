import "reflect-metadata";
import { AppDataSource } from "../data-source";
import { Aluno } from "../entities/Aluno";
import { Vaga, VagaModalidade } from "../entities/Vaga";
import { coordenadasValidas } from "../utils/coordinates";
import { geocodificarEndereco } from "../utils/geocoding";

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function run() {
  await AppDataSource.initialize();

  const alunoRepository = AppDataSource.getRepository(Aluno);
  const vagaRepository = AppDataSource.getRepository(Vaga);

  let alunosCorrigidos = 0;
  let alunosFalharam = 0;
  let vagasCorrigidas = 0;
  let vagasFalharam = 0;

  const alunos = await alunoRepository.find();
  for (const aluno of alunos) {
    if (coordenadasValidas(aluno.latitude, aluno.longitude)) continue;

    const coordenadas = await geocodificarEndereco({
      cep: aluno.cep,
      endereco: aluno.endereco,
      numero: aluno.numero,
    });

    if (coordenadas) {
      aluno.latitude = coordenadas.latitude;
      aluno.longitude = coordenadas.longitude;
      await alunoRepository.save(aluno);
      alunosCorrigidos++;
    } else {
      alunosFalharam++;
    }

    await sleep(1000);
  }

  const vagas = await vagaRepository.find();
  for (const vaga of vagas) {
    if (vaga.modalidade === VagaModalidade.REMOTO) continue;
    if (coordenadasValidas(vaga.latitude, vaga.longitude)) continue;

    const coordenadas = await geocodificarEndereco({
      cep: vaga.cep,
      endereco: vaga.endereco,
      numero: vaga.numero,
      cidade: vaga.cidade,
      estado: vaga.estado,
    });

    if (coordenadas) {
      vaga.latitude = coordenadas.latitude;
      vaga.longitude = coordenadas.longitude;
      await vagaRepository.save(vaga);
      vagasCorrigidas++;
    } else {
      vagasFalharam++;
    }

    await sleep(1000);
  }

  console.log("Backfill de coordenadas concluído.");
  console.log(`Alunos corrigidos: ${alunosCorrigidos}`);
  console.log(`Alunos com falha: ${alunosFalharam}`);
  console.log(`Vagas corrigidas: ${vagasCorrigidas}`);
  console.log(`Vagas com falha: ${vagasFalharam}`);

  await AppDataSource.destroy();
}

run().catch(async (error) => {
  console.error("Erro ao recalcular coordenadas:", error);
  if (AppDataSource.isInitialized) {
    await AppDataSource.destroy();
  }
  process.exit(1);
});

import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { AlunoHabilidade } from "../entities/AlunoHabilidade";
import { Habilidade, HabilidadeArea } from "../entities/Habilidade";
import { VagaHabilidade } from "../entities/VagaHabilidade";
import { habilidadesSeed } from "../data/habilidadesSeed";

function normalizarNomeHabilidade(nome: string): string {
  return nome.trim().replace(/\s+/g, " ");
}

function normalizarComparacaoHabilidade(nome: string): string {
  return normalizarNomeHabilidade(nome)
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
}

function validarArea(area: unknown): HabilidadeArea | null {
  if (typeof area !== "string") return null;
  return Object.values(HabilidadeArea).includes(area as HabilidadeArea)
    ? (area as HabilidadeArea)
    : null;
}

async function findByNomeNormalizado(nome: string) {
  const alvo = normalizarComparacaoHabilidade(nome);
  const habilidades = await AppDataSource.getRepository(Habilidade).find();
  return (
    habilidades.find(
      (habilidade) => normalizarComparacaoHabilidade(habilidade.nome) === alvo
    ) ?? null
  );
}

export class HabilidadeController {
  static async getAll(req: Request, res: Response) {
    try {
      const repo = AppDataSource.getRepository(Habilidade);
      const { busca, area } = req.query;

      if (area !== undefined && !validarArea(area)) {
        return res.status(400).json({
          message: "Área de habilidade inválida.",
        });
      }

      const query = repo
        .createQueryBuilder("habilidade")
        .select(["habilidade.id", "habilidade.nome", "habilidade.area"])
        .orderBy("habilidade.area", "ASC")
        .addOrderBy("habilidade.nome", "ASC");

      if (typeof busca === "string" && busca.trim()) {
        query.andWhere("LOWER(habilidade.nome) LIKE LOWER(:busca)", {
          busca: `%${busca.trim()}%`,
        });
      }

      if (typeof area === "string") {
        query.andWhere("habilidade.area = :area", { area });
      }

      const habilidades = await query.getMany();

      return res.status(200).json(habilidades);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao listar habilidades.",
        error: error.message,
      });
    }
  }

  static async create(req: Request, res: Response) {
    try {
      const { nome, area } = req.body;

      if (!nome || typeof nome !== "string" || !nome.trim()) {
        return res.status(400).json({
          message: "Campo nome é obrigatório.",
        });
      }

      const repo = AppDataSource.getRepository(Habilidade);
      const nomeNormalizado = normalizarNomeHabilidade(nome);
      const areaNormalizada = validarArea(area);

      if (!areaNormalizada) {
        return res.status(400).json({
          message: "Área de habilidade inválida.",
        });
      }

      const existente = await findByNomeNormalizado(nomeNormalizado);

      if (existente) {
        return res.status(409).json({
          message: "Habilidade já cadastrada.",
        });
      }

      const nova = repo.create({
        nome: nomeNormalizado,
        area: areaNormalizada,
      });

      const habilidadeSalva = await repo.save(nova);

      return res.status(201).json(habilidadeSalva);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao cadastrar habilidade.",
        error: error.message,
      });
    }
  }

  static async seed(req: Request, res: Response) {
    try {
      const repo = AppDataSource.getRepository(Habilidade);

      const criadas: Habilidade[] = [];
      const existentes: Habilidade[] = [];

      for (const habilidadeSeed of habilidadesSeed) {
        const nomeNormalizado = normalizarNomeHabilidade(habilidadeSeed.nome);
        const habilidadeExistente = await findByNomeNormalizado(nomeNormalizado);

        if (habilidadeExistente) {
          habilidadeExistente.nome = nomeNormalizado;
          habilidadeExistente.area = habilidadeSeed.area;
          await repo.save(habilidadeExistente);
          existentes.push(habilidadeExistente);
          continue;
        }

        const nova = repo.create({
          nome: nomeNormalizado,
          area: habilidadeSeed.area,
        });
        const salva = await repo.save(nova);
        criadas.push(salva);
      }

      return res.status(200).json({
        message: "Seed de habilidades executado com sucesso.",
        criadas,
        existentes,
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao executar seed de habilidades.",
        error: error.message,
      });
    }
  }

  static async delete(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const habilidadeId = Number(id);

      if (!Number.isInteger(habilidadeId) || habilidadeId <= 0) {
        return res.status(400).json({
          message: "ID de habilidade inválido.",
        });
      }

      const repo = AppDataSource.getRepository(Habilidade);
      const habilidade = await repo.findOne({
        where: { id: habilidadeId },
      });

      if (!habilidade) {
        return res.status(404).json({
          message: "Habilidade não encontrada.",
        });
      }

      const [vinculosAluno, vinculosVaga] = await Promise.all([
        AppDataSource.getRepository(AlunoHabilidade).count({
          where: { habilidade_id: habilidadeId },
        }),
        AppDataSource.getRepository(VagaHabilidade).count({
          where: { habilidade_id: habilidadeId },
        }),
      ]);

      if (vinculosAluno > 0 || vinculosVaga > 0) {
        return res.status(409).json({
          message:
            "Não é possível excluir esta habilidade porque ela está vinculada a alunos ou vagas.",
        });
      }

      await repo.remove(habilidade);

      return res.status(200).json({
        message: "Habilidade removida com sucesso.",
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao remover habilidade.",
        error: error.message,
      });
    }
  }

  static async update(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const habilidadeId = Number(id);

      if (!Number.isInteger(habilidadeId) || habilidadeId <= 0) {
        return res.status(400).json({
          message: "ID de habilidade inválido.",
        });
      }

      const { nome, area } = req.body;
      const repo = AppDataSource.getRepository(Habilidade);
      const habilidade = await repo.findOne({ where: { id: habilidadeId } });

      if (!habilidade) {
        return res.status(404).json({
          message: "Habilidade não encontrada.",
        });
      }

      if (!nome || typeof nome !== "string" || !nome.trim()) {
        return res.status(400).json({
          message: "Campo nome é obrigatório.",
        });
      }

      const areaNormalizada = validarArea(area);
      if (!areaNormalizada) {
        return res.status(400).json({
          message: "Área de habilidade inválida.",
        });
      }

      const nomeNormalizado = normalizarNomeHabilidade(nome);
      const existente = await findByNomeNormalizado(nomeNormalizado);
      if (existente && existente.id !== habilidade.id) {
        return res.status(409).json({
          message: "Habilidade já cadastrada.",
        });
      }

      habilidade.nome = nomeNormalizado;
      habilidade.area = areaNormalizada;

      const salva = await repo.save(habilidade);
      return res.status(200).json(salva);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao atualizar habilidade.",
        error: error.message,
      });
    }
  }
}

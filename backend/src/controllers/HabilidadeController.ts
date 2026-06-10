import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Habilidade } from "../entities/Habilidade";

const HABILIDADES_INICIAIS = [
  "Flutter",
  "Dart",
  "React",
  "Next.js",
  "TypeScript",
  "JavaScript",
  "Node.js",
  "Express",
  "Java",
  "Spring Boot",
  "Python",
  "PostgreSQL",
  "MySQL",
  "Docker",
  "Git",
  "GitHub",
  "APIs REST",
  "HTML",
  "CSS",
  "Figma",
  "UI/UX",
  "Comunicação",
  "Trabalho em equipe",
  "Inglês básico",
  "Inglês intermediário"
];

export class HabilidadeController {
  static async getAll(req: Request, res: Response) {
    try {
      const repo = AppDataSource.getRepository(Habilidade);

      const habilidades = await repo.find({
        order: { nome: "ASC" },
      });

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
      const { nome } = req.body;

      if (!nome || typeof nome !== "string" || !nome.trim()) {
        return res.status(400).json({
          message: "Campo nome é obrigatório.",
        });
      }

      const repo = AppDataSource.getRepository(Habilidade);
      const nomeNormalizado = nome.trim();

      const existente = await repo.findOne({
        where: { nome: nomeNormalizado },
      });

      if (existente) {
        return res.status(409).json({
          message: "Habilidade já cadastrada.",
        });
      }

      const nova = repo.create({
        nome: nomeNormalizado,
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

      for (const nome of HABILIDADES_INICIAIS) {
        const habilidadeExistente = await repo.findOne({
          where: { nome },
        });

        if (habilidadeExistente) {
          existentes.push(habilidadeExistente);
          continue;
        }

        const nova = repo.create({ nome });
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
}

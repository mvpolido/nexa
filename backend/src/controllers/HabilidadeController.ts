import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Habilidade } from "../entities/Habilidade";

export class HabilidadeController {
  static async getAll(req: Request, res: Response) {
    try {
      const repo = AppDataSource.getRepository(Habilidade);
      const habilidades = await repo.find({ order: { nome: "ASC" } });
      return res.status(200).json(habilidades);
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  static async create(req: Request, res: Response) {
    try {
      const { nome } = req.body;
      if (!nome || typeof nome !== "string" || !nome.trim()) {
        return res.status(400).json({ message: "Campo nome é obrigatório." });
      }

      const repo = AppDataSource.getRepository(Habilidade);
      const nomeNormalizado = nome.trim();
      const existente = await repo.findOne({ where: { nome: nomeNormalizado } });
      if (existente) return res.status(409).json({ message: "Habilidade já cadastrada." });

      const nova = repo.create({ nome: nomeNormalizado });
      await repo.save(nova);
      return res.status(201).json(nova);
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }
}
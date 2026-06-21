import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Habilidade, HabilidadeArea } from "../entities/Habilidade";

const HABILIDADES_INICIAIS = [
  { nome: "Flutter", area: HabilidadeArea.TECNOLOGIA },
  { nome: "Dart", area: HabilidadeArea.TECNOLOGIA },
  { nome: "React", area: HabilidadeArea.TECNOLOGIA },
  { nome: "Next.js", area: HabilidadeArea.TECNOLOGIA },
  { nome: "TypeScript", area: HabilidadeArea.TECNOLOGIA },
  { nome: "JavaScript", area: HabilidadeArea.TECNOLOGIA },
  { nome: "Node.js", area: HabilidadeArea.TECNOLOGIA },
  { nome: "Express", area: HabilidadeArea.TECNOLOGIA },
  { nome: "Java", area: HabilidadeArea.TECNOLOGIA },
  { nome: "Spring Boot", area: HabilidadeArea.TECNOLOGIA },
  { nome: "Python", area: HabilidadeArea.TECNOLOGIA },
  { nome: "Docker", area: HabilidadeArea.TECNOLOGIA },
  { nome: "Git", area: HabilidadeArea.TECNOLOGIA },
  { nome: "GitHub", area: HabilidadeArea.TECNOLOGIA },
  { nome: "APIs REST", area: HabilidadeArea.TECNOLOGIA },
  { nome: "PostgreSQL", area: HabilidadeArea.EXATAS },
  { nome: "MySQL", area: HabilidadeArea.EXATAS },
  { nome: "Estatística", area: HabilidadeArea.EXATAS },
  { nome: "Matemática aplicada", area: HabilidadeArea.EXATAS },
  { nome: "Análise de dados", area: HabilidadeArea.EXATAS },
  { nome: "CAD", area: HabilidadeArea.ENGENHARIA },
  { nome: "AutoCAD", area: HabilidadeArea.ENGENHARIA },
  { nome: "SolidWorks", area: HabilidadeArea.ENGENHARIA },
  { nome: "Leitura de projetos", area: HabilidadeArea.ENGENHARIA },
  { nome: "Controle de qualidade", area: HabilidadeArea.ENGENHARIA },
  { nome: "Saúde digital", area: HabilidadeArea.SAUDE },
  { nome: "Biossegurança", area: HabilidadeArea.SAUDE },
  { nome: "Atendimento ao paciente", area: HabilidadeArea.SAUDE },
  { nome: "Análise laboratorial", area: HabilidadeArea.QUIMICA },
  { nome: "Química analítica", area: HabilidadeArea.QUIMICA },
  { nome: "Controle de reagentes", area: HabilidadeArea.QUIMICA },
  { nome: "Modelagem física", area: HabilidadeArea.FISICA },
  { nome: "Instrumentação", area: HabilidadeArea.FISICA },
  { nome: "Medições técnicas", area: HabilidadeArea.FISICA },
  { nome: "Bioinformática", area: HabilidadeArea.BIOLOGIA },
  { nome: "Microbiologia", area: HabilidadeArea.BIOLOGIA },
  { nome: "Biotecnologia", area: HabilidadeArea.BIOLOGIA },
  { nome: "Comunicação", area: HabilidadeArea.COMUNICACAO },
  { nome: "Inglês básico", area: HabilidadeArea.COMUNICACAO },
  { nome: "Inglês intermediário", area: HabilidadeArea.COMUNICACAO },
  { nome: "Redação técnica", area: HabilidadeArea.COMUNICACAO },
  { nome: "Trabalho em equipe", area: HabilidadeArea.GESTAO },
  { nome: "Gestão de projetos", area: HabilidadeArea.GESTAO },
  { nome: "Organização", area: HabilidadeArea.GESTAO },
  { nome: "Liderança", area: HabilidadeArea.GESTAO },
  { nome: "Figma", area: HabilidadeArea.DESIGN },
  { nome: "UI/UX", area: HabilidadeArea.DESIGN },
  { nome: "HTML", area: HabilidadeArea.DESIGN },
  { nome: "CSS", area: HabilidadeArea.DESIGN },
  { nome: "Prototipação", area: HabilidadeArea.DESIGN }
];

export class HabilidadeController {
  static async getAll(req: Request, res: Response) {
    try {
      const repo = AppDataSource.getRepository(Habilidade);

      const habilidades = await repo.find({
        select: {
          id: true,
          nome: true,
          area: true,
        },
        order: { area: "ASC", nome: "ASC" },
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
      const { nome, area } = req.body;

      if (!nome || typeof nome !== "string" || !nome.trim()) {
        return res.status(400).json({
          message: "Campo nome é obrigatório.",
        });
      }

      const repo = AppDataSource.getRepository(Habilidade);
      const nomeNormalizado = nome.trim();
      const areaNormalizada = area ?? HabilidadeArea.TECNOLOGIA;

      if (!Object.values(HabilidadeArea).includes(areaNormalizada)) {
        return res.status(400).json({
          message: "Área de habilidade inválida.",
        });
      }

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

      for (const habilidadeSeed of HABILIDADES_INICIAIS) {
        const habilidadeExistente = await repo.findOne({
          where: { nome: habilidadeSeed.nome },
        });

        if (habilidadeExistente) {
          habilidadeExistente.area = habilidadeSeed.area;
          await repo.save(habilidadeExistente);
          existentes.push(habilidadeExistente);
          continue;
        }

        const nova = repo.create(habilidadeSeed);
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

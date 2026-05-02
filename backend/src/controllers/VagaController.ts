import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Vaga } from "../entities/Vaga";
import { Empresa } from "../entities/Empresa";
import { UsuarioPerfil } from "../entities/Usuario";

export class VagaController {
  // 1. Criar Vaga (Regra: Apenas Empresa pode criar / Aluno recebe 403)
  static async create(req: Request, res: Response) {
    const { titulo, descricao, requisitos, modalidade, latitude, longitude, habilidades } = req.body;
    
    // Dados injetados pelo authMiddleware
    const usuarioLogadoId = (req as any).usuarioId; 
    const perfilLogado = (req as any).usuarioPerfil;

    // Validação de Perfil (Critério de Aceite: Aluno recebe 403)
    if (perfilLogado !== UsuarioPerfil.EMPRESA) {
      return res.status(403).json({ 
        message: "Acesso negado: Apenas usuários do tipo Empresa podem publicar vagas." 
      });
    }

    try {
      const empresaRepository = AppDataSource.getRepository(Empresa);
      
      // Busca a empresa vinculada ao usuário logado
      const empresa = await empresaRepository.findOne({
        where: { usuario: { id: usuarioLogadoId } }
      });

      if (!empresa) {
        return res.status(404).json({ message: "Perfil de empresa não encontrado para este usuário." });
      }

      const vagaRepository = AppDataSource.getRepository(Vaga);
      const novaVaga = vagaRepository.create({
        titulo,
        descricao,
        requisitos,
        modalidade,
        latitude,
        longitude,
        habilidades,
        empresa
      });

      await vagaRepository.save(novaVaga);
      return res.status(201).json(novaVaga);
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  // 2. Listar todas as vagas (Qualquer usuário logado)
  static async getAll(req: Request, res: Response) {
    try {
      const vagaRepository = AppDataSource.getRepository(Vaga);
      const vagas = await vagaRepository.find({
        relations: ["empresa"] // Inclui dados da empresa que postou
      });
      return res.json(vagas);
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  // 3. Buscar vaga por ID
  static async getById(req: Request, res: Response) {
    const { id } = req.params;
    try {
      const vagaRepository = AppDataSource.getRepository(Vaga);
      const vaga = await vagaRepository.findOne({
        where: { id: parseInt(id) },
        relations: ["empresa"]
      });

      if (!vaga) {
        return res.status(404).json({ message: "Vaga não encontrada." });
      }

      return res.json(vaga);
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  // 4. Editar Vaga (Regra: Empresa só edita a própria / Não edita de outra)
  static async update(req: Request, res: Response) {
    const { id } = req.params;
    const dadosAtualizados = req.body;
    const usuarioLogadoId = (req as any).usuarioId;

    try {
      const vagaRepository = AppDataSource.getRepository(Vaga);
      const vaga = await vagaRepository.findOne({
        where: { id: parseInt(id) },
        relations: ["empresa", "empresa.usuario"]
      });

      if (!vaga) {
        return res.status(404).json({ message: "Vaga não encontrada." });
      }

      // Correção TS18048: Usando Optional Chaining (?.) para acesso seguro
      if (vaga.empresa?.usuario?.id !== usuarioLogadoId) {
        return res.status(403).json({ 
          message: "Acesso negado: Você não pode editar uma vaga que pertence a outra empresa." 
        });
      }

      vagaRepository.merge(vaga, dadosAtualizados);
      const resultado = await vagaRepository.save(vaga);
      
      return res.json(resultado);
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  // 5. Deletar Vaga (Regra: Empresa só deleta a própria)
  static async delete(req: Request, res: Response) {
    const { id } = req.params;
    const usuarioLogadoId = (req as any).usuarioId;

    try {
      const vagaRepository = AppDataSource.getRepository(Vaga);
      const vaga = await vagaRepository.findOne({
        where: { id: parseInt(id) },
        relations: ["empresa", "empresa.usuario"]
      });

      if (!vaga) {
        return res.status(404).json({ message: "Vaga não encontrada." });
      }

      // Correção TS18048: Usando Optional Chaining (?.) para acesso seguro
      if (vaga.empresa?.usuario?.id !== usuarioLogadoId) {
        return res.status(403).json({ 
          message: "Acesso negado: Você não tem permissão para remover esta vaga." 
        });
      }

      await vagaRepository.remove(vaga);
      return res.status(200).json({ message: "Vaga removida com sucesso." });
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }
}
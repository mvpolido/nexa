import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Vaga, VagaModalidade } from "../entities/Vaga";
import { Empresa } from "../entities/Empresa";
import { UsuarioPerfil } from "../entities/Usuario";

export class VagaController {
  static async create(req: Request, res: Response) {
    try {
      const {
        titulo,
        descricao,
        requisitos,
        modalidade,
        latitude,
        longitude,
        habilidades,
      } = req.body;

      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.EMPRESA) {
        return res.status(403).json({
          message: "Apenas empresas podem publicar vagas.",
        });
      }

      if (!titulo || !descricao || !modalidade) {
        return res.status(400).json({
          message: "Título, descrição e modalidade são obrigatórios.",
        });
      }

      if (!Object.values(VagaModalidade).includes(modalidade)) {
        return res.status(400).json({
          message: "Modalidade inválida.",
        });
      }

      const empresaRepository = AppDataSource.getRepository(Empresa);

      const empresa = await empresaRepository.findOne({
        where: { usuario: { id: usuarioLogadoId } }, // Busca a empresa que PERTENCE a esse usuário
      });

      if (!empresa) {
        return res.status(404).json({
          message: "Perfil de empresa não encontrado para este usuário.",
        });
      }

      const vagaRepository = AppDataSource.getRepository(Vaga);

      const novaVaga = vagaRepository.create({
        empresa_id: empresa.id,
        titulo,
        descricao,
        requisitos: requisitos || null,
        modalidade,
        latitude: latitude ?? empresa.latitude ?? null,
        longitude: longitude ?? empresa.longitude ?? null,
        habilidades: Array.isArray(habilidades) ? habilidades : [],
        ativo: 1,
      });

      const vagaSalva = await vagaRepository.save(novaVaga);

      return res.status(201).json(vagaSalva);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao criar vaga.",
        error: error.message,
      });
    }
  }

  static async getAll(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      const vagaRepository = AppDataSource.getRepository(Vaga);
      const empresaRepository = AppDataSource.getRepository(Empresa); 

      // 1. Lógica para a EMPRESA (vê apenas as próprias vagas)
      if (perfilLogado === UsuarioPerfil.EMPRESA) {
        const empresa = await empresaRepository.findOne({
          where: { usuario: { id: usuarioLogadoId } }, // Busca a empresa que PERTENCE a esse usuário
        });

        if (!empresa) {
          return res.status(404).json({ message: "Perfil de empresa não encontrado." });
        }

        const vagas = await vagaRepository.find({
          where: { empresa_id: empresa.id }, 
          relations: ["empresa"], 
          order: { criado_em: "DESC" },
        });

        return res.status(200).json(vagas);
      }

      // 2. Lógica para o ALUNO (vê todas as vagas ativas para a Home)
      const vagas = await vagaRepository.find({
        where: { ativo: 1 },
        relations: ["empresa"], 
        order: { criado_em: "DESC" },
      });

      return res.status(200).json(vagas);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao listar vagas.",
        error: error.message,
      });
    }
  }

  static async getById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      const vagaRepository = AppDataSource.getRepository(Vaga);

      const vaga = await vagaRepository.findOne({
        where: { id: Number(id) },
        relations: ["empresa"], // REMOVIDO "empresa.usuario" por segurança
      });

      if (!vaga) {
        return res.status(404).json({ message: "Vaga não encontrada." });
      }

      if (perfilLogado === UsuarioPerfil.ALUNO && vaga.ativo !== 1) {
        return res.status(404).json({ message: "Vaga não encontrada." });
      }

      
      if (perfilLogado === UsuarioPerfil.EMPRESA) {
        const empresaRepository = AppDataSource.getRepository(Empresa);
        const empresa = await empresaRepository.findOne({
          where: { usuario: { id: usuarioLogadoId } },
        });

        if (!empresa || vaga.empresa_id !== empresa.id) {
          return res.status(403).json({
            message: "Você só pode acessar vagas da sua própria empresa.",
          });
        }
      }

      return res.status(200).json(vaga);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao buscar vaga.",
        error: error.message,
      });
    }
  }

  static async update(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.EMPRESA) {
        return res.status(403).json({
          message: "Apenas empresas podem editar vagas.",
        });
      }

      const vagaRepository = AppDataSource.getRepository(Vaga);

      const vaga = await vagaRepository.findOne({
        where: { id: Number(id) },
      });

      if (!vaga) {
        return res.status(404).json({
          message: "Vaga não encontrada.",
        });
      }

      // CORREÇÃO: Busca a empresa do usuário logado antes de comparar
      const empresaRepository = AppDataSource.getRepository(Empresa);
      const empresa = await empresaRepository.findOne({
        where: { usuario: { id: usuarioLogadoId } },
      });

      if (!empresa || vaga.empresa_id !== empresa.id) {
        return res.status(403).json({
          message: "Você só pode editar vagas da sua própria empresa.",
        });
      }

      if (vaga.ativo !== 1) {
        return res.status(400).json({
          message: "Não é possível editar uma vaga arquivada.",
        });
      }

      const {
        titulo,
        descricao,
        requisitos,
        modalidade,
        latitude,
        longitude,
        habilidades,
      } = req.body;

      if (modalidade && !Object.values(VagaModalidade).includes(modalidade)) {
        return res.status(400).json({
          message: "Modalidade inválida.",
        });
      }

      vaga.titulo = titulo ?? vaga.titulo;
      vaga.descricao = descricao ?? vaga.descricao;
      vaga.requisitos = requisitos ?? vaga.requisitos;
      vaga.modalidade = modalidade ?? vaga.modalidade;
      vaga.latitude = latitude ?? vaga.latitude;
      vaga.longitude = longitude ?? vaga.longitude;
      vaga.habilidades = Array.isArray(habilidades)
        ? habilidades
        : vaga.habilidades;

      const vagaAtualizada = await vagaRepository.save(vaga);

      return res.status(200).json(vagaAtualizada);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao atualizar vaga.",
        error: error.message,
      });
    }
  }

  static async archive(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.EMPRESA) {
        return res.status(403).json({
          message: "Apenas empresas podem arquivar vagas.",
        });
      }

      const vagaRepository = AppDataSource.getRepository(Vaga);

      const vaga = await vagaRepository.findOne({
        where: { id: Number(id) },
      });

      if (!vaga) {
        return res.status(404).json({
          message: "Vaga não encontrada.",
        });
      }

      // CORREÇÃO: Busca a empresa do usuário logado antes de comparar
      const empresaRepository = AppDataSource.getRepository(Empresa);
      const empresa = await empresaRepository.findOne({
        where: { usuario: { id: usuarioLogadoId } },
      });

      if (!empresa || vaga.empresa_id !== empresa.id) {
        return res.status(403).json({
          message: "Você só pode arquivar vagas da sua própria empresa.",
        });
      }

      if (vaga.ativo !== 1) {
        return res.status(400).json({
          message: "Esta vaga já está arquivada.",
        });
      }

      vaga.ativo = 0;

      const vagaArquivada = await vagaRepository.save(vaga);

      return res.status(200).json({
        message: "Vaga arquivada com sucesso.",
        vaga: vagaArquivada,
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao arquivar vaga.",
        error: error.message,
      });
    }
  }

  static async unarchive(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.EMPRESA) {
        return res.status(403).json({
          message: "Apenas empresas podem desarquivar vagas.",
        });
      }

      const vagaRepository = AppDataSource.getRepository(Vaga);

      const vaga = await vagaRepository.findOne({
        where: { id: Number(id) },
      });

      if (!vaga) {
        return res.status(404).json({
          message: "Vaga não encontrada.",
        });
      }

      // CORREÇÃO: Busca a empresa do usuário logado antes de comparar
      const empresaRepository = AppDataSource.getRepository(Empresa);
      const empresa = await empresaRepository.findOne({
        where: { usuario: { id: usuarioLogadoId } },
      });

      if (!empresa || vaga.empresa_id !== empresa.id) {
        return res.status(403).json({
          message: "Você só pode desarquivar vagas da sua própria empresa.",
        });
      }

      if (vaga.ativo === 1) {
        return res.status(400).json({
          message: "Esta vaga já está ativa.",
        });
      }

      vaga.ativo = 1;

      const vagaDesarquivada = await vagaRepository.save(vaga);

      return res.status(200).json({
        message: "Vaga desarquivada com sucesso.",
        vaga: vagaDesarquivada,
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao desarquivar vaga.",
        error: error.message,
      });
    }
  }

  static async delete(req: Request, res: Response) {
    return VagaController.archive(req, res);
  }
}
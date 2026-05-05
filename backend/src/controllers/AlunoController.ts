import { Response } from "express";
import { AppDataSource } from "../data-source";
import { Aluno } from "../entities/Aluno";
import { Usuario } from "../entities/Usuario";
import { AuthRequest } from "../middleware/auth";

export class AlunoController {
  // GET /alunos/me - Buscar perfil do aluno logado
  static async getMe(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId;

      if (!userId) {
        return res.status(401).json({
          message: "Usuário não autenticado",
        });
      }

      const usuarioRepository = AppDataSource.getRepository(Usuario);
      const alunoRepository = AppDataSource.getRepository(Aluno);

      const usuario = await usuarioRepository.findOne({
        where: { id: userId },
      });

      if (!usuario) {
        return res.status(404).json({
          message: "Usuário não encontrado",
        });
      }

      const aluno = await alunoRepository.findOne({
        where: { id: userId },
      });

      if (!aluno) {
        return res.status(404).json({
          message: "Perfil do aluno não encontrado",
        });
      }

      return res.status(200).json({
        id: usuario.id,
        nome_exibicao: usuario.nome_exibicao,
        email: usuario.email,
        criado_em: usuario.criado_em,
        atualizado_em: usuario.atualizado_em,
        aluno: {
          cpf: aluno.cpf,
          curso: aluno.curso,
          url_curriculo: aluno.url_curriculo,
          latitude: aluno.latitude,
          longitude: aluno.longitude,
        },
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao buscar perfil",
        error: error.message,
      });
    }
  }

  // PUT /alunos/me - Atualizar perfil do aluno logado
  static async updateMe(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId;
      const { nome_exibicao, curso, url_curriculo, cpf, latitude, longitude } =
        req.body;

      if (!userId) {
        return res.status(401).json({
          message: "Usuário não autenticado",
        });
      }

      const usuarioRepository = AppDataSource.getRepository(Usuario);
      const alunoRepository = AppDataSource.getRepository(Aluno);

      const usuario = await usuarioRepository.findOne({
        where: { id: userId },
      });

      if (!usuario) {
        return res.status(404).json({
          message: "Usuário não encontrado",
        });
      }

      let aluno = await alunoRepository.findOne({
        where: { id: userId },
      });

      if (!aluno) {
        return res.status(404).json({
          message: "Perfil do aluno não encontrado",
        });
      }

      // Atualizar dados do usuário
      if (nome_exibicao) {
        usuario.nome_exibicao = nome_exibicao;
      }

      await usuarioRepository.save(usuario);

      // Atualizar dados do aluno
      if (curso) aluno.curso = curso;
      if (url_curriculo) aluno.url_curriculo = url_curriculo;
      if (cpf) aluno.cpf = cpf;
      if (latitude !== undefined) aluno.latitude = latitude;
      if (longitude !== undefined) aluno.longitude = longitude;

      aluno = await alunoRepository.save(aluno);

      return res.status(200).json({
        message: "Perfil atualizado com sucesso",
        data: {
          id: usuario.id,
          nome_exibicao: usuario.nome_exibicao,
          email: usuario.email,
          atualizado_em: usuario.atualizado_em,
          aluno: {
            cpf: aluno.cpf,
            curso: aluno.curso,
            url_curriculo: aluno.url_curriculo,
            latitude: aluno.latitude,
            longitude: aluno.longitude,
          },
        },
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao atualizar perfil",
        error: error.message,
      });
    }
  }

  // GET /alunos/:id - Buscar perfil de um aluno específico
  static async getById(req: AuthRequest, res: Response) {
    try {
      const { id } = req.params;

      const usuarioRepository = AppDataSource.getRepository(Usuario);
      const alunoRepository = AppDataSource.getRepository(Aluno);

      const usuario = await usuarioRepository.findOne({
        where: { id: parseInt(id) },
      });

      if (!usuario) {
        return res.status(404).json({
          message: "Usuário não encontrado",
        });
      }

      const aluno = await alunoRepository.findOne({
        where: { id: parseInt(id) },
      });

      if (!aluno) {
        return res.status(404).json({
          message: "Perfil do aluno não encontrado",
        });
      }

      return res.status(200).json({
        id: usuario.id,
        nome_exibicao: usuario.nome_exibicao,
        email: usuario.email,
        aluno: {
          cpf: aluno.cpf,
          curso: aluno.curso,
          url_curriculo: aluno.url_curriculo,
          latitude: aluno.latitude,
          longitude: aluno.longitude,
        },
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao buscar perfil",
        error: error.message,
      });
    }
  }
}

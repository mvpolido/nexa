import { Response } from "express";
import { AppDataSource } from "../data-source";
import { Aluno } from "../entities/Aluno";
import { Usuario } from "../entities/Usuario";
import { AuthRequest } from "../middleware/auth";
import { isValidCPF } from "../utils/validators";

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

      let aluno = await alunoRepository.findOne({
        where: { id: userId },
      });

      // Se o aluno não existe, criar um novo (pode ter falhado na criação anterior)
      if (!aluno) {
        console.warn(`⚠️ Aluno não encontrado para userId ${userId}, criando novo registro...`);
        aluno = alunoRepository.create({
          id: userId,
        });
        await alunoRepository.save(aluno);
        console.log(`✅ Novo registro de aluno criado para userId ${userId}`);
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
          instituicao: aluno.instituicao,
          endereco: aluno.endereco,
          logradouro: aluno.logradouro,
          cep: aluno.cep,
          numero: aluno.numero,
          bairro: aluno.bairro,
          cidade: aluno.cidade,
          estado: aluno.estado,
          foto_perfil: aluno.foto_perfil,
          skills: aluno.skills ? JSON.parse(aluno.skills) : [],
        },
      });
    } catch (error: any) {
      console.error("Erro ao buscar perfil:", error);
      return res.status(500).json({
        message: "Erro ao buscar perfil",
        error: error.message,
        details: error.stack,
      });
    }
  }

  // PUT /alunos/me - Atualizar perfil do aluno logado
  static async updateMe(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId;
      const { nome_exibicao, email, curso, url_curriculo, cpf, latitude, longitude, instituicao, skills, endereco, logradouro, cep, numero, bairro, cidade, estado, foto_perfil } =
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

      // Se o aluno não existe, criar um novo (pode ter falhado na criação anterior)
      if (!aluno) {
        console.warn(`⚠️ Aluno não encontrado para userId ${userId}, criando novo registro...`);
        aluno = alunoRepository.create({
          id: userId,
        });
        await alunoRepository.save(aluno);
        console.log(`✅ Novo registro de aluno criado para userId ${userId}`);
      }

      if (cpf && typeof cpf === "string" && cpf.trim() !== "" && !isValidCPF(cpf)) {
        return res.status(400).json({
          message: "CPF inválido",
        });
      }

      // Validar CEP (deve ter 8 dígitos)
      if (cep && typeof cep === "string" && cep.trim() !== "") {
        const cepLimpo = cep.replace(/[^0-9]/g, "");
        if (cepLimpo.length !== 8) {
          console.error(`❌ CEP inválido recebido: "${cep}" (limpo: "${cepLimpo}", tamanho: ${cepLimpo.length})`);
          return res.status(400).json({
            message: `CEP inválido: deve ter 8 dígitos, recebido ${cepLimpo.length}`,
          });
        }
        console.log(`✅ CEP validado: "${cep}" -> "${cepLimpo}"`);
      }

      // Validar estado (deve ser uma sigla de 2 caracteres)
      if (estado && typeof estado === "string" && estado.trim() !== "") {
        if (estado.trim().length !== 2) {
          console.error(`❌ Estado inválido recebido: "${estado}" (tamanho: ${estado.trim().length})`);
          return res.status(400).json({
            message: `Estado inválido: deve ser uma sigla de 2 caracteres (ex: PR)`,
          });
        }
        console.log(`✅ Estado validado: "${estado}"`);
      }

      // Atualizar dados do usuário
      if (nome_exibicao) {
        usuario.nome_exibicao = nome_exibicao;
      }

      if (email !== undefined && typeof email === "string" && email.trim() !== "") {
        const normalizedEmail = email.trim().toLowerCase();
        if (normalizedEmail !== usuario.email) {
          const existing = await usuarioRepository.findOne({ where: { email: normalizedEmail } });
          if (existing && existing.id !== usuario.id) {
            return res.status(409).json({
              message: "Email já cadastrado",
            });
          }
          usuario.email = normalizedEmail;
        }
      }

      await usuarioRepository.save(usuario);

      // Atualizar dados do aluno
      if (curso) aluno.curso = curso;
      if (url_curriculo) aluno.url_curriculo = url_curriculo;
      if (cpf) aluno.cpf = cpf;
      if (latitude !== undefined) aluno.latitude = latitude;
      if (longitude !== undefined) aluno.longitude = longitude;
      if (instituicao) aluno.instituicao = instituicao;
      if (endereco) aluno.endereco = endereco;
      if (logradouro !== undefined) aluno.logradouro = logradouro || undefined;
      // Limpar CEP removendo formatação (apenas dígitos)
      if (cep !== undefined) {
        const cepLimpo = cep ? cep.replace(/[^0-9]/g, "") : undefined;
        if (cepLimpo && cepLimpo.length === 8) {
          aluno.cep = cepLimpo;
          console.log(`💾 CEP salvo: "${cepLimpo}"`);
        } else {
          aluno.cep = undefined;
        }
      }
      if (numero !== undefined) aluno.numero = numero || undefined;
      if (bairro !== undefined) aluno.bairro = bairro || undefined;
      if (cidade !== undefined) aluno.cidade = cidade || undefined;
      // Garantir que estado seja sempre maiúsculo e limitado a 2 caracteres
      if (estado !== undefined) {
        aluno.estado = estado ? estado.toUpperCase().substring(0, 2) : undefined;
        if (aluno.estado) {
          console.log(`💾 Estado salvo: "${aluno.estado}"`);
        }
      }
      if (foto_perfil !== undefined) aluno.foto_perfil = foto_perfil || undefined;
      if (skills !== undefined) {
        if (Array.isArray(skills)) {
          aluno.skills = JSON.stringify(skills);
        } else if (typeof skills === 'string') {
          try {
            const parsed = JSON.parse(skills);
            if (Array.isArray(parsed)) aluno.skills = JSON.stringify(parsed);
            else aluno.skills = skills;
          } catch {
            aluno.skills = skills;
          }
        }
      }

      aluno = await alunoRepository.save(aluno);
      console.log(`✅ Perfil do aluno salvo com sucesso - CEP: "${aluno.cep}", Estado: "${aluno.estado}"`);

      return res.status(200).json({
        message: "Perfil atualizado com sucesso",
        data: {
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
            instituicao: aluno.instituicao,
            endereco: aluno.endereco,
            cep: aluno.cep,
            numero: aluno.numero,
            bairro: aluno.bairro,
            cidade: aluno.cidade,
            estado: aluno.estado,
            foto_perfil: aluno.foto_perfil,
            skills: aluno.skills ? JSON.parse(aluno.skills) : [],
          },
        },
      });
    } catch (error: any) {
      console.error("Erro ao atualizar perfil:", error);
      return res.status(500).json({
        message: "Erro ao atualizar perfil",
        error: error.message,
        details: error.stack,
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
          instituicao: aluno.instituicao,
          endereco: aluno.endereco,
          cep: aluno.cep,
          numero: aluno.numero,
          bairro: aluno.bairro,
          cidade: aluno.cidade,
          estado: aluno.estado,
          foto_perfil: aluno.foto_perfil,
          skills: aluno.skills ? JSON.parse(aluno.skills) : [],
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

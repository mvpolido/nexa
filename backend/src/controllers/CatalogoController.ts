import { Request, Response } from "express";
import jwt from "jsonwebtoken";
import { AppDataSource } from "../data-source";
import { Aluno } from "../entities/Aluno";
import { Curso } from "../entities/Curso";
import { InstituicaoEnsino } from "../entities/InstituicaoEnsino";
import { UsuarioPerfil } from "../entities/Usuario";
import { getJwtSecret } from "../utils/jwtSecret";

type CatalogoTipo = "curso" | "instituicao";

function normalizarTexto(value: string): string {
  return value.trim().replace(/\s+/g, " ");
}

function normalizarComparacao(value: string): string {
  return normalizarTexto(value)
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
}

function parseBoolean(value: unknown): boolean | null {
  if (value === true || value === "true") return true;
  if (value === false || value === "false") return false;
  return null;
}

function isAdminAutenticado(req: Request): boolean {
  const authHeader = req.headers.authorization;
  if (!authHeader) return false;

  const [type, token] = authHeader.split(" ");
  if (type !== "Bearer" || !token) return false;

  try {
    const decoded = jwt.verify(token, getJwtSecret()) as { perfil?: string };
    return decoded.perfil === UsuarioPerfil.ADMIN;
  } catch {
    return false;
  }
}

async function findCursoByNomeNormalizado(nome: string) {
  const alvo = normalizarComparacao(nome);
  const cursos = await AppDataSource.getRepository(Curso).find();
  return cursos.find((curso) => normalizarComparacao(curso.nome) === alvo) ?? null;
}

async function findInstituicaoByNomeNormalizado(nome: string) {
  const alvo = normalizarComparacao(nome);
  const instituicoes = await AppDataSource.getRepository(InstituicaoEnsino).find();
  return (
    instituicoes.find(
      (instituicao) => normalizarComparacao(instituicao.nome) === alvo
    ) ?? null
  );
}

export async function catalogoAtivoExiste(tipo: CatalogoTipo, nome: string) {
  const nomeNormalizado = normalizarTexto(nome);
  if (!nomeNormalizado) return false;

  if (tipo === "curso") {
    const curso = await findCursoByNomeNormalizado(nomeNormalizado);
    return Boolean(curso?.ativo);
  }

  const instituicao = await findInstituicaoByNomeNormalizado(nomeNormalizado);
  return Boolean(instituicao?.ativa);
}

export async function catalogoPodeManterValorAntigo(
  tipo: CatalogoTipo,
  nomeNovo: string,
  nomeAtual?: string | null
) {
  const novo = normalizarTexto(nomeNovo);
  if (!novo) return false;
  if (
    nomeAtual &&
    normalizarComparacao(nomeAtual) === normalizarComparacao(novo)
  ) {
    return true;
  }
  return catalogoAtivoExiste(tipo, novo);
}

export class CatalogoController {
  static async listarCursosPublico(req: Request, res: Response) {
    try {
      const incluirInativos = req.query.incluirInativos === "true";
      if (incluirInativos && !isAdminAutenticado(req)) {
        return res.status(403).json({
          message: "Apenas moderadores podem consultar cursos inativos.",
        });
      }

      return CatalogoController.listarCursosBase(req, res, incluirInativos);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao listar cursos.",
        error: error.message,
      });
    }
  }

  static async listarInstituicoesPublico(req: Request, res: Response) {
    try {
      const incluirInativos = req.query.incluirInativos === "true";
      if (incluirInativos && !isAdminAutenticado(req)) {
        return res.status(403).json({
          message: "Apenas moderadores podem consultar instituições inativas.",
        });
      }

      return CatalogoController.listarInstituicoesBase(req, res, incluirInativos);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao listar instituições.",
        error: error.message,
      });
    }
  }

  static async listarCursosAdmin(req: Request, res: Response) {
    return CatalogoController.listarCursosBase(req, res, true);
  }

  static async listarInstituicoesAdmin(req: Request, res: Response) {
    return CatalogoController.listarInstituicoesBase(req, res, true);
  }

  private static async listarCursosBase(
    req: Request,
    res: Response,
    incluirInativos: boolean
  ) {
    const repo = AppDataSource.getRepository(Curso);
    const busca = typeof req.query.busca === "string" ? req.query.busca.trim() : "";
    const ativoFiltro = parseBoolean(req.query.ativo);

    const query = repo
      .createQueryBuilder("curso")
      .orderBy("curso.nome", "ASC");

    if (!incluirInativos) {
      query.andWhere("curso.ativo = :ativo", { ativo: true });
    } else if (ativoFiltro !== null) {
      query.andWhere("curso.ativo = :ativo", { ativo: ativoFiltro });
    }

    if (busca) {
      query.andWhere("LOWER(curso.nome) LIKE LOWER(:busca)", {
        busca: `%${busca}%`,
      });
    }

    const cursos = await query.getMany();
    return res.status(200).json(cursos);
  }

  private static async listarInstituicoesBase(
    req: Request,
    res: Response,
    incluirInativos: boolean
  ) {
    const repo = AppDataSource.getRepository(InstituicaoEnsino);
    const busca = typeof req.query.busca === "string" ? req.query.busca.trim() : "";
    const ativaFiltro = parseBoolean(req.query.ativa);

    const query = repo
      .createQueryBuilder("instituicao")
      .orderBy("instituicao.nome", "ASC");

    if (!incluirInativos) {
      query.andWhere("instituicao.ativa = :ativa", { ativa: true });
    } else if (ativaFiltro !== null) {
      query.andWhere("instituicao.ativa = :ativa", { ativa: ativaFiltro });
    }

    if (busca) {
      query.andWhere(
        "(LOWER(instituicao.nome) LIKE LOWER(:busca) OR LOWER(instituicao.sigla) LIKE LOWER(:busca))",
        { busca: `%${busca}%` }
      );
    }

    const instituicoes = await query.getMany();
    return res.status(200).json(instituicoes);
  }

  static async criarCurso(req: Request, res: Response) {
    try {
      const nome = typeof req.body.nome === "string" ? normalizarTexto(req.body.nome) : "";
      if (!nome) return res.status(400).json({ message: "Campo nome é obrigatório." });

      const repo = AppDataSource.getRepository(Curso);
      const existente = await findCursoByNomeNormalizado(nome);
      if (existente) {
        return res.status(409).json({ message: "Curso já cadastrado." });
      }

      const curso = await repo.save(repo.create({ nome, ativo: true }));
      return res.status(201).json(curso);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao cadastrar curso.",
        error: error.message,
      });
    }
  }

  static async atualizarCurso(req: Request, res: Response) {
    try {
      const id = Number(req.params.id);
      if (!Number.isInteger(id) || id <= 0) {
        return res.status(400).json({ message: "ID de curso inválido." });
      }

      const repo = AppDataSource.getRepository(Curso);
      const curso = await repo.findOne({ where: { id } });
      if (!curso) return res.status(404).json({ message: "Curso não encontrado." });

      if (Object.prototype.hasOwnProperty.call(req.body, "nome")) {
        const nome = typeof req.body.nome === "string" ? normalizarTexto(req.body.nome) : "";
        if (!nome) return res.status(400).json({ message: "Campo nome é obrigatório." });
        const existente = await findCursoByNomeNormalizado(nome);
        if (existente && existente.id !== curso.id) {
          return res.status(409).json({ message: "Curso já cadastrado." });
        }
        curso.nome = nome;
      }

      if (Object.prototype.hasOwnProperty.call(req.body, "ativo")) {
        const ativo = parseBoolean(req.body.ativo);
        if (ativo === null) {
          return res.status(400).json({ message: "Campo ativo deve ser booleano." });
        }
        curso.ativo = ativo;
      }

      return res.status(200).json(await repo.save(curso));
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao atualizar curso.",
        error: error.message,
      });
    }
  }

  static async deletarCurso(req: Request, res: Response) {
    try {
      const id = Number(req.params.id);
      if (!Number.isInteger(id) || id <= 0) {
        return res.status(400).json({ message: "ID de curso inválido." });
      }

      const repo = AppDataSource.getRepository(Curso);
      const curso = await repo.findOne({ where: { id } });
      if (!curso) return res.status(404).json({ message: "Curso não encontrado." });

      const uso = await AppDataSource.getRepository(Aluno).count({
        where: { curso: curso.nome },
      });

      if (uso > 0) {
        curso.ativo = false;
        await repo.save(curso);
        return res.status(200).json({
          message: "Curso inativado porque já está em uso por alunos.",
          curso,
        });
      }

      await repo.remove(curso);
      return res.status(200).json({ message: "Curso removido com sucesso." });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao remover curso.",
        error: error.message,
      });
    }
  }

  static async criarInstituicao(req: Request, res: Response) {
    try {
      const nome = typeof req.body.nome === "string" ? normalizarTexto(req.body.nome) : "";
      const sigla =
        typeof req.body.sigla === "string" && req.body.sigla.trim()
          ? normalizarTexto(req.body.sigla)
          : null;
      if (!nome) return res.status(400).json({ message: "Campo nome é obrigatório." });

      const repo = AppDataSource.getRepository(InstituicaoEnsino);
      const existente = await findInstituicaoByNomeNormalizado(nome);
      if (existente) {
        return res.status(409).json({ message: "Instituição já cadastrada." });
      }

      const instituicao = await repo.save(repo.create({ nome, sigla, ativa: true }));
      return res.status(201).json(instituicao);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao cadastrar instituição.",
        error: error.message,
      });
    }
  }

  static async atualizarInstituicao(req: Request, res: Response) {
    try {
      const id = Number(req.params.id);
      if (!Number.isInteger(id) || id <= 0) {
        return res.status(400).json({ message: "ID de instituição inválido." });
      }

      const repo = AppDataSource.getRepository(InstituicaoEnsino);
      const instituicao = await repo.findOne({ where: { id } });
      if (!instituicao) {
        return res.status(404).json({ message: "Instituição não encontrada." });
      }

      if (Object.prototype.hasOwnProperty.call(req.body, "nome")) {
        const nome = typeof req.body.nome === "string" ? normalizarTexto(req.body.nome) : "";
        if (!nome) return res.status(400).json({ message: "Campo nome é obrigatório." });
        const existente = await findInstituicaoByNomeNormalizado(nome);
        if (existente && existente.id !== instituicao.id) {
          return res.status(409).json({ message: "Instituição já cadastrada." });
        }
        instituicao.nome = nome;
      }

      if (Object.prototype.hasOwnProperty.call(req.body, "sigla")) {
        instituicao.sigla =
          typeof req.body.sigla === "string" && req.body.sigla.trim()
            ? normalizarTexto(req.body.sigla)
            : null;
      }

      if (Object.prototype.hasOwnProperty.call(req.body, "ativa")) {
        const ativa = parseBoolean(req.body.ativa);
        if (ativa === null) {
          return res.status(400).json({ message: "Campo ativa deve ser booleano." });
        }
        instituicao.ativa = ativa;
      }

      return res.status(200).json(await repo.save(instituicao));
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao atualizar instituição.",
        error: error.message,
      });
    }
  }

  static async deletarInstituicao(req: Request, res: Response) {
    try {
      const id = Number(req.params.id);
      if (!Number.isInteger(id) || id <= 0) {
        return res.status(400).json({ message: "ID de instituição inválido." });
      }

      const repo = AppDataSource.getRepository(InstituicaoEnsino);
      const instituicao = await repo.findOne({ where: { id } });
      if (!instituicao) {
        return res.status(404).json({ message: "Instituição não encontrada." });
      }

      const uso = await AppDataSource.getRepository(Aluno).count({
        where: { instituicao: instituicao.nome },
      });

      if (uso > 0) {
        instituicao.ativa = false;
        await repo.save(instituicao);
        return res.status(200).json({
          message: "Instituição inativada porque já está em uso por alunos.",
          instituicao,
        });
      }

      await repo.remove(instituicao);
      return res.status(200).json({ message: "Instituição removida com sucesso." });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao remover instituição.",
        error: error.message,
      });
    }
  }
}

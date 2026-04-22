import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Usuario, UsuarioPerfil } from "../entities/Usuario";
import bcrypt from "bcrypt";

export class UserController {
  static async create(req: Request, res: Response) {
    const { nome_exibicao, email, senha_hash, perfil } = req.body;

    if (!nome_exibicao || !email || !senha_hash || !perfil) {
      return res.status(400).json({ message: "Campos obrigatórios faltando" });
    }

    const usuarioRepository = AppDataSource.getRepository(Usuario);

    try {
      const hashedPassword = await bcrypt.hash(senha_hash, 10);

      const newUser = usuarioRepository.create({
        nome_exibicao,
        email,
        senha_hash: hashedPassword,
        perfil
      });

      await usuarioRepository.save(newUser);

      const { senha_hash: _, ...userWithoutPassword } = newUser;
      return res.status(201).json(userWithoutPassword);
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  static async getAll(req: Request, res: Response) {
    const usuarioRepository = AppDataSource.getRepository(Usuario);

    try {
      const users = await usuarioRepository.find({
        select: ["id", "nome_exibicao", "email", "perfil", "criado_em"]
      });

      return res.json(users);
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  static async getById(req: Request, res: Response) {
    const { id } = req.params;
    const usuarioRepository = AppDataSource.getRepository(Usuario);

    try {
      const user = await usuarioRepository.findOne({
        where: { id: parseInt(id) }
      });

      if (!user) {
        return res.status(404).json({ message: "Usuário não encontrado" });
      }

      const { senha_hash: _, ...userWithoutPassword } = user;
      return res.json(userWithoutPassword);
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  static async update(req: Request, res: Response) {
    const { id } = req.params;
    const { nome_exibicao, perfil } = req.body;
    const usuarioRepository = AppDataSource.getRepository(Usuario);

    try {
      let user = await usuarioRepository.findOne({
        where: { id: parseInt(id) }
      });

      if (!user) {
        return res.status(404).json({ message: "Usuário não encontrado" });
      }

      user.nome_exibicao = nome_exibicao || user.nome_exibicao;
      user.perfil = perfil || user.perfil;

      await usuarioRepository.save(user);

      const { senha_hash: _, ...userWithoutPassword } = user;
      return res.json(userWithoutPassword);
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  static async delete(req: Request, res: Response) {
    const { id } = req.params;
    const usuarioRepository = AppDataSource.getRepository(Usuario);

    try {
      const result = await usuarioRepository.delete(parseInt(id));

      if (result.affected === 0) {
        return res.status(404).json({ message: "Usuário não encontrado" });
      }

      return res.json({ message: "Usuário deletado com sucesso" });
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }
}

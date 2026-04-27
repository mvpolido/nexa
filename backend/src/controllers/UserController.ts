import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Usuario } from "../entities/Usuario"; // 👈 Nome atualizado
import bcrypt from "bcrypt";

export class UserController {
  static async create(req: Request, res: Response): Promise<Response> {
    const { nome_exibicao, email, senha, perfil } = req.body;
    const userRepository = AppDataSource.getRepository(Usuario); // 👈

    const userExists = await userRepository.findOneBy({ email });
    if (userExists) {
      return res.status(400).json({ message: "E-mail já cadastrado" });
    }

    const hashedPassword = await bcrypt.hash(senha, 10);
    
    const newUser = userRepository.create({
      nome_exibicao,
      email,
      senha_hash: hashedPassword, 
      perfil,
    });

    await userRepository.save(newUser);
    
    // 🛡️ Segurança: Removemos a senha do retorno
    const { senha_hash: _, ...usuarioSemSenha } = newUser;

    return res.status(201).json(usuarioSemSenha);
  }

  static async getAll(req: Request, res: Response): Promise<Response> {
    const userRepository = AppDataSource.getRepository(Usuario);
    const users = await userRepository.find(); 
    return res.json(users);
  }

  static async getById(req: Request, res: Response): Promise<Response> {
    const { id } = req.params;
    const userRepository = AppDataSource.getRepository(Usuario);
    const user = await userRepository.findOneBy({ id: Number(id) }); // 👈 Ajustado para Number se o ID for numérico

    if (!user) return res.status(404).json({ message: "Usuário não encontrado" });
    return res.json(user);
  }

  static async update(req: Request, res: Response): Promise<Response> {
    const { id } = req.params;
    const { nome_exibicao, perfil } = req.body;
    const userRepository = AppDataSource.getRepository(Usuario);

    const user = await userRepository.findOneBy({ id: Number(id) });
    if (!user) return res.status(404).json({ message: "Usuário não encontrado" });

    user.nome_exibicao = nome_exibicao || user.nome_exibicao;
    user.perfil = perfil || user.perfil;

    await userRepository.save(user);
    const { senha_hash: _, ...usuarioSemSenha } = user;
    return res.json({ message: "Usuário atualizado!", user: usuarioSemSenha });
  }

  static async delete(req: Request, res: Response): Promise<Response> {
    const { id } = req.params;
    const userRepository = AppDataSource.getRepository(Usuario);
    const user = await userRepository.findOneBy({ id: Number(id) });

    if (!user) return res.status(404).json({ message: "Usuário não encontrado" });

    await userRepository.remove(user);
    return res.status(200).json({ message: "Usuário deletado com sucesso!" });
  }
}
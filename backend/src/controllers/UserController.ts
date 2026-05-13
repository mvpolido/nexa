import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Usuario } from "../entities/Usuario";
import bcrypt from "bcrypt";

export class UserController {
  static async create(req: Request, res: Response): Promise<Response> {
    // 1. Recebemos os campos (incluindo 'senha' vinda do Swagger)
    const { nome_exibicao, email, senha, perfil } = req.body;
    const userRepository = AppDataSource.getRepository(Usuario);

    // 2. Validação de campos obrigatórios
    if (!nome_exibicao || !email || !senha || !perfil) {
      return res.status(400).json({ message: "Campos obrigatórios faltando" });
    }

    try {
      // 3. Verifica se o e-mail já existe
      const userExists = await userRepository.findOneBy({ email });
      if (userExists) {
        return res.status(400).json({ message: "E-mail já cadastrado" });
      }

      // 4. Hash da senha
      const hashedPassword = await bcrypt.hash(senha, 10);
      
      const newUser = userRepository.create({
        nome_exibicao,
        email,
        senha_hash: hashedPassword, 
        perfil,
      });

      // 5. Salva no banco
      await userRepository.save(newUser);
      
      // 6. Segurança: Removemos a senha do retorno
      const { senha_hash: _, ...usuarioSemSenha } = newUser;
      return res.status(201).json(usuarioSemSenha);

    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  static async getAll(req: Request, res: Response): Promise<Response> {
    const userRepository = AppDataSource.getRepository(Usuario);
    const users = await userRepository.find(); 
    return res.json(users);
  }

  static async getById(req: Request, res: Response): Promise<Response> {
    const { id } = req.params;
    const userRepository = AppDataSource.getRepository(Usuario);
    const user = await userRepository.findOneBy({ id: Number(id) });

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
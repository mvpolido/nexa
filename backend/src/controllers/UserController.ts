import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { User } from "../entities/User";
import bcrypt from "bcrypt";

export class UserController {
  // 1. CREATE - Criar usuário
  static async create(req: Request, res: Response): Promise<Response> {
    const { nome_exibicao, email, senha, perfil } = req.body;
    const userRepository = AppDataSource.getRepository(User);

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
    
    // 🛡️ Segurança: Removemos o senha_hash antes de enviar o JSON
    const { senha_hash: _, ...usuarioSemSenha } = newUser;

    return res.status(201).json(usuarioSemSenha);
  }

  // 2. READ ALL - Listar todos
  static async getAll(req: Request, res: Response): Promise<Response> {
    const userRepository = AppDataSource.getRepository(User);
    // Aqui o 'select: false' da Entity funciona automaticamente
    const users = await userRepository.find(); 
    return res.json(users);
  }

  // 3. READ BY ID - Buscar um
  static async getById(req: Request, res: Response): Promise<Response> {
    const { id } = req.params;
    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOneBy({ id });

    if (!user) return res.status(404).json({ message: "Usuário não encontrado" });

    return res.json(user);
  }

  // 4. UPDATE - Atualizar
  static async update(req: Request, res: Response): Promise<Response> {
    const { id } = req.params;
    const { nome_exibicao, perfil } = req.body;
    const userRepository = AppDataSource.getRepository(User);

    const user = await userRepository.findOneBy({ id });
    if (!user) return res.status(404).json({ message: "Usuário não encontrado" });

    user.nome_exibicao = nome_exibicao || user.nome_exibicao;
    user.perfil = perfil || user.perfil;

    await userRepository.save(user);
    
    // Limpando o objeto de retorno no update também por garantia
    const { senha_hash: _, ...usuarioSemSenha } = user;
    return res.json({ 
      message: "Usuário atualizado com sucesso!",
      user: usuarioSemSenha 
    });
  }

  // 5. DELETE - Deletar
  static async delete(req: Request, res: Response): Promise<Response> {
    const { id } = req.params;
    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOneBy({ id });

    if (!user) return res.status(404).json({ message: "Usuário não encontrado" });

    await userRepository.remove(user);
    return res.status(200).json({ message: "Usuário deletado com sucesso!" });
  }
}
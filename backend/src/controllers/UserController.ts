import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { User } from "../entities/User";
import bcrypt from "bcrypt";

export class UserController {
  // 1. CREATE - Criar usuário
  static async create(req: Request, res: Response): Promise<Response> {
    const { name, email, password, role } = req.body;
    const userRepository = AppDataSource.getRepository(User);

    const userExists = await userRepository.findOneBy({ email });
    if (userExists) {
      return res.status(400).json({ message: "E-mail já cadastrado" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = userRepository.create({
      name,
      email,
      password: hashedPassword,
      role,
    });

    await userRepository.save(newUser);
    
    // Remove a senha do retorno por segurança
    const { password: _, ...userWithoutPassword } = newUser;
    return res.status(201).json(userWithoutPassword);
  }

  // 2. READ ALL - Listar todos
  static async getAll(req: Request, res: Response): Promise<Response> {
    const userRepository = AppDataSource.getRepository(User);
    const users = await userRepository.find({
      select: ["id", "name", "email", "role", "created_at"]
    });
    return res.json(users);
  }

  // 3. READ BY ID - Buscar um
  static async getById(req: Request, res: Response): Promise<Response> {
    const { id } = req.params;
    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOneBy({ id });

    if (!user) return res.status(404).json({ message: "Usuário não encontrado" });

    const { password: _, ...userWithoutPassword } = user;
    return res.json(userWithoutPassword);
  }

  // 4. UPDATE - Atualizar
  static async update(req: Request, res: Response): Promise<Response> {
    const { id } = req.params;
    const { name, role } = req.body;
    const userRepository = AppDataSource.getRepository(User);

    const user = await userRepository.findOneBy({ id });
    if (!user) return res.status(404).json({ message: "Usuário não encontrado" });

    user.name = name || user.name;
    user.role = role || user.role;

    await userRepository.save(user);
    return res.json({ message: "Usuário atualizado com sucesso!" });
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
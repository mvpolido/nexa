import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Empresa } from "../entities/Empresa";
import { Habilidade } from "../entities/Habilidade";
import { Usuario } from "../entities/Usuario";
import { Vaga } from "../entities/Vaga";

export class AdminController {
  // Verificar empresa 
  static async verificarEmpresa(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params; // ID da empresa
      const empresaRepository = AppDataSource.getRepository(Empresa);

      const empresa = await empresaRepository.findOneBy({ id: Number(id) });

      if (!empresa) {
        return res.status(404).json({ message: "Empresa não encontrada." });
      }

      empresa.verificada = true; // Aplica o selo
      await empresaRepository.save(empresa);

      return res.status(200).json({ 
        message: "Empresa verificada com sucesso!", 
        empresa 
      });
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao verificar empresa", error: error.message });
    }
  }

  // Listar vagas suspeitas
  static async listarVagas(req: Request, res: Response): Promise<Response> {
    try {
      const vagaRepository = AppDataSource.getRepository(Vaga);
      
      // Traz as vagas junto com as informações da empresa que as postou
      const vagas = await vagaRepository.find({
        relations: ["empresa", "empresa.usuario"]
      });

      return res.status(200).json(vagas);
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao buscar vagas", error: error.message });
    }
  }

  // Apagar vaga suspeita
  static async deletarVaga(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const vagaRepository = AppDataSource.getRepository(Vaga);

      const vaga = await vagaRepository.findOneBy({ id: Number(id) });

      if (!vaga) {
        return res.status(404).json({ message: "Vaga não encontrada." });
      }

      await vagaRepository.remove(vaga);

      return res.status(200).json({ message: "Vaga removida com sucesso por violação de termos." });
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao deletar vaga", error: error.message });
    }
  }

  static async deletarUsuario(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const usuarioId = Number(id);

      if (Number.isNaN(usuarioId)) {
        return res.status(400).json({ message: "ID de usuário inválido." });
      }

      const usuarioRepository = AppDataSource.getRepository(Usuario);
      const usuario = await usuarioRepository.findOneBy({ id: usuarioId });

      if (!usuario) {
        return res.status(404).json({ message: "Usuário não encontrado." });
      }

      await usuarioRepository.remove(usuario);

      return res.status(200).json({ message: "Usuário removido com sucesso." });
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao deletar usuário", error: error.message });
    }
  }

  static async criarHabilidade(req: Request, res: Response): Promise<Response> {
    try {
      const { nome } = req.body;

      if (!nome || typeof nome !== "string" || !nome.trim()) {
        return res.status(400).json({ message: "Campo nome é obrigatório." });
      }

      const habilidadeRepository = AppDataSource.getRepository(Habilidade);
      const nomeNormalizado = nome.trim();

      const existente = await habilidadeRepository.findOne({ where: { nome: nomeNormalizado } });
      if (existente) {
        return res.status(409).json({ message: "Habilidade já cadastrada." });
      }

      const habilidade = habilidadeRepository.create({ nome: nomeNormalizado });
      const habilidadeSalva = await habilidadeRepository.save(habilidade);

      return res.status(201).json({
        message: "Habilidade criada com sucesso.",
        habilidade: habilidadeSalva,
      });
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao criar habilidade", error: error.message });
    }
  }

  static async deletarHabilidade(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const habilidadeId = Number(id);

      if (Number.isNaN(habilidadeId)) {
        return res.status(400).json({ message: "ID de habilidade inválido." });
      }

      const habilidadeRepository = AppDataSource.getRepository(Habilidade);
      const habilidade = await habilidadeRepository.findOneBy({ id: habilidadeId });

      if (!habilidade) {
        return res.status(404).json({ message: "Habilidade não encontrada." });
      }

      await habilidadeRepository.remove(habilidade);

      return res.status(200).json({ message: "Habilidade removida com sucesso." });
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao deletar habilidade", error: error.message });
    }
  }
}
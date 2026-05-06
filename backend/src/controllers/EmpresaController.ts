import { Response } from "express";
import { AppDataSource } from "../data-source";
import { Empresa } from "../entities/Empresa";
import { Usuario } from "../entities/Usuario";
import { AuthRequest } from "../middleware/auth";
import { isValidCNPJ } from "../utils/validators";

export class EmpresaController {
  static async getMe(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId;
      if (!userId) return res.status(401).json({ message: "Usuário não autenticado" });

      const usuarioRepository = AppDataSource.getRepository(Usuario);
      const empresaRepository = AppDataSource.getRepository(Empresa);

      const usuario = await usuarioRepository.findOne({ where: { id: userId } });
      if (!usuario) return res.status(404).json({ message: "Usuário não encontrado" });

      const empresa = await empresaRepository.findOne({ where: { id: userId } });
      if (!empresa) return res.status(404).json({ message: "Perfil da empresa não encontrado" });

      return res.status(200).json({
        id: usuario.id,
        nome_exibicao: usuario.nome_exibicao,
        email: usuario.email,
        criado_em: usuario.criado_em,
        atualizado_em: usuario.atualizado_em,
        empresa: {
          cnpj: empresa.cnpj,
          razao_social: empresa.razao_social,
          descricao: empresa.descricao,
          cep: empresa.cep,
          logradouro: empresa.logradouro,
          numero: empresa.numero,
          bairro: empresa.bairro,
          cidade: empresa.cidade,
          estado: empresa.estado,
          latitude: empresa.latitude,
          longitude: empresa.longitude,
        },
      });
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao buscar perfil", error: error.message });
    }
  }

  static async updateMe(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId;
      const { nome_exibicao, email, cnpj, razao_social, descricao, cep, logradouro, numero, bairro, cidade, estado, latitude, longitude } = req.body;

      if (!userId) return res.status(401).json({ message: "Usuário não autenticado" });

      if (cnpj && typeof cnpj === "string" && cnpj.trim() !== "" && !isValidCNPJ(cnpj)) {
        return res.status(400).json({ message: "CNPJ inválido" });
      }

      const usuarioRepository = AppDataSource.getRepository(Usuario);
      const empresaRepository = AppDataSource.getRepository(Empresa);

      const usuario = await usuarioRepository.findOne({ where: { id: userId } });
      if (!usuario) return res.status(404).json({ message: "Usuário não encontrado" });

      let empresa = await empresaRepository.findOne({ where: { id: userId } });
      if (!empresa) return res.status(404).json({ message: "Perfil da empresa não encontrado" });

      if (nome_exibicao) usuario.nome_exibicao = nome_exibicao;

      if (email !== undefined && typeof email === "string" && email.trim() !== "") {
        const normalizedEmail = email.trim().toLowerCase();
        if (normalizedEmail !== usuario.email) {
          const existing = await usuarioRepository.findOne({ where: { email: normalizedEmail } });
          if (existing && existing.id !== usuario.id) return res.status(409).json({ message: "Email já cadastrado" });
          usuario.email = normalizedEmail;
        }
      }

      await usuarioRepository.save(usuario);

      if (cnpj !== undefined) empresa.cnpj = cnpj || undefined;
      if (razao_social !== undefined) empresa.razao_social = razao_social || undefined;
      if (descricao !== undefined) empresa.descricao = descricao || undefined;
      if (cep !== undefined) empresa.cep = cep || undefined;
      if (logradouro !== undefined) empresa.logradouro = logradouro || undefined;
      if (numero !== undefined) empresa.numero = numero || undefined;
      if (bairro !== undefined) empresa.bairro = bairro || undefined;
      if (cidade !== undefined) empresa.cidade = cidade || undefined;
      if (estado !== undefined) empresa.estado = estado || undefined;
      if (latitude !== undefined) empresa.latitude = latitude;
      if (longitude !== undefined) empresa.longitude = longitude;

      empresa = await empresaRepository.save(empresa);

      return res.status(200).json({
        message: "Perfil da empresa atualizado com sucesso",
        data: {
          id: usuario.id,
          nome_exibicao: usuario.nome_exibicao,
          email: usuario.email,
          criado_em: usuario.criado_em,
          atualizado_em: usuario.atualizado_em,
          empresa: {
            cnpj: empresa.cnpj,
            razao_social: empresa.razao_social,
            descricao: empresa.descricao,
            cep: empresa.cep,
            logradouro: empresa.logradouro,
            numero: empresa.numero,
            bairro: empresa.bairro,
            cidade: empresa.cidade,
            estado: empresa.estado,
            latitude: empresa.latitude,
            longitude: empresa.longitude,
          },
        },
      });
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao atualizar perfil", error: error.message });
    }
  }
}
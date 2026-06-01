import { Request, Response } from 'express';
import { cnpj as cnpjValidator } from 'cpf-cnpj-validator';
import axios from 'axios';
import { AppDataSource } from '../data-source';
import { Empresa } from '../entities/Empresa';
import { Usuario, UsuarioPerfil } from '../entities/Usuario';
import { Avaliacao } from '../entities/Avaliacao';
import { Candidatura } from '../entities/Candidatura';

export class EmpresaController {
  async create(req: Request, res: Response) {
    try {
      const { cnpj, descricao, endereco } = req.body;

      // 1. Validação de Segurança do CNPJ
      if (!cnpjValidator.isValid(cnpj)) {
        return res.status(400).json({ message: 'CNPJ inválido ou com formato incorreto!' });
      }

      // 2. Inteligência de Dados: Geocodificação (Endereço -> Lat/Lng)
      let latitude: number | null = null;
      let longitude: number | null = null;

      if (endereco) {
        try {
          const response = await axios.get(`https://nominatim.openstreetmap.org/search`, {
            params: {
              q: endereco,
              format: 'json',
              limit: 1
            },
            headers: { 
              'User-Agent': 'NexaApp/1.0' 
            } 
          });

          if (response.data.length > 0) {
            latitude = Number(response.data[0].lat);
            longitude = Number(response.data[0].lon);
          }
        } catch (error) {
          console.error('Erro ao buscar coordenadas:', error);
        }
      }

      // 3. Persistência no Banco de Dados
      const empresaRepository = AppDataSource.getRepository(Empresa);
      
      const dadosEmpresa = {
        cnpj: cnpjValidator.strip(cnpj), 
        descricao: descricao as string,
        latitude: latitude as number,
        longitude: longitude as number
      };

      const novaEmpresa = empresaRepository.create(dadosEmpresa);
      await empresaRepository.save(novaEmpresa);

      return res.status(201).json({
        message: 'Empresa registada com sucesso!',
        empresa: {
          id: novaEmpresa.id,
          cnpj: novaEmpresa.cnpj,
          latitude,
          longitude
        }
      });

    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: 'Erro interno do servidor' });
    }
  }

  async getMe(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const empresaRepository = AppDataSource.getRepository(Empresa);

      const empresa = await empresaRepository.findOne({
        where: { id: usuarioLogadoId },
        relations: ["usuario", "avaliacoes", "avaliacoes.alunoUsuario"]
      });

      if (!empresa) {
        return res.status(404).json({ message: 'Perfil não encontrado.' });
      }

      let avaliacao_media = 0;
      let total_avaliacoes = 0;

      if (empresa.avaliacoes && empresa.avaliacoes.length > 0) {
        total_avaliacoes = empresa.avaliacoes.length;
        avaliacao_media = empresa.avaliacoes.reduce((acc, av) => acc + av.nota, 0) / total_avaliacoes;
      }

      return res.status(200).json({ 
        ...empresa, 
        avaliacao_media, 
        total_avaliacoes 
      });
    } catch (error) {
      console.error('Erro ao buscar perfil:', error);
      return res.status(500).json({ message: 'Erro interno do servidor' });
    }
  }

  async updateMe(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      
      // APENAS A RAZÃO SOCIAL É EDITÁVEL CONFORME SOLICITADO
      const { nome_exibicao } = req.body; 

      const empresaRepository = AppDataSource.getRepository(Empresa);
      const usuarioRepository = AppDataSource.getRepository(Usuario);

      const empresa = await empresaRepository.findOne({
        where: { id: usuarioLogadoId },
        relations: ["usuario"]
      });

      if (!empresa) {
        return res.status(404).json({ message: 'Perfil não encontrado.' });
      }

      // Atualiza apenas a Razão Social (nome_exibicao) na tabela Usuario
      if (nome_exibicao && empresa.usuario) {
        empresa.usuario.nome_exibicao = nome_exibicao;
        await usuarioRepository.save(empresa.usuario);
      }

      return res.status(200).json({ 
        message: 'Perfil atualizado com sucesso!',
        empresa
      });
    } catch (error) {
      console.error('Erro ao atualizar perfil:', error);
      return res.status(500).json({ message: 'Erro ao atualizar perfil' });
    }
  }

  // 🛠️ ROTA PÚBLICA PARA O ALUNO ACEDER VIA CHAT
  async getByCandidatura(req: Request, res: Response) {
    try {
      const { candidaturaId } = req.params;
      const perfilLogado = (req as any).usuarioPerfil;

      const candidatura = await AppDataSource.getRepository(Candidatura).findOne({
        where: { id: Number(candidaturaId) },
        relations: [
          "vaga", 
          "vaga.empresa", 
          "vaga.empresa.usuario", 
          "vaga.empresa.avaliacoes", 
          "vaga.empresa.avaliacoes.alunoUsuario"
        ]
      });

      if (!candidatura || !candidatura.vaga.empresa) {
        return res.status(404).json({ message: 'Empresa não encontrada.' });
      }

      const empresa = candidatura.vaga.empresa;
      
      let avaliacao_media = 0;
      let total_avaliacoes = 0;
      
      if (empresa.avaliacoes && empresa.avaliacoes.length > 0) {
        total_avaliacoes = empresa.avaliacoes.length;
        avaliacao_media = empresa.avaliacoes.reduce((acc, av) => acc + av.nota, 0) / total_avaliacoes;
      }

      return res.status(200).json({
        ...empresa,
        avaliacao_media,
        total_avaliacoes,
        can_review: perfilLogado === UsuarioPerfil.ALUNO
      });
    } catch (error) {
      console.error('Erro ao buscar perfil por candidatura:', error);
      return res.status(500).json({ message: 'Erro ao buscar perfil da empresa' });
    }
  }

  // 🛠️ ROTA PARA ENVIAR AVALIAÇÃO
  async avaliar(req: Request, res: Response) {
    try {
      const { empresa_id, nota, comentario } = req.body;
      const aluno_id = (req as any).usuarioId;
      const avaliacaoRepo = AppDataSource.getRepository(Avaliacao);

      const existente = await avaliacaoRepo.findOne({ 
        where: { empresa_id, aluno_id } 
      });

      if (existente) {
        // Atualiza a avaliação se já existir
        existente.nota = nota; 
        existente.comentario = comentario;
        await avaliacaoRepo.save(existente);
      } else {
        // Cria uma nova avaliação
        const nova = avaliacaoRepo.create({ 
          empresa_id, 
          aluno_id, 
          nota, 
          comentario 
        });
        await avaliacaoRepo.save(nova);
      }
      
      return res.status(200).json({ message: 'Avaliação registada com sucesso!' });
    } catch (error) {
      console.error('Erro ao avaliar empresa:', error);
      return res.status(500).json({ message: 'Erro ao avaliar empresa' });
    }
  }
}
import { Request, Response } from 'express';
import { cnpj as cnpjValidator } from 'cpf-cnpj-validator';
import axios from 'axios';
import { AppDataSource } from '../data-source';
import { Empresa } from '../entities/Empresa';
import { Usuario, UsuarioPerfil } from '../entities/Usuario';
import { Avaliacao } from '../entities/Avaliacao';
import { Candidatura, CandidaturaStatus } from '../entities/Candidatura';
import { Vaga } from '../entities/Vaga';
import { Aluno } from '../entities/Aluno';

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
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.EMPRESA) {
        return res.status(403).json({ message: 'Apenas empresas podem atualizar este recurso.' });
      }

      // APENAS A RAZÃO SOCIAL É EDITÁVEL CONFORME SOLICITADO
      const { nome_exibicao } = req.body; 

      if (nome_exibicao !== undefined && (typeof nome_exibicao !== 'string' || !nome_exibicao.trim())) {
        return res.status(400).json({ message: 'Nome de exibição é obrigatório.' });
      }

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
      if (nome_exibicao !== undefined && empresa.usuario) {
        empresa.usuario.nome_exibicao = nome_exibicao.trim();
        await usuarioRepository.save(empresa.usuario);
      }

      const empresaAtualizada = await empresaRepository.findOne({
        where: { id: usuarioLogadoId },
        relations: ["usuario", "avaliacoes", "avaliacoes.alunoUsuario"]
      });

      return res.status(200).json({ 
        message: 'Perfil atualizado com sucesso!',
        empresa: empresaAtualizada
      });
    } catch (error) {
      console.error('Erro ao atualizar perfil:', error);
      return res.status(500).json({ message: 'Erro ao atualizar perfil' });
    }
  }

  async dashboard(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.EMPRESA) {
        return res.status(403).json({ message: 'Apenas empresas podem acessar este recurso.' });
      }

      const empresaRepository = AppDataSource.getRepository(Empresa);
      const vagaRepository = AppDataSource.getRepository(Vaga);
      const candidaturaRepository = AppDataSource.getRepository(Candidatura);

      const empresa = await empresaRepository.findOne({
        where: { usuario: { id: usuarioLogadoId } },
        relations: ['usuario']
      });

      if (!empresa) {
        return res.status(404).json({ message: 'Perfil de empresa não encontrado.' });
      }

      const [vagasAtivas, vagasArquivadas, totalCandidatos, novasCandidaturas] =
        await Promise.all([
          vagaRepository.count({ where: { empresa_id: empresa.id, ativo: 1 } }),
          vagaRepository.count({ where: { empresa_id: empresa.id, ativo: 0 } }),
          candidaturaRepository
            .createQueryBuilder('candidatura')
            .innerJoin('candidatura.vaga', 'vaga')
            .where('vaga.empresa_id = :empresaId', { empresaId: empresa.id })
            .getCount(),
          candidaturaRepository
            .createQueryBuilder('candidatura')
            .innerJoin('candidatura.vaga', 'vaga')
            .where('vaga.empresa_id = :empresaId', { empresaId: empresa.id })
            .andWhere('candidatura.status = :status', {
              status: CandidaturaStatus.PENDENTE
            })
            .getCount()
        ]);

      return res.status(200).json({
        vagasAtivas,
        vagasArquivadas,
        totalCandidatos,
        novasCandidaturas
      });
    } catch (error) {
      console.error('Erro ao buscar dashboard da empresa:', error);
      return res.status(500).json({ message: 'Erro ao buscar dashboard da empresa' });
    }
  }

  async perfilCandidato(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;
      const alunoId = Number(req.params.alunoId);

      if (perfilLogado !== UsuarioPerfil.EMPRESA) {
        return res.status(403).json({ message: 'Apenas empresas podem acessar este recurso.' });
      }

      if (!alunoId || Number.isNaN(alunoId)) {
        return res.status(400).json({ message: 'ID do aluno inválido.' });
      }

      const empresa = await AppDataSource.getRepository(Empresa).findOne({
        where: { usuario: { id: usuarioLogadoId } },
      });

      if (!empresa) {
        return res.status(404).json({ message: 'Perfil de empresa não encontrado.' });
      }

      const candidaturas = await AppDataSource.getRepository(Candidatura).find({
        where: {
          aluno_id: alunoId,
          vaga: { empresa_id: empresa.id }
        },
        relations: ["vaga"],
        order: { data_candidatura: "DESC" }
      });

      if (candidaturas.length === 0) {
        return res.status(403).json({ message: 'Você só pode visualizar candidatos das suas vagas.' });
      }

      const aluno = await AppDataSource.getRepository(Aluno).findOne({
        where: { id: alunoId },
        relations: ["usuario", "alunoHabilidades", "alunoHabilidades.habilidade"]
      });

      if (!aluno) {
        return res.status(404).json({ message: 'Perfil de aluno não encontrado.' });
      }

      return res.status(200).json({
        id: aluno.id,
        nome: aluno.usuario?.nome_exibicao,
        email: aluno.usuario?.email,
        cpf: aluno.cpf ? `***.${aluno.cpf.slice(3, 6)}.${aluno.cpf.slice(6, 9)}-**` : null,
        curso: aluno.curso,
        instituicao: aluno.instituicao,
        ano_conclusao: aluno.ano_conclusao,
        cep: aluno.cep,
        endereco: aluno.endereco,
        numero: aluno.numero,
        url_curriculo: aluno.url_curriculo,
        tem_curriculo: Boolean(aluno.url_curriculo),
        habilidades: aluno.alunoHabilidades?.map((relacao) => relacao.habilidade).filter(Boolean) ?? [],
        candidaturas: candidaturas.map((candidatura) => ({
          id: candidatura.id,
          vaga_id: candidatura.vaga_id,
          vaga_titulo: candidatura.vaga?.titulo,
          status: candidatura.status,
          match_percent: candidatura.pontuacao_compatibilidade,
          url_curriculo: candidatura.curriculo_path,
          tem_curriculo_candidatura: Boolean(candidatura.curriculo_path),
          created_at: candidatura.data_candidatura
        }))
      });
    } catch (error) {
      console.error('Erro ao buscar perfil do candidato:', error);
      return res.status(500).json({ message: 'Erro ao buscar perfil do candidato' });
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

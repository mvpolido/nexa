import { Request, Response } from 'express';
import { cnpj as cnpjValidator } from 'cpf-cnpj-validator';
import axios from 'axios';
import { AppDataSource } from '../data-source';
import { Empresa } from '../entities/Empresa';

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
            // Convertendo explicitamente para número para evitar erro de DeepPartial
            latitude = Number(response.data[0].lat);
            longitude = Number(response.data[0].lon);
          }
        } catch (error) {
          console.error('Erro ao buscar coordenadas:', error);
        }
      }

      // 3. Persistência no Banco de Dados
      const empresaRepository = AppDataSource.getRepository(Empresa);
      
      // Criamos o objeto explicitamente para evitar o erro de overload
      const dadosEmpresa = {
        cnpj: cnpjValidator.strip(cnpj), // Remove pontos e traços
        descricao: descricao as string,
        latitude: latitude as number,
        longitude: longitude as number
      };

      const novaEmpresa = empresaRepository.create(dadosEmpresa);
      await empresaRepository.save(novaEmpresa);

      return res.status(201).json({
        message: 'Empresa cadastrada com sucesso!',
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
}
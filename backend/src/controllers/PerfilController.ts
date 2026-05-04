import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Aluno } from "../entities/Aluno";
import { AlunoHabilidade } from "../entities/AlunoHabilidade";

export class PerfilController {
  static async update(req: Request, res: Response) {
    const { id } = req.params; // ID do aluno
    const { habilidades } = req.body; // Array de IDs de habilidades, ex: [1, 2, 3]

    const alunoRepo = AppDataSource.getRepository(Aluno);
    const alunoHabilidadeRepo = AppDataSource.getRepository(AlunoHabilidade);

    try {
      const aluno = await alunoRepo.findOneBy({ id: Number(id) });

      if (!aluno) {
        return res.status(404).json({ message: "Aluno não encontrado" });
      }

      // 1. Se houver um arquivo, atualiza a URL do currículo
      if (req.file) {
        aluno.url_curriculo = req.file.filename;
        await alunoRepo.save(aluno);
      }

      // 2. Se houver habilidades no corpo da requisição
      if (habilidades) {
        const skillsIds = JSON.parse(habilidades); // O multer envia como string se for Form-Data

        // Limpa as habilidades antigas para evitar duplicidade
        await alunoHabilidadeRepo.delete({ aluno_id: aluno.id });

        // Cria as novas relações
        const novasHabilidades = skillsIds.map((skillId: number) => {
          return alunoHabilidadeRepo.create({
            aluno_id: aluno.id,
            habilidade_id: skillId
          });
        });

        await alunoHabilidadeRepo.save(novasHabilidades);
      }

      return res.json({ message: "Perfil atualizado com sucesso!", aluno });
    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: "Erro ao atualizar perfil" });
    }
  }
}
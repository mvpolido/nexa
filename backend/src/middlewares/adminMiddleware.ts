import { Request, Response, NextFunction } from "express";
import { UsuarioPerfil } from "../entities/Usuario";

export const adminMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const perfil = (req as any).usuarioPerfil;

  if (perfil !== UsuarioPerfil.ADMIN) {
    return res.status(403).json({ 
      message: "Acesso negado: Apenas administradores podem realizar esta ação." 
    });
  }

  return next();
};
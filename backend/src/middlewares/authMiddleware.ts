import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";


interface TokenPayload {
  id: number;
  perfil: string;
}

export const authMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({ message: "Token não fornecido" });
  }

  
  const [, token] = authHeader.split(" ");

  try {
    // IMPORTANTE: Use a mesma SECRET que foi usada no Login
    const secret = process.env.JWT_SECRET || "sua_chave_secreta_aqui";
    const decoded = jwt.verify(token, secret) as TokenPayload;

    
    (req as any).usuarioId = decoded.id;
    (req as any).usuarioPerfil = decoded.perfil;

    return next();
  } catch (error) {
    return res.status(401).json({ message: "Token inválido ou expirado" });
  }
};
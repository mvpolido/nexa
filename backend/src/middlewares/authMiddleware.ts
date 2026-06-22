import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { getJwtSecret } from "../utils/jwtSecret";

interface TokenPayload {
  id?: number;
  userId?: number;
  perfil: string;
}

export const authMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({ message: "Token não fornecido" });
  }

  const [type, token] = authHeader.split(" ");

  if (type !== "Bearer" || !token) {
    return res.status(401).json({ message: "Token inválido" });
  }

  try {
    const decoded = jwt.verify(token, getJwtSecret()) as TokenPayload;

    const usuarioId = decoded.id ?? decoded.userId;

    if (!usuarioId || !decoded.perfil) {
      return res.status(401).json({ message: "Token inválido" });
    }

    (req as any).usuarioId = usuarioId;
    (req as any).usuarioPerfil = decoded.perfil;

    return next();
  } catch (error) {
    return res.status(401).json({ message: "Token inválido ou expirado" });
  }
};

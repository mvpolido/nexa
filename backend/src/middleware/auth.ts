import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";

export interface AuthRequest extends Request {
  userId?: number;
  perfil?: string;
}

export const authMiddleware = (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        message: "Token não fornecido",
      });
    }

    const token = authHeader.replace("Bearer ", "");

    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET || "default_secret"
    ) as { userId: number; perfil: string };

    req.userId = decoded.userId;
    req.perfil = decoded.perfil;

    next();
  } catch (error) {
    return res.status(401).json({
      message: "Token inválido",
    });
  }
};

import multer from "multer";
import path from "path";
import crypto from "crypto"; // 👈 Alterado aqui! Usando o módulo nativo do Node
import fs from "fs";

// Garante que a pasta de destino existe
const uploadPath = path.resolve(__dirname, "..", "..", "uploads", "curriculos");
if (!fs.existsSync(uploadPath)) {
  fs.mkdirSync(uploadPath, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const uuid = crypto.randomUUID(); // 👈 Gera um UUID v4 perfeitamente idêntico
    const data = new Date().toISOString().split('T')[0]; // Formato YYYY-MM-DD
    
    cb(null, `${uuid}_${data}.pdf`);
  },
});

export const uploadConfig = multer({
  storage,
  fileFilter: (req, file, cb) => {
    const mimeTypesAceitos = ["application/pdf", "application/octet-stream"];
    const extensaoAceita = path.extname(file.originalname).toLowerCase() === ".pdf";

    if (mimeTypesAceitos.includes(file.mimetype) && extensaoAceita) {
      cb(null, true);
    } else {
      cb(new Error("Apenas arquivos .pdf são permitidos!"));
    }
  },
  limits: {
    fileSize: 5 * 1024 * 1024, // Limite opcional de 5MB para não sobrecarregar o servidor
  },
});

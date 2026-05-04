import multer from "multer";
import path from "path";
import { v4 as uuidv4 } from "uuid";
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
    // Regra: uuid_data_nome.pdf
    const uuid = uuidv4();
    const data = new Date().toISOString().split('T')[0]; // Formato YYYY-MM-DD
    const nomeOriginal = file.originalname.replace(/\s+/g, "_"); // Remove espaços para evitar erro em URL
    
    cb(null, `${uuid}_${data}_${nomeOriginal}`);
  },
});

export const uploadConfig = multer({
  storage,
  fileFilter: (req, file, cb) => {
    const mimeTypeAceito = "application/pdf";

    if (file.mimetype === mimeTypeAceito) {
      cb(null, true);
    } else {
      cb(new Error("Apenas arquivos .pdf são permitidos!"));
    }
  },
  limits: {
    fileSize: 5 * 1024 * 1024, // Limite opcional de 5MB para não sobrecarregar o servidor
  },
});
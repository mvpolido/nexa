import crypto from "crypto";
import fs from "fs";
import multer from "multer";
import path from "path";

export const verificacaoEmpresaUploadPath = path.resolve(
  __dirname,
  "..",
  "..",
  "private_uploads",
  "verificacoes_empresas"
);

if (!fs.existsSync(verificacaoEmpresaUploadPath)) {
  fs.mkdirSync(verificacaoEmpresaUploadPath, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, verificacaoEmpresaUploadPath);
  },
  filename: (_req, _file, cb) => {
    cb(null, `${crypto.randomUUID()}.pdf`);
  },
});

export const uploadDocumentoVerificacao = multer({
  storage,
  fileFilter: (_req, file, cb) => {
    const extensaoAceita = path.extname(file.originalname).toLowerCase() === ".pdf";
    const mimeAceito = file.mimetype === "application/pdf";

    if (extensaoAceita && mimeAceito) {
      cb(null, true);
      return;
    }

    cb(new Error("Envie um documento em PDF."));
  },
  limits: {
    fileSize: 5 * 1024 * 1024,
  },
});

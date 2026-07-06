import { Router } from "express";
import axios from "axios";
import { authMiddleware } from "../middlewares/authMiddleware";

const router = Router();

function onlyNumbers(value: string | undefined): string {
  return (value || "").replace(/\D/g, "");
}

router.get("/cep/:cep", authMiddleware, async (req, res) => {
  try {
    const cep = onlyNumbers(req.params.cep);

    if (cep.length !== 8) {
      return res.status(400).json({ message: "CEP inválido. Informe 8 dígitos." });
    }

    const response = await axios.get(`https://viacep.com.br/ws/${cep}/json/`);
    const data = response.data;

    if (!data || data.erro) {
      return res.status(404).json({ message: "CEP não encontrado." });
    }

    return res.status(200).json({
      cep,
      logradouro: data.logradouro || "",
      bairro: data.bairro || "",
      cidade: data.localidade || "",
      estado: data.uf || "",
    });
  } catch (error: any) {
    return res.status(500).json({
      message: "Erro ao consultar CEP.",
      error: error.message,
    });
  }
});

export default router;

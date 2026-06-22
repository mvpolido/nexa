import axios from "axios";
import { coordenadasValidas } from "./coordinates";

export async function geocodificarEndereco(params: {
  cep?: string | null;
  endereco?: string | null;
  numero?: string | null;
  cidade?: string | null;
  estado?: string | null;
}): Promise<{ latitude: number; longitude: number } | null> {
  const endereco = params.endereco?.trim();
  const numero = params.numero?.trim();
  const cidade = params.cidade?.trim();
  const estado = params.estado?.trim();
  const cep = params.cep?.replace(/\D/g, "");

  const enderecoCompleto = [endereco, numero, cidade, estado, cep]
    .filter((parte) => parte && parte.length > 0)
    .join(", ");

  const tentativas = [
    {
      label: "endereco_completo",
      busca: enderecoCompleto,
    },
    {
      label: "cidade_estado_cep",
      busca: [cidade, estado, cep].filter(Boolean).join(", "),
    },
    {
      label: "cep",
      busca: cep,
    },
  ].filter((tentativa) => tentativa.busca && tentativa.busca.trim().length > 0);

  for (const tentativa of tentativas) {
    try {
      const response = await axios.get(
        "https://nominatim.openstreetmap.org/search",
        {
          params: {
            format: "json",
            limit: 1,
            countrycodes: "br",
            q: `${tentativa.busca}, Brasil`,
          },
          headers: {
            "User-Agent": "NexaApp/1.0 contato@nexa.local",
          },
          timeout: 7000,
        }
      );

      const resultado = Array.isArray(response.data) ? response.data[0] : null;
      if (!resultado) {
        console.warn(
          `Geocodificação sem resultado na tentativa ${tentativa.label}.`
        );
        continue;
      }

      const latitude = Number(resultado.lat);
      const longitude = Number(resultado.lon);

      if (!coordenadasValidas(latitude, longitude)) {
        console.warn(
          `Geocodificação retornou coordenadas inválidas na tentativa ${tentativa.label}.`
        );
        continue;
      }

      return { latitude, longitude };
    } catch (error: any) {
      console.warn(
        `Falha na geocodificação na tentativa ${tentativa.label}: ${
          error?.code || error?.message || "erro desconhecido"
        }`
      );
    }
  }

  return null;
}

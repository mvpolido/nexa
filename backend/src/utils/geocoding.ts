import axios from "axios";

export function coordenadasValidas(latitude: unknown, longitude: unknown) {
  if (latitude === null || longitude === null) return false;
  if (latitude === "" || longitude === "") return false;

  const lat = Number(latitude);
  const lng = Number(longitude);

  return (
    Number.isFinite(lat) &&
    Number.isFinite(lng) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180
  );
}

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

  const partes = [endereco, numero, cidade, estado]
    .filter((parte) => parte && parte.length > 0)
    .join(", ");
  const busca = partes || [cidade, estado].filter(Boolean).join(", ") || cep;

  if (!busca) return null;

  try {
    const response = await axios.get(
      "https://nominatim.openstreetmap.org/search",
      {
        params: {
          format: "json",
          limit: 1,
          countrycodes: "br",
          q: `${busca}, Brasil`,
        },
        headers: {
          "User-Agent": "NexaApp/1.0",
        },
        timeout: 5000,
      }
    );

    const resultado = Array.isArray(response.data) ? response.data[0] : null;
    if (!resultado) return null;

    const latitude = Number(resultado.lat);
    const longitude = Number(resultado.lon);

    if (!coordenadasValidas(latitude, longitude)) return null;

    return { latitude, longitude };
  } catch (_) {
    return null;
  }
}

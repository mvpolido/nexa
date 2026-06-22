import axios from "axios";
import { coordenadasValidas } from "./distance";

type GeocodingParams = {
  cep?: string | null;
  endereco?: string | null;
  numero?: string | null;
  cidade?: string | null;
  estado?: string | null;
};

type NominatimResult = {
  lat?: string;
  lon?: string;
  display_name?: string;
  address?: Record<string, string | undefined>;
};

function normalizarTexto(value?: string | null) {
  return (value ?? "")
    .toString()
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, " ");
}

function normalizarCep(value?: string | null) {
  const digits = (value ?? "").replace(/\D/g, "");
  return digits.length === 8 ? digits : "";
}

function normalizarUf(value?: string | null) {
  return (value ?? "").trim().toUpperCase();
}

function debugGeocoding(message: string) {
  if (process.env.NODE_ENV !== "production") {
    console.log(`[geocoding] ${message}`);
  }
}

function cidadeDoResultado(address: Record<string, string | undefined>) {
  return (
    address.city ||
    address.town ||
    address.village ||
    address.municipality ||
    address.county ||
    ""
  );
}

function estadoDoResultado(address: Record<string, string | undefined>) {
  const iso = address["ISO3166-2-lvl4"];
  if (iso && iso.includes("-")) return iso.split("-").pop() ?? "";
  return address.state_code || address.state || "";
}

function resultadoCompativel(
  resultado: NominatimResult,
  params: {
    cep: string;
    cidade?: string;
    estado?: string;
  }
) {
  const address = resultado.address ?? {};
  const cepResultado = normalizarCep(address.postcode);
  const cidadeResultado = normalizarTexto(cidadeDoResultado(address));
  const estadoResultado = normalizarUf(estadoDoResultado(address));

  if (params.cep && cepResultado && cepResultado !== params.cep) {
    return {
      ok: false,
      motivo: `CEP divergente retornado (${cepResultado})`,
    };
  }

  if (
    params.cidade &&
    cidadeResultado &&
    cidadeResultado !== normalizarTexto(params.cidade)
  ) {
    return {
      ok: false,
      motivo: `cidade divergente retornada (${cidadeResultado})`,
    };
  }

  if (
    params.estado &&
    estadoResultado &&
    estadoResultado !== normalizarUf(params.estado)
  ) {
    return {
      ok: false,
      motivo: `estado divergente retornado (${estadoResultado})`,
    };
  }

  return { ok: true, motivo: "compatível" };
}

async function consultarNominatim(
  label: string,
  params: Record<string, string | number | undefined>
) {
  debugGeocoding(`tentativa=${label} consulta=${JSON.stringify(params)}`);

  const response = await axios.get<NominatimResult[]>(
    "https://nominatim.openstreetmap.org/search",
    {
      params: {
        format: "json",
        addressdetails: 1,
        limit: 5,
        countrycodes: "br",
        ...params,
      },
      headers: {
        "User-Agent": "NexaApp/1.0 contato@nexa.local",
      },
      timeout: 7000,
    }
  );

  return Array.isArray(response.data) ? response.data : [];
}

export async function geocodificarEndereco(
  params: GeocodingParams
): Promise<{ latitude: number; longitude: number } | null> {
  const cep = normalizarCep(params.cep);
  const rua = params.endereco?.trim();
  const numero = params.numero?.trim();
  const cidade = params.cidade?.trim();
  const estado = normalizarUf(params.estado);
  const street = [rua, numero].filter(Boolean).join(" ");

  const tentativas = [
    {
      label: "cep_rua_numero_cidade_estado",
      query: {
        postalcode: cep || undefined,
        street: street || undefined,
        city: cidade || undefined,
        state: estado || undefined,
        country: "Brasil",
      },
    },
    {
      label: "cep_cidade_estado",
      query: {
        postalcode: cep || undefined,
        city: cidade || undefined,
        state: estado || undefined,
        country: "Brasil",
      },
    },
    {
      label: "cep",
      query: {
        postalcode: cep || undefined,
        country: "Brasil",
      },
    },
    {
      label: "rua_cidade_estado",
      query: {
        street: street || undefined,
        city: cidade || undefined,
        state: estado || undefined,
        country: "Brasil",
      },
    },
  ].filter((tentativa) =>
    Object.entries(tentativa.query).some(
      ([key, value]) => key !== "country" && value !== undefined && value !== ""
    )
  );

  for (const tentativa of tentativas) {
    let resultados: NominatimResult[] = [];

    try {
      resultados = await consultarNominatim(tentativa.label, tentativa.query);
    } catch (error: any) {
      console.warn(
        `Falha na geocodificação (${tentativa.label}): ${
          error?.code || error?.message || "erro desconhecido"
        }`
      );
      continue;
    }

    for (const resultado of resultados) {
      const compatibilidade = resultadoCompativel(resultado, {
        cep,
        cidade,
        estado,
      });

      if (!compatibilidade.ok) {
        debugGeocoding(
          `candidato rejeitado (${tentativa.label}): ${compatibilidade.motivo}`
        );
        continue;
      }

      const latitude = Number(resultado.lat);
      const longitude = Number(resultado.lon);

      if (!coordenadasValidas(latitude, longitude)) {
        debugGeocoding(
          `candidato rejeitado (${tentativa.label}): coordenadas inválidas`
        );
        continue;
      }

      debugGeocoding(
        `candidato escolhido (${tentativa.label}): ${
          resultado.display_name ?? "sem display_name"
        } lat=${latitude} lon=${longitude}`
      );

      return { latitude, longitude };
    }
  }

  return null;
}

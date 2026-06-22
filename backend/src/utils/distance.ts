export type Coordenadas = {
  latitude: number;
  longitude: number;
};

export function parseCoordenada(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  const numero = Number(value);
  return Number.isFinite(numero) ? numero : null;
}

export function coordenadasValidas(
  latitude: unknown,
  longitude: unknown
): boolean {
  const lat = parseCoordenada(latitude);
  const lng = parseCoordenada(longitude);

  return (
    lat !== null &&
    lng !== null &&
    !(lat === 0 && lng === 0) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180
  );
}

export function normalizarCoordenadas(
  latitude: unknown,
  longitude: unknown
): Coordenadas | null {
  if (!coordenadasValidas(latitude, longitude)) return null;
  return {
    latitude: Number(latitude),
    longitude: Number(longitude),
  };
}

export function calcularDistanciaKm(
  latitudeOrigem: unknown,
  longitudeOrigem: unknown,
  latitudeDestino: unknown,
  longitudeDestino: unknown
): number | null {
  if (!coordenadasValidas(latitudeOrigem, longitudeOrigem)) return null;
  if (!coordenadasValidas(latitudeDestino, longitudeDestino)) return null;

  const lat1 = Number(latitudeOrigem);
  const lng1 = Number(longitudeOrigem);
  const lat2 = Number(latitudeDestino);
  const lng2 = Number(longitudeDestino);
  const toRad = (graus: number) => (graus * Math.PI) / 180;
  const raioTerraKm = 6371;

  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  return raioTerraKm * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
}

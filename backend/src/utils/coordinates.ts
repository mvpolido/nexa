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

export function calcularDistanciaHaversineKm(
  origemLat: number,
  origemLng: number,
  destinoLat: number,
  destinoLng: number
): number {
  const toRad = (graus: number) => (graus * Math.PI) / 180;
  const raioTerraKm = 6371;

  const dLat = toRad(destinoLat - origemLat);
  const dLng = toRad(destinoLng - origemLng);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(origemLat)) *
      Math.cos(toRad(destinoLat)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  return raioTerraKm * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
}

export function calcularDistanciaKmOuNull(
  origemLat: unknown,
  origemLng: unknown,
  destinoLat: unknown,
  destinoLng: unknown
): number | null {
  if (!coordenadasValidas(origemLat, origemLng)) return null;
  if (!coordenadasValidas(destinoLat, destinoLng)) return null;

  return calcularDistanciaHaversineKm(
    Number(origemLat),
    Number(origemLng),
    Number(destinoLat),
    Number(destinoLng)
  );
}

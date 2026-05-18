const RAIO_TERRA_KM = 6371;
const RAIO_MAXIMO_KM = 50;

/**
 * Fórmula de Haversine: calcula a distância em km entre dois pontos geográficos.
 */
export function calcularDistanciaKm(
  latOrigem: number,
  lonOrigem: number,
  latDestino: number,
  lonDestino: number
): number {
  const toRad = (graus: number) => (graus * Math.PI) / 180;

  const dLat = toRad(latDestino - latOrigem);
  const dLon = toRad(lonDestino - lonOrigem);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(latOrigem)) *
      Math.cos(toRad(latDestino)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  return 2 * RAIO_TERRA_KM * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Retorna nota de 0-100 baseada na interseção de habilidades.
 * Se a vaga não exige nenhuma habilidade, considera compatibilidade total.
 */
export function calcularScoreHabilidades(
  habilidadesAluno: number[],
  habilidadesVaga: number[]
): number {
  if (habilidadesVaga.length === 0) return 100;

  const setAluno = new Set(habilidadesAluno);
  const emComum = habilidadesVaga.filter((id) => setAluno.has(id)).length;

  return (emComum / habilidadesVaga.length) * 100;
}

/**
 * Retorna nota de 0-100 baseada na distância km (inversamente proporcional).
 * 0 km → 100 | >= RAIO_MAXIMO_KM → 0
 * Se qualquer coordenada estiver ausente, retorna 0 (sem penalizar o score de skills).
 */
export function calcularScoreDistancia(
  alunoLat: number | null | undefined,
  alunoLon: number | null | undefined,
  vagaLat: number | null | undefined,
  vagaLon: number | null | undefined
): number {
  if (
    alunoLat == null ||
    alunoLon == null ||
    vagaLat == null ||
    vagaLon == null
  ) {
    return 0;
  }

  const distancia = calcularDistanciaKm(
    Number(alunoLat),
    Number(alunoLon),
    Number(vagaLat),
    Number(vagaLon)
  );

  if (distancia >= RAIO_MAXIMO_KM) return 0;

  return ((RAIO_MAXIMO_KM - distancia) / RAIO_MAXIMO_KM) * 100;
}

/**
 * Nota final de compatibilidade: 70% skills + 30% distância.
 * Resultado arredondado a 2 casas decimais, entre 0 e 100.
 */
export function calcularMatchPercent(
  habilidadesAluno: number[],
  habilidadesVaga: number[],
  alunoLat: number | null | undefined,
  alunoLon: number | null | undefined,
  vagaLat: number | null | undefined,
  vagaLon: number | null | undefined
): number {
  const scoreSkills = calcularScoreHabilidades(habilidadesAluno, habilidadesVaga);
  const scoreDistancia = calcularScoreDistancia(alunoLat, alunoLon, vagaLat, vagaLon);

  const total = scoreSkills * 0.7 + scoreDistancia * 0.3;

  return Number(Math.max(0, Math.min(100, total)).toFixed(2));
}

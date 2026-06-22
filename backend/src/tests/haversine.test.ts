import assert from "assert";
import { calcularDistanciaKm } from "../utils/distance";

function assertApprox(actual: number | null, expected: number, tolerance: number) {
  assert.notStrictEqual(actual, null, "distância não deveria ser null");
  assert.ok(
    Math.abs((actual as number) - expected) <= tolerance,
    `esperado ${expected}±${tolerance} km, recebido ${actual}`
  );
}

const curitiba = { lat: -25.4284, lng: -49.2733 };
const saoPaulo = { lat: -23.5505, lng: -46.6333 };

assert.strictEqual(
  calcularDistanciaKm(curitiba.lat, curitiba.lng, curitiba.lat, curitiba.lng),
  0,
  "ponto igual deve retornar 0 km"
);

const ida = calcularDistanciaKm(
  curitiba.lat,
  curitiba.lng,
  saoPaulo.lat,
  saoPaulo.lng
);
const volta = calcularDistanciaKm(
  saoPaulo.lat,
  saoPaulo.lng,
  curitiba.lat,
  curitiba.lng
);

assert.notStrictEqual(ida, null);
assert.notStrictEqual(volta, null);
assert.ok(Math.abs((ida as number) - (volta as number)) < 0.000001);

assert.strictEqual(calcularDistanciaKm(null, curitiba.lng, saoPaulo.lat, saoPaulo.lng), null);
assert.strictEqual(calcularDistanciaKm(0, 0, saoPaulo.lat, saoPaulo.lng), null);
assert.strictEqual(calcularDistanciaKm(-91, curitiba.lng, saoPaulo.lat, saoPaulo.lng), null);

assertApprox(ida, 339, 10);

// Par sintético próximo usado para comprovar que a fórmula não transforma
// uma distância curta (~47 km) em centenas de quilômetros.
assertApprox(calcularDistanciaKm(-23.55, -46.63, -23.55, -46.17), 47, 3);

console.log("Testes de distância passaram.");

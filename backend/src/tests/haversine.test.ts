import assert from "assert";
import { calcularDistanciaHaversineKm } from "../utils/coordinates";

const curitiba = { lat: -25.4284, lng: -49.2733 };
const saoPaulo = { lat: -23.5505, lng: -46.6333 };

const distancia = calcularDistanciaHaversineKm(
  curitiba.lat,
  curitiba.lng,
  saoPaulo.lat,
  saoPaulo.lng
);

assert.ok(
  distancia > 330 && distancia < 350,
  `Distância Curitiba-São Paulo esperada entre 330 e 350 km, recebida ${distancia}`
);

console.log("Teste Haversine passou.");

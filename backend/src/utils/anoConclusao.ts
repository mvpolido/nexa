export const ANO_CONCLUSAO_MINIMO = 2020;

export function anoConclusaoMaximo(): number {
  return new Date().getFullYear() + 10;
}

export function mensagemAnoConclusaoInvalido(): string {
  return `Ano de conclusão inválido. Informe um número inteiro entre ${ANO_CONCLUSAO_MINIMO} e ${anoConclusaoMaximo()}.`;
}

export function parseAnoConclusao(value: unknown): number | null {
  if (typeof value === "number") {
    if (!Number.isInteger(value)) return null;
    return validarFaixa(value) ? value : null;
  }

  if (typeof value !== "string") return null;

  const trimmed = value.trim();
  if (!/^\d+$/.test(trimmed)) return null;

  const parsed = Number(trimmed);
  if (!Number.isInteger(parsed)) return null;

  return validarFaixa(parsed) ? parsed : null;
}

function validarFaixa(year: number): boolean {
  return year >= ANO_CONCLUSAO_MINIMO && year <= anoConclusaoMaximo();
}

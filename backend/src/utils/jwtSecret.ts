export const JWT_DEV_FALLBACK = "nexa_dev_jwt_secret";

export function getJwtSecret(): string {
  return process.env.JWT_SECRET || JWT_DEV_FALLBACK;
}

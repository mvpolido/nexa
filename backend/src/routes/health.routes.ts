import { Router } from 'express';

const router = Router();

/**
 * @swagger
 * /health:
 *   get:
 *     summary: Verifica se a API está funcionando
 *     responses:
 *       200:
 *         description: API está funcionando
 */
router.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

export default router;
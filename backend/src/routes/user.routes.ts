import { Router } from 'express';
const router = Router();


router.get('/profile', (req, res) => {
  res.status(200).json({ name: 'Felipe', role: 'student' });
});

export default router;
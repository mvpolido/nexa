import { Router } from 'express';
const router = Router();


router.post('/register', (req, res) => {
  res.status(201).json({ message: 'Usuário registrado!' });
});


router.post('/login', (req, res) => {
  res.status(200).json({ token: 'jwt-token-fake' });
});

export default router;
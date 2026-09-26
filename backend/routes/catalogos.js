const express = require('express');
const { pool } = require('../db');

const router = express.Router();

// GET /api/razas -> catalogo de razas
router.get('/razas', async (req, res) => {
  try {
    const [filas] = await pool.query('SELECT id, nombre FROM razas ORDER BY nombre');
    res.json(filas);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'No se pudo consultar el catalogo de razas' });
  }
});

// GET /api/colores -> catalogo de colores
router.get('/colores', async (req, res) => {
  try {
    const [filas] = await pool.query('SELECT id, nombre FROM colores ORDER BY nombre');
    res.json(filas);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'No se pudo consultar el catalogo de colores' });
  }
});

module.exports = router;
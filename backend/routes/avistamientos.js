const express = require('express');
const { pool } = require('../db');

const router = express.Router();

// GET /api/avistamientos -> todos los avistamientos con TODOS sus colores,
// pensado para que el servicio Elixir los consuma.
// El JOIN y el agrupado los resuelve SQL (declarativo); aqui solo se da forma al JSON.
router.get('/', async (req, res) => {
  try {
    const [filas] = await pool.query(`
      SELECT p.id, p.nombre, r.nombre AS raza,
             p.ubicacion_lat AS lat, p.ubicacion_lng AS lon,
             p.foto_filename AS foto, p.fecha_registro AS fecha,
             CONCAT_WS('|', cp.nombre, GROUP_CONCAT(ca.nombre ORDER BY ca.nombre SEPARATOR '|')) AS colores
      FROM perritos p
      LEFT JOIN razas r ON r.id = p.raza_id
      JOIN colores cp ON cp.id = p.color_principal_id
      LEFT JOIN perrito_colores_adicionales pca ON pca.perrito_id = p.id
      LEFT JOIN colores ca ON ca.id = pca.color_id
      GROUP BY p.id, r.nombre, cp.nombre
      ORDER BY p.fecha_registro DESC
    `);

    // Estilo funcional: map sin mutar y sin ciclos explicitos.
    // El color principal va siempre primero en la lista.
    const avistamientos = filas.map((f) => ({
      id: f.id,
      nombre: f.nombre,
      raza: f.raza,
      colores: f.colores.split('|'),
      lat: Number(f.lat),
      lon: Number(f.lon),
      foto: f.foto,
      fecha: f.fecha,
    }));

    res.json(avistamientos);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'No se pudieron consultar los avistamientos' });
  }
});

module.exports = router;
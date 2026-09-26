const express = require('express');
const multer = require('multer');
const { pool } = require('../db');
const { guardarImagen } = require('../imagenes');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 8 * 1024 * 1024 } });

// GET /api/perritos -> lista todos, con JOIN a razas y colores (consulta declarativa)
router.get('/', async (req, res) => {
  try {
    const [filas] = await pool.query(`
      SELECT p.id, p.nombre, r.nombre AS raza, c.nombre AS color_principal,
             p.ubicacion_lat, p.ubicacion_lng, p.foto_filename, p.fecha_registro
      FROM perritos p
      LEFT JOIN razas r ON p.raza_id = r.id
      JOIN colores c ON p.color_principal_id = c.id
      ORDER BY p.fecha_registro DESC
    `);
    res.json(filas);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'No se pudieron consultar los perritos' });
  }
});

// GET /api/perritos/:id -> detalle de un perrito, con sus colores adicionales
router.get('/:id', async (req, res) => {
  try {
    const [filas] = await pool.query(`
      SELECT p.id, p.nombre, r.nombre AS raza, c.nombre AS color_principal,
             p.ubicacion_lat, p.ubicacion_lng, p.foto_filename, p.fecha_registro
      FROM perritos p
      LEFT JOIN razas r ON p.raza_id = r.id
      JOIN colores c ON p.color_principal_id = c.id
      WHERE p.id = ?
    `, [req.params.id]);

    if (filas.length === 0) return res.status(404).json({ error: 'Perrito no encontrado' });

    const [coloresAdicionales] = await pool.query(`
      SELECT c.nombre
      FROM perrito_colores_adicionales pca
      JOIN colores c ON pca.color_id = c.id
      WHERE pca.perrito_id = ?
    `, [req.params.id]);

    // Ejemplo de paradigma funcional: transformamos filas -> array de nombres con map,
    // sin mutar el resultado original y sin ciclos explicitos
    const nombresColores = coloresAdicionales.map((fila) => fila.nombre);

    res.json({ ...filas[0], colores_adicionales: nombresColores });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'No se pudo consultar el perrito' });
  }
});

// POST /api/perritos -> registrar un perrito nuevo (idempotente)
router.post('/', upload.single('foto'), async (req, res) => {
  try {
    const {
      nombre,
      raza_id,
      color_principal_id,
      colores_adicionales, // se espera como string JSON: "[2,5]" o vacio
      ubicacion_lat,
      ubicacion_lng,
      idempotency_key,
    } = req.body;

    // --- Validaciones del lado del servidor (nunca confiar solo en el frontend) ---
    if (!idempotency_key) {
      return res.status(400).json({ error: 'Falta la clave de idempotencia (idempotency_key)' });
    }
    if (!nombre || nombre.trim() === '') {
      return res.status(400).json({ error: 'Falta el nombre' });
    }
    if (!color_principal_id) {
      return res.status(400).json({ error: 'Falta el color principal' });
    }
    if (!ubicacion_lat || !ubicacion_lng) {
      return res.status(400).json({ error: 'Falta la ubicacion' });
    }
    if (!req.file) {
      return res.status(400).json({ error: 'Falta la foto' });
    }

    let coloresExtra = [];
    if (colores_adicionales) {
      try {
        coloresExtra = JSON.parse(colores_adicionales);
      } catch {
        return res.status(400).json({ error: 'colores_adicionales debe ser una lista valida' });
      }
    }
    if (coloresExtra.length > 2) {
      return res.status(400).json({ error: 'Maximo 2 colores adicionales' });
    }
    if (coloresExtra.includes(Number(color_principal_id))) {
      return res.status(400).json({ error: 'Un color adicional no puede repetir el color principal' });
    }
    if (new Set(coloresExtra).size !== coloresExtra.length) {
      return res.status(400).json({ error: 'No se puede repetir un color adicional' });
    }

    // --- Idempotencia: si esta clave ya se uso, regresamos el registro existente ---
    const [existentes] = await pool.query(
      'SELECT id FROM perritos WHERE idempotency_key = ?',
      [idempotency_key]
    );
    if (existentes.length > 0) {
      const [filaExistente] = await pool.query('SELECT * FROM perritos WHERE id = ?', [existentes[0].id]);
      return res.status(200).json({ ...filaExistente[0], duplicado_evitado: true });
    }

    // --- Guardar la imagen (valida que sea real y genera el nombre) ---
    let nombreArchivo;
    try {
      nombreArchivo = await guardarImagen(req.file.buffer);
    } catch (err) {
      if (err.codigo === 'IMAGEN_INVALIDA') {
        return res.status(400).json({ error: err.message });
      }
      throw err;
    }

    // --- Insertar el perrito ---
    const [resultado] = await pool.query(
      `INSERT INTO perritos
        (idempotency_key, nombre, raza_id, color_principal_id, ubicacion_lat, ubicacion_lng, foto_filename)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [idempotency_key, nombre.trim(), raza_id || null, color_principal_id, ubicacion_lat, ubicacion_lng, nombreArchivo]
    );

    const perritoId = resultado.insertId;

    // --- Insertar colores adicionales (si hay) ---
    for (const colorId of coloresExtra) {
      await pool.query(
        'INSERT INTO perrito_colores_adicionales (perrito_id, color_id) VALUES (?, ?)',
        [perritoId, colorId]
      );
    }

    const [filaNueva] = await pool.query('SELECT * FROM perritos WHERE id = ?', [perritoId]);
    res.status(201).json(filaNueva[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Ocurrio un error al registrar el perrito' });
  }
});

// GET /api/estadisticas/colores -> agregacion: cuantos perritos hay por color (declarativo)
router.get('/estadisticas/colores', async (req, res) => {
  try {
    const [filas] = await pool.query(`
      SELECT c.nombre AS color, COUNT(*) AS cantidad
      FROM perritos p
      JOIN colores c ON p.color_principal_id = c.id
      GROUP BY c.nombre
      ORDER BY cantidad DESC
    `);
    res.json(filas);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'No se pudo calcular la estadistica' });
  }
});

module.exports = router;
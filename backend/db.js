require('dotenv').config();
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'perritos_db',
  waitForConnections: true,
  connectionLimit: 10,
});

async function esperarConexion(intentos = 10, esperaMs = 2000) {
  for (let i = 1; i <= intentos; i++) {
    try {
      const conn = await pool.getConnection();
      conn.release();
      console.log('Conectado a MySQL correctamente.');
      return;
    } catch (err) {
      console.log(`Intento ${i}/${intentos}: MySQL aun no responde (${err.code}). Reintentando...`);
      await new Promise((r) => setTimeout(r, esperaMs));
    }
  }
  console.error('No se pudo conectar a MySQL despues de varios intentos.');
}

module.exports = { pool, esperarConexion };
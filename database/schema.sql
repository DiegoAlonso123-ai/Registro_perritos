-- Esquema de la base de datos: registro de perritos de la calle

CREATE DATABASE IF NOT EXISTS perritos_db;
USE perritos_db;

CREATE TABLE IF NOT EXISTS razas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS colores (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS perritos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  idempotency_key VARCHAR(100) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  raza_id INT,
  color_principal_id INT NOT NULL,
  ubicacion_lat DECIMAL(10,7) NOT NULL,
  ubicacion_lng DECIMAL(10,7) NOT NULL,
  foto_filename VARCHAR(255) NOT NULL,
  fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (raza_id) REFERENCES razas(id),
  FOREIGN KEY (color_principal_id) REFERENCES colores(id)
);

CREATE TABLE IF NOT EXISTS perrito_colores_adicionales (
  perrito_id INT NOT NULL,
  color_id INT NOT NULL,
  PRIMARY KEY (perrito_id, color_id),
  FOREIGN KEY (perrito_id) REFERENCES perritos(id) ON DELETE CASCADE,
  FOREIGN KEY (color_id) REFERENCES colores(id)
);
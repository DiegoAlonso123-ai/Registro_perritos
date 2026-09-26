require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { randomUUID } = require('crypto');
const FileType = require('file-type');

const RUTA_IMAGENES = process.env.RUTA_IMAGENES || 'C:\\perritos-imagenes';

// Nos aseguramos de que la carpeta exista
if (!fs.existsSync(RUTA_IMAGENES)) {
  fs.mkdirSync(RUTA_IMAGENES, { recursive: true });
}

const TIPOS_PERMITIDOS = ['image/jpeg', 'image/png', 'image/webp'];

// Recibe el buffer del archivo subido, valida que sea una imagen real
// (leyendo sus bytes, no su extension) y la guarda con un nombre generado por el backend
async function guardarImagen(buffer) {
const tipo = await FileType.fromBuffer(buffer);

  if (!tipo || !TIPOS_PERMITIDOS.includes(tipo.mime)) {
    const error = new Error('El archivo no es una imagen valida (solo se permite JPG, PNG o WEBP)');
    error.codigo = 'IMAGEN_INVALIDA';
    throw error;
  }

  // El backend genera el nombre, nunca usa el nombre original del usuario
  const nombreArchivo = `${randomUUID()}.${tipo.ext}`;
  const rutaCompleta = path.join(RUTA_IMAGENES, nombreArchivo);

  fs.writeFileSync(rutaCompleta, buffer);

  return nombreArchivo;
}

// Regresa la ruta completa de una imagen guardada, para poder servirla
function rutaDeImagen(nombreArchivo) {
  // Evita que alguien pida algo como "../../windows/system32" (path traversal)
  const nombreSeguro = path.basename(nombreArchivo);
  return path.join(RUTA_IMAGENES, nombreSeguro);
}

function existeImagen(nombreArchivo) {
  return fs.existsSync(rutaDeImagen(nombreArchivo));
}

module.exports = { guardarImagen, rutaDeImagen, existeImagen, RUTA_IMAGENES };
require('dotenv').config();
const express = require('express');
const cors = require('cors');

const { esperarConexion } = require('./db');
const { rutaDeImagen, existeImagen } = require('./imagenes');
const perritosRouter = require('./routes/perritos');
const catalogosRouter = require('./routes/catalogos');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ mensaje: 'API de Registro de Perritos funcionando' });
});

app.use('/api/perritos', perritosRouter);
app.use('/api', catalogosRouter);

// Sirve una imagen a traves del backend (nunca se expone la carpeta directamente)
app.get('/api/imagenes/:nombre', (req, res) => {
  const nombre = req.params.nombre;

  if (!existeImagen(nombre)) {
    return res.status(404).json({ error: 'Imagen no encontrada' });
  }

  res.sendFile(rutaDeImagen(nombre));
});

async function iniciar() {
  await esperarConexion();
  app.listen(PORT, () => {
    console.log(`Servidor backend corriendo en http://localhost:${PORT}`);
  });
}

iniciar();
// Prueba del doble envio (idempotencia).
// Uso: con el backend corriendo, desde la carpeta backend:  npm run prueba:doble-envio
const fs = require('fs');
const path = require('path');

const API = process.env.API_URL || 'http://localhost:3000';
const carpetaFotos = path.join(__dirname, '..', '..', 'database', 'fotos-prueba');

function crearFormulario(clave) {
  const archivo = fs.readdirSync(carpetaFotos).find((f) => /\.(jpe?g|png|webp)$/i.test(f));
  if (!archivo) throw new Error('No hay fotos en database/fotos-prueba');

  const ext = path.extname(archivo).slice(1).toLowerCase();
  const tipo = `image/${ext === 'jpg' ? 'jpeg' : ext}`;

  const datos = new FormData();
  datos.append('nombre', 'Perrito de prueba (doble envio)');
  datos.append('color_principal_id', '1');
  datos.append('ubicacion_lat', '25.4260');
  datos.append('ubicacion_lng', '-100.9959');
  datos.append('idempotency_key', clave);
  datos.append('foto', new Blob([fs.readFileSync(path.join(carpetaFotos, archivo))], { type: tipo }), archivo);
  return datos;
}

async function contar() {
  const res = await fetch(`${API}/api/perritos`);
  return (await res.json()).length;
}

async function enviar(clave) {
  const res = await fetch(`${API}/api/perritos`, { method: 'POST', body: crearFormulario(clave) });
  return { status: res.status, cuerpo: await res.json() };
}

function comprobar(condicion, mensaje) {
  console.log(`${condicion ? 'OK   ' : 'FALLO'} - ${mensaje}`);
  if (!condicion) process.exitCode = 1;
}

(async () => {
  const clave = `prueba-doble-envio-${Date.now()}`;
  const antes = await contar();

  const primero = await enviar(clave);
  const despuesPrimero = await contar();
  const segundo = await enviar(clave);
  const despuesSegundo = await contar();

  console.log(`Clave usada:   ${clave}`);
  console.log(`Primer envio:  HTTP ${primero.status}, id ${primero.cuerpo.id}`);
  console.log(`Segundo envio: HTTP ${segundo.status}, id ${segundo.cuerpo.id}`);
  console.log('');

  comprobar(primero.status === 201, 'El primer envio crea el perrito (201)');
  comprobar(despuesPrimero === antes + 1, 'Despues del primer envio hay 1 perrito mas');
  comprobar(segundo.cuerpo.id === primero.cuerpo.id, 'El segundo envio devuelve el mismo id');
  comprobar(segundo.cuerpo.duplicado_evitado === true, 'El segundo envio indica duplicado_evitado');
  comprobar(despuesSegundo === despuesPrimero, 'El segundo envio NO creo otro registro');
})().catch((err) => {
  console.error('No se pudo correr la prueba. ¿Esta corriendo el backend?', err.message);
  process.exit(1);
});
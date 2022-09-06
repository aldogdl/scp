/// Cada cmd será separado con un punto y se podran concatenar cmd con coma
/// Los cmd que inicien con una sola letra su valor será un entero
/// Los cmd que inicien con dos letras su valor sera un String
const Map<String, dynamic> commands = {
  'o': {
    'id':10,
    'clv': 'o',
    'campo': 'orden',
    'desc': 'Buscamos la ORDEN',
  },
  'p': {
    'id':11,
    'clv': 'p',
    'campo': 'piezas',
    'desc': ''
    '[PROCESO] Listar las respuestas de esta pieza, la busqueda requiere solo el ID.\n'
    '[BUSQUEDA] Busca la pieza, por nombre.',
  },
  'e': {
    'id':11,
    'clv': 'e',
    'campo': 'orden',
    'desc': 'Buscamos la ORDEN Por NOMBRE de la EMPRESA',
  },
  's': {
    'id':12,
    'clv': 's',
    'campo': 'orden',
    'desc': 'Buscamos la ORDEN Por NOMBRE del SOLICITANTE.',
  },
  'a': {
    'id':13,
    'clv': 'a',
    'campo': 'orden',
    'desc': 'Buscamos la ORDEN Por MODELO del AUTO.',
  },
  'c': {
    'id':31,
    'clv': 'c',
    'campo': 'resps',
    'desc': 'Complemento para ver datos de la COTIZACIÓN por ID',
  },
  'pull': {
    'id':35,
    'clv': 'pull',
    'campo': 'resps',
    'desc': 'Bajamos de la Bandeja de Salida la COTIZACIÓN por ID',
  },
  'push': {
    'id':36,
    'clv': 'push',
    'campo': 'resps',
    'desc': 'Ponemos en la Bandeja de Salida la COTIZACIÓN por ID',
  },
  'pull_all': {
    'id' : 1000,
    'clv'  : 'pull_all',
    'campo': 'resps',
    'desc' : 'Sacamos las 3 opciones de cotización en la bandeja de salida',
  },
  'push_all': {
    'id' : 1000,
    'clv'  : 'push_all',
    'campo': 'resps',
    'desc' : 'Colocamos las 3 opciones de cotización en la bandeja de salida',
  },
  'car': {
    'id':1000,
    'clv': 'car',
    'desc': 'Mostrar en pantalla el Carrito de cotización final',
  },
  'vd': {
    'id':1000,
    'clv': 'vd',
    'desc': 'Mostramos los datos completos de... Ej. vd.o.1, vd.p.2 vd.c.3',
  },
  'rfs': {
    'id':1000,
    'clv': 'rfs',
    'desc': 'Refrescamos la sección indicada',
  },
  'h': {
    'id':1000,
    'clv': 'h',
    'desc': 'Mostramos una ventana con los comandos actuales',
  },
  'cc': {
    'id':1000,
    'clv': 'cc',
    'desc': 'Eliminamos los filtro de la cache, mostrando toda la lista',
  },
  't': {
    'id':1000,
    'clv': 't',
    'desc': 'Prefijo para todos los codigo, Buscar en Todas las secciones',
  },
  'cc-q': {
    'id':1000,
    'clv': 'cc-q',
    'desc': 'Borramos de cache todas las notificaciones pendientes que existen para procesa',
  },
  'refresh_list': {
    'hidden': true,
    'id' : 1000,
    'clv'  : 'refresh_list',
    'desc' : 'Refrescamos la sección indicada, un alias para el cmd [rfs]',
  },
};
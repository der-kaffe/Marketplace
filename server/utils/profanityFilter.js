const modismosChilenos = [
    // ... TU LISTA CHILENA COMPLETA ...
    'weon', 'weona', 'wn', 'wna', 'aweonao', 'aweona', 'weonaje',
    'agueonao', 'ahueonao', 'ahuevonado', 'hueon', 'hueonaje', 'weón', 'weona', 'hueona',
    'ctm', 'conchetumare', 'chucha', 'concha', 'chuchetumare', 'chuchatumare',
    'conchatumadre', 'conchetumadre', 'cochesumadre', 'conchesumare',
    'reconchetumadre', 'recochesumadre', 'reconchesumare', 'conchetumaré',
    'chuchatumaré', 'ctntm', 'chuparsela',
    'culiao', 'ql', 'culia', 'qla', 'sapo culiao', 'weon culiao', 'pajero culiao',
    'culeado', 'culeao', 'qlo', 'q lao', 'q liao',
    'puta', 'puto', 'puta la wea', 'puta el weon', 'hijo de puta', 'hdp',
    'hijo de la perra', 'hijueputa', 'putísima', 'putazo',
    'maraca', 'maricon', 'maricón', 'marica', 'maraco', 'mamón', 'mamon',
    'sapo', 'gil', 'pajero', 'fleto', 'choro', 'pico', 'chupalo', 'tula', 'raja',
    'verga', 'pene', 'vagina', 'culo', 'poto', 'orto', 'mierda', 'mrd', 'mierd4',
    'weon de mierda', 'culiao de mierda', 'marica de mierda', 'sapo de mierda',
    'huevón culiao', 'puta culiada', 'weona chucha', 'perkin', 'perkinazo',
    'sacowea', 'saco wea', 'la wea', 'wea podrida', 'weá', 'huevada', 'huevadas',
    'boton de cuero', 'remojar el cochayuyo', 'chupame la raja', 'traga sable',
    'agacharsele el pico', 'pajaron', 'pajear', 'cachar la pata', 'caharla',
    'tonto', 'estupido', 'ridiculo', 'bobo', 'pelotudo', 'tarado', 'imbecil',
    'bruto', 'payaso', 'payasa', 'loca', 'loco', 'perra', 'perrito', 'perrita',
    'hijo de la chucha', 'concha de tu madre', 'concha de su madre',
    'chucha tu madre', 'chucha su madre', 'la concha de la lora',
    'vete a la chucha', 'vete a la concha', 'vete a la mierda'
];

let listaBloqueoCompleta = null;

function normalizarTexto(texto) {
    if (typeof texto !== 'string') return '';
    let t = texto.toLowerCase();

    const mapaNormalizacion = {
        '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's',
        '7': 't', '8': 'b', '@': 'a', '$': 's',
        'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o',
        'ú': 'u', 'ü': 'u', 'ñ': 'n'
    };

    for (const [original, reemplazo] of Object.entries(mapaNormalizacion)) {
        t = t.split(original).join(reemplazo);
    }

    // Elimina todo lo que no sea a-z
    t = t.replace(/[^a-z]/g, '');

    return t;
}


async function cargarListaDeBloqueo() {
    // Si ya está cargada en memoria, la devolvemos
    if (listaBloqueoCompleta) {
        return listaBloqueoCompleta;
    }

    let listaProfanities = [];

    try {
        // Importamos el paquete
        const profanitiesModule = await import('profanities');

        // Intentamos extraer la lista (suele venir en 'default' o directamente en el módulo)
        if (Array.isArray(profanitiesModule.default)) {
            listaProfanities = profanitiesModule.default;
        } else if (Array.isArray(profanitiesModule)) {
            listaProfanities = profanitiesModule;
        } else {
            console.warn("Advertencia: No se pudo extraer array de 'profanities'. Usando solo lista manual.");
        }

    } catch (error) {
        console.error("Error cargando librería profanities (usando fallback):", error.message);
    }

    // UNIFICACIÓN: Juntamos lista inglés (profanities) + lista chilena (modismosChilenos)
    const listaTotal = [...listaProfanities, ...modismosChilenos];

    // NORMALIZACIÓN: Aplicamos tu función normalizarTexto a TODO
    const listaNormalizada = listaTotal.map(p => normalizarTexto(p));

    // LIMPIEZA: Quitamos duplicados y palabras muy cortas (menores a 3 letras)
    // para evitar bloquear cosas como 'as', 'in', 'on' que a veces vienen en listas gringas.
    listaBloqueoCompleta = [...new Set(listaNormalizada)].filter(p => p.length > 2);

    console.log(`Filtro cargado con ${listaBloqueoCompleta.length} palabras prohibidas.`);

    return listaBloqueoCompleta;
}


async function tienePalabrasProhibidas(texto) {
    if (!texto || typeof texto !== 'string') return false;

    const lista = await cargarListaDeBloqueo();
    const textoNormalizado = normalizarTexto(texto);

    // Verificamos si el texto normalizado contiene alguna de las palabras prohibidas
    return lista.some(palabraNormalizada =>
        textoNormalizado.includes(palabraNormalizada)
    );
}

// Exportar funciones
module.exports = {
    tienePalabrasProhibidas,
    cargarListaDeBloqueo,
    normalizarTexto
};
const modismosChilenos = [
    //agregar insultos aca
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


    t = t.replace(/[^a-z]/g, '');

    return t;
}


async function cargarListaDeBloqueo() {
    if (listaBloqueoCompleta) {
        return listaBloqueoCompleta;
    }

    try {
        const profanitiesModule = await import('profanities');
        const profanitiesES = profanitiesModule.es;
        if (!Array.isArray(profanitiesES)) {
            throw new Error("No se pudo encontrar la lista 'es' en el módulo 'profanities'");
        }

        const listaGlobalNormalizada = profanitiesES.map(p => normalizarTexto(p));
        const listaChilenaNormalizada = modismosChilenos.map(p => normalizarTexto(p));

        listaBloqueoCompleta = [...new Set([...listaGlobalNormalizada, ...listaChilenaNormalizada])];
        listaBloqueoCompleta = listaBloqueoCompleta.filter(p => p.length > 1); // Evita coincidencias vacías

        return listaBloqueoCompleta;

    } catch (error) {
        console.error("Error: No se pudo cargar la lista externa 'profanities'. Usando solo lista chilena.", error.message);
        listaBloqueoCompleta = [...new Set(modismosChilenos.map(p => normalizarTexto(p)))];
        listaBloqueoCompleta = listaBloqueoCompleta.filter(p => p.length > 1);
        return listaBloqueoCompleta;
    }
}


async function tienePalabrasProhibidas(texto) {
    if (!texto || typeof texto !== 'string') return false;

    const lista = await cargarListaDeBloqueo();
    const textoNormalizado = normalizarTexto(texto);

    return lista.some(palabraNormalizada =>
        textoNormalizado.includes(palabraNormalizada)
    );
}

// Exportar funciones
module.exports = {
    tienePalabrasProhibidas,
    cargarListaDeBloqueo, // Útil para "calentar" la caché al iniciar la app
    normalizarTexto       // Útil para pruebas unitarias
};
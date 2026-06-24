/// Todas las strings visibles al usuario en un solo lugar.
/// Preparado para internacionalización futura.
abstract class StringsEs {
  // ── Generales ──────────────────────────────────────────────────────────────
  static const appName = 'PostulaAI';
  static const continuar = 'Continuar';
  static const guardar = 'Guardar';
  static const cancelar = 'Cancelar';
  static const eliminar = 'Eliminar';
  static const editar = 'Editar';
  static const cerrar = 'Cerrar';
  static const volver = 'Volver';
  static const listo = '¡Listo!';
  static const cargando = 'Cargando...';
  static const error = 'Ocurrió un error';
  static const reintentar = 'Reintentar';
  static const sinResultados = 'No hay resultados todavía';
  static const compartir = 'Compartir';
  static const descargar = 'Descargar';

  // ── Onboarding ─────────────────────────────────────────────────────────────
  static const onboardingBienvenida = '¡Bienvenido a PostulaAI!';
  static const onboardingSubtitulo =
      'Te ayudamos a encontrar trabajo con inteligencia artificial.\n'
      'Empecemos con algunos datos básicos.';
  static const onboardingPaso1Titulo = 'Tus datos de contacto';
  static const onboardingPaso2Titulo = 'Tu experiencia laboral';
  static const onboardingPaso3Titulo = 'Tu educación';
  static const onboardingPaso4Titulo = 'Tus habilidades';
  static const onboardingPaso5Titulo = '¡Ya casi terminamos!';
  static const onboardingCompletado =
      'Tu perfil está listo. Ahora podés evaluar ofertas laborales.';

  // ── Perfil ─────────────────────────────────────────────────────────────────
  static const perfilTitulo = 'Mi Perfil';
  static const perfilNombre = 'Nombre completo';
  static const perfilEmail = 'Email';
  static const perfilTelefono = 'Teléfono';
  static const perfilCiudad = 'Ciudad';
  static const perfilPais = 'País';
  static const perfilLinkedIn = 'LinkedIn (opcional)';
  static const perfilExperiencia = 'Experiencia laboral';
  static const perfilEducacion = 'Educación';
  static const perfilHabilidades = 'Habilidades';
  static const perfilIdiomas = 'Idiomas';
  static const perfilAgregarExperiencia = '+ Agregar experiencia';
  static const perfilAgregarEducacion = '+ Agregar educación';
  static const perfilAgregarHabilidad = '+ Agregar habilidad';
  static const perfilActualizado = 'Perfil actualizado correctamente';

  // ── Evaluador ──────────────────────────────────────────────────────────────
  static const evaluadorTitulo = 'Evaluar oferta';
  static const evaluadorSubtitulo =
      'Pegá el texto de la oferta laboral y la IA evaluará si es una buena opción para vos.';
  static const evaluadorPlaceholder =
      'Pegá aquí el texto completo de la oferta...\n\n'
      'Ejemplo: "Buscamos Administrativo con experiencia en...\n'
      'Requisitos: ...\nBeneficios: ..."';
  static const evaluadorBoton = 'Evaluar esta oferta';
  static const evaluadorCargando = 'Analizando la oferta con IA...';
  static const evaluadorCargandoDetalle =
      'Esto tarda entre 10 y 20 segundos. Estamos comparando\n'
      'la oferta con tu perfil para darte un análisis preciso.';

  // ── Resultado de evaluación ────────────────────────────────────────────────
  static const resultadoTitulo = 'Resultado del análisis';
  static const resultadoCompatibilidad = 'Compatibilidad con tu perfil';
  static const resultadoFortalezas = 'Tus puntos fuertes para este puesto';
  static const resultadoBrechas = 'Qué te podría faltar';
  static const resultadoRecomendacion = 'Recomendación';
  static const resultadoGuardar = 'Guardar en mis postulaciones';
  static const resultadoDescartado = 'No me interesa';
  static const resultadoGenerarCV = 'Generar CV para esta oferta';
  static const resultadoPreparar = 'Preparar entrevista';

  static const recomendacionAlta =
      '¡Vale mucho la pena aplicar! Tu perfil encaja muy bien.';
  static const recomendacionMedia =
      'Podés aplicar. Hay brechas, pero son manejables.';
  static const recomendacionBaja =
      'No es la mejor opción ahora. Te recomendamos buscar otras.';

  // ── Tracker ────────────────────────────────────────────────────────────────
  static const trackerTitulo = 'Mis postulaciones';
  static const trackerVacio =
      'Todavía no guardaste ninguna postulación.\n'
      'Evaluá una oferta para empezar.';
  static const trackerFiltroTodas = 'Todas';
  static const trackerFiltroInteresado = 'Interesado';
  static const trackerFiltroAplicado = 'Aplicado';
  static const trackerFiltroEntrevista = 'Entrevista';
  static const trackerFiltroOferta = 'Oferta';
  static const trackerFiltroRechazado = 'No avanzó';
  static const trackerCambiarEstado = 'Cambiar estado';
  static const trackerEstadoActualizado = 'Estado actualizado';

  // ── Generador de CV ────────────────────────────────────────────────────────
  static const cvTitulo = 'Tu CV personalizado';
  static const cvSubtitulo =
      'Generamos un CV adaptado a esta oferta con las palabras clave del aviso.';
  static const cvGenerando = 'Generando tu CV...';
  static const cvGenerandoDetalle =
      'Estamos personalizando tu CV para esta oferta específica.';
  static const cvListo = '¡Tu CV está listo!';
  static const cvCompartir = 'Compartir CV';
  static const cvDescargarPDF = 'Descargar PDF';
  static const cvRegenerarCV = 'Regenerar';

  // ── Coach ──────────────────────────────────────────────────────────────────
  static const coachTitulo = 'Preparar entrevista';
  static const coachSubtitulo =
      'La IA generó preguntas probables para esta entrevista\n'
      'basándose en la oferta y tu perfil.';
  static const coachPreguntasSugeridas = 'Preguntas que te podrían hacer';
  static const coachConsejos = 'Consejos para esta entrevista';
  static const coachMiRespuesta = 'Preparar mi respuesta';
  static const coachRespuestaPlaceholder = 'Escribí tu respuesta...';
  static const coachMejorarRespuesta = 'Mejorar mi respuesta con IA';

  // ── Errores ────────────────────────────────────────────────────────────────
  static const errorRed = 'Sin conexión a internet. Verificá tu conexión.';
  static const errorServidor =
      'El servicio no está disponible. Intentá más tarde.';
  static const errorPerfilIncompleto =
      'Tu perfil está incompleto. Completalo para poder evaluar ofertas.';
  static const errorOfertaVacia =
      'Por favor pegá el texto de la oferta antes de continuar.';
  static const errorOfertaMuyCorta =
      'El texto es muy corto. Pegá el texto completo de la oferta.';
  static const errorSesion = 'Tu sesión expiró. Por favor volvé a ingresar.';

  // ── Login ──────────────────────────────────────────────────────────────────
  static const loginTitulo = 'Ingresá a tu cuenta';
  static const loginGoogle = 'Continuar con Google';
  static const loginEmail = 'Continuar con email';
  static const loginSinCuenta = '¿No tenés cuenta?';
  static const loginRegistrarse = 'Registrarse gratis';

  // ── Navegación ─────────────────────────────────────────────────────────────
  static const navEvaluar = 'Evaluar';
  static const navPostulaciones = 'Postulaciones';
  static const navPerfil = 'Mi Perfil';

  // ── Suscripción y límites ─────────────────────────────────────────────────

  static const planGratuito = 'Plan Gratuito';
  static const planPremium = 'PostulaAI Premium';
  static const planPremiumPrecio = '\$3.99 USD / mes';

  static const paywallTitulo = 'Alcanzaste tu límite de hoy';
  static const paywallSubtitulo =
      'Con el plan gratuito tenés un límite diario.\n'
      'Mañana se renueva automáticamente — o activá Premium para usar sin límites hoy.';

  static String paywallLimiteEvaluaciones(int limite) =>
      '$limite evaluaciones por día (gratis)';
  static String paywallLimiteCv(int limite) => '$limite CV por día (gratis)';
  static String paywallLimiteCoach(int limite) =>
      '$limite sesiones de coach por día (gratis)';

  static const paywallBeneficio1 = 'Evaluaciones ilimitadas';
  static const paywallBeneficio2 = 'CVs ilimitados';
  static const paywallBeneficio3 = 'Coach de entrevistas ilimitado';
  static const paywallBeneficio4 = 'Sin publicidad';

  static const paywallBotonPremium = 'Activar Premium — \$3.99/mes';
  static const paywallBotonEsperar = 'Esperar a mañana (gratis)';
  static const paywallRestaurarCompra = 'Restaurar compra';

  static const suscripcionActivada =
      '¡Premium activado! Gracias por apoyar PostulaAI.';
  static const suscripcionError =
      'No pudimos procesar el pago. Intentá de nuevo o contactanos.';
  static const suscripcionVencida =
      'Tu suscripción venció. Renovála para seguir sin límites.';

  // Contador de uso visible en la pantalla
  static String contadorEvaluaciones(int usadas, int limite) =>
      '$usadas / $limite evaluaciones de hoy';
  static String contadorCv(int usadas, int limite) =>
      '$usadas / $limite CVs de hoy';

  static const usoSinLimite = 'Sin límite · Premium';

  // ── Anuncios ───────────────────────────────────────────────────────────────
  static const adLabel = 'Publicidad';
  static const adQuitarAnuncios = 'Quitar anuncios con Premium';
}

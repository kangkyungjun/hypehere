// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MarketLens';

  @override
  String get tabDashboard => 'Panel';

  @override
  String get tabDashboardTooltip => 'Panel del mercado';

  @override
  String get tabSearch => 'Buscar';

  @override
  String get tabSearchTooltip => 'Buscar acciones';

  @override
  String get tabNews => 'Noticias';

  @override
  String get tabNewsTooltip => 'Noticias del mercado';

  @override
  String get tabCommunity => 'Comunidad';

  @override
  String get tabCommunityTooltip => 'Foro de discusión';

  @override
  String get tabWatchlist => 'Seguimiento';

  @override
  String get tabWatchlistTooltip => 'Mi lista de seguimiento';

  @override
  String get settings => 'Ajustes';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get compareTickers => 'Comparar acciones';

  @override
  String get account => 'Cuenta';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get loginSubtitle => 'Acceder a funciones de la comunidad';

  @override
  String get signup => 'Registrarse';

  @override
  String get signupTitle => 'Registrarse';

  @override
  String get signupSubtitle => 'Crear una cuenta nueva';

  @override
  String get noAccountSignup => '¿No tienes cuenta? Regístrate';

  @override
  String get hasAccountLogin => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get logoutConfirmTitle => 'Cerrar sesión';

  @override
  String get logoutConfirmMessage =>
      '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get welcome => '¡Bienvenido!';

  @override
  String get accountCreated => '¡Cuenta creada!';

  @override
  String get email => 'Correo electrónico';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get emailRequired => 'Introduce tu correo electrónico';

  @override
  String get emailInvalid => 'Formato de correo no válido';

  @override
  String get nickname => 'Apodo';

  @override
  String get nicknameHint => 'Apodo para la comunidad';

  @override
  String get nicknameRequired => 'Introduce un apodo';

  @override
  String get nicknameTooShort => 'El apodo debe tener al menos 2 caracteres';

  @override
  String get password => 'Contraseña';

  @override
  String get passwordHint => 'Introduce tu contraseña';

  @override
  String get passwordRequired => 'Introduce tu contraseña';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get passwordConfirm => 'Confirmar contraseña';

  @override
  String get passwordConfirmHint => 'Vuelve a introducir tu contraseña';

  @override
  String get passwordConfirmRequired => 'Confirma tu contraseña';

  @override
  String get passwordMismatch => 'Las contraseñas no coinciden';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get changePasswordGuide => 'Guía para cambiar contraseña';

  @override
  String get oldPassword => 'Contraseña actual';

  @override
  String get oldPasswordHint => 'Introduce tu contraseña actual';

  @override
  String get oldPasswordRequired => 'Introduce tu contraseña actual';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get newPasswordHint =>
      'Introduce una nueva contraseña (mín. 8 caracteres)';

  @override
  String get newPasswordRequired => 'Introduce una nueva contraseña';

  @override
  String get newPasswordConfirm => 'Confirmar nueva contraseña';

  @override
  String get newPasswordConfirmHint =>
      'Vuelve a introducir la nueva contraseña';

  @override
  String get newPasswordConfirmRequired => 'Confirma la nueva contraseña';

  @override
  String get newPasswordMustDiffer =>
      'La nueva contraseña debe ser diferente a la actual';

  @override
  String get passwordChanged => 'Contraseña cambiada correctamente';

  @override
  String passwordChangeFailed(String error) {
    return 'Error al cambiar contraseña: $error';
  }

  @override
  String get loginRequired => 'Inicio de sesión requerido';

  @override
  String get loginPromptMessage => '¡Inicia sesión y únete a la comunidad!';

  @override
  String get searchHint => 'Buscar por ticker o empresa (ej. AAPL, Apple)';

  @override
  String get searchFailed => 'Búsqueda fallida';

  @override
  String get noSearchResults => 'Sin resultados';

  @override
  String get tryDifferentSearch => 'Prueba con otro ticker';

  @override
  String get tickerSearch => 'Buscar ticker';

  @override
  String get enterTickerAbove => 'Introduce un término de búsqueda';

  @override
  String get recentSearches => 'Búsquedas recientes';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get retry => 'Reintentar';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get sectorMarketOverview => 'Resumen por sectores';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterNasdaq => 'NASDAQ';

  @override
  String get filterDow => 'Dow';

  @override
  String get marketLensAIScore => 'Puntuación IA';

  @override
  String get distributionShownOnFullLoad =>
      'La distribución se muestra al cargar todas las señales';

  @override
  String topN(int n) {
    return '▲ Top $n';
  }

  @override
  String bottomN(int n) {
    return '▼ Últimos $n';
  }

  @override
  String get noData => 'Sin datos';

  @override
  String get signalLoadFailed => 'Error al cargar señales';

  @override
  String dashboardLoadFailed(String error) {
    return 'Error al cargar el panel: $error';
  }

  @override
  String get allSignals => 'Todas las señales';

  @override
  String get sp500Signals => 'Señales S&P 500';

  @override
  String get dow30Signals => 'Señales Dow 30';

  @override
  String get nasdaq100Signals => 'Señales NASDAQ 100';

  @override
  String get marketTrend => 'Tendencia general del mercado';

  @override
  String get loadingSignals => 'Cargando señales...';

  @override
  String get loadingSP500Signals => 'Cargando señales S&P 500...';

  @override
  String get loadingDow30Signals => 'Cargando señales Dow 30...';

  @override
  String get loadingNasdaq100Signals => 'Cargando señales NASDAQ 100...';

  @override
  String get noAdditionalSignals => 'Sin señales adicionales';

  @override
  String showMore(int remaining) {
    return 'Ver más ($remaining restantes)';
  }

  @override
  String nItems(int count) {
    return '$count elementos';
  }

  @override
  String get scoreStrongBuy => 'Compra fuerte';

  @override
  String get scoreBuy => 'Compra';

  @override
  String get scoreHold => 'Mantener';

  @override
  String get scoreSell => 'Venta';

  @override
  String get scoreStrongSell => 'Venta fuerte';

  @override
  String get score => 'Puntuación';

  @override
  String get myWatchlist => 'Mi lista de seguimiento';

  @override
  String nTickers(int count) {
    return '$count acciones';
  }

  @override
  String get watchlistEmpty => 'La lista de seguimiento está vacía';

  @override
  String get watchlistEmptyHint =>
      'Busca y añade acciones desde la pestaña Buscar';

  @override
  String get explore => 'Explorar';

  @override
  String get tapToViewDetails => 'Toca para ver detalles';

  @override
  String tickerRemovedFromWatchlist(String ticker) {
    return '$ticker eliminado de la lista de seguimiento';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get tickerDataLoadFailed => 'Error al cargar datos de la acción';

  @override
  String get addToWatchlist => 'Añadir a seguimiento';

  @override
  String get removeFromWatchlist => 'Eliminar de seguimiento';

  @override
  String get addedToWatchlist => 'Añadido a la lista de seguimiento';

  @override
  String get removedFromWatchlist => 'Eliminado de la lista de seguimiento';

  @override
  String get watchlistDiscoveryTitle => 'Añade a tu lista de seguimiento';

  @override
  String get watchlistDiscoverySubtitle =>
      'Recibe alertas de noticias y señales de tus acciones';

  @override
  String get topTradingVolume => 'Mayor volumen de hoy';

  @override
  String get communitySearchHint => 'Buscar por título o contenido...';

  @override
  String get writePost => 'Escribir publicación';

  @override
  String get deletePost => 'Eliminar publicación';

  @override
  String get deleteConfirm =>
      '¿Estás seguro de que quieres eliminar esta publicación?\nLas publicaciones eliminadas no se pueden recuperar.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get done => 'Hecho';

  @override
  String get confirm => 'Confirmar';

  @override
  String get postDeleted => 'Publicación eliminada';

  @override
  String get report => 'Reportar';

  @override
  String get reportTitle => 'Reportar';

  @override
  String get reportAbuse => 'Abuso / Difamación';

  @override
  String get reportSpam => 'Spam / Publicidad';

  @override
  String get reportInappropriate => 'Contenido inapropiado';

  @override
  String get reportHarassment => 'Acoso';

  @override
  String get reportOther => 'Otro';

  @override
  String get reportDescription => 'Descripción';

  @override
  String get reportSubmitted => 'Reporte enviado';

  @override
  String get reportSubmit => 'Reportar';

  @override
  String postDeleteFailed(String error) {
    return 'Error al eliminar publicación: $error';
  }

  @override
  String get noPostsYet => 'Aún no hay publicaciones';

  @override
  String get writeFirstPost => '¡Escribe la primera publicación!';

  @override
  String get noSearchResultsCommunity => 'Sin resultados de búsqueda';

  @override
  String get tryDifferentFilter => 'Prueba con otra búsqueda o filtro';

  @override
  String get networkError => 'Error de conexión. Inténtalo más tarde.';

  @override
  String get serverTimeout =>
      'Tiempo de espera del servidor agotado. Inténtalo más tarde.';

  @override
  String get postsLoadFailed =>
      'Error al cargar publicaciones. Inténtalo más tarde.';

  @override
  String get searchResultsLoadFailed =>
      'Error al cargar resultados de búsqueda';

  @override
  String get refresh => 'Actualizar';

  @override
  String get all => 'Todos';

  @override
  String get add => 'Añadir';

  @override
  String tickerBoard(String ticker) {
    return 'Foro de $ticker';
  }

  @override
  String get tickerSearchHint => 'Buscar ticker... (ej. AAPL, TSLA)';

  @override
  String get popularTickers => 'Tickers populares';

  @override
  String get freePost => 'Libre';

  @override
  String get checkNetwork => 'Comprueba tu conexión de red';

  @override
  String get tryAgainLater => 'Inténtalo más tarde';

  @override
  String get newPost => 'Nueva publicación';

  @override
  String get editPostTitle => 'Editar publicación';

  @override
  String get tickerOnlyBoard => 'Foro por acción';

  @override
  String get selectTicker => 'Acción';

  @override
  String get tickerSearchLabel => 'Buscar acción';

  @override
  String get tickerSearchHintCreate =>
      'Buscar por nombre, símbolo o nombre local';

  @override
  String get tickerNotSelectedHint =>
      'Si no seleccionas una acción, se publicará como libre';

  @override
  String get noTickerSearchResults => 'Sin resultados de búsqueda';

  @override
  String get postTitle => 'Título';

  @override
  String get postTitleHint => 'Introduce el título de la publicación';

  @override
  String get postTitleRequired => 'Introduce un título';

  @override
  String get postTitleTooShort => 'El título debe tener al menos 2 caracteres';

  @override
  String get postContent => 'Contenido';

  @override
  String get postContentHint => 'Introduce el contenido de la publicación';

  @override
  String get postContentRequired => 'Introduce el contenido';

  @override
  String get postContentTooShort =>
      'El contenido debe tener al menos 5 caracteres';

  @override
  String get postCreated => 'Publicación creada';

  @override
  String get postUpdated => 'Publicación actualizada';

  @override
  String get submitPost => 'Publicar';

  @override
  String get updatePostButton => 'Actualizar';

  @override
  String get deleteComment => 'Eliminar comentario';

  @override
  String get deleteCommentConfirm =>
      '¿Estás seguro de que quieres eliminar este comentario?';

  @override
  String get editComment => 'Editar comentario';

  @override
  String get commentHint => 'Escribe un comentario...';

  @override
  String get commentPlaceholder => 'Introduce el contenido del comentario';

  @override
  String get commentCreated => 'Comentario publicado';

  @override
  String get commentUpdated => 'Comentario actualizado';

  @override
  String get commentDeleted => 'Comentario eliminado';

  @override
  String get commentRequired => 'Introduce un comentario';

  @override
  String get loginToViewComments => 'Inicia sesión para ver los comentarios';

  @override
  String get writeFirstComment => '¡Escribe el primer comentario!';

  @override
  String get postDetail => 'Publicación';

  @override
  String get startWithFirstPost => 'Empieza con tu primera publicación';

  @override
  String get writeAPost => 'Escribir publicación';

  @override
  String get cannotLoadPosts => 'No se pueden cargar las publicaciones';

  @override
  String get noPostsInTicker => 'Aún no hay publicaciones en este foro';

  @override
  String get writeFirstPostInTicker => '¡Escribe la primera publicación!';

  @override
  String get dataManagement => 'Gestión de datos';

  @override
  String get clearRecentSearches => 'Borrar búsquedas recientes';

  @override
  String nSearchRecords(int count) {
    return '$count registros de búsqueda';
  }

  @override
  String get clearRecentSearchesConfirm =>
      '¿Borrar todos los registros de búsqueda recientes?';

  @override
  String get recentSearchesCleared => 'Búsquedas recientes borradas';

  @override
  String get clearWatchlist => 'Borrar lista de seguimiento';

  @override
  String get clearWatchlistConfirm =>
      '¿Borrar todas las acciones de la lista de seguimiento?';

  @override
  String get watchlistCleared => 'Lista de seguimiento borrada';

  @override
  String get deleteAllData => 'Eliminar todos los datos';

  @override
  String get deleteAllDataConfirm =>
      'Se eliminarán todos los datos locales, incluyendo la lista de seguimiento y el historial de búsqueda. Esta acción no se puede deshacer.';

  @override
  String get deleteAllButton => 'Eliminar todo';

  @override
  String get allDataDeleted => 'Todos los datos eliminados';

  @override
  String get removeAllLocalData => 'Eliminar todos los datos locales';

  @override
  String get info => 'Información';

  @override
  String get aboutMarketLens => 'Acerca de';

  @override
  String version(String version) {
    return 'Versión $version';
  }

  @override
  String get appDescription =>
      'Herramienta de análisis bursátil con IA para decisiones de inversión basadas en datos';

  @override
  String get aiStockAnalysis => 'Análisis bursátil con IA';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get termsOfService => 'Términos de servicio';

  @override
  String get admin => 'Administración';

  @override
  String get adminPanel => 'Panel de administración';

  @override
  String get adminPanelSubtitle => 'Gestión de usuarios y permisos';

  @override
  String get showAds => 'Mostrar anuncios';

  @override
  String get adsEnabledDescription =>
      'Banners publicitarios visibles para todos los usuarios';

  @override
  String get adsDisabledDescription => 'Los anuncios están ocultos';

  @override
  String get sendPushNotification => 'Enviar notificación push';

  @override
  String get sendPushNotificationSubtitle => 'Enviar a todos los usuarios';

  @override
  String get pushTitle => 'Título';

  @override
  String get pushBody => 'Mensaje';

  @override
  String get send => 'Enviar';

  @override
  String pushSentResult(int count) {
    return 'Enviado a $count dispositivos';
  }

  @override
  String get pushSendFailed => 'Error al enviar la notificación push';

  @override
  String get promoteToGold => 'Ascender a Gold';

  @override
  String get promoteToManager => 'Ascender a Manager';

  @override
  String get demoteToRegular => 'Degradar a Regular';

  @override
  String get profile => 'Perfil';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get myPosts => 'Mis publicaciones';

  @override
  String get myComments => 'Mis comentarios';

  @override
  String get viewAll => 'Ver todo';

  @override
  String get noPosts => 'Sin publicaciones';

  @override
  String get noComments => 'Sin comentarios';

  @override
  String joinDate(String date) {
    return 'Registro: $date';
  }

  @override
  String get deleteAccount => 'Retirar cuenta';

  @override
  String get withdrawAccountConfirm =>
      '¿Seguro que deseas retirar tu cuenta?\nTu cuenta será eliminada permanentemente después de 7 días. Inicia sesión dentro de ese período para cancelar.';

  @override
  String get withdrawAccountReasonHint =>
      'Ingresa el motivo de tu retiro (opcional)';

  @override
  String get withdrawAccountSuccess =>
      'Se ha solicitado el retiro de la cuenta. Se eliminará permanentemente en 7 días.';

  @override
  String get withdrawAccountFailed =>
      'Error al solicitar el retiro de la cuenta. Inténtalo de nuevo.';

  @override
  String get deactivateAccount => 'Desactivar cuenta';

  @override
  String get profileUpdated => 'Perfil actualizado';

  @override
  String get imagePickerFailed => 'Error al seleccionar imagen';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文(简体)';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSettings => 'Idioma';

  @override
  String get systemDefault => 'Predeterminado del sistema';

  @override
  String get languageChanged => 'Idioma cambiado';

  @override
  String get timeJustNow => 'Ahora mismo';

  @override
  String timeMinutesAgo(int n) {
    return 'Hace $n min';
  }

  @override
  String timeHoursAgo(int n) {
    return 'Hace $n h';
  }

  @override
  String get timeYesterday => 'Ayer';

  @override
  String timeDaysAgo(int n) {
    return 'Hace $n días';
  }

  @override
  String get companyOverview => 'Resumen de la empresa';

  @override
  String get companyDetails => 'Detalles de la empresa';

  @override
  String get companyIntro => 'Acerca de';

  @override
  String employeeCount(String count) {
    return '$count empleados';
  }

  @override
  String get valuation => 'Valoración';

  @override
  String get forwardPE => 'PER estimado';

  @override
  String get beta => 'Beta';

  @override
  String get profitabilityGrowth => 'Rentabilidad y crecimiento';

  @override
  String get netProfitMargin => 'Margen neto';

  @override
  String get revenueGrowth => 'Crec. ingresos';

  @override
  String get operatingMargin => 'Margen operativo';

  @override
  String get earningsGrowth => 'Crec. beneficios';

  @override
  String get financialHealth => 'Salud financiera';

  @override
  String get debtRatio => 'Ratio deuda';

  @override
  String get liquidityRatio => 'Ratio liquidez';

  @override
  String get dividends => 'Dividendos';

  @override
  String get dividendYield => 'Rendimiento ';

  @override
  String get annualDividend => 'Anual ';

  @override
  String get shortInterest => 'Interés en corto';

  @override
  String get shortInterestRatio => 'Ratio en corto';

  @override
  String get shortPercentFloat => '% corto s/ flotante';

  @override
  String shortDays(String days) {
    return '$days días';
  }

  @override
  String get shortInterestLow => 'Interés en corto bajo (estable)';

  @override
  String get shortInterestModerate => 'Interés en corto moderado (precaución)';

  @override
  String get shortInterestHigh => 'Interés en corto alto (alerta)';

  @override
  String get institutionalInsiderFlow => 'Flujo institucional / interno';

  @override
  String get institutional => 'Institucional';

  @override
  String get insider => 'Interno';

  @override
  String get oneDay => '1D';

  @override
  String get fiveDay => '5D';

  @override
  String tickerNews(String ticker) {
    return 'Noticias de $ticker';
  }

  @override
  String newsCount(int count) {
    return '$count';
  }

  @override
  String get oneWeek => '1S';

  @override
  String get oneMonth => '1M';

  @override
  String get noNews => 'Sin noticias';

  @override
  String get marketNews => 'Noticias del mercado';

  @override
  String get viewOriginalArticle => 'Ver artículo original';

  @override
  String get sentimentBullish => 'Alcista';

  @override
  String get sentimentNeutral => 'Neutral';

  @override
  String get sentimentBearish => 'Bajista';

  @override
  String get aiSummaryNews => 'Noticias resumen IA';

  @override
  String get aiSummary => 'Resumen IA';

  @override
  String get noNewsAvailable => 'No hay noticias disponibles';

  @override
  String get earningsHistory => 'Historial de resultados';

  @override
  String get earningsHistoryEPS => 'Historial de resultados (BPA)';

  @override
  String get earningsEstimate => 'Estimado';

  @override
  String get earningsBeat => 'Superado';

  @override
  String get earningsMiss => 'No alcanzado';

  @override
  String get earningsActual => 'Real';

  @override
  String get earningsScheduled => 'Programado';

  @override
  String get epsEstimateLabel => 'BPA estimado';

  @override
  String get revenueEstimateLabel => 'Ingresos estimados';

  @override
  String get averageLabel => 'prom.';

  @override
  String get surpriseLabel => 'Sorpresa';

  @override
  String get thisWeekEarnings => 'Resultados de esta semana';

  @override
  String get previousEarnings => 'Resultados anteriores';

  @override
  String earningsCount(int count) {
    return '$count';
  }

  @override
  String get noEarningsThisWeek => 'No hay resultados programados esta semana';

  @override
  String get nextEarningsDate => 'Próximos resultados';

  @override
  String get earningsConfirmed => 'Confirmado';

  @override
  String get keyEvents => 'Eventos clave';

  @override
  String get eventDetails => 'Detalles del evento';

  @override
  String get upcomingEvents => 'Próximos eventos';

  @override
  String get exDividendDate => 'Fecha ex-dividendo';

  @override
  String get dividendPayDate => 'Fecha de pago de dividendo';

  @override
  String recentEarningsQuarters(int count) {
    return 'Resultados recientes (${count}T)';
  }

  @override
  String get earningsHistoryChart => 'Historial de resultados (Gráfico)';

  @override
  String get weekdayMon => 'Lun';

  @override
  String get weekdayTue => 'Mar';

  @override
  String get weekdayWed => 'Mié';

  @override
  String get weekdayThu => 'Jue';

  @override
  String get weekdayFri => 'Vie';

  @override
  String get weekdaySat => 'Sáb';

  @override
  String get weekdaySun => 'Dom';

  @override
  String get macroFedFunds => 'Tasa Fed';

  @override
  String get macroDGS10 => 'Rend. 10A';

  @override
  String get macroDGS2 => 'Rend. 2A';

  @override
  String get macroT10Y2Y => 'Diferencial';

  @override
  String get macroVIXCLS => 'VIX';

  @override
  String get macroCPIAUCSL => 'IPC';

  @override
  String get macroUNRATE => 'Desempleo';

  @override
  String get macroFedFundsDesc => 'Tasa de fondos federales';

  @override
  String get macroDGS10Desc => 'Rendimiento del Tesoro de EE.UU. a 10 años';

  @override
  String get macroDGS2Desc => 'Rendimiento del Tesoro de EE.UU. a 2 años';

  @override
  String get macroT10Y2YDesc => 'Diferencial de la curva de tipos (10A-2A)';

  @override
  String get macroVIXCLSDesc => 'Índice de volatilidad del mercado';

  @override
  String get macroCPIAUCSLDesc => 'Índice de precios al consumidor (IPC)';

  @override
  String get macroUNRATEDesc => 'Tasa de desempleo de EE.UU.';

  @override
  String get riskBearish => 'Bajista';

  @override
  String get riskCautious => 'Cauteloso';

  @override
  String get riskNeutral => 'Neutral';

  @override
  String get riskPositive => 'Positivo';

  @override
  String get riskBullish => 'Alcista';

  @override
  String get macroCategoryRates => 'Tipos de interés';

  @override
  String get macroCategorySentiment => 'Sentimiento';

  @override
  String get macroCategoryEconomy => 'Economía';

  @override
  String get macroYieldCurve => 'Curva de tipos';

  @override
  String get macroLiquidity => 'Liquidez';

  @override
  String get macroOverall => 'Macro general';

  @override
  String macroCurrentValue(String value) {
    return 'Actual: $value';
  }

  @override
  String macroChange(String value) {
    return 'Cambio: $value';
  }

  @override
  String epsEstimateValue(String value) {
    return 'Est. \$$value';
  }

  @override
  String get bbInterpretation => 'Interpretación de Bandas de Bollinger';

  @override
  String get bbBandWidth =>
      '• Ancho de banda: indica volatilidad (más ancho = mayor)';

  @override
  String get bbUpperApproach =>
      '• Acercamiento a banda superior: posible sobrecompra';

  @override
  String get bbLowerApproach =>
      '• Acercamiento a banda inferior: posible sobreventa';

  @override
  String get bbMiddleLine => '• Línea media: media móvil de 20 días';

  @override
  String get cannotLoadData => 'No se pueden cargar los datos';

  @override
  String get marketlensAI => 'MarketLens AI';

  @override
  String get marketlensAIOpinion => 'Opinión de MarketLens AI';

  @override
  String get bullishFactors => 'Factores alcistas';

  @override
  String get bearishFactors => 'Factores bajistas';

  @override
  String get target => 'Objetivo ';

  @override
  String get stopLoss => 'Stop ';

  @override
  String get averageTargetPrice => 'Precio objetivo promedio';

  @override
  String get currentPrice => 'Actual';

  @override
  String get targetPrice => 'Objetivo';

  @override
  String get recentAnalystRatings => 'Calificaciones recientes de analistas';

  @override
  String get unknownFirm => 'Desconocido';

  @override
  String get volume => 'Volumen';

  @override
  String get legend => 'Leyenda';

  @override
  String get ratingBuy => 'Compra';

  @override
  String get ratingStrongBuy => 'Compra fuerte';

  @override
  String get ratingOutperform => 'Supera al mercado';

  @override
  String get ratingHold => 'Mantener';

  @override
  String get ratingNeutral => 'Neutral';

  @override
  String get ratingMarketPerform => 'Igual al mercado';

  @override
  String get ratingSell => 'Venta';

  @override
  String get ratingStrongSell => 'Venta fuerte';

  @override
  String get ratingUnderperform => 'Por debajo del mercado';

  @override
  String get ratingActionUpgrade => 'Mejora';

  @override
  String get ratingActionDowngrade => 'Rebaja';

  @override
  String get ratingActionReiterated => 'Reiterado';

  @override
  String get ratingActionInitiated => 'Iniciado';

  @override
  String get roleMaster => 'Master';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleGold => 'Gold';

  @override
  String get roleRegular => 'Regular';

  @override
  String get roleGuest => 'Invitado';

  @override
  String get errInvalidCredentials => 'Correo o contraseña incorrectos';

  @override
  String get errLoginRequired => 'Inicio de sesión requerido';

  @override
  String get errSessionExpired => 'Sesión expirada. Inicia sesión de nuevo.';

  @override
  String get errCannotLoadUser =>
      'No se puede cargar la información del usuario';

  @override
  String get errServerConnection =>
      'No se puede conectar al servidor. Comprueba tu red.';

  @override
  String get errServerConnectionShort => 'No se puede conectar al servidor';

  @override
  String get errNetworkFailed =>
      'Error de conexión. Comprueba tu conexión a internet.';

  @override
  String get errResponseFormat => 'Formato de respuesta del servidor no válido';

  @override
  String errTimeout(int seconds) {
    return 'Tiempo de espera del servidor agotado (${seconds}s)';
  }

  @override
  String get errBadRequest => 'Comprueba los datos introducidos';

  @override
  String get errForbidden => 'Acceso denegado';

  @override
  String get errNotFound => 'Página no encontrada';

  @override
  String get errServerError => 'Error del servidor. Inténtalo más tarde.';

  @override
  String get errNoEditPermission => 'Sin permiso de edición';

  @override
  String get errNoDeletePermission => 'Sin permiso de eliminación';

  @override
  String get errPostDeleteFailed => 'Error al eliminar la publicación';

  @override
  String get errCommentDeleteFailed => 'Error al eliminar el comentario';

  @override
  String get errReportAlreadySubmitted => 'Ya has reportado este contenido';

  @override
  String get errCannotReportOwn => 'No puedes reportar tu propio contenido';

  @override
  String get errReportFailed => 'Error al enviar el reporte';

  @override
  String get errManagerRequired => 'Se requiere acceso de Manager o superior';

  @override
  String get errMasterRequired => 'Se requiere acceso de Master';

  @override
  String get errSearchRequired => 'Introduce un término de búsqueda';

  @override
  String get errDemotionFailed => 'Error en la degradación';

  @override
  String get errMaxCompare => 'Se pueden comparar un máximo de 3 acciones';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get dayBeforeYesterday => 'Hace 2 días';

  @override
  String expertCount(String count) {
    return 'Objetivos de analistas ($count)';
  }

  @override
  String scorePoints(String score) {
    return '$score pts';
  }

  @override
  String averageVolume(String volume) {
    return 'Prom.: $volume';
  }

  @override
  String get showBullBearFactors => 'Ver factores';

  @override
  String get hideBullBearFactors => 'Ocultar factores';

  @override
  String analystConsensus(String count) {
    return 'Objetivos de analistas ($count firmas)';
  }

  @override
  String lowestPrice(String price) {
    return 'Mín. \$$price';
  }

  @override
  String highestPrice(String price) {
    return 'Máx. \$$price';
  }

  @override
  String get liveTalk => 'Chat en vivo';

  @override
  String commentsCount(int count) {
    return '$count comentarios';
  }

  @override
  String get browsePosts => 'Explorar publicaciones';

  @override
  String get loginPromptComments =>
      'Descubre lo que piensan otros inversores\ny comparte tu propio análisis.';

  @override
  String get shareThoughtsPrompt =>
      'Comparte tu opinión sobre acciones\ny conecta con otros inversores';

  @override
  String get writeFirstCommentPrompt =>
      'Deja el primer comentario en una publicación';

  @override
  String get startConversationPrompt =>
      'Inicia una conversación comentando\nen publicaciones de otros inversores';

  @override
  String get ratingOverweight => 'Sobreponderar';

  @override
  String get ratingUnderweight => 'Infraponderar';

  @override
  String get ratingSectorOutperform => 'Supera al sector';

  @override
  String get ratingSectorPerform => 'Igual al sector';

  @override
  String get ratingSectorUnderperform => 'Por debajo del sector';

  @override
  String get ratingPositive => 'Positivo';

  @override
  String get ratingNegative => 'Negativo';

  @override
  String get ratingEqualWeight => 'Igual ponderación';

  @override
  String get keyMetricsComparison => 'Comparación de métricas clave';

  @override
  String get metric => 'Métrica';

  @override
  String get serverCalculatedNote =>
      '※ Todas las métricas son valores calculados por el servidor';

  @override
  String get priceTrendComparison => 'Comparación de tendencia de precios';

  @override
  String get rsiComparison => 'Comparación RSI (Valores del servidor)';

  @override
  String get rsiInterpretation =>
      '※ RSI > 70: Sobrecompra / RSI < 30: Sobreventa';

  @override
  String get passwordChangeInstructions =>
      '• La nueva contraseña debe tener al menos 8 caracteres\n• Usa una combinación de letras, números y símbolos\n• Necesitarás iniciar sesión de nuevo con la nueva contraseña';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get noNotifications => 'No hay notificaciones';

  @override
  String get notificationsRetentionHint =>
      'Notificaciones de los últimos 7 días.';

  @override
  String get bioLabel => 'Biografía';

  @override
  String get bioHint => 'Cuéntanos sobre ti';

  @override
  String get profileEditGuide => 'Guía de edición de perfil';

  @override
  String get updatedDate => 'Actualizado:';

  @override
  String get tabCalendar => 'Calendario';

  @override
  String get tabCalendarTooltip => 'Calendario de eventos';

  @override
  String get eventTypeFomc => 'FOMC';

  @override
  String get eventTypeEarnings => 'Resultados';

  @override
  String get eventTypeEconomic => 'Indicadores';

  @override
  String get eventTypeOptionsExpiry => 'Vencimiento opciones';

  @override
  String get eventTypeConference => 'Conferencia';

  @override
  String get eventTypeDividend => 'Dividendo';

  @override
  String get eventTypeProductLaunch => 'Lanzamiento';

  @override
  String get eventTypeShareholder => 'Junta de accionistas';

  @override
  String get eventTypeFedSpeech => 'Discurso Fed';

  @override
  String nEvents(int count) {
    return '$count eventos';
  }

  @override
  String get noEventsThisMonth => 'No hay eventos este mes';

  @override
  String get noEventsSelectedDay => 'No hay eventos en este día';

  @override
  String get forgotPassword => 'Olvidé mi contraseña';

  @override
  String get forgotPasswordSubtitle =>
      'Ingresa tu correo electrónico y te enviaremos un código de verificación.';

  @override
  String get sendVerificationCode => 'Enviar código';

  @override
  String get verificationTitle => 'Verificación de correo';

  @override
  String verificationSubtitle(String email) {
    return 'Ingresa el código de 6 dígitos enviado a $email.';
  }

  @override
  String verificationExpiry(String time) {
    return 'Expira en: $time';
  }

  @override
  String get verificationCode => 'Código de verificación';

  @override
  String get verificationCodeRequired =>
      'Ingresa el código de verificación de 6 dígitos';

  @override
  String get verifyButton => 'Verificar';

  @override
  String get resendCode => 'Reenviar código';

  @override
  String resendCodeCooldown(int seconds) {
    return 'Reenviar en (${seconds}s)';
  }

  @override
  String get verificationCodeResent =>
      'El código de verificación ha sido reenviado.';

  @override
  String get resetPassword => 'Restablecer contraseña';

  @override
  String get resetPasswordSubtitle => 'Ingresa tu nueva contraseña.';

  @override
  String get resetPasswordSuccess =>
      'Contraseña restablecida. Inicia sesión con tu nueva contraseña.';

  @override
  String get errEmailNotVerified => 'Se requiere verificación de correo.';

  @override
  String get errRateLimited => 'Por favor, inténtalo más tarde.';

  @override
  String get myHoldings => 'Mis posiciones';

  @override
  String nHoldings(int count) {
    return '$count posiciones';
  }

  @override
  String get portfolioSummary => 'Resumen del portafolio';

  @override
  String get totalValue => 'Valor total';

  @override
  String get totalPnl => 'P&L total';

  @override
  String get dayPnl => 'Hoy';

  @override
  String get buyStock => 'Comprar';

  @override
  String get shares => 'Acciones';

  @override
  String get avgPrice => 'Precio promedio';

  @override
  String get totalCost => 'Costo total';

  @override
  String get enterShares => 'Número de acciones';

  @override
  String get enterAvgPrice => 'Precio promedio de compra';

  @override
  String get buyConfirm => 'Añadir a posiciones';

  @override
  String holdingAdded(String ticker) {
    return '$ticker añadido a posiciones';
  }

  @override
  String holdingRemoved(String ticker) {
    return '$ticker eliminado de posiciones';
  }

  @override
  String removeHoldingConfirm(String ticker) {
    return '¿Eliminar $ticker de posiciones?';
  }

  @override
  String get aiAdvice => 'Consejo IA';

  @override
  String get aiAdviceInstant => 'Consejo IA instantáneo';

  @override
  String get bullishFactorsPortfolio => 'Factores alcistas';

  @override
  String get bearishFactorsPortfolio => 'Factores bajistas';

  @override
  String get detailedAnalysisComingSoon =>
      'El análisis detallado se actualizará por la mañana';

  @override
  String get loginForPortfolio => 'Inicia sesión para gestionar tu portafolio';

  @override
  String get loginForPortfolioHint =>
      'Seguimiento de posiciones, consejos IA y control de P&L';

  @override
  String sharesAtPrice(String shares, String price) {
    return '$shares acciones @ \$$price';
  }

  @override
  String get noHoldingsYet => 'Sin posiciones aún';

  @override
  String get addFirstHolding =>
      'Compra acciones de tu lista de seguimiento para comenzar';

  @override
  String get invalidShares => 'Introduce un número de acciones válido';

  @override
  String get invalidPrice => 'Introduce un precio válido';

  @override
  String get confidence => 'Confianza';

  @override
  String get tabHoldings => 'Posiciones';

  @override
  String get purchaseDate => 'Fecha de compra';

  @override
  String get sellDate => 'Fecha de venta';

  @override
  String get sellPrice => 'Precio de venta';

  @override
  String get sellShares => 'Cantidad a vender';

  @override
  String get sellConfirm => 'Confirmar venta';

  @override
  String get sellAll => 'Vender todo';

  @override
  String get sellAmount => 'Monto de venta';

  @override
  String get realizedPnlLabel => 'P&L realizado';

  @override
  String get unrealizedPnl => 'P&L no realizado';

  @override
  String get realizedPnl => 'Realizado';

  @override
  String get transactionHistory => 'Historial de transacciones';

  @override
  String get additionalBuy => 'Comprar más';

  @override
  String get partialSell => 'Vender';

  @override
  String get editHolding => 'Editar info';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String holdingUpdated(String ticker) {
    return '$ticker posición actualizada';
  }

  @override
  String get portfolioAIAnalysis => 'Análisis IA del portafolio';

  @override
  String get aiRecommendations => 'Recomendaciones';

  @override
  String get analysisWaiting => 'Análisis IA pendiente...';

  @override
  String get alreadyHeld => 'En cartera';

  @override
  String get goToWatchlistTab => 'Ir a seguimiento';

  @override
  String get noHoldingsHint =>
      'Añade posiciones desde la pestaña de seguimiento';

  @override
  String get closingPriceAuto => 'Precio de cierre automático';

  @override
  String holidayPriceNotice(String date) {
    return 'Precio de cierre del $date (día hábil anterior)';
  }

  @override
  String get addToHoldings => 'Añadir a posiciones';

  @override
  String get currentHoldings => 'Posiciones actuales';

  @override
  String get holdingStatus => 'Estado de posición';

  @override
  String addHoldingTitle(String ticker) {
    return '$ticker Añadir posición';
  }

  @override
  String sellHoldingTitle(String ticker) {
    return '$ticker Vender';
  }

  @override
  String editHoldingTitle(String ticker) {
    return '$ticker Editar posición';
  }

  @override
  String holdingSold(String ticker) {
    return '$ticker vendido exitosamente';
  }

  @override
  String get deleteHolding => 'Eliminar posición';

  @override
  String get avgPriceLabel => 'Precio promedio';

  @override
  String get currentValueLabel => 'Valor actual';

  @override
  String get dailyUpdate => 'Actualización diaria por la mañana';
}

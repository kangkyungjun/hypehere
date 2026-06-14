enum ApiErrorCode {
  // Network & Timeout
  timeout10s,
  timeout15s,
  networkFailed,
  serverConnection,
  serverConnectionShort,

  // Response
  responseFormat,

  // Auth
  invalidCredentials,
  loginRequired,
  sessionExpired,
  cannotLoadUser,
  emailNotVerified,
  rateLimited,
  weakPassword,

  // HTTP Status
  badRequest,
  forbidden,
  notFound,
  tickerNotFound,
  serverError,

  // Permission
  noEditPermission,
  noDeletePermission,

  // Community
  postDeleteFailed,
  commentDeleteFailed,
  reportAlreadySubmitted,
  cannotReportOwnContent,
  reportFailed,

  // Admin
  managerRequired,
  masterRequired,
  searchRequired,
  demotionFailed,

  // Fallback
  genericError,
}

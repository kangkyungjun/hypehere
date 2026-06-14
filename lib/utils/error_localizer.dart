import 'package:flutter/widgets.dart';
import '../exceptions/api_error_codes.dart';
import '../exceptions/api_exception.dart';
import '../l10n/app_localizations.dart';

class ErrorLocalizer {
  static String getMessage(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context);
    if (error is ApiException) return _fromCode(l10n, error);
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  static String _fromCode(AppLocalizations l10n, ApiException e) {
    switch (e.code) {
      case ApiErrorCode.timeout10s:
        return l10n.errTimeout(10);
      case ApiErrorCode.timeout15s:
        return l10n.errTimeout(15);
      case ApiErrorCode.networkFailed:
        return l10n.errNetworkFailed;
      case ApiErrorCode.serverConnection:
        return l10n.errServerConnection;
      case ApiErrorCode.serverConnectionShort:
        return l10n.errServerConnectionShort;
      case ApiErrorCode.responseFormat:
        return l10n.errResponseFormat;
      case ApiErrorCode.invalidCredentials:
        return l10n.errInvalidCredentials;
      case ApiErrorCode.loginRequired:
        return l10n.errLoginRequired;
      case ApiErrorCode.sessionExpired:
        return l10n.errSessionExpired;
      case ApiErrorCode.cannotLoadUser:
        return l10n.errCannotLoadUser;
      case ApiErrorCode.emailNotVerified:
        return l10n.errEmailNotVerified;
      case ApiErrorCode.rateLimited:
        return l10n.errRateLimited;
      case ApiErrorCode.weakPassword:
        return l10n.passwordPolicyFailed;
      case ApiErrorCode.badRequest:
        if (e.debugMessage != null && e.debugMessage!.isNotEmpty) {
          return e.debugMessage!;
        }
        return l10n.errBadRequest;
      case ApiErrorCode.forbidden:
        return l10n.errForbidden;
      case ApiErrorCode.notFound:
        return l10n.errNotFound;
      case ApiErrorCode.tickerNotFound:
        return l10n.errNotFound;
      case ApiErrorCode.serverError:
        return l10n.errServerError;
      case ApiErrorCode.noEditPermission:
        return l10n.errNoEditPermission;
      case ApiErrorCode.noDeletePermission:
        return l10n.errNoDeletePermission;
      case ApiErrorCode.postDeleteFailed:
        return l10n.errPostDeleteFailed;
      case ApiErrorCode.commentDeleteFailed:
        return l10n.errCommentDeleteFailed;
      case ApiErrorCode.reportAlreadySubmitted:
        return l10n.errReportAlreadySubmitted;
      case ApiErrorCode.cannotReportOwnContent:
        return l10n.errCannotReportOwn;
      case ApiErrorCode.reportFailed:
        return l10n.errReportFailed;
      case ApiErrorCode.managerRequired:
        return l10n.errManagerRequired;
      case ApiErrorCode.masterRequired:
        return l10n.errMasterRequired;
      case ApiErrorCode.searchRequired:
        return l10n.errSearchRequired;
      case ApiErrorCode.demotionFailed:
        return l10n.errDemotionFailed;
      case ApiErrorCode.genericError:
        return e.statusCode != null
            ? '${l10n.errServerError} (${e.statusCode})'
            : l10n.errServerError;
    }
  }
}

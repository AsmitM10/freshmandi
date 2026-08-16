import '../../../core/constants/app_routes.dart';

/// Mirrors the `account_status` check constraint on the `restaurants` table.
enum AccountStatus { pending, approved, rejected, suspended }

/// Single source of truth for "given this account status, where does the
/// user go" — used by both the splash session-check and the post-login
/// redirect so the two flows can never disagree.
extension AccountStatusRouting on AccountStatus {
  String get destinationRoute {
    switch (this) {
      case AccountStatus.approved:
        return AppRoutes.home;
      case AccountStatus.pending:
        return AppRoutes.pendingApproval;
      case AccountStatus.rejected:
        return AppRoutes.accountRejected;
      case AccountStatus.suspended:
        return AppRoutes.accountSuspended;
    }
  }
}

extension AccountStatusParsing on String {
  AccountStatus toAccountStatus() {
    switch (this) {
      case 'approved':
        return AccountStatus.approved;
      case 'rejected':
        return AccountStatus.rejected;
      case 'suspended':
        return AccountStatus.suspended;
      case 'pending':
      default:
        return AccountStatus.pending;
    }
  }
}

import '../../../l10n/gen/app_localizations.dart';

enum HistoryTab { allOrders, transaction, pendingInvoice }

extension HistoryTabX on HistoryTab {
  String label(AppLocalizations l10n) {
    switch (this) {
      case HistoryTab.allOrders:
        return l10n.historyTabAll;
      case HistoryTab.transaction:
        return l10n.historyTabTransaction;
      case HistoryTab.pendingInvoice:
        return l10n.historyTabPending;
    }
  }

  String emptyMessage(AppLocalizations l10n) {
    switch (this) {
      case HistoryTab.allOrders:
        return l10n.historyEmptyAll;
      case HistoryTab.transaction:
        return l10n.historyEmptyTransaction;
      case HistoryTab.pendingInvoice:
        return l10n.historyEmptyPending;
    }
  }
}

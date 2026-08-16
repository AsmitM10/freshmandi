enum HistoryTab { allOrders, transaction, pendingInvoice }

extension HistoryTabX on HistoryTab {
  String get label {
    switch (this) {
      case HistoryTab.allOrders:
        return 'All Orders';
      case HistoryTab.transaction:
        return 'Transaction';
      case HistoryTab.pendingInvoice:
        return 'Pending Invoice';
    }
  }

  String get emptyMessage {
    switch (this) {
      case HistoryTab.allOrders:
        return 'No orders yet';
      case HistoryTab.transaction:
        return 'No transactions yet';
      case HistoryTab.pendingInvoice:
        return 'No pending invoices';
    }
  }
}

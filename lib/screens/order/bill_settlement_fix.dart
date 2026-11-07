// =============================================================================
// FIX FOR BillSettlementScreen._markPaidAndComplete
// =============================================================================
//
// REPLACE the whole _markPaidAndComplete method with this version:
// =============================================================================

/*
  Future<void> _markPaidAndComplete() async {
    if (_isSettling) return;

    final selected = _selectedPayment;
    if (selected == null || selected.trim().isEmpty) {
      await _showNotice('Please select a payment method.');
      return;
    }

    setState(() => _isSettling = true);

    try {
      // Convert UI label → lowercase string that the service understands
      final method = switch (selected.trim()) {
        'Cash' => 'cash',
        'Card' => 'card',
        'UPI' => 'upi',
        _ => selected.trim().toLowerCase(),
      };

      // Preferred: call settleOrder directly (Cloud Function)
      await ref.read(orderServiceProvider).settleOrder(
            orderId: widget.bill.orderNumber,
            paymentMethod: method,
          );

      // ─── OR if you still want to keep updatePaymentStatus: ───
      // await ref.read(orderServiceProvider).updatePaymentStatus(
      //       orderId: widget.bill.orderNumber,
      //       status: PaymentStatus.paid,          // enum, not string!
      //       paymentMethod: PaymentMethod.cash,   // or .card / .upi
      //     );

      if (!mounted) return;
      _close();
    } catch (e) {
      if (!mounted) return;
      await _showNotice(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isSettling = false);
    }
  }
*/

// =============================================================================
// ALSO FIX _paymentMethodFromLabel if you still need it
// =============================================================================
//
// Change the return type usage so it returns a String or keep the enum
// and pass PaymentMethod to updatePaymentStatus.
//
// Preferred modern version (no enum conversion needed):
//
//   final method = switch (selected.trim()) {
//     'Cash' => 'cash',
//     'Card' => 'card',
//     'UPI'  => 'upi',
//     _     => selected.trim().toLowerCase(),
//   };
//
//   await ref.read(orderServiceProvider).settleOrder(
//     orderId: widget.bill.orderNumber,
//     paymentMethod: method,
//   );

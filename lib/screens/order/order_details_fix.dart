// =============================================================================
// FIX FOR OrderDetailsScreen – _TerminateAction
// =============================================================================
//
// The old code was:
//
//   await OrderService().updateOrderStatus(
//     order.id,                    // positional
//     OrderStatus.cancelled,       // positional
//   );
//
// REPLACE with named parameters:
//
// =============================================================================

/*
  Future<void> _confirmAndCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await RdxNoticeDialog.showConfirmation(
      context,
      title: 'Terminate order?',
      message: 'This will cancel the order. It will be kept in history and '
          'shown under the Cancelled tab. This cannot be undone.',
      cancelButtonLabel: 'Keep order',
      confirmButtonLabel: 'Terminate',
      confirmButtonColor: const Color(0xFFE05151),
    );

    if (confirmed != true) return;

    try {
      // ✅ Correct named call
      await OrderService().updateOrderStatus(
        orderId: order.id,
        newStatus: OrderStatus.cancelled,
      );

      // or if you injected the service:
      // await ref.read(orderServiceProvider).updateOrderStatus(
      //   orderId: order.id,
      //   newStatus: OrderStatus.cancelled,
      // );

      if (!context.mounted) return;
      ref.invalidate(orderDetailProvider(order.id));
      await ref.read(liveOrdersProvider).load();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to terminate order. $e')),
      );
    }
  }
*/

// =============================================================================
// Also in _WorkflowAction the call is already correct (named).
// Just make sure you use:
//
//   await OrderService().updateOrderStatus(
//     orderId: order.id,
//     newStatus: nextStatus,
//   );

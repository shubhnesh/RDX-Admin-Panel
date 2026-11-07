"use strict";

const validTransitions = {
  pending: ["preparing", "cancelled"],
  preparing: ["ready", "cancelled"],
  ready: ["delivered", "cancelled"],
};

/**
 * Returns an error message if the transition is not allowed, otherwise null.
 * Status and payment values are normalized to lowercase so mixed-case
 * documents from older clients still advance correctly.
 */
function getOrderStatusTransitionError(currentStatus, newStatus, paymentStatus) {
  const current = String(currentStatus || "")
    .trim()
    .toLowerCase();
  const next = String(newStatus || "")
    .trim()
    .toLowerCase();
  const payment = String(paymentStatus || "unpaid")
    .trim()
    .toLowerCase();

  const allowedStatuses = Object.prototype.hasOwnProperty.call(
    validTransitions,
    current
  )
    ? validTransitions[current]
    : null;

  if (!allowedStatuses || !allowedStatuses.includes(next)) {
    return `Cannot change order status from ${current || "(empty)"} to ${next || "(empty)"}.`;
  }

  // Delivery (or served) requires the order to be marked paid first.
  if (next === "delivered" && payment !== "paid") {
    return "Payment must be completed before an order can be delivered.";
  }

  return null;
}

module.exports = { getOrderStatusTransitionError };
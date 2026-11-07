/**
 * RDX Restaurant — shared Cloud Functions entrypoint
 */

"use strict";

const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const { createUserOrder } = require("./orders/createUserOrder");
const { createStaffOrder } = require("./orders/createStaffOrder");
const { validateCoupon } = require("./orders/validateCoupon");
const { getRewardWallet } = require("./rewards/getWallet");
const { settleOrder } = require("./orders/settleOrder");
const { updateOrderStatus } = require("./orders/updateOrderStatus");
const { getDashboardStats } = require("./dashboard/getDashboardStats");
const {
  bootstrapAdmin,
  listManagedUsers,
  setUserRole,
  updateManagedUser,
  createManagedUser,
  disableManagedUser,
} = require("./auth/managedUsers");
const { updateOrderFees } = require("./tax_and_fees/updateOrderFees");
const { manageInventory } = require("./inventory/manageInventory");
const {
  manageRestaurantSettings,
} = require("./settings/manageRestaurantSettings");

exports.createUserOrder = createUserOrder;
exports.createStaffOrder = createStaffOrder;
exports.validateCoupon = validateCoupon;
exports.getRewardWallet = getRewardWallet;
exports.getDashboardStats = getDashboardStats;
exports.settleOrder = settleOrder;
exports.updateOrderStatus = updateOrderStatus;
exports.bootstrapAdmin = bootstrapAdmin;
exports.listManagedUsers = listManagedUsers;
exports.setUserRole = setUserRole;
exports.updateManagedUser = updateManagedUser;
exports.createManagedUser = createManagedUser;
exports.disableManagedUser = disableManagedUser;
exports.updateOrderFees = updateOrderFees;
exports.manageInventory = manageInventory;
exports.manageRestaurantSettings = manageRestaurantSettings;

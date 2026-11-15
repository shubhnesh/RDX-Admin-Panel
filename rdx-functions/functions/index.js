/**
 * RDX Restaurant — shared Cloud Functions entrypoint
 */

"use strict";

const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const { createUserOrder } = require("./orders/createUserOrder");
const { cancelUserOrder } = require("./orders/cancelUserOrder");
const { getCartOfferProgress } = require("./orders/getCartOfferProgress");
const { manageUserAddress } = require("./users/manageUserAddress");
const { filterMenuItems } = require("./menu/filterMenuItems");
const { createStaffOrder } = require("./orders/createStaffOrder");
const { validateCoupon } = require("./orders/validateCoupon");
const { getRewardWallet } = require("./rewards/getWallet");
const { processOrderRewards } = require("./rewards/orderEvents");
const rewardAdmin = require("./rewards/admin");
const {
  getReferralOverview,
  applyReferralCode,
  completeReferralOpportunity,
  awardReferralOnHomeScreen,
  acknowledgeReferralRewardDialog,
  claimReferrerReferralRewardDialog,
  initializeReferralOpportunity,
} = require("./referrals/referrals");
const { settleOrder } = require("./orders/settleOrder");
const { updateOrderStatus } = require("./orders/updateOrderStatus");
const {
  getDashboardStats,
  getTopSellingProducts,
} = require("./dashboard/getDashboardStats");
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
const pushNotifications = require("./notifications/pushNotifications");
const businessNotificationEvents =
  require("./notifications/businessEvents");

exports.createUserOrder = createUserOrder;
exports.cancelUserOrder = cancelUserOrder;
exports.getCartOfferProgress = getCartOfferProgress;
exports.manageUserAddress = manageUserAddress;
exports.filterMenuItems = filterMenuItems;
exports.createStaffOrder = createStaffOrder;
exports.validateCoupon = validateCoupon;
exports.getRewardWallet = getRewardWallet;
exports.processOrderRewards = processOrderRewards;
exports.getRewardConfiguration = rewardAdmin.getRewardConfiguration;
exports.updateRewardConfiguration = rewardAdmin.updateRewardConfiguration;
exports.createFoodReward = rewardAdmin.createFoodReward;
exports.updateFoodReward = rewardAdmin.updateFoodReward;
exports.disableReward = rewardAdmin.disableReward;
exports.reconcileOrderRewards = rewardAdmin.reconcileOrderRewards;
exports.fetchRewardAnalytics = rewardAdmin.fetchRewardAnalytics;
exports.fetchRewardTransactions = rewardAdmin.fetchRewardTransactions;
exports.fetchReferralRecords = rewardAdmin.fetchReferralRecords;
exports.fetchRedemptionRecords = rewardAdmin.fetchRedemptionRecords;
exports.getReferralOverview = getReferralOverview;
exports.applyReferralCode = applyReferralCode;
exports.completeReferralOpportunity = completeReferralOpportunity;
exports.awardReferralOnHomeScreen = awardReferralOnHomeScreen;
exports.acknowledgeReferralRewardDialog = acknowledgeReferralRewardDialog;
exports.claimReferrerReferralRewardDialog =
  claimReferrerReferralRewardDialog;
exports.initializeReferralOpportunity = initializeReferralOpportunity;
exports.getDashboardStats = getDashboardStats;
exports.getTopSellingProducts = getTopSellingProducts;
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
exports.sendBroadcastNotification =
  pushNotifications.sendBroadcastNotification;
exports.processScheduledNotifications =
  pushNotifications.processScheduledNotifications;
exports.notifyMenuItemCreated =
  businessNotificationEvents.notifyMenuItemCreated;
exports.notifyMenuItemUpdated =
  businessNotificationEvents.notifyMenuItemUpdated;
exports.notifyCouponCreated =
  businessNotificationEvents.notifyCouponCreated;
exports.notifyCouponUpdated =
  businessNotificationEvents.notifyCouponUpdated;
exports.notifyOfferCreated =
  businessNotificationEvents.notifyOfferCreated;
exports.notifyOfferUpdated =
  businessNotificationEvents.notifyOfferUpdated;
exports.notifyAppOrderCreated =
  businessNotificationEvents.notifyAppOrderCreated;
exports.notifyAppOrderStatusChanged =
  businessNotificationEvents.notifyAppOrderStatusChanged;
exports.notifySupportRequestCreated =
  businessNotificationEvents.notifySupportRequestCreated;
exports.submitSupportRequest =
  businessNotificationEvents.submitSupportRequest;
exports.activateScheduledPromotions =
  businessNotificationEvents.activateScheduledPromotions;

/**
 * guards.js — Order callable access policy
 */
"use strict";

const { requireRestaurantUser } = require("../auth/roles");

module.exports = {
  assertCanOperateOrders: requireRestaurantUser,
};

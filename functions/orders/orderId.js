"use strict";

const crypto = require("crypto");

const ID_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
const ID_SUFFIX_LENGTH = 10;

/** IST is always UTC+5:30 (no DST). */
const IST_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;

/**
 * Calendar date parts in Asia/Kolkata without depending on ICU timezone data.
 * Uses a fixed UTC+5:30 offset so tests and production behave the same on
 * minimal Node builds that lack full Intl timezone support.
 */
function getIndiaDateParts(date) {
  const ist = new Date(date.getTime() + IST_OFFSET_MS);
  const year = String(ist.getUTCFullYear()).slice(-2);
  const month = String(ist.getUTCMonth() + 1).padStart(2, "0");
  const day = String(ist.getUTCDate()).padStart(2, "0");
  return { year, month, day };
}

function generateOrderId(date = new Date()) {
  const dateParts = getIndiaDateParts(date);

  let suffix = "";
  while (suffix.length < ID_SUFFIX_LENGTH) {
    for (const byte of crypto.randomBytes(16)) {
      if (byte >= 252) continue;
      suffix += ID_ALPHABET[byte % ID_ALPHABET.length];
      if (suffix.length === ID_SUFFIX_LENGTH) break;
    }
  }

  return `ORD-${dateParts.year}${dateParts.month}${dateParts.day}-${suffix}`;
}

module.exports = { generateOrderId, getIndiaDateParts };

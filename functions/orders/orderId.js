"use strict";

const crypto = require("crypto");

const ID_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
const ID_SUFFIX_LENGTH = 10;

function generateOrderId(date = new Date()) {
  const dateParts = Object.fromEntries(
    new Intl.DateTimeFormat("en-US", {
      timeZone: "Asia/Kolkata",
      year: "2-digit",
      month: "2-digit",
      day: "2-digit",
    })
      .formatToParts(date)
      .filter((part) => part.type !== "literal")
      .map((part) => [part.type, part.value])
  );

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

module.exports = { generateOrderId };

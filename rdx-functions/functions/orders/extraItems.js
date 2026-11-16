"use strict";

const REFERENCE_FIELDS = [
  "served_with",
  "servedWith",
  "served_with_ids",
  "servedWithIds",
  "extras",
  "extra_product_ids",
  "extraProductIds",
];

function normalize(value) {
  return String(value || "").toLowerCase().replace(/[^a-z0-9]/g, "");
}

function readReference(value) {
  if (value && typeof value === "object") {
    if (value.product && typeof value.product === "object") {
      return readReference(value.product);
    }
    return String(
      value.product_id ||
        value.productId ||
        value.item_id ||
        value.itemId ||
        value.id ||
        value.name ||
        value.product_name ||
        value.productName ||
        ""
    ).trim();
  }
  return String(value || "").trim();
}

function readReferences(source) {
  if (!source || typeof source !== "object") return [];
  for (const field of REFERENCE_FIELDS) {
    const value = source[field];
    if (Array.isArray(value) && value.length) {
      return value.map(readReference).filter(Boolean);
    }
  }
  return [];
}

function referencesMatch(references, product) {
  const productId = normalize(product && product.id);
  const productName = normalize(product && product.name);
  return references.some((reference) => {
    const normalizedReference = normalize(reference);
    return (
      normalizedReference &&
      (normalizedReference === productId ||
        normalizedReference === productName)
    );
  });
}

function getExtraScope({ baseProduct, extraProduct, category }) {
  const itemReferences = readReferences(baseProduct);
  if (itemReferences.length) {
    return referencesMatch(itemReferences, extraProduct) ? "item" : null;
  }

  const subcategoryId = String(
    baseProduct.sub_category_id ||
      baseProduct.subCategoryId ||
      ""
  ).trim();
  const subcategoryName = normalize(
    baseProduct.sub_category ||
      baseProduct.subCategory ||
      baseProduct.subcategory ||
      ""
  );
  const subcategories =
    category && Array.isArray(category.subcategories)
      ? category.subcategories
      : [];
  const subcategory = subcategories.find((candidate) => {
    const id = String(candidate.id || candidate.sub_category_id || "").trim();
    const name = normalize(candidate.name || candidate.sub_category || "");
    return (
      (subcategoryId && id === subcategoryId) ||
      (subcategoryName && name === subcategoryName)
    );
  });
  const subcategoryReferences = readReferences(subcategory);
  if (subcategoryReferences.length) {
    return referencesMatch(subcategoryReferences, extraProduct)
      ? "subcategory"
      : null;
  }

  const categoryReferences = readReferences(category);
  if (categoryReferences.length) {
    return referencesMatch(categoryReferences, extraProduct)
      ? "category"
      : null;
  }
  return null;
}

function isExtraProduct(product) {
  return !!(
    product &&
    (product.is_extra === true ||
      product.isExtra === true ||
      product.is_extra_item === true)
  );
}

module.exports = {
  getExtraScope,
  isExtraProduct,
};

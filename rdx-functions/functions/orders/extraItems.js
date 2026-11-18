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

function readSelection(value) {
  if (Array.isArray(value)) return value.flatMap(readSelection);
  if (value && typeof value === "object") {
    const selection = readReference(value);
    return selection ? [selection] : [];
  }
  return value == null ? [] : [String(value).trim()].filter(Boolean);
}

const SELECTION_FIELDS = {
  item: {
    mapping: [
      "items", "item", "item_id", "itemId", "item_ids", "itemIds",
      "selected_items", "selectedItems",
    ],
    root: [
      "served_with_item", "served_with_item_id", "served_with_item_ids",
      "served_with_items", "servedWithItemId", "servedWithItemIds",
      "servedWithItems",
    ],
  },
  subcategory: {
    mapping: [
      "subcategory", "sub_category", "sub_category_id", "subCategoryId",
      "subcategories", "sub_category_ids", "subCategoryIds",
      "selected_subcategories", "selectedSubcategories",
    ],
    root: [
      "served_with_subcategory", "served_with_subcategory_id",
      "served_with_sub_category_id", "served_with_subcategory_ids",
      "servedWithSubcategoryId", "servedWithSubcategoryIds",
    ],
  },
  category: {
    mapping: [
      "category", "category_id", "categoryId", "categories",
      "category_ids", "categoryIds", "selected_categories",
      "selectedCategories",
    ],
    root: [
      "served_with_category", "served_with_category_id",
      "served_with_category_ids", "servedWithCategoryId",
      "servedWithCategoryIds",
    ],
  },
};

function getSelection(product, scope) {
  const fields = SELECTION_FIELDS[scope];
  for (const field of fields.root) {
    if (Object.prototype.hasOwnProperty.call(product || {}, field)) {
      return readSelection(product[field]);
    }
  }
  const mapping = product && (product.served_with || product.servedWith);
  if (!mapping || typeof mapping !== "object" || Array.isArray(mapping)) {
    return [];
  }
  for (const field of fields.mapping) {
    if (Object.prototype.hasOwnProperty.call(mapping, field)) {
      return readSelection(mapping[field]);
    }
  }
  return [];
}

function selected(values) {
  return values.filter(
    (value) => value && value.trim().toLowerCase() !== "all"
  );
}

function selectionMatches(selection, values) {
  const normalizedSelection = new Set(selection.map(normalize));
  return values.some((value) => normalizedSelection.has(normalize(value)));
}

function hasConfiguredSelection(product) {
  return ["item", "subcategory", "category"].some(
    (scope) => selected(getSelection(product, scope)).length > 0
  );
}

function matchesSelectedContext(extraProduct, baseProduct) {
  const categories = selected(getSelection(extraProduct, "category"));
  const subcategories = selected(
    getSelection(extraProduct, "subcategory")
  );
  return (
    (!categories.length ||
      selectionMatches(categories, [
        baseProduct.primary_category_id,
        baseProduct.primaryCategoryId,
        baseProduct.category,
      ])) &&
    (!subcategories.length ||
      selectionMatches(subcategories, [
        baseProduct.sub_category_id,
        baseProduct.subCategoryId,
        baseProduct.sub_category,
        baseProduct.subCategory,
        baseProduct.subcategory,
      ]))
  );
}

function getConfiguredExtraScope(extraProduct, baseProduct) {
  const itemSelection = selected(getSelection(extraProduct, "item"));
  if (itemSelection.length) {
    return selectionMatches(itemSelection, [baseProduct.id, baseProduct.name]) &&
      matchesSelectedContext(extraProduct, baseProduct)
      ? "item"
      : null;
  }

  const subcategorySelection = selected(
    getSelection(extraProduct, "subcategory")
  );
  if (subcategorySelection.length) {
    return selectionMatches(subcategorySelection, [
      baseProduct.sub_category_id,
      baseProduct.subCategoryId,
      baseProduct.sub_category,
      baseProduct.subCategory,
      baseProduct.subcategory,
    ]) && matchesSelectedContext(extraProduct, baseProduct)
      ? "subcategory"
      : null;
  }

  const categorySelection = selected(getSelection(extraProduct, "category"));
  if (categorySelection.length) {
    return selectionMatches(categorySelection, [
      baseProduct.primary_category_id,
      baseProduct.primaryCategoryId,
      baseProduct.category,
    ])
      ? "category"
      : null;
  }
  return null;
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
  const configuredScope = getConfiguredExtraScope(extraProduct, baseProduct);
  if (configuredScope) return configuredScope;
  if (hasConfiguredSelection(extraProduct)) return null;

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
      product.is_extra_item === true ||
      hasConfiguredSelection(product))
  );
}

module.exports = {
  getExtraScope,
  isExtraProduct,
};

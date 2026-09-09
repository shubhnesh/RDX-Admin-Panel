import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_item_model.dart';
import '../models/coupon_model.dart';
import '../models/inventory_item_model.dart';
import '../models/order_model.dart';
import '../models/notification_model.dart';

/// Seeds development/sample data into Firestore.
///
/// Call this from Settings → Seed Sample Data.
///
/// The service is designed to be safely called multiple times.
/// Once the seed marker exists, it will not create duplicate data.
class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _seedDocument = 'initial_data_v1';

  Future<bool> isAlreadySeeded() async {
    final doc = await _db.collection('settings').doc('seed_status').get();

    return doc.exists && doc.data()?['seed_version'] == _seedDocument;
  }

  Future<void> seedAll() async {
    if (await isAlreadySeeded()) {
      return;
    }

    final batch = _db.batch();

    final now = DateTime.now();

    // ============================================================
    // MENU ITEMS
    // ============================================================

    final menuItems = [
      MenuItemModel(
        id: '',
        name: 'Spicy Tuna Roll',
        description:
            'Fresh tuna, spicy mayo, cucumber, wrapped in seasoned rice and nori.',
        primaryCategoryId: 'rolls',
        dietaryType: DietaryType.nonVeg,
        preparationStyle: PreparationStyle.other,
        price: 450,
        tags: ['spicy', 'popular'],
      ),
      MenuItemModel(
        id: '',
        name: 'Chicken Biryani',
        description: 'Aromatic basmati rice slow-cooked with spiced chicken.',
        primaryCategoryId: 'combos-thalis',
        dietaryType: DietaryType.nonVeg,
        preparationStyle: PreparationStyle.other,
        tags: ['popular'],
        price: 320,
      ),
      MenuItemModel(
        id: '',
        name: 'Paneer Tikka',
        description:
            'Char-grilled cottage cheese marinated in tandoori spices.',
        primaryCategoryId: 'veg-starters',
        dietaryType: DietaryType.veg,
        preparationStyle: PreparationStyle.tandoori,
        price: 280,
      ),
      MenuItemModel(
        id: '',
        name: 'Butter Naan',
        description: 'Soft leavened bread brushed with butter.',
        primaryCategoryId: 'combos-thalis',
        dietaryType: DietaryType.veg,
        preparationStyle: PreparationStyle.other,
        price: 75,
      ),
    ];

    for (final item in menuItems) {
      final ref = _db.collection('menu_items').doc();

      batch.set(
        ref,
        item.toJson(),
      );
    }

    // ============================================================
    // COUPONS
    // ============================================================

    final coupons = [
      CouponModel(
        id: '',
        code: 'RDX-WINTER25',
        description: 'Winter special discount',
        discountType: DiscountType.percentage,
        discountValue: 25,
        minOrderValue: 500,
        usageLimit: 200,
        usageCount: 0,

        // Updated so the sample coupon is actually usable.
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 12, 31),

        status: CouponStatus.active,
      ),
      CouponModel(
        id: '',
        code: 'WELCOME10',
        description: 'New user first order flat discount',
        discountType: DiscountType.flat,
        discountValue: 10,
        minOrderValue: 200,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        status: CouponStatus.active,
      ),
    ];

    for (final coupon in coupons) {
      final ref = _db.collection('coupons').doc();

      batch.set(
        ref,
        coupon.toJson(),
      );
    }

    // ============================================================
    // INVENTORY
    // ============================================================

   final inventory = [
  InventoryItemModel(
    id: '',
    name: 'A5 Wagyu Ribeye',
    category: 'Proteins & Meats',
    quantity: 4.2,
    minRequired: 8.0,
    maxCapacity: 25.0,
    unit: 'kg',
    unitCost: 42.50,
    lastUpdated: now,
  ),
  InventoryItemModel(
    id: '',
    name: 'Atlantic Salmon',
    category: 'Proteins & Meats',
    quantity: 8.5,
    minRequired: 15.0,
    maxCapacity: 40.0,
    unit: 'kg',
    unitCost: 24.00,
    lastUpdated: now,
  ),
  InventoryItemModel(
    id: '',
    name: 'Black Winter Truffles',
    category: 'Fresh Produce',
    quantity: 0.08, // 80 g
    minRequired: 0.20, // 200 g
    maxCapacity: 0.50, // 500 g
    unit: 'g',
    unitCost: 1.80,
    lastUpdated: now,
  ),
  InventoryItemModel(
    id: '',
    name: 'San Marzano Tomatoes',
    category: 'Dry Pantry',
    quantity: 32,
    minRequired: 15,
    maxCapacity: 50,
    unit: 'cans',
    unitCost: 3.20,
    lastUpdated: now,
  ),
  InventoryItemModel(
    id: '',
    name: 'Organic Mozzarella',
    category: 'Dairy & Cold',
    quantity: 18.0,
    minRequired: 5.0,
    maxCapacity: 20.0,
    unit: 'kg',
    unitCost: 12.50,
    lastUpdated: now,
  ),
  InventoryItemModel(
    id: '',
    name: 'Biodegradable Takeout Boxes',
    category: 'Packaging',
    quantity: 450,
    minRequired: 150,
    maxCapacity: 500,
    unit: 'pcs',
    unitCost: 0.45,
    lastUpdated: now,
  ),
  // Keep a couple of the original seed items for variety
  InventoryItemModel(
    id: '',
    name: 'Arborio Rice',
    category: 'Dry Pantry',
    quantity: 42,
    minRequired: 10,
    maxCapacity: 60,
    unit: 'kg',
    unitCost: 2.80,
    lastUpdated: now,
  ),
  InventoryItemModel(
    id: '',
    name: 'Extra Virgin Olive Oil',
    category: 'Dry Pantry',
    quantity: 18,
    minRequired: 5,
    maxCapacity: 30,
    unit: 'L',
    unitCost: 9.50,
    lastUpdated: now,
  ),
];

for (final item in inventory) {
  final ref = _db.collection('inventory').doc();
  batch.set(ref, item.toJson());
}


    // ============================================================
    // ORDERS
    // ============================================================

    final orders = [
      OrderModel(
        id: '',
        customerName: 'Alex Chen',
        customerPhone: '+91 98765 43210',
        deliveryAddress: '221B Baker Street, MG Road',
        status: OrderStatus.preparing,
        total: 845,
        createdAt: now.subtract(const Duration(minutes: 12)),
        items: [
          OrderItemModel(
            name: 'Spicy Tuna Roll',
            quantity: 2,
            price: 450,
          ),
          OrderItemModel(
            name: 'Miso Soup',
            quantity: 1,
            price: 120,
          ),
        ],
        deliveryLat: 28.6139,
        deliveryLng: 77.2090,
      ),
      OrderModel(
        id: '',
        customerName: 'Priya Sharma',
        customerPhone: '+91 91234 56789',
        deliveryAddress: 'Sector 18, Noida',
        status: OrderStatus.pending,
        total: 620,
        createdAt: now.subtract(const Duration(minutes: 4)),
        items: [
          OrderItemModel(
            name: 'Chicken Biryani',
            quantity: 1,
            price: 320,
          ),
          OrderItemModel(
            name: 'Butter Naan',
            quantity: 2,
            price: 150,
          ),
        ],
      ),
      OrderModel(
        id: '',
        customerName: 'Rohan Mehta',
        customerPhone: '+91 99887 66554',
        deliveryAddress: 'Andheri West, Mumbai',
        status: OrderStatus.ready,
        total: 1120,
        createdAt: now.subtract(const Duration(minutes: 28)),
        items: [
          OrderItemModel(
            name: 'Paneer Tikka',
            quantity: 2,
            price: 280,
          ),
          OrderItemModel(
            name: 'Dal Makhani',
            quantity: 1,
            price: 260,
          ),
        ],
      ),
    ];

    for (final order in orders) {
      final ref = _db.collection('orders').doc();

      batch.set(
        ref,
        order.toJson(),
      );
    }

    // ============================================================
    // NOTIFICATIONS
    // ============================================================

    final notifications = [
      NotificationModel(
        id: '',
        title: 'System Notification',
        message: 'Weekly Menu Rollout Alert',
        audience: NotificationAudience.allApp,
        createdAt: now.subtract(const Duration(days: 1)),
        scheduledAt: null,
        sentAt: now.subtract(const Duration(days: 1)),
        recipientCount: 0,
        scheduled: false,
      ),
    ];

    for (final notification in notifications) {
      final ref = _db.collection('notifications').doc();

      batch.set(
        ref,
        notification.toJson(),
      );
    }

    // ============================================================
    // RESTAURANT SETTINGS
    // ============================================================

    batch.set(
      _db.collection('settings').doc('restaurant'),
      {
        'restaurant_name': 'Uttarakhand Waffles',
        'description':
            'Best comfort waffles in town, freshly made every morning.',
        'address': '17 Winchester Road, Suite 4',
        'phone': '+91 98765 43210',
        'email': 'contact@uttarakhandwaffles.com',
        'auto_accept_orders': true,
        'require_manager_approval_for_refunds': true,
        'keep_pricing_consistent': false,
        'updated_at': FieldValue.serverTimestamp(),
      },
    );

    // ============================================================
    // SEED STATUS
    // ============================================================

    batch.set(
      _db.collection('settings').doc('seed_status'),
      {
        'seed_version': _seedDocument,
        'seeded_at': FieldValue.serverTimestamp(),
      },
    );

    // ============================================================
    // COMMIT
    // ============================================================

    await batch.commit();
  }
}

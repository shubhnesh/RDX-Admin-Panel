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
        price: 450,
        category: 'Rolls',
        subCategory: 'Signature Rolls',
        imageUrl: '',
        isVeg: false,
        majorIngredients: const [
          'Tuna',
          'Nori',
          'Sushi Rice',
          'Cucumber',
        ],
        selectedSize: ItemSize.medium,
        portionQuantities: const {
          ItemSize.small: '4 pcs',
          ItemSize.medium: '8 pcs',
          ItemSize.large: '12 pcs',
        },
        customizations: [
          MenuItemCustomizationGroup(
            id: 'c1',
            title: 'Portion Size',
            required: true,
            options: [
              MenuItemOption(
                id: 'o1',
                name: 'Regular',
                included: true,
              ),
              MenuItemOption(
                id: 'o2',
                name: 'Family Size (Serves 2)',
                extraPrice: 150,
              ),
            ],
          ),
        ],
      ),
      MenuItemModel(
        id: '',
        name: 'Chicken Biryani',
        description: 'Aromatic basmati rice slow-cooked with spiced chicken.',
        price: 320,
        category: 'Mains',
        subCategory: 'Biryani',
        imageUrl: '',
        isVeg: false,
        majorIngredients: const [
          'Basmati Rice',
          'Chicken',
          'Saffron',
        ],
        portionQuantities: const {
          ItemSize.small: '300 g',
          ItemSize.medium: '450 g',
          ItemSize.large: '650 g',
        },
      ),
      MenuItemModel(
        id: '',
        name: 'Paneer Tikka',
        description:
            'Char-grilled cottage cheese marinated in tandoori spices.',
        price: 280,
        category: 'Starters',
        subCategory: 'Tandoori',
        imageUrl: '',
        isVeg: true,
        majorIngredients: const [
          'Paneer',
          'Yogurt',
          'Tandoori Masala',
        ],
      ),
      MenuItemModel(
        id: '',
        name: 'Butter Naan',
        description: 'Soft leavened bread brushed with butter.',
        price: 75,
        category: 'Breads',
        subCategory: 'Naan',
        imageUrl: '',
        isVeg: true,
        majorIngredients: const [
          'Flour',
          'Butter',
        ],
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
        name: 'All Wagyu Beef Ribeye',
        quantity: 3,
        unit: 'kg',
        lowStockThreshold: 5,
        lastUpdated: now,
      ),
      InventoryItemModel(
        id: '',
        name: 'Black Winter Truffles',
        quantity: 0,
        unit: 'kg',
        lowStockThreshold: 1,
        lastUpdated: now,
      ),
      InventoryItemModel(
        id: '',
        name: 'Arborio Rice',
        quantity: 42,
        unit: 'kg',
        lowStockThreshold: 10,
        lastUpdated: now,
      ),
      InventoryItemModel(
        id: '',
        name: 'Extra Virgin Olive Oil',
        quantity: 18,
        unit: 'ltr',
        lowStockThreshold: 5,
        lastUpdated: now,
      ),
    ];

    for (final item in inventory) {
      final ref = _db.collection('inventory').doc();

      batch.set(
        ref,
        item.toJson(),
      );
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

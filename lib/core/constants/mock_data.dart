import '../../models/equipment_model.dart';
import '../../models/booking_model.dart';

class MockData {
  static List<EquipmentModel> getMockEquipment() {
    return [
      EquipmentModel(
        id: '1',
        title: 'Seaflo Single Kayak',
        description: 'Perfect single kayak for exploring the bay.  Stable and easy to paddle.  Includes life jacket and paddle.',
        category: EquipmentCategory.kayak,
        imageUrls: [
          'lib/assets/images/singlekayak.jpeg',
        ],
        pricePerHour:  35,
        location: 'Stanmore Bay Beach',
        latitude: -36.6215,
        longitude: 174.7042,
        rating: 4.9,
        reviewCount: 23,
        isVerified: true,
        ownerId: 'owner1',
        ownerName:  'Sarah Johnson',
        ownerImageUrl: 'https://i.pravatar.cc/150?img=1',
        createdAt: DateTime.parse('2024-08-01'),
        updatedAt: DateTime.parse('2024-08-10'),

      ),
      EquipmentModel(
        id: '2',
        title: 'Moana SUP Board',
        description: 'Your standard stand-up paddleboard, great for beginners. Comes with paddle, and leash.',
        category: EquipmentCategory.sup,
        imageUrls: [
          'lib/assets/images/PaddleBoard.webp',
        ],
        pricePerHour: 40,
        location: 'Orewa',
        latitude:  -36.5792,
        longitude: 174.6858,
        rating: 4.8,
        reviewCount: 15,
        isVerified: true,
        ownerId: 'owner2',
        ownerName: 'Mike Chen',
        ownerImageUrl:  'https://i.pravatar.cc/150?img=12',
        createdAt: DateTime.parse('2024-07-10'),
        updatedAt: DateTime.parse('2024-07-18'),
      ),
      EquipmentModel(
        id: '3',
        title: 'Tandem Kayak - Family Fun',
        description: 'Double kayak perfect for couples or parent + child. Very stable and comfortable.',
        category: EquipmentCategory.kayak,
        imageUrls: [
          'lib/assets/images/tandemkayak.webp',
        ],
        pricePerHour: 50,
        location: 'Stanmore Bay Beach',
        latitude: -36.6215,
        longitude: 174.7042,
        rating: 5.0,
        reviewCount: 31,
        isVerified: true,
        ownerId: 'owner1',
        ownerName: 'Sarah Johnson',
        ownerImageUrl: 'https://i.pravatar.cc/150?img=1',
        createdAt: DateTime.parse('2024-07-15'),
        updatedAt: DateTime.parse('2024-07-20'),
      ),
      EquipmentModel(
        id: '4',
        title:  'Beginner SUP Package',
        description: 'Wide and stable SUP board ideal for first-timers. Includes everything you need to get started! ',
        category: EquipmentCategory.sup,
        imageUrls: [
          'lib/assets/images/beginnersup.webp',
        ],
        pricePerHour: 38,
        location: 'Red Beach',
        latitude: -36.6098,
        longitude: 174.6968,
        rating: 4.7,
        reviewCount: 19,
        isVerified: false,
        ownerId: 'owner3',
        ownerName: 'Emma Wilson',
        ownerImageUrl: 'https://i.pravatar.cc/150? img=5',
        createdAt: DateTime.parse('2024-06-20'),
        updatedAt: DateTime.parse('2024-06-25'),
      ),
      EquipmentModel(
        id: '5',
        title: 'Sea-Doo Jet Ski',
        description: '2023 model, super fun and easy to ride! Perfect for thrill-seekers. Safety gear included.',
        category: EquipmentCategory.jetSki,
        imageUrls: [
          'lib/assets/images/jetski.jpg',
        ],
        pricePerHour: 120,
        location: 'Big Manly Beach',
        latitude: -36.5987,
        longitude: 174.6942,
        rating: 4.9,
        reviewCount: 42,
        isVerified: true,
        ownerId: 'owner4',
        ownerName: 'Jake Roberts',
        ownerImageUrl: 'https://i.pravatar.cc/150?img=8',
        createdAt: DateTime.parse('2024-05-10'),
        updatedAt: DateTime.parse('2024-05-15'),

      ),
      EquipmentModel(
        id: '6',
        title: 'Fishing Kayak with Gear',
        description: 'Stable fishing kayak with rod holders, anchor system, and storage. Perfect for a relaxing day on the water.',
        category: EquipmentCategory.kayak,
        imageUrls: [
          'lib/assets/images/fishingkayak.jpeg',
        ],
        pricePerHour: 45,
        location: 'Hatfields Beach',
        latitude:  -36.5642,
        longitude: 174.6758,
        rating: 4.6,
        reviewCount: 12,
        isVerified: false,
        ownerId: 'owner5',
        ownerName: 'Tom Anderson',
        ownerImageUrl: 'https://i.pravatar.cc/150? img=14',
        createdAt: DateTime.parse('2024-04-05'),
        updatedAt: DateTime.parse('2024-04-12'),
      ),
    ];
  }

  static List<Booking> getMockBookings() {
    final equipment = getMockEquipment();
    
    return [
      Booking(
        id: 'book1',
        equipment: equipment[0], // Ocean Kayak
        startDate: DateTime. now().add(const Duration(days: 2)),
        endDate: DateTime. now().add(const Duration(days: 2)),
        startTime: '09:00 AM',
        endTime: '02:00 PM',
        totalPrice: 175.00,
        status: BookingStatus.upcoming,
        deliveryOption: 'pickup',
        bookingReference: 'WS${DateTime.now().millisecondsSinceEpoch. toString().substring(7)}',
        bookingDate:  DateTime.now().subtract(const Duration(days: 3)),
      ),
      Booking(
        id: 'book2',
        equipment: equipment[1], // Red Paddle SUP
        startDate: DateTime. now().add(const Duration(days: 7)),
        endDate: DateTime. now().add(const Duration(days: 7)),
        startTime: '10:00 AM',
        endTime: '04:00 PM',
        totalPrice: 240.00,
        status: BookingStatus.upcoming,
        deliveryOption: 'delivery',
        deliveryAddress: '123 Beach Road, Orewa',
        bookingReference: 'WS${(DateTime.now().millisecondsSinceEpoch + 1000).toString().substring(7)}',
        bookingDate: DateTime. now().subtract(const Duration(days: 1)),
      ),
      Booking(
        id: 'book3',
        equipment: equipment[2], // Tandem Kayak
        startDate: DateTime. now().subtract(const Duration(days: 14)),
        endDate: DateTime. now().subtract(const Duration(days: 14)),
        startTime: '11:00 AM',
        endTime: '03:00 PM',
        totalPrice: 200.00,
        status: BookingStatus.completed,
        deliveryOption: 'pickup',
        bookingReference: 'WS${(DateTime.now().millisecondsSinceEpoch - 5000).toString().substring(7)}',
        bookingDate: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Booking(
        id: 'book4',
        equipment: equipment[3], // Beginner SUP
        startDate: DateTime. now().subtract(const Duration(days: 30)),
        endDate: DateTime. now().subtract(const Duration(days: 30)),
        startTime: '09:30 AM',
        endTime: '12:30 PM',
        totalPrice: 114.00,
        status: BookingStatus.completed,
        deliveryOption: 'pickup',
        bookingReference: 'WS${(DateTime.now().millisecondsSinceEpoch - 10000).toString().substring(7)}',
        bookingDate: DateTime.now().subtract(const Duration(days: 35)),
      ),
    ];
  }

  static List<EquipmentModel> getMockUserListings() {
    return getMockEquipment().where((e) => e.ownerId == 'owner1').toList();
  }
}
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/equipment_card.dart';
import '../../models/user_model.dart';
import '../../models/equipment_model.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/equipment_service.dart';
import '../../services/booking_service.dart';
import '../equipment/equipment_detail_screen.dart';
import '../list_equipment/list_equipment_screen.dart';
import '../booking/owner_bookings_screen.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import '../../services/notification_service.dart';
import '../notifications/notifications_screen.dart';
import 'user_reviews_screen.dart';
import '../../services/booking_status_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();
  final _userService = UserService();
  final _equipmentService = EquipmentService();
  final _bookingService = BookingService();

  UserModel? _currentUser;
  List<EquipmentModel> _userListings = [];
  List<Booking> _ownerBookings = [];
  List<Booking> _userBookings = [];
  bool _isLoading = true;
  bool _isLoadingListings = true;
  bool _isLoadingBookings = true;
  bool _bookingsStreamInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _loadUserListings();
    _loadUserBookings();
    _loadOwnerBookings();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userData = await _userService.getUserByUid(user.uid);
      if (mounted) {
        setState(() {
          _currentUser = userData;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserListings() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final listings = await _equipmentService.getEquipmentByOwner(user.uid);
        if (mounted) {
          setState(() {
            _userListings = listings;
            _isLoadingListings = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading listings: $e');
        if (mounted) {
          setState(() => _isLoadingListings = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingListings = false);
      }
    }
  }

  Future<void> _loadUserBookings() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        _bookingService.getRenterBookings(user.uid).listen((bookings) {
          if (mounted) {
            setState(() {
              _userBookings = bookings;
              _isLoadingBookings = false;
              _bookingsStreamInitialized = true;
            });
          }
        });

        // Safety timeout - stop loading after 2 seconds regardless
        await Future.delayed(const Duration(seconds: 2));
        if (mounted && !_bookingsStreamInitialized) {
          setState(() => _isLoadingBookings = false);
        }
      } catch (e) {
        debugPrint('Error loading bookings: $e');
        if (mounted) {
          setState(() => _isLoadingBookings = false);
        }
      }
    } else {
      setState(() => _isLoadingBookings = false);
    }
  }

  Future<void> _loadOwnerBookings() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        _bookingService.getOwnerBookings(user.uid).listen((bookings) {
          if (mounted) {
            setState(() {
              _ownerBookings = bookings;
            });
          }
        });
      } catch (e) {
        debugPrint('Error loading owner bookings: $e');
      }
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Not logged in'),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    final bookings = _userBookings;
    final upcomingBookings = bookings
        .where((b) =>
            b.status == BookingStatus.pending ||
            b.status == BookingStatus.confirmed)
        .toList();

    final activeBookings = bookings
        .where((b) => b.status == BookingStatus.active)
        .toList();

    final pastBookings = bookings
        .where((b) =>
            b.status == BookingStatus.completed ||
            b.status == BookingStatus.cancelled ||
            b.status == BookingStatus.declined ||
            b.status == BookingStatus.closed)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Profile Header
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar with Edit Button
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _currentUser!.profileImageUrl != null
                              ? NetworkImage(_currentUser!.profileImageUrl!)
                              : null,
                          child: _currentUser!.profileImageUrl == null
                              ? Icon(Icons.person,
                                  size: 50, color: Colors.grey[400])
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditProfileScreen(user: _currentUser!),
                                ),
                              );

                              if (result == true) {
                                _loadUserData();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Name
                    Text(
                      _currentUser!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Email
                    Text(
                      _currentUser!.email,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),

                    // Location (if set)
                    if (_currentUser!.location != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _currentUser!.location!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Rating
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserReviewsScreen(userId: _currentUser!.uid),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 18, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Text(
                              '${_currentUser!.displayRating} (${_currentUser!.reviewCount} reviews)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    // Bio (if set)
                    if (_currentUser!.bio != null &&
                        _currentUser!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _currentUser!.bio!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Quick Stats with Manage Bookings badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OwnerBookingsScreen(userId: '',),
                                ),
                              );
                              // Refresh data when returning
                              _loadOwnerBookings();
                            },
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _buildStatCard(
                                      Icons.calendar_today,
                                      // Show count of pending bookings
                                      _ownerBookings
                                          .where((b) => b.status == BookingStatus.pending)
                                          .length
                                          .toString(),
                                      'Requests',
                                      AppColors.primary,
                                    ),                                    
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            Icons.inventory_2_outlined,
                            _userListings.length.toString(),
                            'Listings',
                            AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // My Bookings Section
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Bookings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tabs
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: AppColors.primary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      tabs: [
                        Tab(text: 'Upcoming (${upcomingBookings.length})'),
                        Tab(text: 'Active (${activeBookings.length})'),
                        Tab(text: 'Past (${pastBookings.length})'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bookings List
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                constraints: const BoxConstraints(
                  minHeight: 200,
                  maxHeight: 500,
                ),
                child: _isLoadingBookings
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Upcoming Bookings
                          upcomingBookings.isEmpty
                              ? _buildEmptyState(Icons.calendar_today, 'No Upcoming Bookings', 'Your upcoming rentals will appear here')
                              : ListView.builder(
                                  padding: const EdgeInsets.only(
                                      top: 16, bottom: 16),
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: upcomingBookings.length,
                                  itemBuilder: (context, index) {
                                    return BookingCard(
                                        booking: upcomingBookings[index]);
                                  },
                                ),
                          
                          // NEW: Active Bookings
                          activeBookings.isEmpty
                              ? _buildEmptyState(
                                  Icons.play_circle_outline,
                                  'No Active Bookings',
                                  'Your active rentals will appear here',
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: activeBookings.length,
                                  itemBuilder: (context, index) {
                                    return BookingCard(booking: activeBookings[index]);
                                  },
                                ),

                          // Past Bookings
                          pastBookings.isEmpty
                              ? _buildEmptyState(
                                  Icons.history,
                                  'No Past Bookings',
                                  'Your rental history will appear here',
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(
                                      top: 16, bottom: 16),
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: pastBookings.length,
                                  itemBuilder: (context, index) {
                                    return BookingCard(
                                        booking: pastBookings[index]);
                                  },
                                ),
                        ],
                      ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // My Listings Section
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Listings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ListEquipmentScreen(),
                                ),
                              );

                              if (result == true) {
                                _loadUserListings();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isLoadingListings
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _userListings.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: _buildEmptyState(
                                  Icons.inventory_2_outlined,
                                  'No Listings Yet',
                                  'List your equipment to start earning',
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 250,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.only(right: 20),
                                      itemCount: _userListings.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          width: 180,
                                          margin:
                                              const EdgeInsets.only(right: 12),
                                          child: EquipmentCard(
                                            equipment: _userListings[index],
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EquipmentDetailScreen(
                                                    equipment:
                                                        _userListings[index],
                                                    equipmentId: '',
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (_userListings.length > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 12, right: 20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.swipe,
                                              size: 16,
                                              color: Colors.grey[400]),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Swipe to see more',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Settings Section
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildSettingItem(
                      Icons.person_outline,
                      'Account Settings',
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditProfileScreen(user: _currentUser!),
                          ),
                        );

                        if (result == true) {
                          _loadUserData();
                        }
                      },
                    ),
                    
                    _buildSettingItem(
                      Icons.calendar_today_outlined,
                      'Manage Bookings',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OwnerBookingsScreen(userId: '',),
                          ),
                        );
                      },
                    ),
                    
                    _buildNotificationSettingItem(context),
                    
                    _buildSettingItem(
                      Icons.payment_outlined,
                      'Payment Methods',
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Payment Methods coming soon!')),
                        );
                      },
                    ),
                    _buildSettingItem(
                      Icons.help_outline,
                      'Help & Support',
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Help & Support coming soon!')),
                        );
                      },
                    ),
                    _buildSettingItem(
                      Icons.description_outlined,
                      'Terms & Privacy',
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Terms & Privacy coming soon!')),
                        );
                      },
                    ),
                    _buildSettingItem(
                      Icons.logout,
                      'Logout',
                      () => _showLogoutDialog(context),
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color, {String? subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationSettingItem(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.notifications_outlined,
        color: Colors.grey[700],
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Notification Badge with error handling
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(_currentUser!.uid),
            builder: (context, snapshot) {
              // Show error if any
              if (snapshot.hasError) {
                debugPrint('Badge stream error: ${snapshot.error}');
                return Icon(Icons.error, color: Colors.red, size: 20);
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              
              final count = snapshot.data ?? 0;
              debugPrint('Unread count: $count');
              
              if (count == 0) return const SizedBox.shrink();
              
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationsScreen(userId: _currentUser!.uid),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isDestructive ? AppColors.error : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
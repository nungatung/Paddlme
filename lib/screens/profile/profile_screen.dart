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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Profile Header
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    
                    // Avatar with Edit Button
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: Colors.grey[100],
                            backgroundImage: _currentUser!.profileImageUrl != null
                                ? NetworkImage(_currentUser!.profileImageUrl!)
                                : null,
                            child: _currentUser!.profileImageUrl == null
                                ? Icon(Icons.person, size: 54, color: Colors.grey[400])
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfileScreen(user: _currentUser!),
                                ),
                              );
                              if (result == true) _loadUserData();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.edit, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Name
                    Text(
                      _currentUser!.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Email
                    Text(
                      _currentUser!.email,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Location
                    if (_currentUser!.location != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              _currentUser!.location!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent.withOpacity(0.15),
                              AppColors.accent.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star, size: 18, color: AppColors.accent),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_currentUser!.displayRating}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${_currentUser!.reviewCount} reviews)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),

                    // Bio
                    if (_currentUser!.bio != null && _currentUser!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          _currentUser!.bio!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Quick Stats
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OwnerBookingsScreen(userId: ''),
                                  ),
                                );
                                _loadOwnerBookings();
                              },
                              child: _buildStatCard(
                                Icons.calendar_today_rounded,
                                _ownerBookings
                                    .where((b) => b.status == BookingStatus.pending)
                                    .length
                                    .toString(),
                                'Requests',
                                AppColors.primary,
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
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // My Bookings Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'My Bookings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey[500],
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      tabs: [
                        Tab(text: 'Upcoming (${upcomingBookings.length})'),
                        Tab(text: 'Active (${activeBookings.length})'),
                        Tab(text: 'Past (${pastBookings.length})'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(minHeight: 200, maxHeight: 500),
                      child: _isLoadingBookings
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                upcomingBookings.isEmpty
                                    ? _buildEmptyState(Icons.calendar_today, 'No Upcoming Bookings', 'Your upcoming rentals will appear here')
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        shrinkWrap: true,
                                        physics: const ClampingScrollPhysics(),
                                        itemCount: upcomingBookings.length,
                                        itemBuilder: (context, index) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: BookingCard(booking: upcomingBookings[index]),
                                        ),
                                      ),
                                activeBookings.isEmpty
                                    ? _buildEmptyState(Icons.play_circle_outline, 'No Active Bookings', 'Your active rentals will appear here')
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        shrinkWrap: true,
                                        physics: const ClampingScrollPhysics(),
                                        itemCount: activeBookings.length,
                                        itemBuilder: (context, index) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: BookingCard(booking: activeBookings[index]),
                                        ),
                                      ),
                                pastBookings.isEmpty
                                    ? _buildEmptyState(Icons.history, 'No Past Bookings', 'Your rental history will appear here')
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        shrinkWrap: true,
                                        physics: const ClampingScrollPhysics(),
                                        itemCount: pastBookings.length,
                                        itemBuilder: (context, index) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: BookingCard(booking: pastBookings[index]),
                                        ),
                                      ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // My Listings Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.inventory_2_outlined, color: Colors.orange[700]),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'My Listings',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ListEquipmentScreen()),
                              );
                              if (result == true) _loadUserListings();
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoadingListings
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _userListings.isEmpty
                            ? _buildEmptyState(Icons.inventory_2_outlined, 'No Listings Yet', 'List your equipment to start earning')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 280,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      itemCount: _userListings.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          width: 200,
                                          margin: const EdgeInsets.only(right: 16),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.06),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: EquipmentCard(
                                              equipment: _userListings[index],
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => EquipmentDetailScreen(
                                                      equipment: _userListings[index],
                                                      equipmentId: '',
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (_userListings.length > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16, bottom: 20),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.swipe, size: 16, color: Colors.grey[400]),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Swipe to see more',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[500],
                                              fontWeight: FontWeight.w600,
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

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Settings Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingItem(Icons.person_outline, 'Account Settings', () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditProfileScreen(user: _currentUser!)),
                      );
                      if (result == true) _loadUserData();
                    }),
                    _buildDivider(),
                    _buildSettingItem(Icons.calendar_today_outlined, 'Manage Bookings', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OwnerBookingsScreen(userId: '')),
                      );
                    }),
                    _buildDivider(),
                    _buildNotificationSettingItem(context),
                    _buildDivider(),
                    _buildSettingItem(Icons.payment_outlined, 'Payment Methods', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment Methods coming soon!')),
                      );
                    }),
                    _buildDivider(),
                    _buildSettingItem(Icons.help_outline, 'Help & Support', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help & Support coming soon!')),
                      );
                    }),
                    _buildDivider(),
                    _buildSettingItem(Icons.description_outlined, 'Terms & Privacy', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms & Privacy coming soon!')),
                      );
                    }),
                    _buildDivider(),
                    _buildSettingItem(Icons.logout, 'Logout', () => _showLogoutDialog(context), isDestructive: true),
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

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey[200]);
  }

  Widget _buildNotificationSettingItem(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.notifications_outlined, color: Colors.blue[700], size: 22),
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(_currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const SizedBox.shrink();
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
              }
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              );
            },
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NotificationsScreen(userId: _currentUser!.uid)),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.error.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDestructive ? AppColors.error : Colors.grey[700], size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.error : Colors.black87,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
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
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
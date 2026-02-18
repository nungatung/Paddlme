import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';

class UserReviewsScreen extends StatelessWidget {
  final String userId;

  const UserReviewsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Reviews',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('reviewedId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reviews = snapshot.data?.docs ?? [];

          if (reviews.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index].data() as Map<String, dynamic>;
              return _ReviewCard(review: review);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star_outline, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          const Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reviews will appear here once received',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  Future<String> _getReviewerName() async {
    final storedName = review['reviewerName'] as String?;
    if (storedName != null && storedName.isNotEmpty) {
      return storedName;
    }
    
    final reviewerId = review['reviewerId'] as String?;
    if (reviewerId == null) return 'Anonymous';
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(reviewerId)
          .get();
      return doc.data()?['name'] ?? 'Anonymous';
    } catch (e) {
      return 'Anonymous';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] as num).toDouble();
    final comment = review['comment'] as String;
    final reviewerType = review['reviewerType'] as String;
    final timestamp = review['createdAt'] as Timestamp?;

    return FutureBuilder<String>(
      future: _getReviewerName(),
      builder: (context, snapshot) {
        final reviewerName = snapshot.data ?? 'Loading...';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar with gradient background
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (reviewerType == 'owner' ? Colors.blue : Colors.green).withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: reviewerType == 'owner' 
                            ? Colors.blue[50] 
                            : Colors.green[50],
                        child: Text(
                          reviewerName.isNotEmpty && reviewerName != 'Loading...' 
                              ? reviewerName[0].toUpperCase() 
                              : '?',
                          style: TextStyle(
                            color: reviewerType == 'owner' 
                                ? Colors.blue[700] 
                                : Colors.green[700],
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name and role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewerName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: reviewerType == 'owner' 
                                  ? Colors.blue[50] 
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              reviewerType == 'owner' ? 'Owner' : 'Renter',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: reviewerType == 'owner' 
                                    ? Colors.blue[700] 
                                    : Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Rating badge with gradient
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withOpacity(0.15),
                            AppColors.accent.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 18, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            '$rating',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stars display with better spacing
                Row(
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.accent,
                        size: 22,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Comment with quote styling
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    comment,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(timestamp.toDate()),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
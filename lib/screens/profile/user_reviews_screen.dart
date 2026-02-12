import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';

class UserReviewsScreen extends StatelessWidget {
  final String userId;

  const UserReviewsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
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
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  Future<String> _getReviewerName() async {
    // First check if name is stored in review
    final storedName = review['reviewerName'] as String?;
    if (storedName != null && storedName.isNotEmpty) {
      return storedName;
    }
    
    // Fallback: fetch from users collection
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
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar with initial
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: reviewerType == 'owner' 
                          ? Colors.blue[100] 
                          : Colors.green[100],
                      child: Text(
                        reviewerName.isNotEmpty && reviewerName != 'Loading...' 
                            ? reviewerName[0].toUpperCase() 
                            : '?',
                        style: TextStyle(
                          color: reviewerType == 'owner' 
                              ? Colors.blue[700] 
                              : Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            reviewerType == 'owner' ? 'Owner' : 'Renter',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Rating badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$rating',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stars display
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: AppColors.accent,
                      size: 18,
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _formatDate(timestamp.toDate()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
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
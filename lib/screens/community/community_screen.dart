import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:women_safety/providers/user_provider.dart';
import 'package:women_safety/services/community_service.dart';
import 'package:women_safety/theme/app_theme.dart';
import 'package:women_safety/models/user_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _postController = TextEditingController();
  List<UserModel> _nearbyUsers = [];
  bool _isLoadingNearby = true;

  @override
  void initState() {
    super.initState();
    _fetchNearby();
  }

  Future<void> _fetchNearby() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      final users = await _communityService.getNearbyUsers(
        pos,
        5.0,
      ); // 5km radius
      if (mounted) {
        setState(() {
          _nearbyUsers = users;
          _isLoadingNearby = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingNearby = false);
    }
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safety Update'),
        content: TextField(
          controller: _postController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Share a safety tip or incident report...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = Provider.of<UserProvider>(
                context,
                listen: false,
              ).currentUser;
              final content = _postController.text.trim();
              if (user != null && content.isNotEmpty) {
                try {
                  await _communityService.createPost(
                    userId: user.uid,
                    userName: user.name,
                    content: content,
                  );
                  _postController.clear();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Post shared!'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to share post: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _broadcastSOS() async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      Position pos = await Geolocator.getCurrentPosition();
      await _communityService.broadcastCommunitySOS(
        userId: user.uid,
        userName: user.name,
        message: '🚨 COMMUNITY ALERT: ${user.name} needs help nearby!',
        position: pos,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS Broadcasted to nearby users!'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to broadcast SOS: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Community Safety Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency_share_rounded, color: Colors.red),
            onPressed: _broadcastSOS,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Nearby Users
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'NEARBY MEMBERS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoadingNearby)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: _nearbyUsers.isEmpty && !_isLoadingNearby
                  ? const Center(
                      child: Text(
                        'No other members nearby',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _nearbyUsers.length,
                      itemBuilder: (context, index) =>
                          _nearbyAvatar(_nearbyUsers[index]),
                    ),
            ),

            const SizedBox(height: 24),
            // Safety Posts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'COMMUNITY UPDATES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showCreatePostDialog,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Post', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _communityService.getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _emptyPosts();
                }

                final posts = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: posts.length,
                  itemBuilder: (context, index) => _postCard(posts[index]),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _nearbyAvatar(UserModel user) {
    return FadeInRight(
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: user.role == 'guardian'
                  ? Colors.green.shade50
                  : Colors.blue.shade50,
              child: Text(
                user.name.isNotEmpty
                    ? user.name.trim()[0].toUpperCase()
                    : (user.role == 'guardian' ? 'G' : 'U'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: user.role == 'guardian'
                      ? Colors.green.shade700
                      : AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _postCard(Map<String, dynamic> post) {
    final DateTime? timestamp = (post['timestamp'] as Timestamp?)?.toDate();
    final String timeStr = timestamp != null
        ? DateFormat('hh:mm a').format(timestamp)
        : 'Just now';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                child: const Icon(Icons.person, size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                post['userName'] ?? 'Anonymous',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post['content'] ?? '',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _communityService.likePost(post['id']),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post['likes'] ?? 0}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              const Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyPosts() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.forum_outlined, size: 60, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Text(
            'No safety posts yet',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

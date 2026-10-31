import 'package:flutter/material.dart';
import 'package:women_safety/theme/app_theme.dart';

class CircleScreen extends StatelessWidget {
  const CircleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Safety Circle',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Safety Tips'),
              Tab(text: 'Community'),
            ],
            indicatorColor: AppTheme.primaryBlue,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: const TabBarView(
          children: [SafetyTipsList(), CommunityChatPlaceholder()],
        ),
      ),
    );
  }
}

class SafetyTipsList extends StatelessWidget {
  const SafetyTipsList({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = [
      {
        'title': 'Travel safety',
        'desc': 'Always share your ride details with a trusted contact.',
        'icon': Icons.directions_car_rounded,
      },
      {
        'title': 'Social Awareness',
        'desc': 'Keep your phone charged and stay aware of your surroundings.',
        'icon': Icons.remove_red_eye_rounded,
      },
      {
        'title': 'Emergency SOS',
        'desc': 'Learn how to trigger SOS quickly on your phone.',
        'icon': Icons.emergency_rounded,
      },
      {
        'title': 'Safe Zones',
        'desc':
            'Identify safe locations like police stations or hospitals on your route.',
        'icon': Icons.verified_user_rounded,
      },
      {
        'title': 'Trust your Gut',
        'desc':
            'If a situation feels wrong, leave immediately or call for help.',
        'icon': Icons.psychology_rounded,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        final tip = tips[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundBlue.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                tip['icon'] as IconData,
                color: AppTheme.primaryBlue,
                size: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip['desc'] as String,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CommunityChatPlaceholder extends StatelessWidget {
  const CommunityChatPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Safety Community Chat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect with other users in your area.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Join Discussion',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';

class DashboardOverviewView extends StatelessWidget {
  const DashboardOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ).animate().fade().slideY(begin: 0.1),
          const SizedBox(height: 8),
          const Text(
            'Here is a quick summary of your app\'s content.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ).animate().fade().slideY(begin: 0.1),
          const SizedBox(height: 24),
          
          // Use a GridView for metrics
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMetricCard(
                title: 'Wallpapers',
                icon: Icons.image,
                color: Colors.blueAccent,
                query: FirebaseFirestore.instance.collection('wallpapers'),
                delayMs: 0,
              ),
              _buildMetricCard(
                title: 'Categories',
                icon: Icons.category,
                color: Colors.greenAccent,
                query: FirebaseFirestore.instance.collection('categories'),
                delayMs: 100,
              ),
              _buildMetricCard(
                title: 'Drafts',
                icon: Icons.drafts,
                color: Colors.orangeAccent,
                query: FirebaseFirestore.instance.collection('wallpapers').where('status', isEqualTo: 'draft'),
                delayMs: 200,
              ),
              _buildMetricCard(
                title: 'Featured',
                icon: Icons.star,
                color: Colors.amber,
                query: FirebaseFirestore.instance.collection('wallpapers').where('featured', isEqualTo: true),
                delayMs: 300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required Color color,
    required Query query,
    required int delayMs,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 12),
          FutureBuilder<AggregateQuerySnapshot>(
            future: query.count().get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(strokeWidth: 2);
              }
              if (snapshot.hasError) {
                return const Text('Error', style: TextStyle(color: Colors.red));
              }
              final count = snapshot.data?.count ?? 0;
              return Text(
                count.toString(),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    ).animate().fade(delay: delayMs.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import 'views/upload_view.dart';
import 'views/manage_categories_view.dart';
import 'views/manage_wallpapers_view.dart';
import 'views/dashboard_overview_view.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.surface,
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.cloud_upload), text: 'Upload'),
              Tab(icon: Icon(Icons.category), text: 'Categories'),
              Tab(icon: Icon(Icons.image), text: 'Manage'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DashboardOverviewView(),
            UploadView(),
            ManageCategoriesView(),
            ManageWallpapersView(),
          ],
        ),
      ),
    );
  }
}


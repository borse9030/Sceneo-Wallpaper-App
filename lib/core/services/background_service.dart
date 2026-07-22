import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:dio/dio.dart';
import 'package:sceneo/firebase_options.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == "dailyWallpaperTask") {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        
        // Fetch featured wallpapers
        final snapshot = await FirebaseFirestore.instance
            .collection('wallpapers')
            .where('featured', isEqualTo: true)
            .get();
            
        if (snapshot.docs.isEmpty) return Future.value(true);
        
        final docs = snapshot.docs;
        final randomDoc = docs[Random().nextInt(docs.length)];
        final data = randomDoc.data();
        
        final url = data['imageUrl'] as String;
        
        // Download image to temp dir
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/daily_wallpaper.jpg';
        
        await Dio().download(url, filePath);
        
        await AsyncWallpaper.setWallpaper(
          WallpaperRequest(
            target: WallpaperTarget.home,
            sourceType: WallpaperSourceType.file,
            source: filePath,
            goToHome: false,
          ),
        );
      }
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) print("Background task failed: $e");
      return Future.value(false);
    }
  });
}

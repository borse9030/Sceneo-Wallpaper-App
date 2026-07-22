import '../models/wallpaper_model.dart';

class MockData {
  static final List<WallpaperModel> wallpapers = [
    WallpaperModel(
      id: '1',
      title: 'Neon Cyberpunk',
      imageUrl: 'https://images.unsplash.com/photo-1542831371-29b0f74f9713?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=1080',
      thumbnailUrl: 'https://images.unsplash.com/photo-1542831371-29b0f74f9713?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=400',
      category: 'Cyberpunk',
      tags: ['neon', 'dark', 'city'],
      resolution: '4K',
      featured: true,
      trending: true,
      createdAt: DateTime.now(),
      dominantColor: '#FF0055',
    ),
    WallpaperModel(
      id: '2',
      title: 'Minimalist Mountain',
      imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=1080',
      thumbnailUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=400',
      category: 'Minimal',
      tags: ['mountains', 'dark', 'nature'],
      resolution: '4K',
      featured: true,
      createdAt: DateTime.now(),
      dominantColor: '#2C3E50',
    ),
    WallpaperModel(
      id: '3',
      title: 'Dark Forest',
      imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=1080',
      thumbnailUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=400',
      category: 'Nature',
      tags: ['forest', 'dark', 'trees'],
      resolution: '1440p',
      trending: true,
      createdAt: DateTime.now(),
      dominantColor: '#1A252C',
    ),
    WallpaperModel(
      id: '4',
      title: 'Abstract Fluid',
      imageUrl: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=1080',
      thumbnailUrl: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=400',
      category: 'Abstract',
      tags: ['fluid', 'colorful', 'abstract'],
      resolution: '4K',
      featured: true,
      createdAt: DateTime.now(),
      dominantColor: '#5C2D91',
    ),
  ];
  
  static final List<String> categories = [
    'AMOLED', 'Nature', 'Cars', 'Supercars', 'Bikes', 'Space', 'Minimal',
    'Abstract', 'Mountains', 'Forests', 'Animals', 'Technology', 'Cyberpunk',
    'Gaming', 'Anime', 'Architecture', 'Fantasy', 'Rain', 'Sunset', 'Neon', 'Dark'
  ];
}

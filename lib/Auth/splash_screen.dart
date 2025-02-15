import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart'; // Import video player package
import '../Screens/main_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize video controller
    _videoController = VideoPlayerController.asset('assets/images/0_MAIN_COMP.mp4')
      ..setLooping(false)
      ..setPlaybackSpeed(2.5) // Speed up video playback
      ..initialize().then((_) {
        setState(() {}); // Ensure the first frame is shown
        _videoController.play();
      });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    Future.delayed(const Duration(seconds: 6), () {
      _checkLoginStatus();
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('login_status') ?? false;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserAppLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
  backgroundColor: Colors.white,
  body: Center(
    child: _videoController.value.isInitialized
        ? AspectRatio(
            aspectRatio: _videoController.value.aspectRatio,
            child: VideoPlayer(_videoController),
          )
        : Container(), // Placeholder while the video initializes
  ),
);
  }
}
// lib/presentation/screens/aod_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AodScreen extends StatefulWidget {
  final List<XFile> images;
  final Duration updateFrequency;

  const AodScreen({
    super.key,
    required this.images,
    required this.updateFrequency,
  });

  @override
  State<AodScreen> createState() => _AodScreenState();
}

class _AodScreenState extends State<AodScreen> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    if (widget.images.isNotEmpty) {
      _timer = Timer.periodic(widget.updateFrequency, (timer) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.images.length;
        });
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _timer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  // --- MODIFIED BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // We replace the Scaffold with a Material widget.
    // Material provides a basic canvas for our app, but crucially,
    // it does NOT add any Safe Area padding.
    return Material(
      color: Colors.black, // Set the background color here
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        // The body of our screen remains the same
        child: Center(
          child: widget.images.isEmpty
              ? const Text(
                  'No images selected.',
                  style: TextStyle(color: Colors.white),
                )
              : AnimatedSwitcher(
                  duration: const Duration(seconds: 2),
                  child: Image.file(
                    key: ValueKey<String>(widget.images[_currentIndex].path),
                    File(widget.images[_currentIndex].path),
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                  ),
                ),
        ),
      ),
    );
  }
}
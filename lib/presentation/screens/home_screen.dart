// lib/presentation/screens/home_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEW: Import shared_preferences

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.artfulaod.service');

  bool _isAodServiceEnabled = false;
  int _selectedImageCount = 0;
  double _updateFrequencyInMinutes = 5;
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    // NEW: Load saved settings when the app starts
    _loadSettings();
  }

  // --- NEW: Method to save all current settings to the device ---
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aod_enabled', _isAodServiceEnabled);
    await prefs.setDouble('update_frequency', _updateFrequencyInMinutes);
    // We store the list of image paths as a List<String>
    final imagePaths = _selectedImages.map((file) => file.path).toList();
    await prefs.setStringList('image_paths', imagePaths);
    print('Settings Saved!');
  }

  // --- NEW: Method to load settings from the device ---
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAodServiceEnabled = prefs.getBool('aod_enabled') ?? false;
      _updateFrequencyInMinutes = prefs.getDouble('update_frequency') ?? 5.0;
      final imagePaths = prefs.getStringList('image_paths') ?? [];
      _selectedImages = imagePaths.map((path) => XFile(path)).toList();
      _selectedImageCount = _selectedImages.length;
    });
    print('Settings Loaded!');
  }

  // --- MODIFIED: This now saves state and passes data to the service ---
  // In home_screen.dart

  Future<void> _onToggleAodService(bool newValue) async {
    setState(() {
      _isAodServiceEnabled = newValue;
    });
    await _saveSettings();

    if (_isAodServiceEnabled) {
      // 1. Check for Draw Over Apps permission
      var alertStatus = await Permission.systemAlertWindow.request();
      if (!alertStatus.isGranted) {
        print("Draw over other apps permission denied.");
        setState(() {
          _isAodServiceEnabled = false;
        });
        return;
      }

      // NEW: 2. Check for Notification permission (required for Foreground Service)
      var notificationStatus = await Permission.notification.request();
      if (!notificationStatus.isGranted) {
        print("Notification permission denied.");
        setState(() {
          _isAodServiceEnabled = false;
        });
        return;
      }

      // 3. Start the service
      try {
        final Map<String, dynamic> settings = {
          'imagePaths': _selectedImages.map((f) => f.path).toList(),
          'frequency': _updateFrequencyInMinutes.toInt(),
        };
        final String result =
            await platform.invokeMethod('startService', settings);
        print(result);
      } on PlatformException catch (e) {
        print("Failed to start service: '${e.message}'.");
      }
    } else {
      try {
        final String result = await platform.invokeMethod('stopService');
        print(result);
      } on PlatformException catch (e) {
        print("Failed to stop service: '${e.message}'.");
      }
    }
  }

  // --- MODIFIED: This now saves state after picking images ---
  Future<void> _pickImages() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      return;
    }

    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.image);

    if (result != null) {
      final List<XFile> newImages = result.paths
          .where((path) => path != null)
          .map((path) => XFile(path!))
          .toList();
      setState(() {
        _selectedImages = newImages;
        _selectedImageCount = newImages.length;
      });
      // NEW: Save settings every time the images change
      await _saveSettings();
    }
  }

  // --- (The rest of the file is UI and remains the same) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Artful AOD',
            style: GoogleFonts.lato(
                fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildServiceToggleCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('Configuration'),
          const SizedBox(height: 12),
          _buildConfigurationCard(),
        ],
      ),
    );
  }

  Widget _buildServiceToggleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Enable AOD Service',
              style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500)),
          Switch(
            value: _isAodServiceEnabled,
            onChanged: _onToggleAodService,
            activeColor: Colors.deepPurpleAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.lato(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2),
    );
  }

  Widget _buildConfigurationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildConfigRow(
            icon: Icons.photo_library_outlined,
            title: 'Select Wallpapers',
            subtitle: _selectedImageCount == 0
                ? 'No images selected'
                : '$_selectedImageCount images selected',
            onTap: _pickImages,
          ),
          const Divider(color: Colors.grey),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change Frequency',
                    style: GoogleFonts.lato(color: Colors.white, fontSize: 16)),
                Text('${_updateFrequencyInMinutes.toInt()} minutes',
                    style: GoogleFonts.lato(
                        color: Colors.grey.shade400, fontSize: 14)),
                Slider(
                  value: _updateFrequencyInMinutes,
                  min: 1,
                  max: 60,
                  divisions: 59,
                  label: _updateFrequencyInMinutes.round().toString(),
                  activeColor: Colors.deepPurpleAccent,
                  inactiveColor: Colors.grey.shade700,
                  onChanged: (double value) {
                    setState(() {
                      _updateFrequencyInMinutes = value;
                    });
                  },
                  // NEW: Save settings when the user stops sliding
                  onChangeEnd: (double value) {
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurpleAccent),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.lato(color: Colors.white, fontSize: 16)),
                Text(subtitle,
                    style: GoogleFonts.lato(
                        color: Colors.grey.shade400, fontSize: 14)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

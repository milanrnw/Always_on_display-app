import 'dart:io';
import 'dart:convert'; // Make sure this import is here
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.artfulaod.settings');

  int _selectedImageCount = 0;
  double _updateFrequencyInMinutes = 5;
  List<XFile> _selectedImages = [];
  bool _isServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkServiceStatus());
    _loadSettings();
  }

  Future<void> _checkServiceStatus() async {
    try {
      final bool isEnabled =
          await platform.invokeMethod('isAccessibilityServiceEnabled');
      if (mounted) {
        setState(() {
          _isServiceEnabled = isEnabled;
        });
      }
    } on PlatformException catch (e) {
      print("Failed to check service status: '${e.message}'.");
    }
  }

  Future<void> _saveSettings(
      {String? imageData, List<String>? imagePaths}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'update_frequency', _updateFrequencyInMinutes.toString());

    if (imageData != null) {
      await prefs.setString('image_data_base64', imageData);
      await prefs.remove('image_paths');
      print('Settings Saved with SINGLE IMAGE DATA!');
    } else if (imagePaths != null) {
      await prefs.setStringList('image_paths', imagePaths);
      await prefs.remove('image_data_base64');
      print('Settings Saved with MULTIPLE IMAGE PATHS!');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // For this test, we don't need to load the image data back into the UI,
    // just the paths for the counter.
    final imagePaths = prefs.getStringList('image_paths') ?? [];
    setState(() {
      _updateFrequencyInMinutes =
          double.parse(prefs.getString('update_frequency') ?? '5.0');
      _selectedImages = imagePaths.map((path) => XFile(path)).toList();
      _selectedImageCount = _selectedImages.length;
    });
    print('Settings Loaded!');
  }

  Future<void> _requestPermissionsAndPickImages() async {
    await Permission.manageExternalStorage.request();
    final imageStatus = await Permission.photos.request();
    if (!imageStatus.isGranted) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result != null && result.paths.isNotEmpty) {
      final String? firstImagePath = result.paths.first;
      if (firstImagePath == null) return;

      final imageBytes = await File(firstImagePath).readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      await _saveSettings(imageData: base64Image);

      setState(() {
        _selectedImages =
            result.paths.where((p) => p != null).map((p) => XFile(p!)).toList();
        _selectedImageCount = _selectedImages.length;
      });
    }
  }

  // --- UNMODIFIED CODE BELOW (EXCEPT FOR THE ONE LINE FIX) ---

  Future<void> _openAccessibilitySettings() async {
    try {
      await platform.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      print("Failed to open accessibility settings: '${e.message}'.");
    }
  }

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
          _buildActivationCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('Configuration'),
          const SizedBox(height: 12),
          _buildConfigurationCard(),
        ],
      ),
    );
  }

  Widget _buildActivationCard() {
    return Card(
      color: _isServiceEnabled
          ? const Color(0xFF1E1E1E)
          : Colors.red[900]?.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AOD Service',
                style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                _isServiceEnabled
                    ? 'The Artful AOD service is active and will show when you lock your screen.'
                    : 'To use Artful AOD, you must enable its Accessibility Service in system settings. This allows the app to know when your screen is locked.',
                style: GoogleFonts.lato(color: Colors.grey.shade300)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openAccessibilitySettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isServiceEnabled
                    ? Colors.grey[700]
                    : Colors.deepPurpleAccent,
              ),
              child: Text(
                  _isServiceEnabled ? 'Disable in Settings' : 'Enable Service'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton.icon(
                onPressed: _checkServiceStatus,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Refresh Status"),
              ),
            )
          ],
        ),
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

  // --- THIS IS THE ONLY WIDGET YOU NEED TO REPLACE ---
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
            onTap: _requestPermissionsAndPickImages,
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
                  // --- THE FINAL FIX IS HERE ---
                  // This now ONLY saves the frequency, it cannot erase the image data.
                  onChangeEnd: (double value) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('update_frequency', value.toString());
                    print('Frequency Updated!');
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

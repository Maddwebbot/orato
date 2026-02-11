import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Available TTS languages - must match dropdown options
const Map<String, String> availableLanguages = {
  'en-US': 'English (US)',
  'en-GB': 'English (UK)',
  'de': 'German',
  'fr': 'French',
  'es': 'Spanish',
  'it': 'Italian',
  'pt-BR': 'Portuguese (Brazil)',
  'ja': 'Japanese',
  'ko': 'Korean',
  'zh-CN': 'Chinese (Simplified)',
};

void main() {
  runApp(const OratoApp());
}

class OratoApp extends StatelessWidget {
  const OratoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orato',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 4,
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 8,
        ),
      ),
      home: const QRScannerPage(),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final FlutterTts _flutterTts = FlutterTts();

  final List<String> _scanHistory = [];
  final List<String> _ttsQueue = [];
  String _currentSpeaking = '';
  bool _isSpeaking = false;

  // TTS Settings
  double _volume = 1.0;
  double _pitch = 1.0;
  double _speechRate = 0.75; // More natural speech rate (0.75-0.95 recommended)
  String _language = "en-US";
  bool _addNaturalPauses = true; // Add pauses for natural speech

  @override
  void initState() {
    super.initState();
    // Validate language is in available options
    if (!availableLanguages.containsKey(_language)) {
      _language = 'en-US'; // Fallback to English (US)
    }
    _initializeTTS();
  }

  void _initializeTTS() {
    _flutterTts.setLanguage(_language);
    _flutterTts.setPitch(_pitch);
    _flutterTts.setSpeechRate(_speechRate);
    _flutterTts.setVolume(_volume);

    // Set higher quality speech synthesis (offline, device-native)
    _flutterTts.awaitSpeakCompletion(true);

    _flutterTts.setCompletionHandler(() {
      _processQueue();
    });

    _flutterTts.setErrorHandler((message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Language "$_language" not available on device. Try another language.',
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange.shade600,
        ),
      );
    });
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final String code = barcode.rawValue?.trim() ?? '';
      if (code.isEmpty) continue;

      final ttsText = "Scanned: $code";

      if (!_scanHistory.contains(code) &&
          !_ttsQueue.contains(ttsText) &&
          _currentSpeaking != ttsText) {
        setState(() {
          _scanHistory.add(code);
          _ttsQueue.add(ttsText);
        });

        if (!_isSpeaking) _processQueue();
      }
    }
  }

  void _processQueue() async {
    if (_ttsQueue.isEmpty) {
      setState(() {
        _isSpeaking = false;
        _currentSpeaking = '';
      });
      return;
    }

    setState(() {
      _isSpeaking = true;
      _currentSpeaking = _ttsQueue.removeAt(0);
    });

    // Process text for natural pauses if enabled
    final textToSpeak = _addNaturalPauses
        ? _processTextForExpression(_currentSpeaking)
        : _currentSpeaking;

    await _flutterTts.speak(textToSpeak);
  }

  // Add natural pauses and emphasis to text
  String _processTextForExpression(String text) {
    // Add slight pauses at sentence endings for more natural speech
    text = text.replaceAll(RegExp(r'([.!?])'), r'$1 ');
    // Ensure proper spacing around commas
    text = text.replaceAll(RegExp(r','), ', ');
    return text.trim();
  }

  void _addToQueue(String text) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty &&
        !_ttsQueue.contains(trimmed) &&
        _currentSpeaking != trimmed) {
      setState(() {
        _ttsQueue.add(trimmed);
      });
      if (!_isSpeaking) _processQueue();
    }
  }

  void _showTextInputDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Add Text to Read',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6366F1),
            fontSize: 18,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter text that you want the app to read aloud',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type or paste text here...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            onPressed: () {
              _addToQueue(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Add to Queue', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsPanel(
        volume: _volume,
        pitch: _pitch,
        speechRate: _speechRate,
        language: _language,
        addNaturalPauses: _addNaturalPauses,
        onVolumeChanged: (v) {
          setState(() => _volume = v);
          _flutterTts.setVolume(v);
        },
        onPitchChanged: (v) {
          setState(() => _pitch = v);
          _flutterTts.setPitch(v);
        },
        onSpeechRateChanged: (v) {
          setState(() => _speechRate = v);
          _flutterTts.setSpeechRate(v);
        },
        onAddNaturalPausesChanged: (v) {
          setState(() => _addNaturalPauses = v);
        },
        onLanguageChanged: (lang) {
          _setLanguage(lang);
        },
      ),
    );
  }

  void _setLanguage(String lang) {
    // Validate language before setting
    if (!availableLanguages.containsKey(lang)) {
      lang = 'en-US'; // Fallback to English (US)
    }

    setState(() => _language = lang);
    _flutterTts
        .setLanguage(lang)
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language changed to ${availableLanguages[lang]}'),
              duration: const Duration(seconds: 1),
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Language "${availableLanguages[lang]}" is not supported on this device',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red.shade600,
            ),
          );
          setState(() => _language = 'en-US');
          _flutterTts.setLanguage('en-US');
        });
  }

  void _showOfflineInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_off, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('Offline Mode'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This app works completely offline without internet.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildOfflineFeature(
                '📱 QR Code Scanning',
                'Camera-based, no upload',
              ),
              const SizedBox(height: 12),
              _buildOfflineFeature('🔊 Text-to-Speech', 'Device native engine'),
              const SizedBox(height: 12),
              _buildOfflineFeature(
                '💾 History Storage',
                'All data stored locally',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Zero internet dependency',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineFeature(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _showHistoryPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HistoryPanel(
        history: _scanHistory,
        onDelete: (item) {
          setState(() => _scanHistory.remove(item));
        },
        onClear: () {
          setState(() => _scanHistory.clear());
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orato'),
        centerTitle: true,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Tooltip(
              message: 'Works offline - no internet required',
              child: Icon(Icons.cloud_off, size: 20),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isSpeaking ? 'Speaking...' : 'Ready',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showOfflineInfo,
            tooltip: 'About Offline Mode',
            iconSize: 22,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryPanel,
            tooltip: 'View Scan History',
            iconSize: 22,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsPanel,
            tooltip: 'Settings',
            iconSize: 22,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Stack(
              children: [
                MobileScanner(onDetect: _onDetect),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 60,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Position QR Code',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey.shade50, Colors.grey.shade100],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_scanHistory.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.history,
                                size: 16,
                                color: const Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Recently Scanned',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF6366F1),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _scanHistory.reversed
                                  .take(3)
                                  .map(
                                    (code) => Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(
                                              0xFF6366F1,
                                            ).withOpacity(0.1),
                                            const Color(
                                              0xFF8B5CF6,
                                            ).withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF6366F1,
                                          ).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        code,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    Row(
                      children: [
                        Icon(
                          Icons.volume_up,
                          size: 16,
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Now Speaking',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF6366F1),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: _isSpeaking
                              ? const Color(0xFF6366F1)
                              : Colors.grey.shade300,
                          width: _isSpeaking ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_isSpeaking)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: _buildAnimatedSpeakingIndicator(),
                            ),
                          Expanded(
                            child: Text(
                              _currentSpeaking.isEmpty
                                  ? 'Idle'
                                  : _currentSpeaking,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: _isSpeaking
                                    ? const Color(0xFF6366F1)
                                    : Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.playlist_play,
                              size: 16,
                              color: const Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Reading Queue',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF6366F1),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_ttsQueue.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _ttsQueue.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Queue is Empty',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Scan QR codes or add text to get started',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _ttsQueue.length,
                              itemBuilder: (context, index) {
                                final text = _ttsQueue[index];
                                final isCurrent = text == _currentSpeaking;
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? const Color(
                                            0xFF6366F1,
                                          ).withOpacity(0.15)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCurrent
                                          ? const Color(0xFF6366F1)
                                          : Colors.grey.shade300,
                                      width: isCurrent ? 1.5 : 1,
                                    ),
                                    boxShadow: isCurrent
                                        ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF6366F1,
                                              ).withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isCurrent
                                              ? const Color(0xFF6366F1)
                                              : Colors.grey.shade300,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: isCurrent
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              text,
                                              style: TextStyle(
                                                fontWeight: isCurrent
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: isCurrent
                                                    ? const Color(0xFF6366F1)
                                                    : Colors.black87,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isCurrent)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8.0,
                                          ),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: _buildQueueIndicator(),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildEnhancedBottomBar(),
    );
  }

  Widget _buildAnimatedSpeakingIndicator() {
    return Icon(Icons.volume_up, color: const Color(0xFF6366F1), size: 18);
  }

  Widget _buildQueueIndicator() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(milliseconds: 500)),
      builder: (context, snapshot) {
        final isActive = (snapshot.data ?? 0) % 2 == 0;
        return Icon(
          Icons.circle,
          size: 10,
          color: isActive
              ? const Color(0xFF6366F1)
              : const Color(0xFF6366F1).withOpacity(0.3),
        );
      },
    );
  }

  Widget _buildEnhancedBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomBarButton(
                icon: Icons.stop_circle_outlined,
                label: 'Stop',
                onPressed: _ttsQueue.isEmpty && !_isSpeaking
                    ? null
                    : () => _flutterTts.stop(),
              ),
              _buildBottomBarButton(
                icon: _isSpeaking
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                label: _isSpeaking ? 'Pause' : 'Play',
                onPressed: () {
                  if (_isSpeaking) {
                    _flutterTts.pause();
                  } else if (_ttsQueue.isNotEmpty ||
                      _currentSpeaking.isNotEmpty) {
                    _processQueue();
                  }
                },
                isPrimary: true,
              ),
              _buildBottomBarButton(
                icon: Icons.add_circle_outline,
                label: 'Add Text',
                onPressed: _showTextInputDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrimary ? const Color(0xFF6366F1) : Colors.grey.shade100,
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : onPressed != null
                  ? [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  height: 56,
                  width: 56,
                  child: Icon(
                    icon,
                    color: isPrimary
                        ? Colors.white
                        : onPressed != null
                        ? Colors.grey.shade700
                        : Colors.grey.shade400,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: onPressed != null
                  ? Colors.grey.shade700
                  : Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Settings Panel
class SettingsPanel extends StatelessWidget {
  final double volume;
  final double pitch;
  final double speechRate;
  final String language;
  final bool addNaturalPauses;
  final Function(double) onVolumeChanged;
  final Function(double) onPitchChanged;
  final Function(double) onSpeechRateChanged;
  final Function(String) onLanguageChanged;
  final Function(bool) onAddNaturalPausesChanged;

  const SettingsPanel({
    required this.volume,
    required this.pitch,
    required this.speechRate,
    required this.language,
    required this.addNaturalPauses,
    required this.onVolumeChanged,
    required this.onPitchChanged,
    required this.onSpeechRateChanged,
    required this.onLanguageChanged,
    required this.onAddNaturalPausesChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingSlider(
            label: 'Volume',
            value: volume,
            onChanged: onVolumeChanged,
            suffix: '${(volume * 100).toStringAsFixed(0)}%',
            icon: Icons.volume_up,
          ),
          const SizedBox(height: 20),
          _buildSettingSlider(
            label: 'Pitch',
            value: pitch,
            min: 0.5,
            max: 2.0,
            onChanged: onPitchChanged,
            suffix: pitch.toStringAsFixed(1),
            icon: Icons.music_note,
          ),
          const SizedBox(height: 20),
          _buildSettingSlider(
            label: 'Speech Rate',
            value: speechRate,
            min: 0.1,
            max: 1.0,
            onChanged: onSpeechRateChanged,
            suffix: speechRate.toStringAsFixed(2),
            icon: Icons.speed,
          ),
          const SizedBox(height: 20),
          _buildLanguageSelector(language, onLanguageChanged),
          const SizedBox(height: 24),
          _buildExpressivenessToggle(),
          const SizedBox(height: 24),
          _buildOfflineBadge(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOfflineBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline App',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Works without internet - 100% local processing',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSlider({
    required String label,
    required double value,
    required Function(double) onChanged,
    required String suffix,
    required IconData icon,
    double min = 0,
    double max = 1,
  }) {
    const int divisionCount = 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                suffix,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisionCount,
            activeColor: const Color(0xFF6366F1),
            inactiveColor: Colors.grey.shade300,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(
    String language,
    Function(String) onLanguageChanged,
  ) {
    // Ensure language value is valid
    String validLanguage = language;
    if (!availableLanguages.containsKey(validLanguage)) {
      validLanguage = 'en-US'; // Fallback to English (US)
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.language,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Language',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: DropdownButton<String>(
            value: validLanguage,
            isExpanded: true,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            items: availableLanguages.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) {
              if (v != null && availableLanguages.containsKey(v)) {
                onLanguageChanged(v);
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Language availability depends on device TTS support',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpressivenessToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.record_voice_over,
                  color: Colors.purple.shade700,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Natural Speech',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Add pauses for expressive speech',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: addNaturalPauses,
                onChanged: onAddNaturalPausesChanged,
                activeColor: const Color(0xFF6366F1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    addNaturalPauses
                        ? 'Speech will pause naturally at punctuation marks'
                        : 'Continuous speech without pauses',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// History Panel
class HistoryPanel extends StatelessWidget {
  final List<String> history;
  final Function(String) onDelete;
  final Function() onClear;

  const HistoryPanel({
    required this.history,
    required this.onDelete,
    required this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scan History',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
              if (history.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onClear,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.delete_sweep,
                          color: Colors.red.shade600,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.qr_code_2, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No Scans Yet',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan QR codes to see them appear here',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.qr_code_2,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        history[index],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onDelete(history[index]),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

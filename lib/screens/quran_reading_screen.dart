import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/quran_service.dart';
import '../services/reciter_service.dart';
import '../repositories/reciter_repository.dart';
import '../core/theme/app_theme.dart';

class QuranReadingScreen extends StatefulWidget {
  final dynamic surah;

  const QuranReadingScreen({super.key, required this.surah});

  @override
  State<QuranReadingScreen> createState() => _QuranReadingScreenState();
}

class _QuranReadingScreenState extends State<QuranReadingScreen> {
  static const String _fontSizeKey = 'quran_font_size';

  Map<String, dynamic>? _data;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Audio State
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  List<dynamic> _timestamps = [];
  String? _onlineAudioUrl;

  // Highlight State
  int _currentVerseIndex = -1;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  double _fontSize = 24.0;

  // Download State
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isDownloaded = false;

  // Reciter State
  Reciter _selectedReciter = ReciterRepository.reciters.first;

  @override
  void initState() {
    super.initState();
    _loadFontSize();
    _loadSelectedReciter();
    _loadData();
    _checkDownloadedStatus();

    // specific listeners
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() => _position = newPosition);
        _updateHighlight(newPosition);
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _isPlaying = false;
          _currentVerseIndex = -1;
        });
      }
    });
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSize = prefs.getDouble(_fontSizeKey);
    if (savedSize != null && mounted) {
      setState(() {
        _fontSize = savedSize;
      });
    }
  }

  Future<void> _saveFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, _fontSize);
  }

  Future<void> _loadSelectedReciter() async {
    final id = await ReciterService.getSelectedReciterId();
    if (mounted) {
      setState(() {
        _selectedReciter = ReciterRepository.getReciterById(id);
      });
    }
  }

  Future<void> _loadData() async {
    final service = Provider.of<QuranService>(context, listen: false);

    try {
      // 1. Fetch Surah Details (Critical)
      final surahDetails = await service.getSurahDetails(widget.surah['id']);

      if (mounted) {
        setState(() {
          _data = surahDetails;
        });
        _loadScrollPosition();
      }

      // 2. Fetch Audio Metadata (Optional - Don't block UI if fails)
      final audioData = await service.getChapterRecitation(widget.surah['id']);
      if (mounted) {
        setState(() {
          _timestamps = audioData['timestamps'] ?? [];
          _onlineAudioUrl = audioData['audio_url'];
        });
      }
    } catch (e) {
      debugPrint('Data fetch failed: $e');
      // Handle error visually if needed
    }
  }

  Future<void> _checkDownloadedStatus() async {
    final file = await _getLocalAudioFile();
    if (await file.exists()) {
      if (mounted) setState(() => _isDownloaded = true);
    }
  }

  Future<File> _getLocalAudioFile() async {
    final dir = await getApplicationDocumentsDirectory();
    // E.g. mishary_001.mp3
    final filename =
        "${_selectedReciter.id}_${widget.surah['id'].toString().padLeft(3, '0')}.mp3";
    return File('${dir.path}/$filename');
  }

  String _getAudioUrl() {
    final surahId = widget.surah['id'].toString().padLeft(3, '0');
    return '${_selectedReciter.serverUrl}/$surahId.mp3';
  }

  void _showReciterSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'اختر القارئ',
                style: TextStyle(
                  color: AppTheme.accentGold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: ReciterRepository.reciters.length,
                  itemBuilder: (context, index) {
                    final reciter = ReciterRepository.reciters[index];
                    final isSelected = reciter.id == _selectedReciter.id;
                    return ListTile(
                      title: Text(
                        reciter.name,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.accentGold
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppTheme.accentGold,
                            )
                          : null,
                      onTap: () async {
                        final nav = Navigator.of(context);
                        await ReciterService.setSelectedReciterId(reciter.id);
                        setState(() {
                          _selectedReciter = reciter;
                          _isDownloaded = false;
                        });
                        if (mounted) nav.pop();
                        _checkDownloadedStatus();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadAudio() async {
    final audioUrl = _getAudioUrl();

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final file = await _getLocalAudioFile();
      final response = await http.Client().send(
        http.Request('GET', Uri.parse(audioUrl)),
      );

      final total = response.contentLength ?? 0;
      int received = 0;
      final sink = file.openWrite();

      await response.stream.listen((chunk) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          if (mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        }
      }).asFuture();

      await sink.close();

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم التحميل بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل التحميل: $e')));
      }
    }
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      // Play local if exists, else online
      final file = await _getLocalAudioFile();
      if (await file.exists()) {
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else if (_onlineAudioUrl != null) {
        await _audioPlayer.play(UrlSource(_onlineAudioUrl!));
      }
    }
  }

  void _seek(double value) {
    _audioPlayer.seek(Duration(seconds: value.toInt()));
  }

  void _updateHighlight(Duration position) {
    if (_timestamps.isEmpty) return;
    final ms = position.inMilliseconds;

    // Find verse where ms is between start and end
    // timestamps structure: { timestamp_from: ms, timestamp_to: ms, ... }
    int foundIndex = -1;
    for (int i = 0; i < _timestamps.length; i++) {
      final ts = _timestamps[i];
      if (ms >= ts['timestamp_from'] && ms <= ts['timestamp_to']) {
        foundIndex = i;
        break;
      }
    }

    if (foundIndex != -1 && foundIndex != _currentVerseIndex) {
      setState(() {
        _currentVerseIndex = foundIndex;
      });
      _scrollToVerse(foundIndex);
    }
  }

  void _scrollToVerse(int index) {
    final key = _itemKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        alignment: 0.3, // Top third of screen
      );
    }
  }

  @override
  void dispose() {
    _saveScrollPosition(); // Save on exit
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadScrollPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'quran_scroll_${widget.surah['id']}';
    final savedOffset = prefs.getDouble(key);
    if (savedOffset != null) {
      // Wait for the frame to render (RichText to be laid out)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(savedOffset);
        }
      });
    }
  }

  Future<void> _saveScrollPosition() async {
    if (!_scrollController.hasClients) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'quran_scroll_${widget.surah['id']}';
    await prefs.setDouble(key, _scrollController.offset);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.surah['name_arabic'],
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
              color: AppTheme.accentGold,
            ),
          ),
          // Right side: Person, Download, Audio
          actions: [
            // Audio Button
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_circle : Icons.headphones,
                color: _isPlaying ? AppTheme.accentGold : Colors.white,
              ),
              onPressed: () {
                _showAudioControls(context);
              },
            ),
            // Download Button
            if (!_isDownloaded && !_isDownloading)
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _downloadAudio,
              ),
            if (_isDownloading)
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                child: CircularProgressIndicator(
                  value: _downloadProgress,
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            if (_isDownloaded)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Icon(Icons.check_circle, color: Colors.green, size: 20),
              ),
            // Reciter Selection Button
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: _selectedReciter.name,
              onPressed: _showReciterSelectionDialog,
            ),
          ],
          // Left side: Zoom-, Zoom+
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  setState(() {
                    if (_fontSize > 18) _fontSize -= 2;
                  });
                  _saveFontSize();
                },
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  setState(() {
                    if (_fontSize < 40) _fontSize += 2;
                  });
                  _saveFontSize();
                },
              ),
            ],
          ),
          leadingWidth: 140,
          automaticallyImplyLeading: false,
        ),
        body: _data == null
            ? const Center(child: CircularProgressIndicator())
            : NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification) {
                    _saveScrollPosition();
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: RichText(
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    text: TextSpan(
                      children: List.generate(_data!['verses'].length, (index) {
                        final verse = _data!['verses'][index];
                        final verseNumber = verse['verse_key'].split(':')[1];
                        final isHighlighted = (index == _currentVerseIndex);

                        return TextSpan(
                          children: [
                            TextSpan(
                              text: verse['text_uthmani'] + " ",
                              style: AppTheme.quranTextStyle.copyWith(
                                fontSize: _fontSize,
                                color: isHighlighted
                                    ? AppTheme.accentGold
                                    : Colors.white,
                                backgroundColor: isHighlighted
                                    ? Colors.black.withValues(alpha: 0.5)
                                    : null,
                              ),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Container(
                                width: 30,
                                height: 30,
                                margin: const EdgeInsets.only(
                                  left: 4,
                                  right: 4,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.accentGold,
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  verseNumber,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.accentGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _showAudioControls(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: _position.inSeconds.toDouble().clamp(
                      0.0,
                      _duration.inSeconds.toDouble(),
                    ),
                    min: 0,
                    max: _duration.inSeconds.toDouble(),
                    activeColor: AppTheme.accentGold,
                    inactiveColor: Colors.grey,
                    onChanged: (value) {
                      _seek(value);
                      setModalState(() {});
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white),
                        onPressed: () {
                          _seek(_position.inSeconds.toDouble() - 10);
                          setModalState(() {});
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          size: 50,
                          color: AppTheme.accentGold,
                        ),
                        onPressed: () {
                          _toggleAudio();
                          setModalState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white),
                        onPressed: () {
                          _seek(_position.inSeconds.toDouble() + 10);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return "0:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

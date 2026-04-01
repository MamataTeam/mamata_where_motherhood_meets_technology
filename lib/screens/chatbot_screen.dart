import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

// ─────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'time': time,
    'isError': isError,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'] ?? '',
    isUser: json['isUser'] ?? false,
    time: json['time'] ?? '',
    isError: json['isError'] ?? false,
  );
}

class ChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  final List<ChatMessage> messages;
  final String language;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
    this.language = 'en',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'messages': messages.map((m) => m.toJson()).toList(),
    'language': language,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final timestampVal = json['createdAt'];
    DateTime createdAt;
    if (timestampVal is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(timestampVal);
    } else {
      createdAt = DateTime.tryParse(timestampVal.toString()) ?? DateTime.now();
    }
    return ChatSession(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Chat',
      createdAt: createdAt,
      messages: (json['messages'] as List? ?? [])
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      language: json['language'] ?? 'en',
    );
  }
}

// ─────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────

class ChatbotScreen extends StatefulWidget {
  final String? userId;

  const ChatbotScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  // Language
  String _selectedLanguage = 'en';

  // UUID session id for backend context (per chat session)
  String _backendSessionId = const Uuid().v4();

  // Sidebar
  bool _sidebarOpen = false;
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;

  // Current Firestore session id
  late String _currentSessionId;

  // Firestore + SecureStorage
  final _firestore = FirebaseFirestore.instance;
  final _secureStorage = const FlutterSecureStorage();
  static const String _userIdKey = 'userId';
  late String _userId;

  final List<ChatSession> _sessions = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSub;

  // ── Palette ──────────────────────────────────
  static const Color primaryPurple = Color(0xFF7B4F9E);
  static const Color secondaryColor = Color(0xFF764BA2);
  static const Color roseDark = Color(0xFF8B3A62);
  static const Color roseLight = Color(0xFFE8A0BB);
  static const Color blushBg = Color(0xFFF9F0FB);
  static const Color sageGreen = Color(0xFF6B9E8A);
  static const Color textDark = Color(0xFF2C1A26);
  static const Color textGrey = Color(0xFF9E7A8E);
  static const Color pinkAvatar = Color(0xFFFF6B9D);
  static const double kPad = 16.0;

  late AnimationController _typingAnimationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeInOutCubic,
    );

    _startNewSession();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _resolveUserIdAndListen();
    });
  }

  @override
  void dispose() {
    _sessionsSub?.cancel();
    _typingAnimationController.dispose();
    _pulseController.dispose();
    _sidebarController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── UserId resolution (mirrors calendar_screen.dart) ─────────────────────

  Future<void> _resolveUserIdAndListen() async {
    final passed = widget.userId;
    if (passed != null && passed.isNotEmpty) {
      _userId = passed;
    } else {
      final stored = await _secureStorage.read(key: _userIdKey);
      _userId = (stored != null && stored.isNotEmpty) ? stored : 'unknown_user';
    }
    _startSessionsListener();
  }

  // ── Firestore real-time listener ─────────────────────────────────────────

  void _startSessionsListener() {
    final coll = _firestore
        .collection('users')
        .doc(_userId)
        .collection('chatSessions')
        .orderBy('createdAt', descending: true);

    _sessionsSub = coll.snapshots().listen((snapshot) {
      final List<ChatSession> loaded = [];
      for (final doc in snapshot.docs) {
        try {
          final session = ChatSession.fromJson({'id': doc.id, ...doc.data()});
          loaded.add(session);
        } catch (e) {
          debugPrint('Error parsing session ${doc.id}: $e');
        }
      }
      setState(() {
        _sessions
          ..clear()
          ..addAll(loaded);
      });
    });
  }

  // ── Session helpers ──────────────────────────────────────────────────────

  void _startNewSession() {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _backendSessionId = const Uuid().v4(); // fresh UUID for each new session
    _messages.clear();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text: _selectedLanguage == 'en'
            ? "Hello! 🤰 I'm your Pregnancy Care Assistant.\n\nI'm here to help with questions about nutrition, symptoms, baby development, exercises, and more.\n\nHow can I support you today?"
            : "नमस्ते! 🤰 म तपाईंको गर्भावस्था स्वास्थ्य सहायक हुँ।\n\nपोषण, लक्षण, बच्चाको विकास र अन्य कुराहरूमा मद्दत गर्न यहाँ छु!\n\nआज म तपाईंलाई कसरी मद्दत गर्न सक्छु?",
        isUser: false,
        time: _currentTime(),
      ),
    );
  }

  Future<void> _saveCurrentSession() async {
    final hasUserMsg = _messages.any((m) => m.isUser);
    if (!hasUserMsg) return;

    final userMessages = _messages.where((m) => m.isUser).toList();
    final title = userMessages.isNotEmpty
        ? _truncate(userMessages.first.text, 40)
        : 'Chat';

    final coll = _firestore
        .collection('users')
        .doc(_userId)
        .collection('chatSessions');

    final data = {
      'id': _currentSessionId,
      'title': title,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'messages': _messages.map((m) => m.toJson()).toList(),
      'language': _selectedLanguage,
    };

    final existing = _sessions.any((s) => s.id == _currentSessionId);
    if (existing) {
      await coll.doc(_currentSessionId).update(data);
    } else {
      await coll.doc(_currentSessionId).set(data);
    }
  }

  void _loadSession(ChatSession session) {
    _saveCurrentSession();
    setState(() {
      _currentSessionId = session.id;
      _selectedLanguage = session.language;
      _messages
        ..clear()
        ..addAll(session.messages);
      _sidebarOpen = false;
    });
    _sidebarController.reverse();
    _scrollToBottom();
  }

  Future<void> _deleteSession(String id) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('chatSessions')
        .doc(id)
        .delete();

    if (id == _currentSessionId) {
      setState(() => _startNewSession());
    }
  }

  void _newChat() {
    _saveCurrentSession();
    setState(() {
      _startNewSession();
      _sidebarOpen = false;
    });
    _sidebarController.reverse();
  }

  // ── Language switch ───────────────────────────────────────────────────────

  void _switchLanguage(String lang) {
    if (_selectedLanguage == lang) return;
    setState(() {
      _selectedLanguage = lang;
      _messages.clear();
      _addWelcomeMessage();
    });
  }

  // ── Utility ──────────────────────────────────────────────────────────────

  String _currentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _truncate(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max)}…';

  String _friendlyDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ── Quick questions ───────────────────────────────────────────────────────

  List<String> get _quickQuestions => _selectedLanguage == 'en'
      ? [
          "What should I eat this week?",
          "Is tiredness normal?",
          "Safe exercises for pregnancy?",
          "What vitamins should I take?",
        ]
      : [
          "यस हप्ता के खाने?",
          "थकान सामान्य हो?",
          "कस्तो व्यायाम गर्ने?",
          "कुन भिटामिन लिने?",
        ];

  // ── Messaging ────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _isSending = true;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, time: _currentTime()),
      );
      _isLoading = true;
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final url = _selectedLanguage == 'np' ? nepaliChatbotUrl : chatbotUrl;

      final response = await http
          .post(
            Uri.parse('$url/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': text,
              'language': _selectedLanguage,
              'session_id': _backendSessionId,
            }),
          )
          .timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botReply =
            data['response'] ??
            data['message'] ??
            'Sorry, I could not understand that.';
        setState(() {
          _messages.add(
            ChatMessage(text: botReply, isUser: false, time: _currentTime()),
          );
        });
      } else {
        _addErrorMessage();
      }
    } catch (e) {
      _addErrorMessage();
    } finally {
      setState(() => _isLoading = false);
      _isSending = false;
      await _saveCurrentSession();
      _scrollToBottom();
    }
  }

  void _addErrorMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text: _selectedLanguage == 'en'
              ? "Sorry, I couldn't connect to the server. Please make sure the chatbot backend is running."
              : "माफ गर्नुहोस्, सर्भरसँग जडान गर्न सकिएन।",
          isUser: false,
          time: _currentTime(),
          isError: true,
        ),
      );
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blushBg,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ── Main content ──────────────────────────────────────────────────
          Column(
            children: [
              _buildAIDisclaimerBanner(),
              Expanded(
                child: _messages.length == 1
                    ? _buildWelcomeView()
                    : _buildMessageList(),
              ),
              if (_isLoading) _buildTypingIndicator(),
              _buildInputArea(),
            ],
          ),

          // ── Dim overlay ───────────────────────────────────────────────────
          if (_sidebarOpen)
            GestureDetector(
              onTap: () {
                setState(() => _sidebarOpen = false);
                _sidebarController.reverse();
              },
              child: AnimatedBuilder(
                animation: _sidebarAnimation,
                builder: (_, __) => Container(
                  color: Colors.black.withOpacity(
                    0.35 * _sidebarAnimation.value,
                  ),
                ),
              ),
            ),

          // ── Sidebar drawer ────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _sidebarAnimation,
            builder: (_, child) {
              final offset = (1.0 - _sidebarAnimation.value) * -300.0;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: _buildSidebar(),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leadingWidth: 40,
      titleSpacing: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(color: primaryPurple),
      ),

      // ✅ Back arrow
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: Colors.white,
          size: 20,
        ),
        tooltip: 'Back to Dashboard',
        onPressed: () => Navigator.pop(context),
      ),

      // ✅ Title: hamburger + avatar + name/status
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Chat History',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() => _sidebarOpen = !_sidebarOpen);
              if (_sidebarOpen) {
                _sidebarController.forward();
              } else {
                _sidebarController.reverse();
              }
            },
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedLanguage == 'en'
                    ? 'Pregnancy Assistant'
                    : 'गर्भावस्था सहायक',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),

      actions: [
        // Language switcher
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLangChip('en', '🇬🇧 EN'),
              _buildLangChip('np', '🇳🇵 NP'),
            ],
          ),
        ),
        // Refresh / clear
        IconButton(
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 20,
          ),
          tooltip: 'Clear chat',
          onPressed: () {
            setState(() {
              _messages.clear();
              _addWelcomeMessage();
            });
          },
        ),
      ],
    );
  }

  Widget _buildLangChip(String lang, String label) {
    final isSelected = _selectedLanguage == lang;
    return GestureDetector(
      onTap: () => _switchLanguage(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  // ── AI Disclaimer banner ──────────────────────────────────────────────────

  Widget _buildAIDisclaimerBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: kPad, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFFD580).withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 13,
            color: Color(0xFFB8860B),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              _selectedLanguage == 'en'
                  ? 'AI can make mistakes. Always verify important health info with your doctor.'
                  : 'AI ले गल्ती गर्न सक्छ। महत्त्वपूर्ण जानकारी आफ्नो डाक्टरसँग प्रमाणित गर्नुहोस्।',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8B6914),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 300,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(6, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                decoration: const BoxDecoration(color: primaryPurple),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedLanguage == 'en'
                            ? 'Chat History'
                            : 'कुराकानी इतिहास',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _sidebarOpen = false);
                        _sidebarController.reverse();
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // New chat button
              Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: _newChat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryPurple, Color(0xFF9B59B6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _selectedLanguage == 'en'
                              ? 'New Chat'
                              : 'नयाँ कुराकानी',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),

              // Session list
              Expanded(
                child: _sessions.isEmpty
                    ? _buildEmptyHistory()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) =>
                            _buildSessionTile(_sessions[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            _selectedLanguage == 'en'
                ? 'No history yet'
                : 'अहिलेसम्म इतिहास छैन',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedLanguage == 'en'
                ? 'Start chatting to save history'
                : 'इतिहास बचत गर्न कुरा गर्नुहोस्',
            style: TextStyle(color: Colors.grey[350], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(ChatSession session) {
    final isActive = session.id == _currentSessionId;
    final msgCount = session.messages.where((m) => m.isUser).length;
    final isNepali = session.language == 'np';

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      confirmDismiss: (_) async => await _showDeleteConfirm(session.title),
      onDismissed: (_) => _deleteSession(session.id),
      child: GestureDetector(
        onTap: () => _loadSession(session),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? primaryPurple.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: primaryPurple.withOpacity(0.3))
                : null,
          ),
          child: Row(
            children: [
              // Avatar with language indicator
              Stack(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? primaryPurple
                          : primaryPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryPurple.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        isNepali ? '🇳🇵' : '🇬🇧',
                        style: const TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isActive
                            ? primaryPurple
                            : const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 10,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _friendlyDate(session.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 10,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$msgCount msg${msgCount != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.grey[350],
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  final confirm = await _showDeleteConfirm(session.title);
                  if (confirm == true) _deleteSession(session.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(String title) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _selectedLanguage == 'en' ? 'Delete Chat?' : 'कुराकानी मेटाउने?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          _selectedLanguage == 'en'
              ? 'Are you sure you want to delete "$title"? This cannot be undone.'
              : '"$title" मेटाउन निश्चित हुनुहुन्छ? यो फिर्ता गर्न सकिँदैन।',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_selectedLanguage == 'en' ? 'Cancel' : 'रद्द गर्नुस्'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _selectedLanguage == 'en' ? 'Delete' : 'मेटाउनुस्',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Welcome view ──────────────────────────────────────────────────────────

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: kPad, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageBubble(_messages[0]),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text(
              _selectedLanguage == 'en' ? 'Quick Questions' : 'छिटो प्रश्नहरू',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textGrey,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickQuestions.map((q) {
                return GestureDetector(
                  onTap: () {
                    if (_isSending) return;
                    _messageController.text = q;
                    Future.microtask(() => _sendMessage());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: roseLight.withOpacity(0.6),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      q,
                      style: const TextStyle(
                        color: primaryPurple,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          // Info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sageGreen.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🏥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedLanguage == 'en'
                        ? 'This AI provides general pregnancy information. Always consult your healthcare provider for personalized advice.'
                        : 'यो AI सहायकले सामान्य गर्भावस्था जानकारी प्रदान गर्छ। व्यक्तिगत सल्लाहको लागि आफ्नो डाक्टरसँग परामर्श गर्नुहोस्।',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3D7A65),
                      height: 1.5,
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

  // ── Message list & bubbles ────────────────────────────────────────────────

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: kPad, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 8, bottom: 18),
              decoration: BoxDecoration(
                color: primaryPurple,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB07CC6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 16),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!message.isUser && !message.isError)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      'AI Assistant',
                      style: TextStyle(
                        fontSize: 10,
                        color: textGrey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? primaryPurple
                        : message.isError
                        ? Colors.red[50]
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: message.isUser
                            ? roseDark.withOpacity(0.25)
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: message.isError
                        ? Border.all(color: Colors.red.shade200)
                        : message.isUser
                        ? null
                        : Border.all(
                            color: const Color(0xFFE0C4EA).withOpacity(0.5),
                            width: 1,
                          ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : message.isError
                          ? Colors.red[700]
                          : textDark,
                      fontSize: 14.5,
                      height: 1.55,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    message.time,
                    style: TextStyle(fontSize: 10, color: textGrey),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(left: 8, bottom: 18),
              decoration: BoxDecoration(
                color: pinkAvatar.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: pinkAvatar.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: pinkAvatar,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Typing indicator ──────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: kPad, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: primaryPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFE0C4EA).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _typingAnimationController,
                  builder: (context, child) {
                    final delay = index * 0.25;
                    final t = ((_typingAnimationController.value - delay).clamp(
                      0.0,
                      1.0,
                    ));
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Color.lerp(roseLight, roseDark, t),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input area ────────────────────────────────────────────────────────────

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: kPad,
        right: kPad,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: blushBg,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFFE0C4EA).withOpacity(0.8),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: textDark,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: _selectedLanguage == 'en'
                      ? 'Ask about your pregnancy...'
                      : 'गर्भावस्थाको बारेमा सोध्नुहोस्...',
                  hintStyle: TextStyle(
                    color: textGrey.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) {
                  if (!_isSending) _sendMessage();
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isLoading ? const Color(0xFFEFD9F2) : primaryPurple,
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isLoading ? textGrey : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

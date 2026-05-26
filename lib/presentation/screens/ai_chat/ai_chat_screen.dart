import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/chat_message_model.dart';

const _disclaimerPrefKey = 'chat_disclaimer_seen';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with SingleTickerProviderStateMixin {
  final List<ChatMessageModel> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  bool _showDisclaimer = false;
  bool _isThinking = false;

  // Typewriter streaming state
  Timer? _typewriterTimer;
  String? _streamingMessageId;
  int _streamedChars = 0;

  // Message entrance animation
  late final AnimationController _msgCtrl;
  late final Animation<double> _msgFade;
  late final Animation<Offset> _msgSlide;
  String? _latestMessageId;

  Map<String, dynamic> _patientContext = {};

  @override
  void initState() {
    super.initState();
    _msgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _msgFade = CurvedAnimation(parent: _msgCtrl, curve: Curves.easeOut);
    _msgSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _msgCtrl, curve: Curves.easeOutCubic));
    _msgCtrl.value = 1.0; // start fully visible; only animate on new messages
    _inputController.addListener(() => setState(() {}));
    _loadDisclaimerState();
    _loadPatientContext();
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _msgCtrl.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _loadPatientContext() async {
    try {
      final data = await ApiService.instance.getMyProfile();
      if (!mounted) return;
      final user = data['user'] as Map<String, dynamic>?;
      final profile = data['patient_profile'] as Map<String, dynamic>?;
      if (user != null) {
        final fullName = user['full_name'] as String? ?? '';
        _patientContext['patient_name'] = fullName.split(' ').first;
      }
      if (profile != null) {
        final startStr = profile['treatment_start_date'] as String?;
        int dayNumber = 1;
        if (startStr != null) {
          final startDate = DateTime.parse(startStr);
          dayNumber = DateTime.now().difference(startDate).inDays + 1;
        }
        _patientContext = {
          'phase': profile['current_phase'] ?? 'intensive',
          'day_number': dayNumber,
          'faskes_name': profile['faskes_name'] ?? '',
          'doctor_name': profile['doctor_name'] ?? '',
        };
      }
    } catch (_) {}
  }

  Future<void> _loadDisclaimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_disclaimerPrefKey) ?? false;
    if (mounted) setState(() => _showDisclaimer = !seen);
  }

  Future<void> _dismissDisclaimer() async {
    setState(() => _showDisclaimer = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disclaimerPrefKey, true);
  }

  void _scrollToBottom() {
    // With reverse:true the bottom is offset 0.
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isThinking) return;

    final now = DateTime.now();
    final userMsg = ChatMessageModel(
      id: 'u_${now.microsecondsSinceEpoch}',
      role: 'user',
      content: text,
      timestamp: now,
    );

    setState(() {
      _messages.add(userMsg);
      _latestMessageId = userMsg.id;
      _inputController.clear();
      _isThinking = true;
    });
    _msgCtrl.forward(from: 0);
    HapticFeedback.lightImpact();
    _inputFocus.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Build history from prior messages (exclude the one just added)
    final prior = _messages.take(_messages.length - 1).toList();
    final histStart = (prior.length - 20).clamp(0, prior.length);
    final history = prior.sublist(histStart).map((m) => {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.content,
        }).toList();

    final aiId = 'ai_${DateTime.now().microsecondsSinceEpoch}';
    final aiPlaceholder = ChatMessageModel(
      id: aiId,
      role: 'ai',
      content: '',
      timestamp: DateTime.now(),
    );

    setState(() {
      _isThinking = false;
      _messages.add(aiPlaceholder);
      _latestMessageId = aiId;
      _streamingMessageId = aiId;
      _streamedChars = 0;
    });
    _msgCtrl.forward(from: 0);

    try {
      await for (final chunk in ApiService.instance.chatStream(
        text,
        history,
        _patientContext,
      )) {
        if (!mounted) break;
        final idx = _messages.indexWhere((m) => m.id == aiId);
        if (idx < 0) break;
        final newContent = _messages[idx].content + chunk;
        setState(() {
          _messages[idx] = _messages[idx].copyWith(content: newContent);
          _streamedChars = newContent.length;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {
      if (mounted) {
        final idx = _messages.indexWhere((m) => m.id == aiId);
        if (idx >= 0) {
          const err = 'Maaf, terjadi gangguan koneksi. Coba lagi.';
          setState(() {
            _messages[idx] = _messages[idx].copyWith(content: err);
            _streamedChars = err.length;
          });
        }
      }
    } finally {
      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() => _streamingMessageId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _ChatHeader(
            thinking: _isThinking,
            onBack: () => context.go('/home/dashboard'),
          ),
          if (_showDisclaimer)
            _DisclaimerBanner(onDismiss: _dismissDisclaimer),
          Expanded(
            child: _messages.isEmpty
                ? _WelcomeView(onQuestionTap: _sendMessage)
                : _buildChatList(),
          ),
          if (_messages.isNotEmpty && !_isThinking)
            _QuickReplies(onSelect: _sendMessage),
          _InputBar(
            controller: _inputController,
            focusNode: _inputFocus,
            onSend: () => _sendMessage(_inputController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    // Build display items in chronological order.
    final items = <Widget>[];
    items.add(_TimestampDivider(
      label: 'Hari ini, ${_formatTime(_messages.first.timestamp)}',
    ));

    for (var i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final prev = i > 0 ? _messages[i - 1] : null;
      final next = i < _messages.length - 1 ? _messages[i + 1] : null;
      final isLatest = msg.id == _latestMessageId;

      Widget bubble;
      if (msg.isUser) {
        final grouped = prev != null && prev.isUser;
        bubble = _UserBubble(
          text: msg.content,
          time: _formatTime(msg.timestamp),
          grouped: grouped,
        );
      } else {
        final showAvatar = prev == null || !prev.isAI;
        final showTime = next == null || !next.isAI;
        final isStreaming = msg.id == _streamingMessageId;
        final displayText = isStreaming
            ? msg.content.substring(
                0, _streamedChars.clamp(0, msg.content.length))
            : msg.content;
        bubble = _AIBubble(
          text: displayText,
          time: showTime && !isStreaming ? _formatTime(msg.timestamp) : null,
          showAvatar: showAvatar,
          cardType: isStreaming ? null : msg.cardType,
          cardData: msg.cardData,
        );
      }

      if (isLatest) {
        bubble = FadeTransition(
          opacity: _msgFade,
          child: SlideTransition(position: _msgSlide, child: bubble),
        );
      }

      items.add(bubble);
    }

    if (_isThinking) {
      items.add(const _TypingIndicator());
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: items.length,
      itemBuilder: (context, index) => items[items.length - 1 - index],
    );
  }
}

// ── Robot glyph painter ──────────────────────────────────────
class RobotGlyph extends StatelessWidget {
  final double size;
  final Color color;

  const RobotGlyph({super.key, this.size = 24, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RobotPainter(color: color),
    );
  }
}

class _RobotPainter extends CustomPainter {
  final Color color;

  _RobotPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.7 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(4 * s, 7 * s, 16 * s, 12 * s),
      Radius.circular(4 * s),
    );
    canvas.drawRRect(body, stroke);
    canvas.drawCircle(Offset(9 * s, 13 * s), 1.4 * s, fill);
    canvas.drawCircle(Offset(15 * s, 13 * s), 1.4 * s, fill);
    canvas.drawLine(Offset(12 * s, 4 * s), Offset(12 * s, 7 * s), stroke);
    canvas.drawLine(Offset(9 * s, 19 * s), Offset(9 * s, 21 * s), stroke);
    canvas.drawLine(Offset(15 * s, 19 * s), Offset(15 * s, 21 * s), stroke);
    canvas.drawCircle(Offset(12 * s, 3 * s), 1.2 * s, fill);
  }

  @override
  bool shouldRepaint(covariant _RobotPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ── Header ───────────────────────────────────────────────────
class _ChatHeader extends StatelessWidget {
  final bool thinking;
  final VoidCallback onBack;

  const _ChatHeader({required this.thinking, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 12;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.7, -1),
          end: Alignment(0.7, 1),
          colors: [AppColors.primary, Color(0xFF15594B)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, topPad, 16, 14),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
            bgOpacity: 0.15,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _PulsingAvatar(),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PMO Digital',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _StatusLine(thinking: thinking),
                  ],
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.info_outline_rounded,
            onTap: () {
              // TODO: open AI assistant info sheet
            },
            bgOpacity: 0.12,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double bgOpacity;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.bgOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: bgOpacity),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final bool thinking;

  const _StatusLine({required this.thinking});

  @override
  Widget build(BuildContext context) {
    if (thinking) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Sedang berpikir...',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3ED27E),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3ED27E).withValues(alpha: 0.7),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Aktif',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _PulsingAvatar extends StatefulWidget {
  const _PulsingAvatar();

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final wave = (t < 0.5 ? t : 1 - t) * 2; // 0→1→0
              final scale = 1.0 + wave * 0.18;
              final opacity = 0.6 - wave * 0.42;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: opacity.clamp(0, 1)),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: const Center(
              child: RobotGlyph(size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Disclaimer banner ────────────────────────────────────────
class _DisclaimerBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const _DisclaimerBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.amberSoft,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFFB8760A)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'PMO Digital memberikan edukasi, bukan diagnosis medis',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB8760A),
                height: 1.35,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  size: 14, color: Color(0xFFB8760A)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Welcome / empty state ────────────────────────────────────
class _WelcomeView extends StatefulWidget {
  final ValueChanged<String> onQuestionTap;

  const _WelcomeView({required this.onQuestionTap});

  @override
  State<_WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<_WelcomeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _questions = [
    (icon: Icons.medication_rounded, q: 'Efek samping obat TB?'),
    (icon: Icons.restaurant_rounded, q: 'Makanan yang boleh?'),
    (icon: Icons.schedule_rounded, q: 'Lupa minum obat?'),
    (icon: Icons.water_drop_rounded, q: 'Urine merah normal?'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    final wave = (t < 0.5 ? t : 1 - t) * 2;
                    return Transform.scale(
                      scale: 1.0 + wave * 0.08,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary
                              .withValues(alpha: 0.55 - wave * 0.3),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDeep],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: RobotGlyph(size: 48, color: Colors.white),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3ED27E),
                      border: Border.all(
                          color: AppColors.background, width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Halo! Saya PMO Digital 👋',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              'Siap menjawab pertanyaanmu tentang pengobatan TB kapanpun',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMute,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'PERTANYAAN YANG SERING DITANYAKAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMute,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              for (final item in _questions)
                _QuestionCard(
                  icon: item.icon,
                  question: item.q,
                  onTap: () => widget.onQuestionTap(item.q),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'atau ketik pertanyaanmu sendiri ↓',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textMute,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final IconData icon;
  final String question;
  final VoidCallback onTap;

  const _QuestionCard({
    required this.icon,
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, Color(0xFF2A8B73)],
                    ),
                  ),
                  child: Icon(icon, size: 15, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tealSoft,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar (chat bubble) ─────────────────────────────────────
class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.33),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: RobotGlyph(size: 18, color: Colors.white),
      ),
    );
  }
}

// ── AI bubble ────────────────────────────────────────────────
class _AIBubble extends StatelessWidget {
  final String text;
  final String? time;
  final bool showAvatar;
  final String? cardType;
  final Map<String, dynamic>? cardData;

  const _AIBubble({
    required this.text,
    required this.time,
    required this.showAvatar,
    this.cardType,
    this.cardData,
  });

  @override
  Widget build(BuildContext context) {
    final isEmergency = cardType == 'emergency';
    final isMotivation = cardType == 'motivation';
    final accent = isEmergency
        ? AppColors.danger
        : isMotivation
            ? AppColors.amber
            : AppColors.primary;
    final bg = isEmergency
        ? const Color(0xFFFFF8F7)
        : isMotivation
            ? const Color(0xFFFFFCF6)
            : Colors.white;

    return Padding(
      padding: EdgeInsets.only(top: showAvatar ? 16 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          showAvatar
              ? const _ChatAvatar()
              : const SizedBox(width: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                    ),
                    border: Border(
                      top: BorderSide(color: AppColors.border),
                      right: BorderSide(color: AppColors.border),
                      bottom: BorderSide(color: AppColors.border),
                      left: BorderSide(color: accent, width: 3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.text,
                          height: 1.55,
                        ),
                      ),
                      if (cardType == 'education')
                        _EducationInfoCard(data: cardData),
                      if (cardType == 'motivation')
                        _MotivationProgress(data: cardData),
                    ],
                  ),
                ),
                if (isEmergency) const _EmergencyActionCard(),
                if (time != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 4),
                    child: Text(
                      time!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textMute,
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

// ── User bubble ──────────────────────────────────────────────
class _UserBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool grouped;

  const _UserBubble({
    required this.text,
    required this.time,
    required this.grouped,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: grouped ? 4 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1F7C68),
                        AppColors.primary,
                        AppColors.primaryDeep,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.27),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, right: 4),
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMute,
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

// ── Typing indicator ─────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _ChatAvatar(),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border(
                top: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
                left: BorderSide(color: AppColors.primary, width: 3),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final phase = (_controller.value - i * 0.15) % 1.0;
                      final lift = phase < 0.3
                          ? (phase / 0.3)
                          : phase < 0.6
                              ? (1 - (phase - 0.3) / 0.3)
                              : 0.0;
                      return Transform.translate(
                        offset: Offset(0, -5 * lift),
                        child: Opacity(
                          opacity: 0.4 + 0.6 * lift,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timestamp divider ────────────────────────────────────────
class _TimestampDivider extends StatelessWidget {
  final String label;

  const _TimestampDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.dark.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMute,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Emergency action card ────────────────────────────────────
class _EmergencyActionCard extends StatelessWidget {
  const _EmergencyActionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.13),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE5E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('🏥', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cari Faskes Terdekat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Puskesmas buka 24 jam tersedia',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMute,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // TODO: launch maps with nearby health facilities
                },
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDeep],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Buka Maps',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Education info card ──────────────────────────────────────
class _EducationInfoCard extends StatelessWidget {
  final Map<String, dynamic>? data;

  const _EducationInfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data?['title'] as String? ?? 'Tentang Obat TB';
    final rawFacts = data?['facts'] as List? ?? const [];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💊 ${title.toUpperCase()}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          for (final fact in rawFacts)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•  ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: '${(fact as List)[0]}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: '${fact[1]}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              // TODO: navigate to education detail
            },
            child: const Text(
              'Baca lebih lanjut →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Motivation progress card ─────────────────────────────────
class _MotivationProgress extends StatelessWidget {
  final Map<String, dynamic>? data;

  const _MotivationProgress({required this.data});

  @override
  Widget build(BuildContext context) {
    final pct = (data?['percentage'] as int? ?? 50).clamp(0, 100);
    final daysRemaining = data?['daysRemaining'] as int? ?? 90;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'PROGRESS KAMU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA66A00),
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Container(
              height: 8,
              color: Colors.white,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct / 100,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFF2A8B73)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$daysRemaining hari tersisa menuju kesembuhan 🎯',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFA66A00),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick reply chips ────────────────────────────────────────
class _QuickReplies extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const _QuickReplies({required this.onSelect});

  static const _items = [
    'Tidak ada efek samping',
    'Mual ringan',
    'Urine merah',
    'Nyeri sendi',
    'Tanya lain...',
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final label in _items) ...[
                  GestureDetector(
                    onTap: () => onSelect(label),
                    child: Container(
                      height: 34,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                            color: AppColors.primary, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 10,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Input bar ────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = controller.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: hasContent || focusNode.hasFocus
                    ? Colors.white
                    : AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: hasContent || focusNode.hasFocus
                      ? AppColors.primary
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.only(left: 6, right: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.mic_none_rounded,
                        color: Color(0xFF9AAFA8)),
                    onPressed: () {
                      // TODO: voice-to-text input
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Ketik pertanyaanmu...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMute,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: hasContent ? onSend : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasContent
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDeep],
                      )
                    : null,
                color: hasContent ? null : const Color(0xFFCFDDD8),
                boxShadow: hasContent
                    ? [
                        BoxShadow(
                          color:
                              AppColors.primary.withValues(alpha: 0.33),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

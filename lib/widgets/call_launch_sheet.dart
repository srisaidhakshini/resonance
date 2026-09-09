import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/studio_items.dart';
import '../services/call_tutor_service.dart';

class CallLaunchSheet extends StatefulWidget {
  final String? initialTopic;
  final String? initialGrade;

  const CallLaunchSheet({
    super.key,
    this.initialTopic,
    this.initialGrade,
  });

  static Future<void> show(BuildContext context, {String? topic, String? grade}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CallLaunchSheet(initialTopic: topic, initialGrade: grade),
    );
  }

  @override
  State<CallLaunchSheet> createState() => _CallLaunchSheetState();
}

class _CallLaunchSheetState extends State<CallLaunchSheet> {
  final CallTutorService _callService = CallTutorService.instance;
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _topicCtrl = TextEditingController();
  final TextEditingController _twilioSidCtrl = TextEditingController();
  final TextEditingController _twilioAuthCtrl = TextEditingController();
  final TextEditingController _twilioFromCtrl = TextEditingController();
  final TextEditingController _elevenLabsKeyCtrl = TextEditingController();
  final TextEditingController _agentIdCtrl = TextEditingController();

  String _selectedGrade = 'Class 10';
  bool _isDialing = false;
  bool _showSettings = false;
  String? _statusMessage;

  final List<String> _quickTopics = [
    'Newton\'s Laws of Motion',
    'Calculus: Derivatives & Limits',
    'Chemical Reactions & Bonding',
    'Cell Division & Genetics',
    '3D Vectors & Matrices',
    'Light: Reflection & Refraction',
  ];

  final TextEditingController _customTopicCtrl = TextEditingController();
  bool _isAddingCustomTopic = false;
  bool _callDispatched = false;

  @override
  void initState() {
    super.initState();
    _topicCtrl.text = widget.initialTopic ?? 'Physics: Laws of Motion';
    _phoneCtrl.text = '+918248059760';
    _initData();
  }

  Future<void> _initData() async {
    final userGrade = await StudioPreTemplates.getUserGradeFormatted();
    final creds = await _callService.loadCredentials();

    if (mounted) {
      setState(() {
        if (widget.initialGrade != null) {
          _selectedGrade = widget.initialGrade!;
        } else if (StudioPreTemplates.allGrades.contains(userGrade)) {
          _selectedGrade = userGrade;
        }

        final phoneVal = creds['studentPhone'];
        _phoneCtrl.text = (phoneVal != null && phoneVal.trim().isNotEmpty) ? phoneVal : '+918248059760';
        _twilioSidCtrl.text = creds['twilioSid'] ?? '';
        _twilioAuthCtrl.text = creds['twilioAuth'] ?? '';
        _twilioFromCtrl.text = creds['twilioFromNumber'] ?? '';
        _elevenLabsKeyCtrl.text = creds['elevenLabsKey'] ?? '';
        _agentIdCtrl.text = creds['elevenLabsAgentId'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _topicCtrl.dispose();
    _customTopicCtrl.dispose();
    _twilioSidCtrl.dispose();
    _twilioAuthCtrl.dispose();
    _twilioFromCtrl.dispose();
    _elevenLabsKeyCtrl.dispose();
    _agentIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    await _callService.saveCredentials(
      twilioSid: _twilioSidCtrl.text,
      twilioAuth: _twilioAuthCtrl.text,
      twilioFromNumber: _twilioFromCtrl.text,
      elevenLabsKey: _elevenLabsKeyCtrl.text,
      elevenLabsAgentId: _agentIdCtrl.text,
      elevenLabsVoiceId: CallTutorService.defaultVoiceRachel,
      studentPhone: _phoneCtrl.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API configuration saved successfully!'),
          backgroundColor: Color(0xFF0D9488),
        ),
      );
      setState(() => _showSettings = false);
    }
  }

  void _addCustomTopic() {
    final custom = _customTopicCtrl.text.trim();
    if (custom.isNotEmpty) {
      setState(() {
        if (!_quickTopics.contains(custom)) {
          _quickTopics.insert(0, custom);
        }
        _topicCtrl.text = custom;
        _customTopicCtrl.clear();
        _isAddingCustomTopic = false;
      });
    }
  }

  Future<void> _triggerTwilioCall() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _statusMessage = 'Please enter your phone number with country code');
      return;
    }

    setState(() {
      _isDialing = true;
      _callDispatched = true;
      _statusMessage = 'Connecting carrier gateway & ringing your phone...';
    });

    final topic = _topicCtrl.text.trim().isEmpty ? 'General STEM' : _topicCtrl.text.trim();
    final result = await _callService.initiateTwilioPhoneCall(
      toNumber: phone,
      topic: topic,
      grade: _selectedGrade,
    );

    if (mounted) {
      setState(() {
        _isDialing = false;
        _statusMessage = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sheetBg = isDark ? const Color(0xFF070B11) : Colors.white;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.055) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final textMuted = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.09) : const Color(0xFFE2E8F0);
    final brandTeal = isDark ? const Color(0xFF00F5A0) : const Color(0xFF0D9488);
    final brandAccent = isDark ? const Color(0xFF00F5A0) : const Color(0xFF14B8A6);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: brandAccent.withValues(alpha: isDark ? 0.15 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: brandAccent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    Icons.phone_in_talk_rounded,
                    color: isDark ? const Color(0xFF00F5A0) : brandTeal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Voice Tutor Call',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Receive an instant live voice call on your phone',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'API Settings',
                  icon: Icon(
                    _showSettings ? Icons.close_rounded : Icons.tune_rounded,
                    color: _showSettings ? (isDark ? const Color(0xFF00F5A0) : brandTeal) : textMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showSettings = !_showSettings),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_showSettings) ...[
              _buildSettingsForm(isDark, cardBg, textPrimary, textSecondary, textMuted, borderCol, brandTeal),
            ] else if (_callDispatched) ...[
              // Active Calling Mic UI (No complicated popup, just focused mic state)
              _buildActiveCallingMicUi(isDark, cardBg, textPrimary, textSecondary, brandTeal, brandAccent),
            ] else ...[
              // Topic Section Header with "Add Custom Topic" button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOPIC / DOUBT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF2DD4BF) : brandTeal,
                      letterSpacing: 0.6,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _isAddingCustomTopic = !_isAddingCustomTopic),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            _isAddingCustomTopic ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                            size: 13,
                            color: brandAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isAddingCustomTopic ? 'Cancel' : '+ Add Own Topic',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: brandAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Add Custom Topic Inline Box
              if (_isAddingCustomTopic) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: brandAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customTopicCtrl,
                          autofocus: true,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Enter your custom doubt or topic...',
                            hintStyle: TextStyle(color: textMuted, fontSize: 12.5),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                          onSubmitted: (_) => _addCustomTopic(),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _addCustomTopic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Add',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Current Selected Topic Input Field
              TextField(
                controller: _topicCtrl,
                style: TextStyle(color: textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'e.g. Newton\'s 2nd Law, Organic Reactions, Limits',
                  hintStyle: TextStyle(color: textMuted, fontSize: 13),
                  filled: true,
                  fillColor: cardBg,
                  prefixIcon: Icon(Icons.school_rounded, color: brandTeal, size: 18),
                  suffixIcon: _topicCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: textMuted, size: 16),
                          onPressed: () => setState(() => _topicCtrl.clear()),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderCol),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderCol),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: brandAccent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const SizedBox(height: 12),

              // Clean Topic Grid
              Text(
                'SELECT OR CHOOSE TOPIC',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickTopics.map((t) {
                  final isSelected = _topicCtrl.text == t;
                  return InkWell(
                    onTap: () => setState(() => _topicCtrl.text = t),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? brandTeal.withValues(alpha: isDark ? 0.22 : 0.12)
                            : cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? brandAccent : borderCol,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                            size: 13,
                            color: isSelected
                                ? (isDark ? const Color(0xFF5EEAD4) : brandTeal)
                                : textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF5EEAD4) : brandTeal)
                                  : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Phone number input
              Text(
                'YOUR PHONE NUMBER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF2DD4BF) : brandTeal,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: '+91 82480 59760',
                  hintStyle: TextStyle(color: textMuted),
                  filled: true,
                  fillColor: cardBg,
                  prefixIcon: Icon(Icons.phone_iphone_rounded, color: brandTeal, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderCol),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderCol),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: brandAccent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              if (_statusMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: brandTeal.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: brandAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: isDark ? const Color(0xFF2DD4BF) : brandTeal,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Primary Action Button (Call Phone Now)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _isDialing
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? const Color(0xFF070B11) : Colors.white,
                          ),
                        )
                      : const Icon(Icons.phone_in_talk_rounded, size: 20),
                  label: Text(
                    _isDialing ? 'Connecting Carrier Gateway...' : 'Call My Phone Now',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : brandTeal,
                    foregroundColor: isDark ? const Color(0xFF070B11) : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isDialing ? null : _triggerTwilioCall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Clean active calling UI: Just a sleek pulsing microphone UI with call status
  Widget _buildActiveCallingMicUi(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color brandTeal,
    Color brandAccent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      width: double.infinity,
      child: Column(
        children: [
          // Animated Pulsing Mic Wave
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: brandTeal.withValues(alpha: 0.12),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: brandTeal.withValues(alpha: 0.22),
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [brandTeal, brandAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brandTeal.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.mic_rounded, color: Colors.white, size: 34),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            _isDialing ? 'Calling ${_phoneCtrl.text}...' : 'Carrier Gateway Connected',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _statusMessage ?? 'Pick up your incoming phone call to speak directly with Echo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Done / Dismiss
          SizedBox(
            width: 160,
            height: 42,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsForm(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color borderCol,
    Color brandTeal,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TWILIO & ELEVENLABS API CREDENTIALS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF14B8A6) : brandTeal,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField('Twilio Account SID', _twilioSidCtrl, cardBg, textPrimary, textMuted, borderCol, hint: 'AC...'),
        const SizedBox(height: 10),
        _buildTextField('Twilio Auth Token', _twilioAuthCtrl, cardBg, textPrimary, textMuted, borderCol, isPassword: true, hint: 'Your auth token'),
        const SizedBox(height: 10),
        _buildTextField('Twilio From Phone Number', _twilioFromCtrl, cardBg, textPrimary, textMuted, borderCol, hint: '+14155552671'),
        const SizedBox(height: 10),
        _buildTextField('ElevenLabs API Key', _elevenLabsKeyCtrl, cardBg, textPrimary, textMuted, borderCol, isPassword: true, hint: 'xi_api_key'),
        const SizedBox(height: 10),
        _buildTextField('ElevenLabs Agent ID (Optional)', _agentIdCtrl, cardBg, textPrimary, textMuted, borderCol, hint: 'Conversational agent ID'),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _saveSettings,
            child: Text(
              'Save API Settings',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl,
    Color cardBg,
    Color textPrimary,
    Color textMuted,
    Color borderCol, {
    bool isPassword = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textPrimary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          obscureText: isPassword,
          style: TextStyle(color: textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textMuted, fontSize: 12),
            filled: true,
            fillColor: cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderCol)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderCol)),
          ),
        ),
      ],
    );
  }
}

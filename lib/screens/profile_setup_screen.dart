import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_profile.dart';
import '../providers/user_profile_provider.dart';
import '../services/personalization_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'settings_screen.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final bool isEditMode;
  final bool isStandaloneTab;
  const ProfileSetupScreen({
    super.key,
    this.isEditMode = false,
    this.isStandaloneTab = false,
  });

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  String? _selectedGrade;
  TeachingStyle _selectedTeachingStyle = TeachingStyle.socratic;
  PacingLevel _selectedPacingLevel = PacingLevel.stepByStep;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    final profile = await PersonalizationService.instance.getUserProfile();
    if (mounted) {
      setState(() {
        if (widget.isEditMode || profile.userName != 'Student') {
          _nameController.text = profile.userName;
        }
        _selectedGrade = profile.grade;
        _selectedTeachingStyle = profile.teachingStyle;
        _selectedPacingLevel = profile.pacingLevel;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _selectedGrade != null) {
      final profile = UserProfile(
        userName: _nameController.text.trim(),
        grade: _selectedGrade!,
        teachingStyle: _selectedTeachingStyle,
        pacingLevel: _selectedPacingLevel,
      );
      await ref.read(userProfileNotifierProvider.notifier).updateProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Learning profile updated successfully!'),
            backgroundColor: AppColors.lightTeal,
          ),
        );

        if (!widget.isStandaloneTab && widget.isEditMode) {
          Navigator.pop(context);
        } else if (!widget.isEditMode) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } else if (_selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your grade or class'),
          backgroundColor: AppColors.chart4,
        ),
      );
    }
  }

  Future<void> _showExitDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
          title: Text(
            'Exit Setup?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'We use your grade and learning preferences to customize Echo\'s explanations. Are you sure you want to exit?',
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                SystemNavigator.pop();
              },
              child: Text(
                'Exit',
                style: TextStyle(color: AppColors.lightDestructive),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.lightTeal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070B11) : AppColors.lightBackground,
      drawer: widget.isStandaloneTab ? const AppDrawer() : null,
      body: Stack(
        children: [
          // Spirit ambient radial glows in dark mode
          if (isDark) ...[
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00F5A0).withOpacity(0.12),
                      const Color(0xFF00F5A0).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 350,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0EA5E9).withOpacity(0.08),
                      const Color(0xFF0EA5E9).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(context, isDark),

                  const SizedBox(height: 16),

                  // Student Avatar & Bio Banner
                  _buildStudentHeader(context, isDark),

                  const SizedBox(height: 24),

                  // Personalization Form
                  _buildSectionHeader(context, 'PERSONALIZATION & PREFERENCES', isDark),
                  const SizedBox(height: 12),
                  _buildPersonalizationForm(context, isDark),

                  const SizedBox(height: 24),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        widget.isEditMode ? 'Save Profile Changes' : 'Finish & Start Learning',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : AppColors.lightTeal,
                        foregroundColor: isDark ? const Color(0xFF070B11) : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  if (widget.isStandaloneTab) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('Advanced Settings & Benchmarks'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : AppColors.lightTeal,
                          side: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.18) : AppColors.lightTeal,
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    if (widget.isStandaloneTab) {
      return Row(
        children: [
          Builder(
            builder: (context) => InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
              borderRadius: BorderRadius.circular(21),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.12) : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.menu_rounded,
                  size: 20,
                  color: isDark ? Colors.white : AppColors.lightForeground,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Profile',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.lightForeground,
              letterSpacing: -0.4,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        InkWell(
          onTap: widget.isEditMode ? () => Navigator.pop(context) : _showExitDialog,
          borderRadius: BorderRadius.circular(21),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.12) : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : AppColors.lightForeground,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          widget.isEditMode ? 'Edit Profile' : 'Profile Setup',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.lightForeground,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
      ),
    );
  }

  Widget _buildStudentHeader(BuildContext context, bool isDark) {
    final name = _nameController.text.trim().isEmpty ? 'Student' : _nameController.text.trim();
    final gradeText = _selectedGrade != null ? 'Class $_selectedGrade' : 'High School';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.055) : AppColors.lightCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.09) : AppColors.lightBorder,
          width: 1.1,
        ),
        boxShadow: isDark ? null : AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightSecondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF00F5A0).withOpacity(0.25) : AppColors.lightBorder,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 30,
              color: isDark ? const Color(0xFF00F5A0) : AppColors.lightPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.lightForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        gradeText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF00F5A0) : AppColors.lightPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  Echo Learner',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationForm(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.055) : AppColors.lightCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.09) : AppColors.lightBorder,
          width: 1.1,
        ),
        boxShadow: isDark ? null : AppShadows.card,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Name
            Text(
              'STUDENT NAME',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter student name',
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter your name';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),

            // Grade/Class
            Text(
              'GRADE / CLASS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : AppColors.lightInput,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.09) : AppColors.lightBorder,
                  width: 1.1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGrade,
                  hint: Text(
                    'Select Grade/Class',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                    ),
                  ),
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                  ),
                  dropdownColor: isDark ? const Color(0xFF0E1520) : AppColors.lightCard,
                  items: List.generate(12, (index) => (index + 1).toString()).map((grade) {
                    return DropdownMenuItem(
                      value: grade,
                      child: Text(
                        'Class $grade',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGrade = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Teaching Style
            Text(
              'TEACHING STYLE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : AppColors.lightInput,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.09) : AppColors.lightBorder,
                  width: 1.1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TeachingStyle>(
                  value: _selectedTeachingStyle,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                  ),
                  dropdownColor: isDark ? const Color(0xFF0E1520) : AppColors.lightCard,
                  items: TeachingStyle.values.map((style) {
                    return DropdownMenuItem(
                      value: style,
                      child: Text(
                        style.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTeachingStyle = value;
                      });
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(
                _selectedTeachingStyle.description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Learning Pacing
            Text(
              'LEARNING PACING',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : AppColors.lightInput,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.09) : AppColors.lightBorder,
                  width: 1.1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PacingLevel>(
                  value: _selectedPacingLevel,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                  ),
                  dropdownColor: isDark ? const Color(0xFF0E1520) : AppColors.lightCard,
                  items: PacingLevel.values.map((pacing) {
                    return DropdownMenuItem(
                      value: pacing,
                      child: Text(
                        pacing.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPacingLevel = value;
                      });
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(
                _selectedPacingLevel.description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/honkers_session.dart';
import './widgets/photo_upload_strip_widget.dart';

class AskAQuestionScreen extends StatefulWidget {
  const AskAQuestionScreen({super.key});

  @override
  State<AskAQuestionScreen> createState() => _AskAQuestionScreenState();
}

class _AskAQuestionScreenState extends State<AskAQuestionScreen> {
  // TODO: Replace with Riverpod/Bloc for production
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;
  final List<String> _photoUrls = [];

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final userId = HonkersSession.instance.userId;
    if (userId.isEmpty) {
      setState(() => _isSubmitting = false);
      return;
    }

    final result = await SupabaseService.instance.submitQuestion(
      userId: userId,
      title: _titleController.text.trim(),
      details: _detailsController.text.trim(),
      photoUrls: List<String>.from(_photoUrls),
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _submitted = result != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        title: Text(
          'Ask a Question',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.goldSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.gold.withAlpha(77)),
            ),
            child: Text(
              'AhmedabadHonkers',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.gold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 480 : double.infinity,
            ),
            child: _submitted ? _buildSuccessState() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.goldSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.gold.withAlpha(102),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Question Submitted!',
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your question has been submitted for approval. It will be visible to the AhmedabadHonkers community once approved.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Back to Feed',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.goldSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gold.withAlpha(64)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppTheme.gold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Questions are reviewed by admins before going live.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title field
            _FieldLabel(label: 'Question Title *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              maxLength: 120,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Best misal pav in Navrangpura area?',
                counterStyle: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a question title';
                }
                if (v.trim().length < 10) {
                  return 'Title must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Details field
            _FieldLabel(label: 'Additional Details (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _detailsController,
              maxLines: 5,
              maxLength: 500,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText:
                    'Add context, location, budget, or anything helpful for the community...',
                counterStyle: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // Photo upload
            _FieldLabel(label: 'Photos (up to 5, optional)'),
            const SizedBox(height: 8),
            PhotoUploadStripWidget(
              photos: _photoUrls,
              onAdd: () {
                // TODO: Implement image_picker for production
                if (_photoUrls.length < 5) {
                  setState(() {
                    _photoUrls.add(
                      'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=300',
                    );
                  });
                }
              },
              onRemove: (index) {
                setState(() => _photoUrls.removeAt(index));
              },
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF0A0A0A),
                        ),
                      )
                    : Text(
                        'Submit Question',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A0A0A),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.2,
      ),
    );
  }
}

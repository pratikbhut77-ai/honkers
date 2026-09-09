import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class EditProfileBottomSheetWidget extends StatefulWidget {
  final String initialName;
  final String initialBio;
  final void Function(String name, String bio) onSave;

  const EditProfileBottomSheetWidget({
    required this.initialName,
    required this.initialBio,
    required this.onSave,
    super.key,
  });

  @override
  State<EditProfileBottomSheetWidget> createState() =>
      _EditProfileBottomSheetWidgetState();
}

class _EditProfileBottomSheetWidgetState
    extends State<EditProfileBottomSheetWidget> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _bioController = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    // TODO: Replace with actual API call for production
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        widget.onSave(_nameController.text.trim(), _bioController.text.trim());
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withAlpha(102),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Title
          Text(
            'Edit Profile',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Community: AhmedabadHonkers (cannot be changed)',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                _fieldLabel('Display Name *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: const InputDecoration(hintText: 'Your name'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Bio field
                _fieldLabel('Bio (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  maxLength: 150,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Tell the AhmedabadHonkers community about yourself...',
                    counterStyle: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF0A0A0A),
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A0A0A),
                            ),
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

  Widget _fieldLabel(String label) {
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

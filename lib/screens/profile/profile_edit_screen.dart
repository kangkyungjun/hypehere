import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/community/community_user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/error_localizer.dart';

/// 프로필 편집 화면
///
/// 사용자 정보 수정: 닉네임, 소개글, 프로필 사진
class ProfileEditScreen extends StatefulWidget {
  final CommunityUser user;

  const ProfileEditScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 초기값 설정
    _nicknameController.text = widget.user.nickname;
    _bioController.text = widget.user.bio ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// 이미지 선택 (갤러리)
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).imagePickerFailed}: ${ErrorLocalizer.getMessage(context, e)}')),
        );
      }
    }
  }

  /// 프로필 저장
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await authProvider.updateProfile(
        nickname: _nicknameController.text.trim(),
        bio: _bioController.text.trim(),
        profilePicture: _selectedImage,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // 성공 시 true 반환
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).profileUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        actions: [
          // 저장 버튼
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: AppStroke.medium),
                  )
                : Text(l10n.done, style: const TextStyle(fontWeight: AppTypography.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // 프로필 사진 섹션
            Center(
              child: Stack(
                children: [
                  // 프로필 사진
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: context.mlColors.subtleBorder,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (widget.user.profilePicture != null
                            ? NetworkImage(widget.user.profilePicture!)
                            : null) as ImageProvider?,
                    child: (_selectedImage == null && widget.user.profilePicture == null)
                        ? Icon(Icons.person, size: 64, color: Theme.of(context).colorScheme.outline)
                        : null,
                  ),

                  // 편집 버튼
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        tooltip: l10n.tooltipChangePhoto,
                        icon: Icon(Icons.camera_alt, size: 20, color: context.mlColors.onPrimary),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // 닉네임 입력
            TextFormField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: l10n.nickname,
                hintText: l10n.nicknameHint,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              maxLength: 30,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.nicknameRequired;
                }
                if (value.trim().length < 2) {
                  return l10n.nicknameTooShort;
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // 소개글 입력
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: l10n.bioLabel,
                hintText: l10n.bioHint,
                prefixIcon: const Icon(Icons.edit_note),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 200,
              validator: (value) {
                // 소개글은 선택사항이므로 빈 값도 허용
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.xxl),

            // 안내 텍스트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        l10n.profileEditGuide,
                        style: TextStyle(
                          fontWeight: AppTypography.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '• 닉네임: 2-30자, 다른 사용자와 중복 가능\n'
                    '• 소개글: 최대 200자 (선택사항)\n'
                    '• 프로필 사진: 권장 크기 800x800px',
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

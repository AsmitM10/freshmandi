import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Shared "not designed yet" body for admin tabs whose Figma screens
/// haven't arrived yet (Stats, Parties, Items) — same treatment as the
/// temporary admin home screen was before the Home dashboard shipped.
class AdminPlaceholderScreen extends StatelessWidget {
  const AdminPlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$title screens are coming soon.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.placeholder,
              fontSize: 15,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

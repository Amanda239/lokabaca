
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class PasswordRequirements extends StatelessWidget {
  final String password;
  final String? confirmPassword;
  final bool showConfirmation;

  const PasswordRequirements({
    super.key,
    required this.password,
    this.confirmPassword,
    this.showConfirmation = false,
  });

  @override
  Widget build(BuildContext context) {
    final requirements = [
      _Requirement(
        label: 'Minimal 8 karakter',
        fulfilled: password.length >= 8,
      ),
      _Requirement(
        label: 'Mengandung huruf besar dan huruf kecil',
        fulfilled: RegExp(r'(?=.*[A-Z])(?=.*[a-z])')
            .hasMatch(password),
      ),
      _Requirement(
        label: 'Mengandung minimal 1 angka',
        fulfilled: RegExp(r'[0-9]').hasMatch(password),
      ),
    ];

    if (showConfirmation) {
      requirements.add(
        _Requirement(
          label: 'Password dan konfirmasi harus sesuai',
          fulfilled: password.isNotEmpty &&
              password == (confirmPassword ?? ''),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.cream.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ketentuan Kata Sandi',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          ...requirements.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.fulfilled
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 15,
                    color: item.fulfilled
                        ? Colors.green.shade700
                        : AppColors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.4,
                        color: item.fulfilled
                            ? Colors.green.shade700
                            : AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Requirement {
  final String label;
  final bool fulfilled;

  _Requirement({
    required this.label,
    required this.fulfilled,
  });
}

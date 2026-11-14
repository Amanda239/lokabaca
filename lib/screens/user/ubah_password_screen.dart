
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../core/constants/app_colors.dart';

// class UbahPasswordScreen extends StatefulWidget {
//   const UbahPasswordScreen({super.key});

//   @override
//   State<UbahPasswordScreen> createState() =>
//       _UbahPasswordScreenState();
// }

// class _UbahPasswordScreenState extends State<UbahPasswordScreen> {
//   final SupabaseClient supabase =
//       Supabase.instance.client;

//   final TextEditingController oldPasswordController =
//       TextEditingController();

//   final TextEditingController newPasswordController =
//       TextEditingController();

//   final TextEditingController confirmPasswordController =
//       TextEditingController();

//   bool obscureOldPassword = true;
//   bool obscureNewPassword = true;
//   bool obscureConfirmPassword = true;

//   bool isLoading = false;

//   bool get hasMinLength =>
//       newPasswordController.text.length >= 8;

//   bool get hasUppercase =>
//       newPasswordController.text.contains(
//         RegExp(r'[A-Z]'),
//       );

//   bool get hasNumberAndSymbol =>
//       newPasswordController.text.contains(
//         RegExp(r'[0-9]'),
//       ) &&
//       newPasswordController.text.contains(
//         RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\];]'),
//       );

//   bool get passwordsMatch =>
//       newPasswordController.text ==
//           confirmPasswordController.text &&
//       confirmPasswordController.text.isNotEmpty;

//   @override
//   void initState() {
//     super.initState();

//     newPasswordController.addListener(_refresh);
//     confirmPasswordController.addListener(_refresh);
//   }

//   void _refresh() {
//     if (mounted) {
//       setState(() {});
//     }
//   }

//   @override
//   void dispose() {
//     oldPasswordController.dispose();
//     newPasswordController.dispose();
//     confirmPasswordController.dispose();

//     super.dispose();
//   }

//   void _showMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: AppColors.navy,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   Future<void> _savePassword() async {
//     final oldPassword =
//         oldPasswordController.text.trim();

//     final newPassword =
//         newPasswordController.text.trim();

//     final confirmPassword =
//         confirmPasswordController.text.trim();

//     if (oldPassword.isEmpty ||
//         newPassword.isEmpty ||
//         confirmPassword.isEmpty) {
//       _showMessage(
//         'Semua kolom password wajib diisi.',
//       );
//       return;
//     }

//     if (!hasMinLength ||
//         !hasUppercase ||
//         !hasNumberAndSymbol) {
//       _showMessage(
//         'Password baru belum memenuhi persyaratan.',
//       );
//       return;
//     }

//     if (newPassword != confirmPassword) {
//       _showMessage(
//         'Konfirmasi password tidak sama.',
//       );
//       return;
//     }

//     if (oldPassword == newPassword) {
//       _showMessage(
//         'Password baru harus berbeda dari password lama.',
//       );
//       return;
//     }

//     final user = supabase.auth.currentUser;
//     final email = user?.email;

//     if (user == null || email == null) {
//       _showMessage(
//         'Sesi pengguna tidak ditemukan. Silakan login kembali.',
//       );
//       return;
//     }

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       // VERIFIKASI PASSWORD LAMA
//       await supabase.auth.signInWithPassword(
//         email: email,
//         password: oldPassword,
//       );

//       // UPDATE PASSWORD BARU
//       await supabase.auth.updateUser(
//         UserAttributes(
//           password: newPassword,
//         ),
//       );

//       if (!mounted) return;

//       _showMessage(
//         'Kata sandi berhasil diperbarui.',
//       );

//       Navigator.pop(context, true);
//     } on AuthException catch (e) {
//       if (!mounted) return;

//       _showMessage(
//         e.message.toLowerCase().contains('invalid')
//             ? 'Kata sandi lama tidak sesuai.'
//             : 'Gagal mengganti kata sandi: ${e.message}',
//       );
//     } catch (e) {
//       if (!mounted) return;

//       _showMessage(
//         'Terjadi kesalahan saat mengganti password.',
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   Widget _passwordField({
//     required String hint,
//     required TextEditingController controller,
//     required bool obscure,
//     required VoidCallback onToggle,
//   }) {
//     return Container(
//       height: 44,
//       decoration: BoxDecoration(
//         color: const Color(0xFFFAF5EB),
//         borderRadius: BorderRadius.circular(13),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.20),
//             blurRadius: 4,
//             offset: const Offset(1, 2),
//           ),
//         ],
//       ),
//       child: TextField(
//         controller: controller,
//         obscureText: obscure,
//         style: const TextStyle(
//           fontSize: 13,
//           color: AppColors.navy,
//         ),
//         decoration: InputDecoration(
//           hintText: hint,
//           hintStyle: const TextStyle(
//             color: Colors.black38,
//             fontSize: 12,
//           ),
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 13,
//             vertical: 12,
//           ),
//           border: InputBorder.none,
//           suffixIcon: IconButton(
//             onPressed: onToggle,
//             icon: Icon(
//               obscure
//                   ? Icons.visibility_outlined
//                   : Icons.visibility_off_outlined,
//               color: AppColors.navy,
//               size: 21,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _requirement(
//     String text,
//     bool fulfilled,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 3),
//       child: Row(
//         children: [
//           Icon(
//             fulfilled
//                 ? Icons.check
//                 : Icons.check,
//             color: fulfilled
//                 ? Colors.green
//                 : Colors.grey,
//             size: 17,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(
//                 color: fulfilled
//                     ? Colors.green
//                     : Colors.black45,
//                 fontSize: 11,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // HEADER
//             Padding(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 20,
//                 vertical: 12,
//               ),
//               child: Row(
//                 children: [
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(
//                       Icons.arrow_back_ios_new_rounded,
//                       color: AppColors.navy,
//                       size: 21,
//                     ),
//                   ),
//                   const Expanded(
//                     child: Center(
//                       child: Text(
//                         'Ubah Kata Sandi',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w800,
//                           color: AppColors.navy,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 45),
//                 ],
//               ),
//             ),

//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 34,
//                 ),
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 30),

//                     // LOGO LOKABACA
//                     Center(
//                       child: Image.asset(
//                         'assets/images/lokabaca.png',
//                         width: 160,
//                         height: 160,
//                         fit: BoxFit.contain,
//                         errorBuilder: (_, __, ___) {
//                           return const SizedBox(
//                             width: 160,
//                             height: 160,
//                             child: Icon(
//                               Icons.menu_book_rounded,
//                               size: 100,
//                               color: AppColors.navy,
//                             ),
//                           );
//                         },
//                       ),
//                     ),

//                     const SizedBox(height: 40),

//                     const Text(
//                       'Buat kata sandi yang kuat untuk akunmu.',
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: AppColors.navy,
//                       ),
//                     ),

//                     const SizedBox(height: 14),

//                     // PASSWORD LAMA
//                     _passwordField(
//                       hint: 'Kata Sandi Lama',
//                       controller: oldPasswordController,
//                       obscure: obscureOldPassword,
//                       onToggle: () {
//                         setState(() {
//                           obscureOldPassword =
//                               !obscureOldPassword;
//                         });
//                       },
//                     ),

//                     const SizedBox(height: 32),

//                     // PASSWORD BARU
//                     _passwordField(
//                       hint: 'Kata Sandi Baru',
//                       controller: newPasswordController,
//                       obscure: obscureNewPassword,
//                       onToggle: () {
//                         setState(() {
//                           obscureNewPassword =
//                               !obscureNewPassword;
//                         });
//                       },
//                     ),

//                     const SizedBox(height: 32),

//                     // KONFIRMASI PASSWORD
//                     _passwordField(
//                       hint: 'Konfirmasi Kata Sandi Baru',
//                       controller:
//                           confirmPasswordController,
//                       obscure: obscureConfirmPassword,
//                       onToggle: () {
//                         setState(() {
//                           obscureConfirmPassword =
//                               !obscureConfirmPassword;
//                         });
//                       },
//                     ),

//                     const SizedBox(height: 25),

//                     // PERSYARATAN PASSWORD
//                     _requirement(
//                       'Minimal 8 karakter.',
//                       hasMinLength,
//                     ),

//                     _requirement(
//                       'Sertakan huruf kapital.',
//                       hasUppercase,
//                     ),

//                     _requirement(
//                       'Sertakan angka & simbol.',
//                       hasNumberAndSymbol,
//                     ),

//                     _requirement(
//                       'Kata sandi baru dan konfirmasi harus sama.',
//                       passwordsMatch,
//                     ),

//                     const SizedBox(height: 65),

//                     // TOMBOL SIMPAN
//                     SizedBox(
//                       width: double.infinity,
//                       height: 44,
//                       child: ElevatedButton(
//                         onPressed: isLoading
//                             ? null
//                             : _savePassword,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.navy,
//                           foregroundColor: Colors.white,
//                           elevation: 3,
//                           shape: RoundedRectangleBorder(
//                             borderRadius:
//                                 BorderRadius.circular(13),
//                           ),
//                         ),
//                         child: isLoading
//                             ? const SizedBox(
//                                 width: 22,
//                                 height: 22,
//                                 child:
//                                     CircularProgressIndicator(
//                                   color: Colors.white,
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                             : const Text(
//                                 'Simpan',
//                                 style: TextStyle(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                       ),
//                     ),

//                     const SizedBox(height: 30),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';

/// Visual design is unchanged from the original prototype — only navigation
/// now goes through go_router instead of Navigator.push.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 260,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7F2),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 30,
              top: 110,
              child: Container(
                width: 334,
                height: 334,
                decoration: const BoxDecoration(
                  color: Color(0x264A8754),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 145,
              top: 69,
              child: Container(
                width: 334,
                height: 300,
                decoration: const BoxDecoration(
                  color: Color(0x264A8354),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 55,
              top: 142,
              child: Container(
                width: 334,
                height: 300,
                decoration: const BoxDecoration(
                  color: Color(0x3F4A8754),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 60,
              right: -10,
              child: SizedBox(
                width: 360,
                child: Image.asset(
                  'lib/assets/images/welcome.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 375,
                height: 508,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x15000000),
                        blurRadius: 12,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Partner for',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF242424),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Daily Fresh Supply',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF4A8754),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'FreshMandi bridges the gap between vegetable wholesalers and restaurants through a single digital platform. By replacing manual order lists, phone calls, and spreadsheets with real-time inventory, bulk ordering, and order tracking, FreshMandi simplifies procurement while improving accuracy, transparency, and operational efficiency.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF242424),
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => context.push(AppRoutes.terms),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF355C7D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => context.push(AppRoutes.login),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF355C7D),
                              side: const BorderSide(color: Color(0xFF355C7D)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
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

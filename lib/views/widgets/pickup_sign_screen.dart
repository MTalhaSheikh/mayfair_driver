import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PickupSignScreen extends StatefulWidget {
  final String passengerName;
  final String companyName;

  const PickupSignScreen({
    super.key,
    required this.passengerName,
    this.companyName = 'MayFair Limousine',
  });

  @override
  State<PickupSignScreen> createState() => _PickupSignScreenState();
}

class _PickupSignScreenState extends State<PickupSignScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get safe area top padding for proper close button placement
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Orange strip — left edge
          Container(width: 16, color: const Color(0xFFF97316)),

          // White panel — name rotated 90° counter-clockwise (bottom-to-top)
          Expanded(
            child: Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: RotatedBox(
                quarterTurns: 3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      widget.passengerName,
                      style: const TextStyle(
                        fontSize: 100,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                        letterSpacing: 1,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Black panel — company name + close button
          Container(
            width: 120,
            color: Colors.black,
            child: Stack(
              children: [
                // ✕ close button — more padding from top + safe area
                Positioned(
                  top: topPadding + 32,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // Company name — centered, rotated bottom-to-top
                Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      widget.companyName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 5,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
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

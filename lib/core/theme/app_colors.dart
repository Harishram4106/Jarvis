import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const background = Color(0xFF000000); // True Black
  static const backgroundMid = Color(0xFF050B14); // Very dark navy
  static const backgroundCard = Color(0xFF0A1118); // Dark navy for cards

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const surface = Color(0xFF0E1721); // Slightly lighter navy
  static const surfaceElevated = Color(0xFF141F2D); // Lighter for hovers/elevation
  static const surfaceHighlight = Color(0xFF1C2A3A);

  // ── Accents ───────────────────────────────────────────────────────────────
  static const primaryBlue = Color(0xFF29B6F6); // Bright blue accent
  static const primaryCyan = Color(0xFF00E5FF); // Neon cyan for glows
  static const accentViolet = Color(0xFF7C4DFF);

  // Glow variants
  static const glowBlue = Color(0x3329B6F6);
  static const glowCyan = Color(0x3300E5FF);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFFFFFFF); // White
  static const textSecondary = Color(0xFF90CAF9); // Light blue-grey
  static const textTertiary = Color(0xFF546E7A); // Darker blue-grey
  static const textDisabled = Color(0xFF37474F);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const borderSubtle = Color(0xFF152232); // Dark navy border
  static const borderMid = Color(0xFF1F3247); // Lighter navy border
  static const borderAccent = Color(0xFF29B6F6);

  // ── Status ────────────────────────────────────────────────────────────────
  static const success = Color(0xFF00E676); 
  static const error = Color(0xFFFF3D00); 
  static const warning = Color(0xFFFFC400);

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  static const navBackground = Color(0xFF000000); // Solid black bottom bar
  static const navSelected = Color(0xFF29B6F6);
  static const navUnselected = Color(0xFF546E7A);
}

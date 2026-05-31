import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

String friendlyError(Object error) {
  final raw = error.toString();
  final lower = raw.toLowerCase();
  if (lower.contains('infinite recursion') || lower.contains('42p17') || lower.contains('row-level security') || lower.contains('policy')) {
    return 'We could not save this yet. Please run the latest Supabase migration and try again.';
  }
  if (lower.contains('socket') || lower.contains('host lookup') || lower.contains('network') || lower.contains('clientexception')) {
    return 'Connection issue. Please check your internet connection and try again.';
  }
  if (lower.contains('invalid login') || lower.contains('invalid credentials') || lower.contains('email not confirmed')) {
    return 'Please check your email/password or confirm your email before logging in.';
  }
  if (lower.contains('permission')) {
    return 'Permission is required to continue. Please allow access in your phone settings.';
  }
  if (lower.contains('duplicate') || lower.contains('unique')) {
    return 'This item already exists. Please try another name.';
  }
  return 'Something went wrong. Please try again.';
}

ImageProvider? imageProviderFromValue(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final v = value.trim();
  if (v.startsWith('data:image')) {
    final comma = v.indexOf(',');
    if (comma > 0) {
      try {
        final Uint8List bytes = base64Decode(v.substring(comma + 1));
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }
  }
  if (v.startsWith('http://') || v.startsWith('https://')) {
    return NetworkImage(v);
  }
  return null;
}

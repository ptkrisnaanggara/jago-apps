import 'package:equatable/equatable.dart';

/// A Home "Shortcut" tile (e.g. Kantong Utama, Kirim & Bayar).
class Shortcut extends Equatable {
  final String name;
  final String imageUrl;

  /// Optional amount; `null` hides the amount line (replaces the old
  /// `price == -1` sentinel from the mockup).
  final double? amount;

  const Shortcut({
    required this.name,
    required this.imageUrl,
    this.amount,
  });

  @override
  List<Object?> get props => [name, imageUrl, amount];
}

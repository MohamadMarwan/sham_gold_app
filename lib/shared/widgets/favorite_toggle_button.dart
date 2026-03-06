import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/favorites_service.dart';
import '../../core/constants/app_colors.dart';

class FavoriteToggleButton extends StatefulWidget {
  final String priceId;
  final double size;

  const FavoriteToggleButton({
    super.key,
    required this.priceId,
    this.size = 24,
  });

  @override
  State<FavoriteToggleButton> createState() => _FavoriteToggleButtonState();
}

class _FavoriteToggleButtonState extends State<FavoriteToggleButton> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final status = await _favoritesService.isFavorite(widget.priceId);
    if (mounted) {
      setState(() => _isFavorite = status);
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.mediumImpact();
    await _favoritesService.toggleFavorite(widget.priceId);
    setState(() => _isFavorite = !_isFavorite);

    // Optional: Show a snackbar or small overlay
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isFavorite ? 'تمت الإضافة للمفضلة' : 'تمت الإزالة من المفضلة'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          width: 200,
          backgroundColor: AppColors.darkGreen.withValues(alpha: 0.9),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggleFavorite,
      icon: Icon(
        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color:
            _isFavorite ? Colors.redAccent : Colors.grey.withValues(alpha: 0.5),
        size: widget.size,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: 20,
    );
  }
}

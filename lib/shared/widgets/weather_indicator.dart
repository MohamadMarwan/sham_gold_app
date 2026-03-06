import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/app_colors.dart';

class WeatherIndicator extends StatefulWidget {
  const WeatherIndicator({super.key});

  @override
  State<WeatherIndicator> createState() => _WeatherIndicatorState();
}

class _WeatherIndicatorState extends State<WeatherIndicator> {
  String _temp = '--';
  bool _isDay = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      // Damascus Coordinates
      const lat = '33.5138';
      const lon = '36.2765';
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,is_day&timezone=auto');

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        if (mounted) {
          setState(() {
            _temp = current['temperature_2m'].round().toString();
            _isDay = current['is_day'] == 1;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Weather Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _temp == '--') {
      return const SizedBox(
        width: 80,
        height: 32,
        child: Center(
            child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white70))),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            color: _isDay ? AppColors.gold : Colors.lightBlueAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'دمشق: $_temp°C',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

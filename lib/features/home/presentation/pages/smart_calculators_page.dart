import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../core/services/calculators_service.dart';
import '../../../../shared/models/savings_goal_model.dart';
import '../../../../core/services/savings_goal_service.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/widgets/premium_logo.dart';

class SmartCalculatorsPage extends ConsumerStatefulWidget {
  const SmartCalculatorsPage({super.key});

  @override
  ConsumerState<SmartCalculatorsPage> createState() => _SmartCalculatorsPageState();
}

class _SmartCalculatorsPageState extends ConsumerState<SmartCalculatorsPage> {
  int? _selectedCalculatorIndex;

  // Controllers - Zakat
  final _zakat24Controller = TextEditingController();
  final _zakat21Controller = TextEditingController();
  final _zakat18Controller = TextEditingController();
  final _zakatSilverController = TextEditingController();
  bool _includeJewelry = false;
  Map<String, dynamic>? _zakatResult;

  // Controllers - Making Charge & Scrap
  final _itemWeightController = TextEditingController();
  final _goldGramPriceController = TextEditingController();
  final _makingChargeController = TextEditingController();
  final _vatPercentController = TextEditingController(text: '0');
  Map<String, dynamic>? _makingResult;

  // Scrap
  final _scrapWeightController = TextEditingController();
  final _scrapPriceController = TextEditingController();
  final _stoneDeductionController = TextEditingController(text: '0');
  Map<String, dynamic>? _scrapResult;

  // Controllers - Unit Converter
  final _convertAmountController = TextEditingController(text: '1');
  String _fromUnit = 'ounce';
  Map<String, double>? _conversionResult;

  // Controllers - ROI
  final _investmentAmountController = TextEditingController();
  final _buyPriceRoiController = TextEditingController();
  final _currentPriceRoiController = TextEditingController();
  Map<String, dynamic>? _roiResult;

  // Controllers - Savings Goal Planner
  final _goalTitleController = TextEditingController();
  final _goalTargetAmountController = TextEditingController();
  final _goalInitialSavedController = TextEditingController(text: '0');
  int _goalDurationMonths = 12;
  bool _isGoalTargetInGrams = true;
  final String _goalCategory = 'marriage';
  Map<String, dynamic>? _savingsPlanResult;
  final SavingsGoalService _savingsService = SavingsGoalService();

  @override
  void initState() {
    super.initState();

    _savingsService.initialize().then((_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillLivePrices();
      _runConversion();
    });
  }

  void _prefillLivePrices() {
    final priceService = ref.read(priceServiceProvider);
    final allPrices = priceService.currentPrices;

    final p24 = allPrices.where((p) => p.id.contains('24') || p.id == 'xau_usd').firstOrNull;
    if (p24 != null && p24.buyPrice > 0) {
      final gram24 = p24.id == 'xau_usd' ? (p24.buyPrice / 31.1035) : p24.buyPrice;
      _goldGramPriceController.text = gram24.toStringAsFixed(2);
      _scrapPriceController.text = (gram24 * 0.97).toStringAsFixed(2);
      _currentPriceRoiController.text = gram24.toStringAsFixed(2);
    }
  }

  void _runConversion() {
    final amount = double.tryParse(_convertAmountController.text) ?? 1.0;
    setState(() {
      _conversionResult = CalculatorsService.convertWeight(amount: amount, fromUnit: _fromUnit);
    });
  }

  @override
  void dispose() {
    _zakat24Controller.dispose();
    _zakat21Controller.dispose();
    _zakat18Controller.dispose();
    _zakatSilverController.dispose();
    _itemWeightController.dispose();
    _goldGramPriceController.dispose();
    _makingChargeController.dispose();
    _vatPercentController.dispose();
    _scrapWeightController.dispose();
    _scrapPriceController.dispose();
    _stoneDeductionController.dispose();
    _convertAmountController.dispose();
    _investmentAmountController.dispose();
    _buyPriceRoiController.dispose();
    _currentPriceRoiController.dispose();
    _goalTitleController.dispose();
    _goalTargetAmountController.dispose();
    _goalInitialSavedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countryProvider = ref.watch(countryProvider);
    final country = countryProvider.selectedCountry;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _selectedCalculatorIndex == null
          ? _buildHub(isDark)
          : _buildSelectedCalculator(isDark, country),
    );
  }

  Widget _buildHub(bool isDark) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppColors.darkGreen,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            titlePadding: const EdgeInsets.only(bottom: 20),
            title: Text(
              'smart_calculators'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 22,
                fontFamily: 'Cairo',
                shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
              ),
            ),
            background: Container(
              decoration: BoxDecoration(gradient: AppColors.emeraldGradient),
              child: const Center(
                child: PremiumLogo(size: 100, isBackground: true),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildCalculatorCard(
                title: 'zakat_calculator'.tr(),
                subtitle: 'zakat_calculator_desc'.tr(),
                icon: Icons.scale_rounded,
                color: const Color(0xFF10B981),
                onTap: () => setState(() => _selectedCalculatorIndex = 0),
                isDark: isDark,
              ),
              SizedBox(height: 16),
              _buildCalculatorCard(
                title: 'making_charge_calculator'.tr(),
                subtitle: 'making_charge_desc'.tr(),
                icon: Icons.diamond_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () => setState(() => _selectedCalculatorIndex = 1),
                isDark: isDark,
              ),
              SizedBox(height: 16),
              _buildCalculatorCard(
                title: 'weight_converter'.tr(),
                subtitle: 'weight_converter_desc'.tr(),
                icon: Icons.swap_horiz_rounded,
                color: const Color(0xFF3B82F6),
                onTap: () => setState(() => _selectedCalculatorIndex = 2),
                isDark: isDark,
              ),
              SizedBox(height: 16),
              _buildCalculatorCard(
                title: 'roi_calculator'.tr(),
                subtitle: 'roi_calculator_desc'.tr(),
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () => setState(() => _selectedCalculatorIndex = 3),
                isDark: isDark,
              ),
              SizedBox(height: 16),
              _buildCalculatorCard(
                title: 'auto_str_269'.tr(),
                subtitle: 'auto_str_040'.tr(),
                icon: Icons.track_changes_rounded,
                color: const Color(0xFFEC4899),
                onTap: () => setState(() => _selectedCalculatorIndex = 4),
                isDark: isDark,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatorCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.darkGreen,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.mutedText, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCalculator(bool isDark, dynamic country) {
    Widget content;
    String title;

    switch (_selectedCalculatorIndex) {
      case 0:
        title = 'auto_str_225'.tr();
        content = _buildZakatTab(isDark, country);
        break;
      case 1:
        title = 'auto_str_183'.tr();
        content = _buildMakingAndScrapTab(isDark, country);
        break;
      case 2:
        title = 'auto_str_244'.tr();
        content = _buildUnitConverterTab(isDark);
        break;
      case 3:
        title = 'auto_str_159'.tr();
        content = _buildRoiTab(isDark, country);
        break;
      case 4:
        title = 'auto_str_245'.tr();
        content = _buildSavingsGoalTab(isDark, country);
        break;
      default:
        content = SizedBox();
        title = '';
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
          decoration: BoxDecoration(gradient: AppColors.emeraldGradient),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCalculatorIndex = null);
                },
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 48), // Balance the icon button
            ],
          ),
        ),
        Expanded(child: content),
      ],
    );
  }

  // --- 1. Zakat Tab ---
  Widget _buildZakatTab(bool isDark, dynamic country) {
    final priceService = ref.watch(priceServiceProvider);
    final allPrices = priceService.currentPrices;
    final p24 = allPrices.where((p) => p.id.contains('24') || p.id == 'xau_usd').firstOrNull;
    final double gram24 = p24 != null ? (p24.id == 'xau_usd' ? p24.buyPrice / 31.1035 : p24.buyPrice) : 85.0;

    final numberFormat = NumberFormat('#,##0.##', 'ar');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(
            title: 'auto_str_054'.tr(),
            subtitle: 'auto_str_021'.tr(),
          ),
          SizedBox(height: 16),
          _buildInputField('auto_str_142'.tr(), _zakat24Controller, isDark),
          _buildInputField('auto_str_141'.tr(), _zakat21Controller, isDark),
          _buildInputField('auto_str_140'.tr(), _zakat18Controller, isDark),
          _buildInputField('auto_str_121'.tr(), _zakatSilverController, isDark),
          SwitchListTile.adaptive(
            title: Text('auto_str_056'.tr(), style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
            value: _includeJewelry,
            activeThumbColor: AppColors.gold,
            onChanged: (val) => setState(() => _includeJewelry = val),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                final g24 = double.tryParse(_zakat24Controller.text) ?? 0;
                final g21 = double.tryParse(_zakat21Controller.text) ?? 0;
                final g18 = double.tryParse(_zakat18Controller.text) ?? 0;
                final sil = double.tryParse(_zakatSilverController.text) ?? 0;

                setState(() {
                  _zakatResult = CalculatorsService.calculateZakat(
                    grams24k: g24,
                    grams22k: 0,
                    grams21k: g21,
                    grams18k: g18,
                    silverGrams: sil,
                    price24kPerGram: gram24,
                    silverPricePerGram: 1.1,
                    includeJewelry: _includeJewelry,
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('auto_str_149'.tr(), style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo', fontSize: 14)),
            ),
          ),
          if (_zakatResult != null) ...[
            SizedBox(height: 18),
            _buildResultCard(
              title: _zakatResult!['isGoldNisabReached'] ? 'auto_str_161'.tr() : 'auto_str_129'.tr(),
              items: [
                {'label': 'auto_str_136'.tr(), 'value': '${(_zakatResult!['totalEquivalent24k'] as double).toStringAsFixed(1)} ${'auto_str_050'.tr()}'},
                {'label': 'auto_str_122'.tr(), 'value': '${numberFormat.format(_zakatResult!['goldTotalValue'])} ${country.currencySymbol}'},
                {'label': 'auto_str_104'.tr(), 'value': '${(_zakatResult!['goldZakatGrams'] as double).toStringAsFixed(1)} ${'auto_str_044'.tr()}'},
                {'label': 'auto_str_092'.tr(), 'value': '${numberFormat.format(_zakatResult!['totalZakatDue'])} ${country.currencySymbol}'},
              ],
              isHighlight: _zakatResult!['isGoldNisabReached'],
            ),
          ],
        ],
      ),
    );
  }

  // --- 2. Making Charge & Scrap Tab ---
  Widget _buildMakingAndScrapTab(bool isDark, dynamic country) {
    final numberFormat = NumberFormat('#,##0.##', 'ar');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(
            title: 'auto_str_034'.tr(),
            subtitle: 'auto_str_027'.tr(),
          ),
          SizedBox(height: 16),
          _buildInputField('auto_str_194'.tr(), _itemWeightController, isDark),
          _buildInputField('سعر غرام الذهب الخام (${country.currencySymbol})', _goldGramPriceController, isDark),
          _buildInputField('أجرة المصنعية للغرام الواحد (${country.currencySymbol})', _makingChargeController, isDark),
          _buildInputField('auto_str_079'.tr(), _vatPercentController, isDark),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                final w = double.tryParse(_itemWeightController.text) ?? 0;
                final gp = double.tryParse(_goldGramPriceController.text) ?? 0;
                final mc = double.tryParse(_makingChargeController.text) ?? 0;
                final vat = double.tryParse(_vatPercentController.text) ?? 0;

                setState(() {
                  _makingResult = CalculatorsService.calculateJewelryCost(
                    weightGrams: w,
                    goldPricePerGram: gp,
                    makingChargePerGram: mc,
                    vatPercent: vat,
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('auto_str_084'.tr(), style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo', fontSize: 14)),
            ),
          ),
          if (_makingResult != null) ...[
            SizedBox(height: 18),
            _buildResultCard(
              title: 'auto_str_127'.tr(),
              items: [
                {'label': 'auto_str_192'.tr(), 'value': '${numberFormat.format(_makingResult!['rawGoldCost'])} ${country.currencySymbol}'},
                {'label': 'auto_str_158'.tr(), 'value': '${numberFormat.format(_makingResult!['totalMakingCharge'])} ${country.currencySymbol}'},
                {'label': 'auto_str_139'.tr(), 'value': '${(_makingResult!['makingRatio'] as double).toStringAsFixed(1)}%'},
                {'label': 'auto_str_086'.tr(), 'value': '${numberFormat.format(_makingResult!['totalCost'])} ${country.currencySymbol}'},
              ],
              isHighlight: true,
            ),
          ],
          const Divider(height: 36),
          _buildInfoBanner(
            title: 'auto_str_052'.tr(),
            subtitle: 'auto_str_026'.tr(),
          ),
          SizedBox(height: 16),
          _buildInputField('auto_str_051'.tr(), _scrapWeightController, isDark),
          _buildInputField('سعر شراء الكسر للغرام (${country.currencySymbol})', _scrapPriceController, isDark),
          _buildInputField('auto_str_059'.tr(), _stoneDeductionController, isDark),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                final w = double.tryParse(_scrapWeightController.text) ?? 0;
                final sp = double.tryParse(_scrapPriceController.text) ?? 0;
                final st = double.tryParse(_stoneDeductionController.text) ?? 0;

                setState(() {
                  _scrapResult = CalculatorsService.calculateScrapGoldSale(
                    weightGrams: w,
                    scrapPricePerGram: sp,
                    stoneDeductionGrams: st,
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('auto_str_150'.tr(), style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo', fontSize: 14)),
            ),
          ),
          if (_scrapResult != null) ...[
            SizedBox(height: 18),
            _buildResultCard(
              title: 'auto_str_130'.tr(),
              items: [
                {'label': 'auto_str_171'.tr(), 'value': '${(_scrapResult!['netWeight'] as double).toStringAsFixed(1)} ${'auto_str_050'.tr()}'},
                {'label': 'auto_str_117'.tr(), 'value': '${numberFormat.format(_scrapResult!['totalPayout'])} ${country.currencySymbol}'},
              ],
              isHighlight: false,
            ),
          ],
        ],
      ),
    );
  }

  // --- 3. Unit Converter Tab ---
  Widget _buildUnitConverterTab(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(
            title: 'auto_str_060'.tr(),
            subtitle: 'auto_str_016'.tr(),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildInputField('auto_str_339'.tr(), _convertAmountController, isDark),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _fromUnit,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    decoration: InputDecoration(
                      labelText: 'auto_str_238'.tr(),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: [
                      DropdownMenuItem(value: 'gram', child: Text('auto_str_319'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'ounce', child: Text('auto_str_247'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'tola', child: Text('auto_str_254'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'mithqal', child: Text('auto_str_297'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'english', child: Text('auto_str_176'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'rashadi', child: Text('auto_str_209'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'kilo', child: Text('auto_str_208'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _fromUnit = val;
                          _runConversion();
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _runConversion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('auto_str_162'.tr(), style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo', fontSize: 14)),
            ),
          ),
          if (_conversionResult != null) ...[
            SizedBox(height: 18),
            _buildResultCard(
              title: 'auto_str_070'.tr(),
              items: [
                {'label': 'auto_str_333'.tr(), 'value': '${_conversionResult!['gram']} ${'auto_str_097'.tr()}'},
                {'label': 'auto_str_126'.tr(), 'value': '${_conversionResult!['ounce']} ${'auto_str_089'.tr()}'},
                {'label': 'auto_str_316'.tr(), 'value': '${_conversionResult!['mithqal']} ${'auto_str_088'.tr()}'},
                {'label': 'auto_str_239'.tr(), 'value': '${_conversionResult!['tola']} ${'auto_str_096'.tr()}'},
                {'label': 'auto_str_118'.tr(), 'value': '${_conversionResult!['english']} ${'auto_str_095'.tr()}'},
                {'label': 'auto_str_063'.tr(), 'value': '${_conversionResult!['rashadi']} ${'auto_str_095'.tr()}'},
                {'label': 'auto_str_274'.tr(), 'value': '${_conversionResult!['kilo']} ${'auto_str_107'.tr()}'},
              ],
              isHighlight: true,
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. ROI Tab ---
  Widget _buildRoiTab(bool isDark, dynamic country) {
    final numberFormat = NumberFormat('#,##0.##', 'ar');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(
            title: 'auto_str_064'.tr(),
            subtitle: 'auto_str_023'.tr(),
          ),
          SizedBox(height: 16),
          _buildInputField('إجمالي رأس المال المستثمر (${country.currencySymbol})', _investmentAmountController, isDark),
          _buildInputField('auto_str_110'.tr(), _buyPriceRoiController, isDark),
          _buildInputField('auto_str_146'.tr(), _currentPriceRoiController, isDark),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                final inv = double.tryParse(_investmentAmountController.text) ?? 0;
                final buyP = double.tryParse(_buyPriceRoiController.text) ?? 0;
                final curP = double.tryParse(_currentPriceRoiController.text) ?? 0;

                setState(() {
                  _roiResult = CalculatorsService.calculateInvestmentReturn(
                    initialInvestment: inv,
                    buyGoldPrice: buyP,
                    currentGoldPrice: curP,
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('auto_str_113'.tr(), style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo', fontSize: 14)),
            ),
          ),
          if (_roiResult != null) ...[
            SizedBox(height: 18),
            _buildResultCard(
              title: _roiResult!['isProfit'] ? 'auto_str_231'.tr() : 'auto_str_186'.tr(),
              items: [
                {'label': 'auto_str_167'.tr(), 'value': '${(_roiResult!['gramsBought'] as double).toStringAsFixed(1)} ${'auto_str_050'.tr()}'},
                {'label': 'auto_str_116'.tr(), 'value': '${numberFormat.format(_roiResult!['currentValue'])} ${country.currencySymbol}'},
                {'label': 'auto_str_155'.tr(), 'value': '${numberFormat.format(_roiResult!['netProfit'])} ${country.currencySymbol}'},
                {'label': 'auto_str_112'.tr(), 'value': '${(_roiResult!['roiPercent'] as double).toStringAsFixed(2)}%'},
              ],
              isHighlight: _roiResult!['isProfit'],
            ),
          ],
        ],
      ),
    );
  }

  // --- 5. Gold Savings Goal Planner & DCA Tab (المقترح 3) ---
  Widget _buildSavingsGoalTab(bool isDark, dynamic country) {
    final priceService = ref.watch(priceServiceProvider);
    final allPrices = priceService.currentPrices;
    final p24 = allPrices.where((p) => p.id.contains('24') || p.id == 'xau_usd').firstOrNull;
    final double gram24 = p24 != null ? (p24.id == 'xau_usd' ? p24.buyPrice / 31.1035 : p24.buyPrice) : 85.0;

    final numberFormat = NumberFormat('#,##0.##', 'ar');
    final activeGoals = _savingsService.goals;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(
            title: 'auto_str_031'.tr(),
            subtitle: 'auto_str_010'.tr(),
          ),
          SizedBox(height: 16),

          // Planner Form Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131B2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'auto_str_072'.tr(),
                  style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Cairo', fontSize: 15, color: AppColors.gold),
                ),
                SizedBox(height: 12),

                // Target Type Switch (Grams vs Currency)
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text('auto_str_169'.tr(), style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold))),
                        selected: _isGoalTargetInGrams,
                        selectedColor: AppColors.gold.withValues(alpha: 0.2),
                        onSelected: (val) => setState(() => _isGoalTargetInGrams = true),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text('الهدف بالمبلغ (${country.currencySymbol}) 💵', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold))),
                        selected: !_isGoalTargetInGrams,
                        selectedColor: AppColors.gold.withValues(alpha: 0.2),
                        onSelected: (val) => setState(() => _isGoalTargetInGrams = false),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                _buildInputField(
                  _isGoalTargetInGrams ? 'auto_str_125'.tr() : 'المبلغ المستهدف (${country.currencySymbol})',
                  _goalTargetAmountController,
                  isDark,
                ),

                _buildInputField('auto_str_049'.tr(), _goalInitialSavedController, isDark),

                // Duration Selector
                Text('auto_str_098'.tr(), style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedText)),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDurationChip(6, 'auto_str_336'.tr()),
                    _buildDurationChip(12, 'auto_str_306'.tr()),
                    _buildDurationChip(24, 'auto_str_355'.tr()),
                    _buildDurationChip(36, 'auto_str_323'.tr()),
                    _buildDurationChip(60, 'auto_str_324'.tr()),
                  ],
                ),

                SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      final targetAmt = double.tryParse(_goalTargetAmountController.text) ?? 0;
                      final initialSaved = double.tryParse(_goalInitialSavedController.text) ?? 0;

                      setState(() {
                        _savingsPlanResult = CalculatorsService.calculateSavingsGoalPlan(
                          targetAmount: targetAmt,
                          isTargetInGrams: _isGoalTargetInGrams,
                          currentGoldPricePerGram: gram24,
                          durationMonths: _goalDurationMonths,
                          initialSavingsGrams: initialSaved,
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('auto_str_076'.tr(), style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo', fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),

          // Plan Calculation Result
          if (_savingsPlanResult != null) ...[
            SizedBox(height: 18),
            _buildResultCard(
              title: 'auto_str_091'.tr(),
              items: [
                {'label': 'auto_str_237'.tr(), 'value': '${(_savingsPlanResult!['totalTargetGrams'] as double).toStringAsFixed(1)} ${'auto_str_050'.tr()}'},
                {'label': 'auto_str_132'.tr(), 'value': '${(_savingsPlanResult!['monthlyGramsNeeded'] as double).toStringAsFixed(1)} ${'auto_str_042'.tr()}'},
                {'label': 'auto_str_114'.tr(), 'value': '${(_savingsPlanResult!['weeklyGramsNeeded'] as double).toStringAsFixed(1)} ${'auto_str_039'.tr()}'},
                {'label': 'auto_str_134'.tr(), 'value': '${numberFormat.format(_savingsPlanResult!['monthlyCostEstimate'])} ${country.currencySymbol}'},
                {'label': 'auto_str_046'.tr(), 'value': '${numberFormat.format(_savingsPlanResult!['futureTargetValue'])} ${country.currencySymbol}'},
              ],
              isHighlight: true,
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCreateGoalDialog(context, gram24, country),
                icon: const Icon(Icons.bookmark_add_rounded, color: AppColors.gold),
                label: Text('auto_str_065'.tr(), style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.gold, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],

          SizedBox(height: 24),

          // 2. Active Savings Goals Tracker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أهدافي الادخارية النشطة (${activeGoals.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.primaryText,
                  fontFamily: 'Cairo',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_rounded, color: AppColors.gold, size: 28),
                onPressed: () => _showCreateGoalDialog(context, gram24, country),
                tooltip: 'auto_str_229'.tr(),
              ),
            ],
          ),

          SizedBox(height: 12),

          if (activeGoals.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.flag_rounded, size: 40, color: AppColors.gold),
                    SizedBox(height: 10),
                    Text(
                      'auto_str_087'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'auto_str_033'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mutedText, fontFamily: 'Cairo', fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ...activeGoals.map((goal) => _buildGoalTrackerCard(goal, isDark, country, numberFormat)),
        ],
      ),
    );
  }

  Widget _buildDurationChip(int months, String label) {
    final isSelected = _goalDurationMonths == months;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _goalDurationMonths = months);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.gold : Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFamily: 'Cairo',
            color: isSelected ? Colors.white : AppColors.mutedText,
          ),
        ),
      ),
    );
  }

  Widget _buildGoalTrackerCard(SavingsGoalModel goal, bool isDark, dynamic country, NumberFormat numberFormat) {
    final progress = goal.progressPercentage;
    final isCompleted = progress >= 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isCompleted ? const Color(0xFF00E676) : (isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFF00E676).withValues(alpha: 0.15) : AppColors.gold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle_rounded : Icons.savings_rounded,
                      color: isCompleted ? const Color(0xFF00E676) : AppColors.gold,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Cairo', fontSize: 14)),
                      Text(
                        'المستهدف: ${goal.targetGrams.toStringAsFixed(1)} غرام (${goal.durationMonths} شهر)',
                        style: const TextStyle(color: AppColors.mutedText, fontSize: 11, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _savingsService.removeGoal(goal.id);
                  setState(() {});
                },
              ),
            ],
          ),
          SizedBox(height: 12),

          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المنجز: ${goal.currentGrams.toStringAsFixed(1)} غرام', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${progress.toStringAsFixed(1)}%', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w900, color: isCompleted ? const Color(0xFF00E676) : AppColors.gold)),
            ],
          ),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? const Color(0xFF00E676) : AppColors.gold),
            ),
          ),

          SizedBox(height: 12),

          // Action: Add Contribution
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCompleted ? 'auto_str_080'.tr() : 'المتبقي: ${goal.remainingGrams.toStringAsFixed(1)} غرام',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Cairo',
                  color: isCompleted ? const Color(0xFF00E676) : AppColors.mutedText,
                ),
              ),
              if (!isCompleted)
                ElevatedButton.icon(
                  onPressed: () => _showAddGramsDialog(context, goal),
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  label: Text('auto_str_246'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context, double currentGoldPrice, dynamic country) {
    final titleCtrl = TextEditingController(text: _goalTitleController.text.isNotEmpty ? _goalTitleController.text : 'auto_str_180'.tr());
    final gramsCtrl = TextEditingController(text: _savingsPlanResult != null ? (_savingsPlanResult!['totalTargetGrams'] as double).toStringAsFixed(1) : '50');
    final initialCtrl = TextEditingController(text: _goalInitialSavedController.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('auto_str_123'.tr(), style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(labelText: 'auto_str_105'.tr(), labelStyle: const TextStyle(fontFamily: 'Cairo')),
              ),
              SizedBox(height: 10),
              TextField(
                controller: gramsCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'auto_str_109'.tr(), labelStyle: const TextStyle(fontFamily: 'Cairo')),
              ),
              SizedBox(height: 10),
              TextField(
                controller: initialCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'auto_str_099'.tr(), labelStyle: const TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('auto_str_349'.tr(), style: TextStyle(fontFamily: 'Cairo', color: AppColors.mutedText)),
          ),
          ElevatedButton(
            onPressed: () {
              final targetG = double.tryParse(gramsCtrl.text) ?? 50.0;
              final currentG = double.tryParse(initialCtrl.text) ?? 0.0;
              final title = titleCtrl.text.isNotEmpty ? titleCtrl.text : 'auto_str_272'.tr();

              final newGoal = SavingsGoalModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title,
                category: _goalCategory,
                targetGrams: targetG,
                currentGrams: currentG,
                durationMonths: _goalDurationMonths,
                karat: '24',
                currency: country.currencySymbol,
                targetCurrencyAmount: targetG * currentGoldPrice,
                createdAt: DateTime.now(),
                targetDate: DateTime.now().add(Duration(days: _goalDurationMonths * 30)),
              );

              _savingsService.addGoal(newGoal);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('auto_str_083'.tr(), style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.darkGreen),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('auto_str_302'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _showAddGramsDialog(BuildContext context, SavingsGoalModel goal) {
    final addCtrl = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('إضافة ادخار لـ "${goal.title}"', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('auto_str_032'.tr(), style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.mutedText)),
            SizedBox(height: 12),
            TextField(
              controller: addCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'auto_str_160'.tr(),
                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                suffixText: 'auto_str_363'.tr(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('auto_str_349'.tr(), style: TextStyle(fontFamily: 'Cairo', color: AppColors.mutedText)),
          ),
          ElevatedButton(
            onPressed: () {
              final added = double.tryParse(addCtrl.text) ?? 0.0;
              if (added > 0) {
                _savingsService.addContribution(goal.id, added);
                Navigator.pop(ctx);
                setState(() {});
                HapticFeedback.heavyImpact();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text('auto_str_224'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          filled: true,
          fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildInfoBanner({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold, fontFamily: 'Cairo', fontSize: 14)),
                SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedText, fontFamily: 'Cairo', height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({required String title, required List<Map<String, String>> items, bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isHighlight ? AppColors.gold : const Color(0xFFE2E8F0), width: isHighlight ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: isHighlight ? AppColors.gold : AppColors.primaryText, fontFamily: 'Cairo', fontSize: 16)),
          SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['label']!, style: TextStyle(color: isHighlight ? Colors.white70 : AppColors.mutedText, fontFamily: 'Cairo', fontSize: 13)),
                    Text(item['value']!, style: TextStyle(color: isHighlight ? Colors.white : AppColors.primaryText, fontWeight: FontWeight.w900, fontFamily: 'Cairo', fontSize: 14)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

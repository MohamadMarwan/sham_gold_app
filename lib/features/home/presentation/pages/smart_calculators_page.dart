import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../core/services/calculators_service.dart';
import '../../../../shared/models/savings_goal_model.dart';
import '../../../../core/services/savings_goal_service.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/widgets/premium_logo.dart';

class SmartCalculatorsPage extends StatefulWidget {
  const SmartCalculatorsPage({super.key});

  @override
  State<SmartCalculatorsPage> createState() => _SmartCalculatorsPageState();
}

class _SmartCalculatorsPageState extends State<SmartCalculatorsPage> {
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
    final priceService = Provider.of<PriceService>(context, listen: false);
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
    final countryProvider = Provider.of<CountryProvider>(context);
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
            title: const Text(
              'الآلات الحاسبة الذكية',
              style: TextStyle(
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
                title: 'حاسبة الزكاة',
                subtitle: 'احسب النصاب والزكاة المستحقة على الذهب والفضة بسهولة',
                icon: Icons.scale_rounded,
                color: const Color(0xFF10B981),
                onTap: () => setState(() => _selectedCalculatorIndex = 0),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildCalculatorCard(
                title: 'حاسبة المصنعية والكسر',
                subtitle: 'التكلفة الإجمالية للقطع الجديدة وتقدير سعر الكسر',
                icon: Icons.diamond_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () => setState(() => _selectedCalculatorIndex = 1),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildCalculatorCard(
                title: 'محول الأوزان',
                subtitle: 'تحويل سريع بين الأونصة والغرام والليرات والمثقال',
                icon: Icons.swap_horiz_rounded,
                color: const Color(0xFF3B82F6),
                onTap: () => setState(() => _selectedCalculatorIndex = 2),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildCalculatorCard(
                title: 'حاسبة العائد الاستثماري',
                subtitle: 'مقارنة سعر الشراء بالسعر الحالي لمعرفة نسبة الأرباح',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () => setState(() => _selectedCalculatorIndex = 3),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildCalculatorCard(
                title: 'مخطط الادخار',
                subtitle: 'ضع هدفاً للادخار بالذهب وتتبع خطتك نحو تحقيقه',
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
            const SizedBox(width: 20),
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
                  const SizedBox(height: 4),
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
        title = 'حاسبة الزكاة ⚖️';
        content = _buildZakatTab(isDark, country);
        break;
      case 1:
        title = 'المصنعية والكسر 💎';
        content = _buildMakingAndScrapTab(isDark, country);
        break;
      case 2:
        title = 'محول الأوزان 🔄';
        content = _buildUnitConverterTab(isDark);
        break;
      case 3:
        title = 'العائد الاستثماري 📈';
        content = _buildRoiTab(isDark, country);
        break;
      case 4:
        title = 'مخطط الادخار 🎯';
        content = _buildSavingsGoalTab(isDark, country);
        break;
      default:
        content = const SizedBox();
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
              const SizedBox(width: 48), // Balance the icon button
            ],
          ),
        ),
        Expanded(child: content),
      ],
    );
  }

  // --- 1. Zakat Tab ---
  Widget _buildZakatTab(bool isDark, dynamic country) {
    final priceService = Provider.of<PriceService>(context);
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
            title: 'نصاب الذهب الشرعي: 85 غرام (عيار 24)',
            subtitle: 'يتم احتساب زكاة الذهب بنسبة 2.5% بعد تحويل كافة العيارات إلى ما يعادلها من الذهب الخالص.',
          ),
          const SizedBox(height: 16),
          _buildInputField('وزن ذهب عيار 24 (غرام)', _zakat24Controller, isDark),
          _buildInputField('وزن ذهب عيار 21 (غرام)', _zakat21Controller, isDark),
          _buildInputField('وزن ذهب عيار 18 (غرام)', _zakat18Controller, isDark),
          _buildInputField('وزن الفضة الخالصة (غرام)', _zakatSilverController, isDark),
          SwitchListTile.adaptive(
            title: const Text('احتساب ذهب الزينة والحلية المستعملة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
            value: _includeJewelry,
            activeThumbColor: AppColors.gold,
            onChanged: (val) => setState(() => _includeJewelry = val),
          ),
          const SizedBox(height: 12),
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
              child: const Text('احسب الزكاة المستحقة', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo', fontSize: 14)),
            ),
          ),
          if (_zakatResult != null) ...[
            const SizedBox(height: 18),
            _buildResultCard(
              title: _zakatResult!['isGoldNisabReached'] ? 'بلغ النصاب الشرعي ✅' : 'لم يبلغ النصاب الشرعي ❌',
              items: [
                {'label': 'الوزن المكافئ لعيار 24', 'value': '${(_zakatResult!['totalEquivalent24k'] as double).toStringAsFixed(2)} غرام'},
                {'label': 'إجمالي القيمة التقديرية', 'value': '${numberFormat.format(_zakatResult!['goldTotalValue'])} ${country.currencySymbol}'},
                {'label': 'مقدار الزكاة الواجبة (غرام)', 'value': '${(_zakatResult!['goldZakatGrams'] as double).toStringAsFixed(2)} غرام 24K'},
                {'label': 'قيمة الزكاة النقدية المستحقة', 'value': '${numberFormat.format(_zakatResult!['totalZakatDue'])} ${country.currencySymbol}'},
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
            title: 'حاسبة أجور الصياغة (المصنعية) وشراء الذهب الجديد',
            subtitle: 'احسب السعر الإجمالي للقطعة مع المصنعية والضريبة بدقة قبل الذهاب للصائغ.',
          ),
          const SizedBox(height: 16),
          _buildInputField('وزن القطعة (غرام)', _itemWeightController, isDark),
          _buildInputField('سعر غرام الذهب الخام (${country.currencySymbol})', _goldGramPriceController, isDark),
          _buildInputField('أجرة المصنعية للغرام الواحد (${country.currencySymbol})', _makingChargeController, isDark),
          _buildInputField('نسبة ضريبة القيمة المضافة VAT %', _vatPercentController, isDark),
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
              child: const Text('احسب التكلفة الإجمالية للقطعة', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo', fontSize: 14)),
            ),
          ),
          if (_makingResult != null) ...[
            const SizedBox(height: 18),
            _buildResultCard(
              title: 'تفاصيل فاتورة الشراء 🛍️',
              items: [
                {'label': 'قيمة الذهب الصافي', 'value': '${numberFormat.format(_makingResult!['rawGoldCost'])} ${country.currencySymbol}'},
                {'label': 'إجمالي أجور الصياغة', 'value': '${numberFormat.format(_makingResult!['totalMakingCharge'])} ${country.currencySymbol}'},
                {'label': 'نسبة المصنعية من السعر', 'value': '${(_makingResult!['makingRatio'] as double).toStringAsFixed(1)}%'},
                {'label': 'السعر الإجمالي النهائي للقطعة', 'value': '${numberFormat.format(_makingResult!['totalCost'])} ${country.currencySymbol}'},
              ],
              isHighlight: true,
            ),
          ],
          const Divider(height: 36),
          _buildInfoBanner(
            title: 'حاسبة بيع الذهب المستعمل (ذهب الكسر)',
            subtitle: 'احسب المبلغ الصافي الذي ستحصل عليه عند بيع ذهبك القديم بعد خصم وزن الفصوص.',
          ),
          const SizedBox(height: 16),
          _buildInputField('الوزن الإجمالي للذهب المستعمل (غرام)', _scrapWeightController, isDark),
          _buildInputField('سعر شراء الكسر للغرام (${country.currencySymbol})', _scrapPriceController, isDark),
          _buildInputField('خصم وزن الفصوص والخرز (غرام إن وجد)', _stoneDeductionController, isDark),
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
              child: const Text('احسب صافي قيمة البيع', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo', fontSize: 14)),
            ),
          ),
          if (_scrapResult != null) ...[
            const SizedBox(height: 18),
            _buildResultCard(
              title: 'مستحقات البيع الصافية 💰',
              items: [
                {'label': 'الوزن الصافي للذهب', 'value': '${(_scrapResult!['netWeight'] as double).toStringAsFixed(2)} غرام'},
                {'label': 'المبلغ النقدي المستحق لك', 'value': '${numberFormat.format(_scrapResult!['totalPayout'])} ${country.currencySymbol}'},
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
            title: 'محول أوزان المعادن الثمينة والليرات',
            subtitle: 'تحويل فوري وشامل بين الأونصة العالمية، الغرام، التولة الهندية، المثقال الخليجي/العراقي والليرات الذهبية.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildInputField('الكمية', _convertAmountController, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _fromUnit,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    decoration: InputDecoration(
                      labelText: 'الوحدة الأصلية',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'gram', child: Text('غرام (g)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'ounce', child: Text('أونصة (31.1g)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'tola', child: Text('تولة (11.66g)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'mithqal', child: Text('مثقال (5g)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'english', child: Text('ليرة إنجليزية (8g)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'rashadi', child: Text('ليرة رشادية (7g)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'kilo', child: Text('كيلوغرام (1000g)', style: TextStyle(fontFamily: 'Cairo'))),
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
              child: const Text('تحويل لجميع الوحدات', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo', fontSize: 14)),
            ),
          ),
          if (_conversionResult != null) ...[
            const SizedBox(height: 18),
            _buildResultCard(
              title: 'الوزن المعادل في كافة الوحدات ⚖️',
              items: [
                {'label': 'بالغرام', 'value': '${_conversionResult!['gram']!.toStringAsFixed(3)} غرام'},
                {'label': 'بالأونصة الترويسية (Oz)', 'value': '${_conversionResult!['ounce']!.toStringAsFixed(4)} أونصة'},
                {'label': 'بالمثقال', 'value': '${_conversionResult!['mithqal']!.toStringAsFixed(3)} مثقال'},
                {'label': 'بالتولة (Tola)', 'value': '${_conversionResult!['tola']!.toStringAsFixed(3)} تولة'},
                {'label': 'بالليرات الإنجليزية (8g)', 'value': '${_conversionResult!['english']!.toStringAsFixed(2)} ليرة'},
                {'label': 'بالليرات الرشادية / العثمانية (7g)', 'value': '${_conversionResult!['rashadi']!.toStringAsFixed(2)} ليرة'},
                {'label': 'بالكيلوغرام', 'value': '${_conversionResult!['kilo']!.toStringAsFixed(5)} كغ'},
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
            title: 'حاسبة العائد الاستثماري على الذهب',
            subtitle: 'احسب نسبة أرباحك وعائد استثمارك بمقارنة سعر الشراء السابق مع سعر السوق الحي الحالي.',
          ),
          const SizedBox(height: 16),
          _buildInputField('إجمالي رأس المال المستثمر (${country.currencySymbol})', _investmentAmountController, isDark),
          _buildInputField('سعر غرام الذهب وقت الشراء', _buyPriceRoiController, isDark),
          _buildInputField('سعر غرام الذهب الحالي', _currentPriceRoiController, isDark),
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
              child: const Text('احسب الأرباح ومعدل ROI %', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo', fontSize: 14)),
            ),
          ),
          if (_roiResult != null) ...[
            const SizedBox(height: 18),
            _buildResultCard(
              title: _roiResult!['isProfit'] ? 'استثمار رابح 🚀' : 'خسارة غير محققة 📉',
              items: [
                {'label': 'كمية الذهب المشتراة', 'value': '${(_roiResult!['gramsBought'] as double).toStringAsFixed(2)} غرام'},
                {'label': 'القيمة الإجمالية الحالية', 'value': '${numberFormat.format(_roiResult!['currentValue'])} ${country.currencySymbol}'},
                {'label': 'صافي الربح / الخسارة', 'value': '${numberFormat.format(_roiResult!['netProfit'])} ${country.currencySymbol}'},
                {'label': 'معدل العائد على الاستثمار', 'value': '${(_roiResult!['roiPercent'] as double).toStringAsFixed(2)}%'},
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
    final priceService = Provider.of<PriceService>(context);
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
            title: 'مخطط أهداف الادخار بالذهب (Gold Savings & DCA Planner)',
            subtitle: 'خطط لمستقبلك بالذهب وحقق أهدافك المالية (زواج، شراء سيارة، عقار أو تقاعد) باحتساب خطة الشراء التراكمي شهرياً وأسبوعياً.',
          ),
          const SizedBox(height: 16),

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
                const Text(
                  '1. محاكي وخطة الادخار المستقبلي',
                  style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Cairo', fontSize: 15, color: AppColors.gold),
                ),
                const SizedBox(height: 12),

                // Target Type Switch (Grams vs Currency)
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('الهدف بالغرامات ⚖️', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold))),
                        selected: _isGoalTargetInGrams,
                        selectedColor: AppColors.gold.withValues(alpha: 0.2),
                        onSelected: (val) => setState(() => _isGoalTargetInGrams = true),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                const SizedBox(height: 12),

                _buildInputField(
                  _isGoalTargetInGrams ? 'الكمية المستهدفة (غرام)' : 'المبلغ المستهدف (${country.currencySymbol})',
                  _goalTargetAmountController,
                  isDark,
                ),

                _buildInputField('ما تملكه حالياً من الذهب كبداية (غرام)', _goalInitialSavedController, isDark),

                // Duration Selector
                const Text('المدة الزمنية لتحقيق الهدف:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedText)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDurationChip(6, '6 أشهر'),
                    _buildDurationChip(12, 'سنة واحدة'),
                    _buildDurationChip(24, 'سنتين'),
                    _buildDurationChip(36, '3 سنوات'),
                    _buildDurationChip(60, '5 سنوات'),
                  ],
                ),

                const SizedBox(height: 16),

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
                    child: const Text('احسب خطة الادخار التراكمي (DCA)', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo', fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),

          // Plan Calculation Result
          if (_savingsPlanResult != null) ...[
            const SizedBox(height: 18),
            _buildResultCard(
              title: 'خطة استقطاع الادخار الذكية 🎯',
              items: [
                {'label': 'الهدف الإجمالي', 'value': '${(_savingsPlanResult!['totalTargetGrams'] as double).toStringAsFixed(2)} غرام'},
                {'label': 'الادخار الشهري المطلوب', 'value': '${(_savingsPlanResult!['monthlyGramsNeeded'] as double).toStringAsFixed(2)} غرام / شهر'},
                {'label': 'الادخار الأسبوعي المطلوب', 'value': '${(_savingsPlanResult!['weeklyGramsNeeded'] as double).toStringAsFixed(2)} غرام / أسبوع'},
                {'label': 'المبلغ الشهري التقديري', 'value': '${numberFormat.format(_savingsPlanResult!['monthlyCostEstimate'])} ${country.currencySymbol}'},
                {'label': 'القيمة المتوقعة مع نمو الذهب (~8% سنوياً)', 'value': '${numberFormat.format(_savingsPlanResult!['futureTargetValue'])} ${country.currencySymbol}'},
              ],
              isHighlight: true,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCreateGoalDialog(context, gram24, country),
                icon: const Icon(Icons.bookmark_add_rounded, color: AppColors.gold),
                label: const Text('حفظ كهدف ادخاري ومتابعة الإنجاز 📌', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.gold, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

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
                tooltip: 'إضافة هدف جديد',
              ),
            ],
          ),

          const SizedBox(height: 12),

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
                      'لا توجد أهداف ادخار مسجلة بعد',
                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'اضغط على زر + أو احسب خطتك أعلاه لحفظ أول هدف لك!',
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
                  const SizedBox(width: 10),
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
          const SizedBox(height: 12),

          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المنجز: ${goal.currentGrams.toStringAsFixed(1)} غرام', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${progress.toStringAsFixed(1)}%', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w900, color: isCompleted ? const Color(0xFF00E676) : AppColors.gold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? const Color(0xFF00E676) : AppColors.gold),
            ),
          ),

          const SizedBox(height: 12),

          // Action: Add Contribution
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCompleted ? '🎉 مبروك! تم تحقيق الهدف بالكامل' : 'المتبقي: ${goal.remainingGrams.toStringAsFixed(1)} غرام',
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
                  label: const Text('+ إضافة ادخار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, fontFamily: 'Cairo')),
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
    final titleCtrl = TextEditingController(text: _goalTitleController.text.isNotEmpty ? _goalTitleController.text : 'ادخار الذهب للهدف');
    final gramsCtrl = TextEditingController(text: _savingsPlanResult != null ? (_savingsPlanResult!['totalTargetGrams'] as double).toStringAsFixed(1) : '50');
    final initialCtrl = TextEditingController(text: _goalInitialSavedController.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('إنشاء هدف ادخاري جديد 🎯', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'اسم الهدف (مثال: للزواج 💍)', labelStyle: TextStyle(fontFamily: 'Cairo')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: gramsCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'الهدف الإجمالي (غرام ذهب)', labelStyle: TextStyle(fontFamily: 'Cairo')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: initialCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'المدخر الحالي كبداية (غرام)', labelStyle: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: AppColors.mutedText)),
          ),
          ElevatedButton(
            onPressed: () {
              final targetG = double.tryParse(gramsCtrl.text) ?? 50.0;
              final currentG = double.tryParse(initialCtrl.text) ?? 0.0;
              final title = titleCtrl.text.isNotEmpty ? titleCtrl.text : 'ادخار الذهب';

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
                const SnackBar(content: Text('تم حفظ الهدف الادخاري بنجاح! 🎯', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.darkGreen),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('حفظ الهدف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
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
            const Text('أدخل وزن الذهب الذي قمت بشرائه وإضافته لادخارك اليوم:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.mutedText)),
            const SizedBox(height: 12),
            TextField(
              controller: addCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'الوزن المضاف (غرام)',
                labelStyle: TextStyle(fontFamily: 'Cairo'),
                suffixText: 'غرام',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: AppColors.mutedText)),
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
            child: const Text('تأكيد الإضافة 💎', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold, fontFamily: 'Cairo', fontSize: 14)),
                const SizedBox(height: 4),
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
          const SizedBox(height: 12),
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

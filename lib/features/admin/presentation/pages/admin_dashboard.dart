import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/models/banner_item.dart';
import '../../../../shared/services/price_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم الشاملة'),
          backgroundColor: AppColors.warmBrown,
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            tabs: [
              Tab(icon: Icon(Icons.attach_money), text: 'الأسعار'),
              Tab(icon: Icon(Icons.view_carousel), text: 'البنرات'),
              Tab(icon: Icon(Icons.notifications), text: 'الإشعارات'),
              Tab(icon: Icon(Icons.settings), text: 'الإعدادات'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PricesTab(),
            BannersTab(),
            NotificationsTab(),
            SettingsTab(),
          ],
        ),
      ),
    );
  }
}

// ... existing Tabs ...

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _telegramController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    // Wait for service to be available and fetch
    final priceService = Provider.of<PriceService>(context, listen: false);
    // We can listen to the stream to fill initial values
    priceService.settingsStream.listen((settings) {
      if (mounted && _appNameController.text.isEmpty) {
        // initialize only once or if empty to avoid overwrite while typing (though stream usually emits once on connect)
        setState(() {
          _appNameController.text = settings['appName'] ?? '';
          _logoUrlController.text = settings['logoUrl'] ?? '';
          final links = settings['socialLinks'] ?? {};
          _facebookController.text = links['facebook'] ?? '';
          _whatsappController.text = links['whatsapp'] ?? '';
          _telegramController.text = links['telegram'] ?? '';
          _instagramController.text = links['instagram'] ?? '';
          _websiteController.text = links['website'] ?? '';
        });
      }
    });
    priceService.fetchSettings();
  }

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('إعدادات التطبيق',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(
            controller: _appNameController,
            decoration: const InputDecoration(
                labelText: 'اسم التطبيق', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _logoUrlController,
            decoration: const InputDecoration(
                labelText: 'رابط اللوغو (URL)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 25),
          const Text('روابط التواصل الاجتماعي',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(
            controller: _facebookController,
            decoration: const InputDecoration(
                labelText: 'Facebook Link',
                prefixIcon: Icon(Icons.facebook),
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _whatsappController,
            decoration: const InputDecoration(
                labelText: 'WhatsApp Link',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _telegramController,
            decoration: const InputDecoration(
                labelText: 'Telegram Link',
                prefixIcon: Icon(Icons.send),
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _instagramController,
            decoration: const InputDecoration(
                labelText: 'Instagram Link',
                prefixIcon: Icon(Icons.camera_alt),
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _websiteController,
            decoration: const InputDecoration(
                labelText: 'Website Link',
                prefixIcon: Icon(Icons.language),
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() => _isLoading = true);
                    final socialLinks = {
                      'facebook': _facebookController.text,
                      'whatsapp': _whatsappController.text,
                      'telegram': _telegramController.text,
                      'instagram': _instagramController.text,
                      'website': _websiteController.text,
                    };

                    final success = await priceService.updateSettings(
                        _appNameController.text,
                        _logoUrlController.text,
                        socialLinks);

                    setState(() => _isLoading = false);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(success ? 'تم الحفظ بنجاح' : 'فشل الحفظ')),
                      );
                    }
                  },
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('حفظ التغييرات',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class PricesTab extends StatelessWidget {
  const PricesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);

    return StreamBuilder<List<PriceItem>>(
      stream: priceService.pricesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final prices = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: prices.length,
          itemBuilder: (context, index) {
            final item = prices[index];
            return Card(
              color: item.isManual ? Colors.amber.shade50 : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      item.isManual ? Colors.orange : const Color(0x33D4AF37),
                  child: Icon(
                    item.isManual ? Icons.handshake : Icons.edit,
                    color: AppColors.copper,
                  ),
                ),
                title: Text(item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'مبيع: ${item.sellPrice} - شراء: ${item.buyPrice}\n${item.isManual ? "(تعديل يدوي)" : "(تلقائي)"}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showEditDialog(context, item, priceService),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(
      BuildContext context, PriceItem item, PriceService service) {
    final sellController =
        TextEditingController(text: item.sellPrice.toString());
    final buyController = TextEditingController(text: item.buyPrice.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تعديل ${item.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.isManual)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              "هذا السعر معدل يدوياً ولن يتم تحديثه تلقائياً.")),
                    ],
                  ),
                ),
              TextField(
                controller: sellController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'سعر المبيع', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: buyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'سعر الشراء', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            if (item.isManual)
              TextButton.icon(
                onPressed: () {
                  service.resetPrice(item.id);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.refresh, color: Colors.blue),
                label: const Text('استعادة التلقائي',
                    style: TextStyle(color: Colors.blue)),
              ),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
              onPressed: () {
                final double? newSell = double.tryParse(sellController.text);
                final double? newBuy = double.tryParse(buyController.text);
                if (newSell != null && newBuy != null) {
                  service.updatePrice(item.id, newBuy, newSell);
                  Navigator.pop(context);
                }
              },
              child:
                  const Text('حفظ يدوي', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }
}

class BannersTab extends StatelessWidget {
  const BannersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () => _showAddDialog(context, priceService),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<BannerItem>>(
        stream: priceService.bannersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final banners = snapshot.data!;
          if (banners.isEmpty) {
            return const Center(child: Text("لا توجد بنرات حالياً"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Card(
                color: Color(banner.color).withValues(alpha: 0.9),
                child: ListTile(
                  title: Text(banner.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "${banner.subtitle}\n(${banner.type == 'ad' ? 'إعلان' : banner.type == 'image' ? 'صورة' : 'نص'}) - ${banner.location}",
                      style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () => priceService.deleteBanner(banner.id),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, PriceService service) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final imageUrlController = TextEditingController();
    final linkUrlController = TextEditingController();
    final adCodeController = TextEditingController();

    String selectedType = 'text';
    String selectedLocation = 'home_top';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('إضافة بنر جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'نوع البنر'),
                    items: const [
                      DropdownMenuItem(value: 'text', child: Text('نصي')),
                      DropdownMenuItem(value: 'image', child: Text('صورة')),
                      DropdownMenuItem(value: 'ad', child: Text('إعلان (كود)')),
                    ],
                    onChanged: (val) => setState(() => selectedType = val!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedLocation,
                    decoration: const InputDecoration(labelText: 'المكان'),
                    items: const [
                      DropdownMenuItem(
                          value: 'home_top', child: Text('أعلى الرئيسية')),
                      DropdownMenuItem(
                          value: 'syria_market_mid',
                          child: Text('وسط سوق سوريا')),
                      DropdownMenuItem(
                          value: 'global_market_bottom',
                          child: Text('أسفل السوق العالمي')),
                    ],
                    onChanged: (val) => setState(() => selectedLocation = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                        labelText: 'العنوان', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subtitleController,
                    decoration: const InputDecoration(
                        labelText: 'النص الفرعي', border: OutlineInputBorder()),
                  ),
                  if (selectedType == 'image') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                          labelText: 'رابط الصورة (URL)',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: linkUrlController,
                      decoration: const InputDecoration(
                          labelText: 'رابط التوجيه (عند النقر)',
                          border: OutlineInputBorder()),
                    ),
                  ],
                  if (selectedType == 'ad') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: adCodeController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: 'كود الإعلان',
                          border: OutlineInputBorder()),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء')),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    service.addBanner(
                      titleController.text,
                      subtitleController.text,
                      0xFFB87333,
                      type: selectedType,
                      location: selectedLocation,
                      imageUrl: imageUrlController.text,
                      linkUrl: linkUrlController.text,
                      adCode: adCodeController.text,
                    );
                    Navigator.pop(context);
                  }
                },
                child:
                    const Text('إضافة', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        });
      },
    );
  }
}

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  final TextEditingController _msgController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_active,
              size: 60, color: AppColors.copper),
          const SizedBox(height: 20),
          const Text(
            'إرسال إشعار فوري لجميع المستخدمين',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _msgController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'نص الرسالة',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmBrown,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            icon: const Icon(Icons.send, color: AppColors.gold),
            label: const Text('إرسال الآن',
                style: TextStyle(color: AppColors.gold, fontSize: 16)),
            onPressed: () {
              if (_msgController.text.isNotEmpty) {
                priceService.sendNotification(_msgController.text);
                _msgController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم الإرسال بنجاح')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

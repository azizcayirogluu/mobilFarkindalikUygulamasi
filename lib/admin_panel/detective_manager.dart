import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============ ENUMS & CONSTANTS ============
enum SecurityStatus { safe, dangerous }

extension SecurityStatusExt on SecurityStatus {
  String get label => this == SecurityStatus.safe ? "GÜVENLİ" : "TEHLİKELİ";
  Color get color => this == SecurityStatus.safe ? Colors.green : Colors.red;
  IconData get icon => this == SecurityStatus.safe ? Icons.check_circle_outline : Icons.error_outline;
}

enum IconType { warning, security, thumbUp, vpnKey }

extension IconTypeExt on IconType {
  String get label => name;
  IconData get icon {
    return switch (this) {
      IconType.warning => Icons.warning_rounded,
      IconType.security => Icons.security_rounded,
      IconType.thumbUp => Icons.thumb_up_rounded,
      IconType.vpnKey => Icons.vpn_key_rounded,
    };
  }
}

class _Constants {
  static const double defaultPadding = 40;
  static const double mobilePadding = 20;
  static const double borderRadius = 12;
  static const double largeBorderRadius = 16;
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color bgColor = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textLight = Colors.blueGrey;
}

class DetectiveManager extends StatefulWidget {
  const DetectiveManager({super.key});

  @override
  State<DetectiveManager> createState() => _DetectiveManagerState();
}

class _DetectiveManagerState extends State<DetectiveManager> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _metinController;
  late TextEditingController _aciklamaController;
  late ScrollController _formScrollController;

  SecurityStatus _secilenDurum = SecurityStatus.dangerous;
  IconType _secilenIkon = IconType.warning;
  String? _editingDocId;

  @override
  void initState() {
    super.initState();
    _metinController = TextEditingController();
    _aciklamaController = TextEditingController();
    _formScrollController = ScrollController();
  }

  @override
  void dispose() {
    _metinController.dispose();
    _aciklamaController.dispose();
    _formScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isMobile
          ? SingleChildScrollView(
        padding: const EdgeInsets.all(_Constants.mobilePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildForm(),
            const SizedBox(height: 40),
            _buildQuestionsList(),
          ],
        ),
      )
          : Row(
        children: [
          Expanded(flex: 4, child: _buildForm()),
          Expanded(flex: 6, child: _buildQuestionsList()),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(_Constants.defaultPadding),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: _Constants.borderColor)),
      ),
      child: SingleChildScrollView(
        controller: _formScrollController,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerSection(),
              const SizedBox(height: 40),
              _proTextField(
                "Soru Senaryosu",
                _metinController,
                "Çocukların karşılaşabileceği bir durumu yazın...",
                maxLines: 4,
              ),
              const SizedBox(height: 25),
              _proTextField(
                "Eğitici Geri Bildirim",
                _aciklamaController,
                "Doğru karar verildiğinde/yanlış yapıldığında gösterilecek açıklama...",
                maxLines: 3,
              ),
              const SizedBox(height: 25),
              _buildOptionsRow(),
              const SizedBox(height: 40),
              _buildFormActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Dedektif Soru Yönetim Ekranı", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        SizedBox(height: 40,),
        Text(
          _editingDocId != null ? "Soru Düzenleniyor" : "Yeni İçerik Oluştur",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _Constants.textDark),
        ),
        const SizedBox(height: 4),
        const Text(
          "Siber Dedektif oyunu için interaktif sorular ekleyin.",
          style: TextStyle(color: Colors.blueGrey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _proTextField(
      String label,
      TextEditingController ctrl,
      String hint, {
        int maxLines = 1,
        String? Function(String?)? customValidator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: _Constants.textLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          minLines: maxLines == 1 ? 1 : maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: _Constants.bgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_Constants.borderRadius),
              borderSide: const BorderSide(color: _Constants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_Constants.borderRadius),
              borderSide: const BorderSide(color: _Constants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_Constants.borderRadius),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_Constants.borderRadius),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: customValidator ?? (v) => _validateNotEmpty(v),
        ),
      ],
    );
  }

  String? _validateNotEmpty(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Zorunlu alan";
    }
    if (value.trim().length < 3) {
      return "En az 3 karakter gerekli";
    }
    return null;
  }

  Widget _buildOptionsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdownField<SecurityStatus>(
            label: "GÜVENLİK DURUMU",
            value: _secilenDurum,
            items: SecurityStatus.values,
            itemLabel: (e) => e.label,
            onChanged: (v) => setState(() => _secilenDurum = v),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildDropdownField<IconType>(
            label: "İKON TİPİ",
            value: _secilenIkon,
            items: IconType.values,
            itemLabel: (e) => e.label,
            onChanged: (v) => setState(() => _secilenIkon = v),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required Function(T) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: _Constants.textLight,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items
              .map(
                (e) => DropdownMenuItem(
              value: e,
              child: Row(
                children: [
                  if (e is SecurityStatus) ...[
                    Icon(e.icon, color: e.color, size: 18),
                    const SizedBox(width: 8),
                  ] else if (e is IconType) ...[
                    Icon(e.icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(itemLabel(e)),
                ],
              ),
            ),
          )
              .toList(),
          onChanged: (v) => onChanged(v!),
          decoration: InputDecoration(
            filled: true,
            fillColor: _Constants.bgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_Constants.borderRadius),
              borderSide: const BorderSide(color: _Constants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_Constants.borderRadius),
              borderSide: const BorderSide(color: _Constants.borderColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormActions() {
    return Row(
      children: [
        if (_editingDocId != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton(
                onPressed: _formuSifirla,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_Constants.borderRadius),
                  ),
                ),
                child: const Text("İPTAL"),
              ),
            ),
          ),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _kaydet,
            style: ElevatedButton.styleFrom(
              backgroundColor: _Constants.textDark,
              minimumSize: const Size(0, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_Constants.borderRadius),
              ),
            ),
            child: Text(
              _editingDocId != null ? "DEĞİŞİKLİKLERİ KAYDET" : "SİSTEME EKLE",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('detective_questions')
          .orderBy('eklenmeTarihi', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Text(
              'Hata: ${snap.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 64, color: Colors.blueGrey.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  'Henüz soru eklenmemiş',
                  style: TextStyle(color: Colors.blueGrey.shade400),
                ),
              ],
            ),
          );
        }

        final docs = snap.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(_Constants.defaultPadding),
          itemCount: docs.length,
          itemBuilder: (context, i) => _buildQuestionListItem(docs[i]),
        );
      },
    );
  }

  Widget _buildQuestionListItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final durum = data['durum'] == "GÜVENLİ"
        ? SecurityStatus.safe
        : SecurityStatus.dangerous;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _Constants.bgColor,
        borderRadius: BorderRadius.circular(_Constants.largeBorderRadius),
        border: Border.all(color: _Constants.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: durum.color.withOpacity(0.1),
          child: Icon(durum.icon, color: durum.color),
        ),
        title: Text(
          data['metin'] ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          durum.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: durum.color,
          ),
        ),
        trailing: SizedBox(
          width: 100,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                onPressed: () => _duzenle(doc),
                tooltip: 'Düzenle',
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                onPressed: () => _showDeleteConfirmation(doc),
                tooltip: 'Sil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final metin = data['metin'] as String? ?? 'Bu soru';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Soru Sil'),
        content: Text('$metin" sorusu silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İPTAL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'SİL',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await doc.reference.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Soru silindi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  void _formuSifirla() {
    setState(() {
      _metinController.clear();
      _aciklamaController.clear();
      _secilenDurum = SecurityStatus.dangerous;
      _secilenIkon = IconType.warning;
      _editingDocId = null;
    });
  }

  void _duzenle(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _editingDocId = doc.id;
      _metinController.text = data['metin'] ?? "";
      _aciklamaController.text = data['aciklama'] ?? "";

      // Parse durum from string
      final durumStr = data['durum'] as String?;
      _secilenDurum = durumStr == "GÜVENLİ"
          ? SecurityStatus.safe
          : SecurityStatus.dangerous;

      // Parse ikon from string
      final ikonStr = data['ikon'] as String?;
      _secilenIkon = IconType.values.firstWhere(
            (e) => e.label == ikonStr,
        orElse: () => IconType.warning,
      );
    });

    // Scroll form'a, düzenleme başladığında
    _formScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _kaydet() async {
    if (_formKey.currentState!.validate()) {
      final metin = _metinController.text.trim();
      final aciklama = _aciklamaController.text.trim();

      final data = {
        "metin": metin,
        "durum": _secilenDurum.label,
        "aciklama": aciklama,
        "ikon": _secilenIkon.label,
        "sonGuncelleme": FieldValue.serverTimestamp(),
      };

      try {
        if (_editingDocId != null) {
          await FirebaseFirestore.instance
              .collection('detective_questions')
              .doc(_editingDocId)
              .update(data);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Soru başarıyla güncellendi')),
            );
          }
        } else {
          data["eklenmeTarihi"] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('detective_questions')
              .add(data);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Soru başarıyla eklendi')),
            );
          }
        }

        _formuSifirla();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
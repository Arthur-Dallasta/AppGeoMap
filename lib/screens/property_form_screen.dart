












import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/properties/data/property_repository.dart';
import '../features/properties/providers/properties_provider.dart';
import 'property_detail_screen.dart'; 

const _kBrStates = [
  'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS',
  'MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC',
  'SP','SE','TO',
];

class PropertyFormScreen extends ConsumerStatefulWidget {
  final String? propertyId; 
  const PropertyFormScreen({super.key, this.propertyId});

  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  final _name         = TextEditingController();
  final _location     = TextEditingController();
  final _municipality = TextEditingController();
  final _zipCode      = TextEditingController();
  final _totalArea    = TextEditingController();
  final _ownArea      = TextEditingController();
  final _leasedArea   = TextEditingController();
  final _protectedArea= TextEditingController();
  final _peopleCount  = TextEditingController();
  final _cropArea     = TextEditingController();
  String _state = 'MT'; 

  @override
  void initState() {
    super.initState();
    
    if (widget.propertyId != null) _loadProperty();
  }

  Future<void> _loadProperty() async {
    setState(() => _loading = true);
    try {
      final p = await PropertyRepository().getProperty(widget.propertyId!);
      _name.text = p.name;
      _location.text = p.location;
      _municipality.text = p.municipality;
      _zipCode.text = p.zipCode;
      _totalArea.text = p.totalAreaHa.toString();
      _ownArea.text = p.ownAreaHa.toString();
      _leasedArea.text = p.leasedAreaHa.toString();
      _protectedArea.text = p.protectedAreaHa.toString();
      _peopleCount.text = p.peopleCount.toString();
      _cropArea.text = p.cropAreaHa.toString();
      
      setState(() => _state = _kBrStates.contains(p.state) ? p.state : 'MT');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    
    for (final c in [
      _name, _location, _municipality, _zipCode,
      _totalArea, _ownArea, _leasedArea, _protectedArea,
      _peopleCount, _cropArea,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _loading = true; _error = null; });

    try {
      
      final data = {
        'name':              _name.text.trim(),
        'location':          _location.text.trim(),
        'municipality':      _municipality.text.trim(),
        'state':             _state,
        'zip_code':          _zipCode.text.trim(),
        
        'total_area_ha':     double.parse(_totalArea.text.replaceAll(',', '.')),
        'own_area_ha':       double.parse(_ownArea.text.replaceAll(',', '.')),
        'leased_area_ha':    double.parse(_leasedArea.text.replaceAll(',', '.')),
        'protected_area_ha': double.parse(_protectedArea.text.replaceAll(',', '.')),
        'people_count':      int.parse(_peopleCount.text),
        'crop_area_ha':      double.parse(_cropArea.text.replaceAll(',', '.')),
      };

      if (widget.propertyId == null) {
        await PropertyRepository().createProperty(data);
      } else {
        await PropertyRepository().updateProperty(widget.propertyId!, data);
      }

      ref.invalidate(propertiesProvider);
      
      if (widget.propertyId != null) {
        ref.invalidate(propertyDetailProvider(widget.propertyId!));
      }
      if (mounted) context.pop(); 
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'];
      setState(() => _error = msg is String ? msg : 'Erro ao salvar propriedade.');
    } catch (_) {
      setState(() => _error = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: Text(widget.propertyId == null ? 'Nova Propriedade' : 'Editar Propriedade'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _section('Identificação'),
            _text(_name, 'Nome da propriedade', required: true),
            _text(_location, 'Localização / endereço rural', required: true),
            Row(children: [
              Expanded(child: _text(_municipality, 'Município', required: true)),
              const SizedBox(width: 12),
              _stateDropdown(), 
            ]),
            _text(_zipCode, 'CEP', hint: '00000-000',
                type: TextInputType.number,
                inputFormatters: [_CepFormatter()]), 

            const SizedBox(height: 24),
            _section('Áreas (hectares)'),
            Row(children: [
              Expanded(child: _decimal(_totalArea, 'Área total')),
              const SizedBox(width: 12),
              Expanded(child: _decimal(_ownArea, 'Área própria')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _decimal(_leasedArea, 'Área arrendada')),
              const SizedBox(width: 12),
              Expanded(child: _decimal(_protectedArea, 'Área protegida')),
            ]),
            const SizedBox(height: 12),
            _decimal(_cropArea, 'Área de cultivo'),

            const SizedBox(height: 24),
            _section('Outros'),
            _text(_peopleCount, 'Pessoas na propriedade',
                type: TextInputType.number,
                
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                required: true),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                ]),
              ),
            ],

            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.propertyId == null ? 'Cadastrar Propriedade' : 'Salvar Alterações',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
              letterSpacing: 0.5,
            )),
      );

  Widget _text(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    String? hint,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: type,
          inputFormatters: inputFormatters,
          validator: required
              ? (v) => v != null && v.trim().isNotEmpty ? null : '* Obrigatório'
              : null,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      );

  Widget _decimal(TextEditingController ctrl, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
          validator: (v) {
            if (v == null || v.isEmpty) return '* Obrigatório';
            final val = double.tryParse(v.replaceAll(',', '.'));
            if (val == null || val < 0) return 'Valor inválido';
            return null;
          },
          decoration: InputDecoration(
            labelText: label,
            suffixText: 'ha', 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      );

  Widget _stateDropdown() => SizedBox(
        width: 90,
        child: DropdownButtonFormField<String>(
          value: _state,
          items: _kBrStates
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _state = v!),
          decoration: InputDecoration(
            labelText: 'UF',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      );
}




class _CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    
    var digits = nv.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) digits = digits.substring(0, 8); 
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 5) buf.write('-'); 
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

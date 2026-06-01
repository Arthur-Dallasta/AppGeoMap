








import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/areas/data/area_repository.dart';
import '../features/areas/providers/areas_provider.dart';

class AreaUploadScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final String propertyName;

  const AreaUploadScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  ConsumerState<AreaUploadScreen> createState() => _AreaUploadScreenState();
}

class _AreaUploadScreenState extends ConsumerState<AreaUploadScreen> {
  String _areaType = 'internal'; 
  PlatformFile? _pickedFile;     
  bool _loading = false;         
  double? _progress;             
  String? _error;                
  String? _success;              

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['geojson', 'json', 'zip'], 
      withData: true, 
    );
    if (result == null || result.files.isEmpty) return; 
    setState(() {
      _pickedFile = result.files.first;
      _error = null;
      _success = null;
    });
  }

  Future<void> _upload() async {
    if (_pickedFile == null) return;
    final bytes = _pickedFile!.bytes;
    if (bytes == null) {
      
      setState(() => _error = 'Não foi possível ler o arquivo.');
      return;
    }

    setState(() {
      _loading = true;
      _progress = 0;
      _error = null;
      _success = null;
    });

    try {
      await AreaRepository().uploadArea(
        propertyId: widget.propertyId,
        areaType: _areaType,
        fileBytes: bytes,
        fileName: _pickedFile!.name,
        
        onProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = sent / total); 
          }
        },
      );
      
      ref.invalidate(areasProvider(widget.propertyId));
      setState(() {
        _success = 'Upload concluído!';
        _pickedFile = null;   
        _progress = null;     
      });
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      setState(() => _error = detail is String ? detail : 'Erro no upload (${e.response?.statusCode}).');
    } catch (e) {
      setState(() => _error = 'Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.propertyName, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tipo de área',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'boundary', label: Text('Contorno'), icon: Icon(Icons.crop_square)),
                ButtonSegment(value: 'internal', label: Text('Interna'), icon: Icon(Icons.layers)),
              ],
              selected: {_areaType}, 
              onSelectionChanged: (s) => setState(() => _areaType = s.first),
              style: ButtonStyle(
                
                backgroundColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected) ? const Color(0xFF2E7D32) : null),
                foregroundColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected) ? Colors.white : null),
              ),
            ),
            const SizedBox(height: 24),
            
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(_pickedFile == null ? 'Selecionar arquivo .geojson' : _pickedFile!.name),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                foregroundColor: const Color(0xFF2E7D32),
              ),
            ),
            
            if (_pickedFile != null) ...[
              const SizedBox(height: 8),
              Text(
                '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            
            if (_progress != null && _loading)
              Column(
                children: [
                  LinearProgressIndicator(value: _progress, color: const Color(0xFF2E7D32)),
                  const SizedBox(height: 8),
                  Text('${((_progress ?? 0) * 100).toInt()}%', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                ],
              ),
            
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                ]),
              ),
            
            if (_success != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: const Color(0xFF2E7D32)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_success!, style: const TextStyle(color: Color(0xFF2E7D32)))),
                ]),
              ),
            
            ElevatedButton.icon(
              onPressed: (_pickedFile == null || _loading) ? null : _upload,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.upload),
              label: Text(_loading ? 'Enviando...' : 'Fazer upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            Text(
              'Formatos aceitos: .geojson, .json, .zip\n'
              'Contorno: delimita a propriedade\n'
              'Interna: áreas classificadas por categoria',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

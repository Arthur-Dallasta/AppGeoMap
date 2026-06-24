import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/areas/data/area_repository.dart';
import '../features/areas/providers/areas_provider.dart';

const _kGreen = Color(0xFF2E7D32);

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
        _success = 'Upload concluído com sucesso!';
        _pickedFile = null;
        _progress = null;
      });
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      setState(
        () => _error = detail is String
            ? detail
            : 'Erro no upload (${e.response?.statusCode}).',
      );
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
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page heading
            const Text(
              'Upload de Área',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Selecione o tipo e o arquivo GeoJSON para importar.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),

            // Area type label
            Text(
              'TIPO DE ÁREA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'boundary',
                  label: Text('Contorno'),
                  icon: Icon(Icons.crop_square),
                ),
                ButtonSegment(
                  value: 'internal',
                  label: Text('Interna'),
                  icon: Icon(Icons.layers),
                ),
              ],
              selected: {_areaType},
              onSelectionChanged: (s) => setState(() => _areaType = s.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? _kGreen
                      : null,
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // File drop zone
            Text(
              'ARQUIVO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: _loading ? null : _pickFile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 130,
                decoration: BoxDecoration(
                  color: _pickedFile != null
                      ? _kGreen.withValues(alpha: 0.04)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _pickedFile != null
                        ? _kGreen
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _pickedFile != null
                            ? Icons.insert_drive_file_outlined
                            : Icons.cloud_upload_outlined,
                        size: 36,
                        color: _pickedFile != null
                            ? _kGreen
                            : Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pickedFile != null
                            ? _pickedFile!.name
                            : 'Toque para selecionar arquivo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _pickedFile != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                          color: _pickedFile != null
                              ? _kGreen
                              : Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _pickedFile != null
                            ? '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB'
                            : '.geojson · .json · .zip',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Progress
            if (_progress != null && _loading) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        color: _kGreen,
                        backgroundColor: Colors.grey.shade200,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${((_progress ?? 0) * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Error banner
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Success banner
            if (_success != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: _kGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _success!,
                        style: const TextStyle(color: _kGreen, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Upload button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_pickedFile == null || _loading) ? null : _upload,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(
                  _loading ? 'Enviando...' : 'Fazer upload',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Formatos aceitos: .geojson, .json, .zip\n'
                      'Contorno: delimita o perímetro da propriedade\n'
                      'Interna: áreas classificadas por categoria',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

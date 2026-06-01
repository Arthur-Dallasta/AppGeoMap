







import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/data/auth_repository.dart';

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buf = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 3 || i == 6) buf.write('.');
      if (i == 9) buf.write('-');
      buf.write(limited[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _sex = 'M'; 
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthRepository().register(
        name: _nameController.text.trim(),
        cpf: _cpfController.text.trim(),
        sex: _sex,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) context.go('/login');
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      String msg;
      if (detail is String) {
        
        msg = detail;
      } else if (detail is List && detail.isNotEmpty) {
        
        msg = (detail.first['msg'] ?? detail.first.toString()).toString();
      } else {
        msg = 'Erro ao criar conta. (${e.response?.statusCode})';
      }
      setState(() => _error = msg);
    } catch (_) {
      setState(() => _error = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 40.0, bottom: 24.0),
                child: Text(
                  'Crie sua conta GeoMap',
                  style: TextStyle(fontSize: 20, color: Color(0xFF2E7D32)),
                ),
              ),
              
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32.0, 0, 32.0, 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              _field(_nameController, 'Nome completo', false),
              
              _field(
                _cpfController,
                'CPF',
                false,
                type: TextInputType.number,
                inputFormatters: [_CpfInputFormatter()],
                validator: (v) {
                  if (v == null || v.isEmpty) return '* Campo obrigatório';
                  final pattern = RegExp(r'^\d{3}\.\d{3}\.\d{3}-\d{2}$');
                  if (!pattern.hasMatch(v)) return 'Formato: XXX.XXX.XXX-XX';
                  return null;
                },
              ),
              _field(_emailController, 'Email', false, type: TextInputType.emailAddress),
              _field(_passwordController, 'Senha (mín. 8 caracteres)', true),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: _sex,
                  decoration: InputDecoration(
                    labelText: 'Sexo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Masculino')),
                    DropdownMenuItem(value: 'F', child: Text('Feminino')),
                    DropdownMenuItem(value: 'O', child: Text('Outro')),
                  ],
                  onChanged: (v) => setState(() => _sex = v!),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                width: 250,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Criar Conta', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 24),
              
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Já tenho conta',
                  style: TextStyle(color: Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  
  Widget _field(
    TextEditingController controller,
    String label,
    bool obscure, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        inputFormatters: inputFormatters,
        validator: validator ?? (v) => v != null && v.isNotEmpty ? null : '* Campo obrigatório',
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          label: Text(label),
        ),
      ),
    );
  }
}

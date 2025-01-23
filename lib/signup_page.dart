import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  SignupPageState createState() => SignupPageState();
}

class SignupPageState extends State<SignupPage> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();

  String? _selectedGender;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
        backgroundColor: Colors.black54,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Center(
                    child: Text(
                      'Crie sua Conta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Full Name Field
                  _buildTextField(_nameController, 'Nome completo', false),
                  const SizedBox(height: 20),
                  // Username Field
                  _buildTextField(_usernameController, 'Nome de usuário', false),
                  const SizedBox(height: 20),
                  // Phone Number Field
                  _buildTextField(_phoneController, 'Número de telefone', true),
                  const SizedBox(height: 20),
                  // Age Field
                  _buildTextField(_ageController, 'Idade', true),
                  const SizedBox(height: 20),
                  // Gender Dropdown
                  _buildDropdown(),
                  const SizedBox(height: 20),
                  // Email Field
                  _buildTextField(_emailController, 'Email', false),
                  const SizedBox(height: 20),
                  // Password Field
                  _buildPasswordField(),
                  const SizedBox(height: 20),
                  
                  // Submit Button
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() {
                                _isLoading = true;
                              });
                              if (_formKey.currentState!.validate()) {
                                try {
                                  // Firebase Signup
                                  UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                  );

                                  final user = userCredential.user;

                                  // Check if user creation is successful
                                  if (user != null) {
                                    debugPrint('Usuário criado com sucesso! UID: ${user.uid}');
                                    
                                    // Save user info to Firestore
                                    await _firestore.collection('users').doc(user.uid).set({
                                      'name': _nameController.text.trim(),
                                      'username': _usernameController.text.trim(),
                                      'phone': _phoneController.text.trim(),
                                      'age': int.parse(_ageController.text.trim()),
                                      'gender': _selectedGender,
                                      'email': _emailController.text.trim(),
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Cadastro realizado com sucesso!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    // Navigate to login page
                                    Navigator.pushNamed(context, '/login');
                                  }
                                } on FirebaseAuthException catch (e) {
                                  String message;
                                  switch (e.code) {
                                    case 'email-already-in-use':
                                      message = 'Este email já está em uso.';
                                      break;
                                    case 'invalid-email':
                                      message = 'Formato de email inválido.';
                                      break;
                                    case 'weak-password':
                                      message = 'A senha é muito fraca.';
                                      break;
                                    default:
                                      message = 'Ocorreu um erro: ${e.message}';
                                  }

                                  // Print the error to console for debugging
                                  debugPrint('Erro: ${e.code}, Mensagem: ${e.message}');

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message), backgroundColor: Colors.red),
                                  );
                                } finally {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Cadastrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TextField builder for form fields
  Widget _buildTextField(TextEditingController controller, String label, bool isNumber) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira $label';
            }
            if (isNumber && int.tryParse(value) == null) {
              return 'Por favor, insira um número válido';
            }
            return null;
          },
        ),
      ),
    );
  }

  // Dropdown for gender selection
  Widget _buildDropdown() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            labelText: 'Gênero',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Masculino',
              child: Text('Masculino'),
            ),
            DropdownMenuItem(
              value: 'Feminino',
              child: Text('Feminino'),
            ),
            DropdownMenuItem(
              value: 'Outro',
              child: Text('Outro'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, selecione seu gênero';
            }
            return null;
          },
        ),
      ),
    );
  }

  // Password field with visibility toggle
  Widget _buildPasswordField() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Senha',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira sua senha';
            } else if (value.length < 6) {
              return 'A senha deve ter pelo menos 6 caracteres';
            }
            return null;
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}

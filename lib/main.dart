
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Text(
          'Estoque APP',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text;
    final String password = _passwordController.text;

    final url = Uri.parse('https://admin.webbers.com.br/admin/loginEstoque');
    final response = await http.post(
      url,
      body: jsonEncode({'email': email, 'password': password}),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'ok') {
        List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(data['items']);

        // Navegar para a MainScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(initialItems: items),
          ),
        );
      } else {
        // Handle other statuses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha no login: ${data['msg']}')),
        );
      }
    } else {
      // Handle the error here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha no login: ${response.body}')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faça seu login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialItems;

  const MainScreen({super.key, required this.initialItems});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    // Inicializa a lista de itens com os dados passados
    items = widget.initialItems;
  }

  void _addItem(Map<String, dynamic> newItem) {
    setState(() {
      items.add(newItem);
    });
  }

  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Atenção'),
          content: Text('Deseja realmente remover o produto "${item['title']}" do estoque??'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
              },
            ),
            TextButton(
              child: Text('Apagar'),
              onPressed: () {
                _deleteItem(item); // Função que remove o item da lista
                Navigator.of(context).pop(); // Fecha o diálogo após apagar
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final url = Uri.parse('https://admin.webbers.com.br/admin/delEstoque/${item['id']}');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      setState(() {
        items.remove(item); // Remove o item da lista
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produto removido do estoque com sucesso')),
        );
      });
    } else {
      // Handle the error here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao apagar produto do estoque')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos no Estoque'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddItemScreen(onItemAdded: _addItem),
                ),
              );
            },
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('No items available'))
          : ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: item['image'] != null
                ? Image.network(item['image'])
                : null,
            title: Text(item['title'] ?? 'No Title'),
            subtitle: Text('Total: ${item['total']} ${item['type']}'),
            onLongPress: () {
              _showDeleteConfirmation(context, item);
            },
          );
        },
      ),
    );
  }
}

class AddItemScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onItemAdded;

  const AddItemScreen({super.key, required this.onItemAdded});

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _titleController = TextEditingController();
  final _totalController = TextEditingController();
  File? _image;
  bool isLoading = false; // Variável para controlar o carregamento

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitItem() async {
    final title = _titleController.text.trim();
    final total = double.tryParse(_totalController.text) ?? 0;

    setState(() {
      isLoading = true; // Mostra o carregamento
    });

    if (title.isNotEmpty && total > 0) {
      try {
        // Cria a requisição POST usando MultipartRequest
        var request = http.MultipartRequest(
            'POST',
            Uri.parse('https://admin.webbers.com.br/admin/addEstoque')
        );

        // Adiciona os campos ao corpo da requisição
        request.fields['title'] = title;
        request.fields['total'] = total.toString();  // Certifique-se de converter 'total' para string
        request.fields['type'] = 'Kg';

        // Adiciona a imagem, se houver
        if (_image != null) {
          request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
        }

        // Envia a requisição
        final streamedResponse = await request.send();

        // Processa a resposta para verificar o status e ler o corpo
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          var returnedData = json.decode(response.body);

          final newItemWithId = {
            'id': returnedData['id'] ?? DateTime.now().millisecondsSinceEpoch,
            'title':  returnedData['title'],
            'image': returnedData['image'],
            'total':  returnedData['total'],
            'type': 'Kg', // Substitua conforme necessário
          };

          widget.onItemAdded(newItemWithId);
          Navigator.of(context).pop();
        } else {
          // Caso a API retorne um erro, trate-o aqui
          const SnackBar(content: Text('Erro ao adicionar item'));
        }
      } catch (e) {
        // Trate qualquer erro de rede aqui
        SnackBar(content: Text('Erro ao conectar à API: $e'));
      } finally {
        setState(() {
          isLoading = false; // Esconde o carregamento
        });
      }
    } else {
      SnackBar(content: Text('A descrição e o total devem ser inseridos'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Estoque'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera),
            onPressed: _pickImage,
          ),
        ],
      ),
      body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _image == null
                      ? const Text('Nenhuma imagem para o produto.')
                      : SizedBox(
                    width: 150, // Defina a largura desejada
                    height: 150, // Defina a altura desejada
                    child: Image.file(_image!, fit: BoxFit.cover), // BoxFit.cover mantém a proporção da imagem
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  TextField(
                    controller: _totalController,
                    decoration: const InputDecoration(labelText: 'Total'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitItem,
                    child: const Text('Adicionar Estoque'),
                  ),
                ],
              ),
            ),
            if (isLoading)
              Center(
                child: CircularProgressIndicator(),
              ),
          ]
      ),
    );
  }
}
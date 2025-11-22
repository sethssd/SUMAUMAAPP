import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final _suggestionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _sendSuggestion() async {
    // Valida se o campo não está vazio
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Salva a sugestão na nova coleção 'sugestoes'
      await FirebaseFirestore.instance.collection('sugestoes').add({
        'texto': _suggestionController.text,
        'timestamp': FieldValue.serverTimestamp(), // Adiciona a data/hora
        'lido': false, // Útil para você marcar como lido no futuro
      });

      // Limpa o campo de texto
      _suggestionController.clear();

      if (mounted) {
        // Mostra mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Obrigado! Sua sugestão foi enviada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Mostra mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar sugestão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enviar Sugestão"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Viu alguma informação errada ou tem uma ideia para uma nova planta? Nos avise!",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _suggestionController,
                decoration: const InputDecoration(
                  labelText: "Sua sugestão",
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, escreva algo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                // Desabilita o botão enquanto carrega
                onPressed: _isLoading ? null : _sendSuggestion,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Enviar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
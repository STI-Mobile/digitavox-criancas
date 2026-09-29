import 'package:flutter/material.dart';

import '../domain/progress/profile_repository.dart';

final class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({
    required this.profileRepository,
    required this.onProfileSelected,
    super.key,
  });

  final ProfileRepository profileRepository;
  final ValueChanged<StudentProfile> onProfileSelected;

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

final class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  final controller = TextEditingController();

  List<StudentProfile> _profiles = const [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await widget.profileRepository.loadProfiles();

      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Não foi possível carregar os perfis.';
      });
    }
  }

  Future<void> _createProfile() async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Criar perfil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nome',
            hintText: 'Digite seu nome',
          ),
          onSubmitted: (value) {
            Navigator.of(dialogContext).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(controller.text);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    print("\n\n\n\n\n\n\n\n\n$name\n\n\n\n\n\n\n\n\n");
    if (!mounted || name == null || name.trim().isEmpty) return;

    try {
      final profile = await widget.profileRepository.createProfile(name);
      print("\n\n\n\n\n\n\n\n\n" + name +"\n\n\n\n\n\n\n\n\n");

      if (!mounted) return;

      setState(() {
        _profiles = [..._profiles, profile];
      });

      
    } on ArgumentError catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message.toString();
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível criar o perfil: $error';
      });
    }
  }

  Future<void> _confirmDelete(StudentProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir perfil?'),
        content: Text(
          'O perfil de ${profile.name} e seu progresso serão excluídos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      await widget.profileRepository.deleteProfile(profile.id);

      if (!mounted) return;

      setState(() {
        _profiles = _profiles
            .where((item) => item.id != profile.id)
            .toList(growable: false);
      });
    } on Object {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Não foi possível excluir o perfil.';
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quem vai aprender?')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Escolha um perfil',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  for (final profile in _profiles)
                    Card(
                      child: ListTile(
                        title: Text(profile.name),
                        onTap: () => widget.onProfileSelected(profile),
                        trailing: Semantics(
                          button: true,
                          label: 'Excluir perfil de ${profile.name}',
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Excluir perfil de ${profile.name}',
                            onPressed: () => _confirmDelete(profile),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _createProfile,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Criar novo perfil'),
                  ),
                ],
              ),
      ),
    );
  }
}

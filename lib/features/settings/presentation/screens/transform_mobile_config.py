import re

with open("mobile_config_screen.dart", "r") as f:
    text = f.read()

# Replace the build method to use LayoutBuilder and extract the two panels
build_pattern = re.compile(r'Widget build\(BuildContext context\) \{.*?Widget _buildColorPicker', re.DOTALL)
new_build = """Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.grey[50], // Or theme based
      appBar: AppBar(
        title: const Text('Terminal Configuration'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          _buildConnectedTerminalsButton(context),
          const SizedBox(width: 24),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            // Mobile: Stacked
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfigForm(),
                  _buildPreviewPanel(),
                ],
              ),
            );
          } else {
            // Desktop: Side by Side
            return SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildConfigForm()),
                  Expanded(child: _buildPreviewPanel()),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildConfigForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Branding & customization',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Logo Picker
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _logoPath != null ? FileImage(File(_logoPath!)) : null,
                      child: _logoPath == null
                          ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: Text('Tap to change Logo')),
                const SizedBox(height: 24),

                const Text('Theme Colors', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildColorPicker('Primary', _primaryColor, (c) => setState(() => _primaryColor = c)),
                    const SizedBox(width: 24),
                    _buildColorPicker('Secondary', _secondaryColor, (c) => setState(() => _secondaryColor = c)),
                  ],
                ),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _saveConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Configuration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a237e),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // Server Info Card
          Card(
            color: const Color(0xFF1a237e),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_tethering, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Connect Terminal',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter this IP Address in the Terminal to sync:',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _serverIp, // IP ADDRESS
                      style: const TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Live Preview
          SizedBox(
            height: 400,
            child: Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                color: _primaryColor,
                child: Stack(
                  children: [
                    // Pattern background
                    Positioned.fill(
                      child: _backgroundPath != null && _backgroundPath!.isNotEmpty
                          ? SvgPicture.asset(
                              _backgroundPath!,
                              fit: BoxFit.cover,
                            )
                          : SvgPicture.asset(
                              'assets/images/Pattern.svg',
                              fit: BoxFit.cover,
                            ),
                    ),
                    
                    // Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          SizedBox(
                            height: 60,
                            child: _logoPath != null && _logoPath!.isNotEmpty
                                ? Image.file(
                                    File(_logoPath!),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/logo.png',
                                        fit: BoxFit.contain,
                                      );
                                    },
                                  )
                                : Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Welcome message
                          Text(
                            _welcomeController.text.isNotEmpty 
                                ? _welcomeController.text 
                                : 'WELCOME',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Start Order Button mock
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8562A),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Start Order',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildColorPicker"""

text = build_pattern.sub(new_build, text)

with open("mobile_config_screen.dart", "w") as f:
    f.write(text)


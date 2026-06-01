# GeoMap Mobile

App mobile Flutter para gestão de propriedades rurais. Conecta ao backend FastAPI do GeoMap Web via REST API.

---

## Pré-requisitos

| Ferramenta | Versão mínima | Download |
|------------|---------------|----------|
| Flutter SDK | 3.11.1+ | https://docs.flutter.dev/get-started/install |
| Android Studio | Hedgehog+ | https://developer.android.com/studio |
| Java (JDK) | 17+ | bundled no Android Studio |
| Docker | qualquer | https://www.docker.com/products/docker-desktop |
| Git | qualquer | https://git-scm.com |

Após instalar o Flutter, verifique o ambiente:

```bash
flutter doctor
```

Todos os itens devem estar marcados (exceto iOS/Xcode se não for Mac).

---

## 1. Backend (obrigatório antes de rodar o app)

Clone o repositório do backend GeoMap Web e siga os passos:

```bash
# 1. Sobe o banco PostgreSQL + PostGIS
docker-compose up -d

# 2. Ativa o ambiente virtual Python
cd backend
.venv\Scripts\activate        # Windows
source .venv/bin/activate     # Linux/Mac

# 3. Roda as migrations
alembic upgrade head

# 4. Inicia o servidor (aceita conexões de qualquer IP)
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

## 2. Configuração do projeto Flutter

```bash
# Clone e entre na pasta
git clone <url-do-repo>
cd AppGeoMap

# Instala dependências
flutter pub get
```

---

## 3. Rodando o app

### 3a. Android Emulator

> **Atenção:** Não use emuladores com "16k" no nome (ex: `sdk gphone16k`). Esses emuladores usam page size de 16KB e causam crash nativo em algumas bibliotecas. Use **Pixel 8 API 34** ou similar.

**Criar emulador no Android Studio:**
1. **Tools → Device Manager → +**
2. Selecione **Pixel 8** (ou qualquer Pixel sem "16k")
3. System image: **API 34** (recomendado)
4. Finalize e inicie o emulador

**Terminal:**
```bash
# Lista emuladores disponíveis
flutter emulators

# Inicia um emulador específico
flutter emulators --launch <emulator_id>

# Lista dispositivos conectados
flutter devices

# Roda no emulador (URL padrão: 10.0.2.2:8000 → localhost da máquina host)
flutter run -d <emulator_id>

# Build release (mais rápido, sem hot reload)
flutter run -d <emulator_id> --release
```

**Android Studio:**
1. **File → Open** → selecione a pasta do projeto
2. Aguarde indexing e sync do Gradle
3. Selecione o emulador na toolbar (certifique que **não** está selecionado "Windows")
4. Clique em **Run** (▶) ou `Shift+F10`

---

### 3b. Dispositivo físico (USB)

**Preparar o celular:**
1. **Settings → About → Build number** — toque 7x para ativar Opções do desenvolvedor
2. **Settings → Developer options → USB debugging** — habilitar
3. Conectar via USB e aceitar o prompt de autorização no celular

**Descobrir o IP da máquina** (para o app se comunicar com o backend):
```bash
ipconfig        # Windows → IPv4 Address
ip a            # Linux/Mac → inet da interface ativa
```

**Rodar:**
```bash
# Confirma que o celular aparece
flutter devices

# Roda passando o IP da máquina como URL da API
flutter run -d <device_id> --dart-define=BASE_URL=http://<SEU_IP>:8000

# Exemplo
flutter run -d R58M123ABCD --dart-define=BASE_URL=http://192.168.1.10:8000
```

> Celular e máquina devem estar na **mesma rede Wi-Fi**.

---

### 3c. Chrome (Web)

> **Limitação:** `file_picker` e `flutter_secure_storage` têm suporte parcial no web. Upload de GeoJSON e armazenamento de JWT podem ter comportamento diferente do mobile.

```bash
# Habilita suporte web (só precisa rodar uma vez por máquina)
flutter config --enable-web

# Roda no Chrome
flutter run -d chrome --dart-define=BASE_URL=http://localhost:8000

# Se der erro de CORS, rode com web security desabilitada (apenas desenvolvimento!)
flutter run -d chrome \
  --dart-define=BASE_URL=http://localhost:8000 \
  --web-browser-flag="--disable-web-security"
```

---

### Resumo rápido

| Plataforma | Comando |
|------------|---------|
| Emulador Android | `flutter run -d <emulator_id>` |
| Celular USB | `flutter run -d <device_id> --dart-define=BASE_URL=http://<SEU_IP>:8000` |
| Chrome | `flutter run -d chrome --dart-define=BASE_URL=http://localhost:8000` |
| Listar dispositivos | `flutter devices` |
| Listar emuladores | `flutter emulators` |

---

## 4. Configuração da URL da API

A URL base é injetada em tempo de compilação via `--dart-define`. Sem o parâmetro, o default é `http://10.0.2.2:8000` (alias do emulador Android para localhost).

| Ambiente | Comando |
|----------|---------|
| Emulador Android | `flutter run` (default já correto) |
| Dispositivo físico | `--dart-define=BASE_URL=http://<IP_DA_MAQUINA>:8000` |
| Produção | `flutter build apk --dart-define=BASE_URL=https://api.exemplo.com` |

---

## 5. Estrutura do projeto

```
lib/
├── main.dart                          # Entry point — ProviderScope + SQLite init
├── app_widget.dart                    # MaterialApp.router + GoRouter
├── core/
│   ├── config/app_config.dart         # BASE_URL via --dart-define
│   ├── network/
│   │   ├── api_client.dart            # Dio com base URL configurável
│   │   └── auth_interceptor.dart      # Injeta JWT, limpa em 401
│   ├── router/app_router.dart         # GoRouter + redirect por auth state
│   ├── storage/secure_storage.dart    # JWT em flutter_secure_storage
│   └── models/                        # Modelos espelhando a API
├── features/
│   ├── auth/                          # Login, registro, JWT
│   ├── properties/                    # CRUD de propriedades
│   ├── areas/                         # Upload e listagem de áreas GeoJSON
│   └── categories/                    # Categorias de áreas
└── screens/
    ├── login_screen.dart
    ├── register_screen.dart
    ├── home_screen.dart               # Dashboard
    ├── map_screen.dart                # flutter_map com GeoJSON colorido
    ├── area_upload_screen.dart        # Upload .geojson / .zip
    └── property_form_screen.dart
```

---

## 6. Dependências principais

| Pacote | Uso |
|--------|-----|
| `flutter_riverpod` | State management |
| `go_router` | Navegação declarativa |
| `dio` | HTTP client com interceptors JWT |
| `flutter_secure_storage` | Armazenamento seguro do JWT |
| `flutter_map` + `latlong2` | Mapa interativo (OpenStreetMap, sem API key) |
| `file_picker` | Seleção de arquivo GeoJSON/ZIP |
| `sqflite` | SQLite local (cache offline futuro) |

---

## 7. Fluxo do app

```
Login / Registro
    ↓
Dashboard — lista de propriedades
    ↓                    ↓
[Nova Propriedade]    [Toca card]
    ↓                    ↓
PropertyFormScreen    MapScreen (flutter_map)
                         ↓
                   [Upload área] → .geojson ou .zip
                   Áreas aparecem coloridas por categoria
```

---

## 8. Problemas comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| `Connection refused` no login | Backend não está rodando | Inicie o backend (`uvicorn main:app --reload`) |
| App fecha sozinho no emulador | Emulador com 16k page size | Use Pixel 8 API 34 (sem "16k" no nome) |
| Mapa não carrega tiles | Sem conexão com internet | Checar rede — tiles vêm do OpenStreetMap |
| `Gradle sync failed` | Cache corrompido | File → Invalidate Caches → Restart |
| `flutter pub get` falha | Versão do Flutter incompatível | `flutter upgrade` ou `flutter --version` |
| Emulador não aparece em `flutter devices` | Emulador não iniciado | `flutter emulators --launch <id>` |
| `adb` não reconhecido | Não está no PATH | Adicione `<Android SDK>/platform-tools` ao PATH |

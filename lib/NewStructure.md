# 🧠 Arquitectura BLoC - AI_Therapy_Teteocan

Este documento detalla la reestructuración de la aplicación Flutter **AI_Therapy_Teteocan** para adoptar una arquitectura limpia basada en **BLoC** y **Cubit**. El objetivo principal es mejorar la **escalabilidad**, **mantenibilidad** y **claridad del código**, separando las responsabilidades en distintas capas.

---

## 1. De la Estructura Anterior a la Arquitectura Limpia (BLoC)

### 📦 Estructura Anterior (Simplificada):

lib/
├── providers/ # Lógica de autenticación, etc.
├── screens/ # Vistas (mezclaban UI y lógica)
├── services/ # Llamadas a API/Firebase
├── widgets/ # Widgets reutilizables
└── main.dart

### ✅ Nueva Estructura con Arquitectura Limpia (BLoC):

lib/
├── core/ # Fundamentos y utilidades transversales
├── data/ # Implementaciones de acceso a datos (Firebase, Backend)
├── domain/ # Lógica de negocio pura
├── presentation/ # UI + lógica de presentación (BLoC/Cubit + vistas)
├── firebase_options.dart
└── main.dart

---

## 2. Explicación de las Capas

### 2.1. `core/` - Fundamentos y Utilidades

- `constants/`: Constantes globales (colores, rutas de imágenes, duraciones, URLs base).
- `exceptions/`: Manejo estructurado de errores personalizados (`AppException`, `UserNotFoundException`, etc.).
- `utils/`: Validadores de entrada (`InputValidators`) para email, contraseña, teléfono, cédula profesional, etc.

---

### 2.2. `data/` - Acceso a Datos

#### `datasources/`:

- `AuthRemoteDataSource`: Autenticación con Firebase.
- `UserRemoteDataSource`: Comunicación con backend Node.js/PostgreSQL para obtener y actualizar usuarios.

🔁 **Migración:** los antiguos `providers` y `services` ahora se transforman en `datasources`.

#### `models/`:

- Modelos de datos: `UserModel`, `PatientModel`, `PsychologistModel`.
- Métodos: `fromJson()`, `toJson()`, `fromEntity()` para convertir entre capas.

#### `repositories/`:

- `AuthRepositoryImpl`: Usa `AuthRemoteDataSource` y `UserRemoteDataSource`.
- `UserRepositoryImpl`: Se conecta con `UserRemoteDataSource`.

---

### 2.3. `domain/` - Lógica de Negocio Pura

#### `entities/`:

- Clases inmutables y sin dependencias externas: `UserEntity`, `PatientEntity`, `PsychologistEntity`.

#### `repositories/`:

- Interfaces abstractas:
  - `AuthRepository`: Autenticación.
  - `UserRepository`: Datos del usuario.

#### `usecases/`:

Cada caso de uso orquesta una operación de negocio:

- `SignInUseCase`
- `RegisterUserUseCase`
- `GetUserRoleUseCase`

---

### 2.4. `presentation/` - Interfaz de Usuario y Presentación

#### Subcarpetas organizadas por funcionalidad:

- `auth/`, `patient/`, `psychologist/`

#### `bloc/` o `cubit/`:

- Ejemplo: `AuthBloc`
  - Maneja login, registro, logout.
  - Usa los `usecases` del `domain`.

#### `views/`:

Vistas principales:

- `LoginScreen`
- `RoleSelectionScreen`
- `RegisterPatientScreen`
- `RegisterPsychologistScreen`
- `PatientHomeScreen`
- `PsychologistHomeScreen`
- `ProfileScreenPatient`
- `ProfileScreenPsychologist`

#### `widgets/`:

Widgets reutilizables específicos para cada sección.

#### `shared/`:

Widgets reutilizables globales como:

- `CustomTextField`
- `ProgressBarWidget`

---

## 3. Flujo de Autenticación con BLoC (Ejemplo Detallado)

### `main.dart`:

- Inicializa Firebase y dependencias (datasources, repositorios, usecases).
- Configura `MultiBlocProvider` para inyectar `AuthBloc`.
- Dispara evento `AuthUserChanged` al inicio.
- Usa `AuthWrapper` como `home` del `MaterialApp`.

### `AuthWrapper`:

- Escucha estados de `AuthBloc`:
  - `AuthStatus.loading`: `SplashScreen`.
  - `AuthStatus.authenticatedPatient`: `PatientHomeScreen`.
  - `AuthStatus.authenticatedPsychologist`: `PsychologistHomeScreen`.
  - `AuthStatus.unauthenticated`: `LoginScreen`.

### `LoginScreen`:

- UI con campos de email y contraseña.
- Valida con `InputValidators`.
- Envía evento `AuthLoginRequested` a `AuthBloc`.
- Escucha estado: loading → loader, error → snackbar.

### `AuthBloc`:

- Recibe `AuthLoginRequested`.
- Emite `AuthState.loading()`.
- Llama a `SignInUseCase`.
- En éxito: `AuthUserChanged` (detectado por `authStateChanges`).
- En error: emite `AuthState.error()` y luego `AuthState.unauthenticated()`.

### `SignInUseCase`:

- Llama a `AuthRepository.signIn(email, password)`.

### `AuthRepositoryImpl`:

- Usa `AuthRemoteDataSource.signIn(...)`.
- Luego, `UserRemoteDataSource.getUserData(uid)` para obtener el rol.
- Convierte `UserModel` → `UserEntity`.

### `AuthRemoteDataSourceImpl`:

- Interactúa con `FirebaseAuth`.

### `UserRemoteDataSourceImpl`:

- Consulta al backend Node.js/PostgreSQL con `http.Client`.

### Backend Node.js/PostgreSQL:

- Busca `firebaseUid` y devuelve datos del usuario con su rol.

---

## 4. Beneficios de esta Arquitectura

✅ **Claridad y Organización:** Cada archivo tiene una única responsabilidad.  
🧩 **Mantenibilidad:** Cambios en una capa no afectan a otras.  
🚀 **Escalabilidad:** Añadir nuevas funcionalidades es más fácil.  
🧪 **Probabilidad:** `Usecases`, `Repositories` y `BLoC` pueden testearse de forma aislada.  
♻️ **Reutilización:** Los mismos `usecases` o `repositories` pueden usarse en diferentes vistas o cubits.

---

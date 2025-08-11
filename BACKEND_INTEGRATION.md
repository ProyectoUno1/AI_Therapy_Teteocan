# Integración Backend - Perfil Profesional de Psicólogos

## Campos del Modelo PsychologistModel

### Campos Básicos (ya existentes)

- `uid`: String - ID único del psicólogo
- `username`: String - Nombre completo del psicólogo
- `email`: String - Email del psicólogo
- `phoneNumber`: String - Teléfono de contacto
- `professionalLicense`: String - Número de cédula profesional
- `profilePictureUrl`: String? - URL de la foto de perfil
- `dateOfBirth`: DateTime - Fecha de nacimiento
- `createdAt`: DateTime - Fecha de creación del registro
- `updatedAt`: DateTime - Fecha de última actualización
- `role`: String - Rol (siempre 'psychologist')

### Campos de Perfil Profesional (nuevos)

- `specialty`: String? - Especialidad principal
- `rating`: double? - Calificación promedio (calculado por el sistema)
- `isAvailable`: bool - Disponibilidad actual (por defecto false)
- `description`: String? - Descripción profesional
- `hourlyRate`: double? - **MANEJADO POR EL ADMIN** - Tarifa por hora
- `schedule`: String? - Horario general de disponibilidad

### Campos Adicionales del Perfil Completo (nuevos)

- `professionalTitle`: String? - Título profesional (ej: "Psicóloga Clínica")
- `yearsExperience`: int? - Años de experiencia
- `education`: String? - Formación académica
- `certifications`: String? - Certificaciones adicionales
- `subSpecialties`: List<String>? - Sub-especialidades
- `availability`: Map<String, String>? - Horarios detallados por día

## Flujo de Registro de Psicólogos

### 1. Registro Básico

El psicólogo completa el registro básico con:

- Email, contraseña
- Nombre completo, teléfono
- Cédula profesional, fecha de nacimiento

### 2. Configuración del Perfil Profesional

Después del registro exitoso, el psicólogo completa:

- **Paso 1**: Información personal (nombre, título, cédula, foto)
- **Paso 2**: Experiencia profesional (años, descripción, educación)
- **Paso 3**: Especialidades y certificaciones adicionales
- **Paso 4**: Horarios de disponibilidad

### 3. Revisión Administrativa

- El perfil queda pendiente de revisión por el administrador
- El administrador establece las tarifas (`hourlyRate`)
- El administrador configura las modalidades de atención
- El administrador activa el perfil (`isAvailable = true`)

## Endpoints Requeridos

### Para Psicólogos

- `POST /psychologists/profile` - Crear/actualizar perfil profesional
- `GET /psychologists/profile/:id` - Obtener perfil completo
- `PUT /psychologists/profile/:id` - Actualizar información profesional

### Para Pacientes

- `GET /psychologists` - Listar psicólogos disponibles con filtros
- `GET /psychologists/:id` - Obtener detalles de un psicólogo específico

### Para Administradores

- `PUT /admin/psychologists/:id/rates` - Establecer tarifas
- `PUT /admin/psychologists/:id/status` - Activar/desactivar psicólogo
- `GET /admin/psychologists/pending` - Listar perfiles pendientes de revisión

## Estructura JSON de Ejemplo

```json
{
  "uid": "12345",
  "username": "Dra. María González",
  "email": "maria.gonzalez@example.com",
  "phone_number": "+1234567890",
  "professional_license": "PSI-12345",
  "profile_picture_url": "https://example.com/photo.jpg",
  "date_of_birth": "1985-03-15",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z",
  "role": "psychologist",
  "specialty": "Psicología Clínica",
  "rating": 4.8,
  "is_available": true,
  "description": "Especialista en terapia cognitivo-conductual con 10 años de experiencia.",
  "hourly_rate": 80.0,
  "schedule": "Lun-Vie 9:00-18:00",
  "professional_title": "Psicóloga Clínica",
  "years_experience": 10,
  "education": "Maestría en Psicología Clínica - Universidad Nacional",
  "certifications": "Certificación en Terapia Cognitivo-Conductual",
  "sub_specialties": ["Depresión", "Ansiedad", "Terapia Cognitiva"],
  "availability": {
    "Lunes": "09:00-18:00",
    "Martes": "09:00-18:00",
    "Miércoles": "09:00-18:00",
    "Jueves": "09:00-18:00",
    "Viernes": "09:00-18:00",
    "Sábado": null,
    "Domingo": null
  }
}
```

## Notas Importantes

1. **Tarifas**: Los psicólogos NO pueden establecer sus propias tarifas. Estas son establecidas por el administrador.

2. **Modalidades**: Las modalidades de atención (presencial/en línea) son configuradas por el administrador, no por el psicólogo.

3. **Estado de Disponibilidad**: Los perfiles inician como `is_available: false` y deben ser activados por el administrador después de la revisión.

4. **Validaciones**:

   - La descripción debe tener al menos 50 caracteres
   - Los años de experiencia deben ser un número positivo
   - La especialidad es obligatoria
   - Al menos un día de disponibilidad debe estar configurado

5. **Frontend Listo**: El frontend ya está preparado para recibir estos datos y mostrarlos en la interfaz de pacientes.

## Archivos Modificados

- `lib/data/models/psychologist_model.dart` - Modelo actualizado con nuevos campos
- `lib/presentation/psychologist/views/professional_info_setup_screen.dart` - Pantalla de configuración profesional
- `lib/presentation/auth/views/register_psychologist_screen.dart` - Integración del flujo de registro
- `lib/presentation/patient/views/psychologists_list_screen.dart` - Lista de psicólogos para pacientes

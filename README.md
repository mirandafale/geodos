# Geodos

Portal Flutter para visor público de proyectos y panel de administración conectado con Firebase.

## Configuración rápida
1. Crea un proyecto de Firebase y descarga `firebase_options.dart` (FlutterFire CLI) para web/ios/android/web.
2. Habilita **Authentication > Email/Password** y crea los usuarios admins. Actualiza los correos permitidos en `lib/services/auth_service.dart` (`_adminEmails`).
3. Crea las colecciones `projects` y `news` en Firestore y habilita **Storage** para las imágenes de noticias.
4. Ejecuta `flutter pub get` (desde un entorno con Flutter/Dart instalado) para resolver las dependencias nuevas (`firebase_storage`, `image_picker`, etc.).

## Reglas recomendadas (Firestore / Storage)
Ajusta los ID/paths a tus necesidades. Permite lectura pública y escritura solo a administradores autenticados (por UID o claims):

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      // Puedes validar por claim custom o por lista de emails en Firestore.
      return request.auth != null && request.auth.token.admin == true;
    }

    match /projects/{projectId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /news/{newsId} {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
}
```

```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /news/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
  }
}
```

## Uso
- `/admin`: tablero con pestañas para **Proyectos** y **Noticias** (CRUD, subida de imagen, publicación).
- Home muestra el carrusel de noticias publicadas y el visor sigue siendo público con filtros.
- Sesión de admin persistente gracias a Firebase Auth y el guardián de ruta `AdminGate`.

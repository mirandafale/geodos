# geodos

Portal GEODOS con integración de Firebase para web y Android.

## Seguridad de Firebase

Para desplegar las reglas de Firestore se recomienda partir de esta estructura:

- `contact_messages`: permitir `create` al público y restringir las lecturas a administradores.
- `projects` y `news`: solo administradores pueden crear/actualizar/eliminar documentos.

Configura las reglas según tu modelo de autenticación antes de publicar.

# NOVA — catálogo Flutter

Aplicación Android y web conectada al backend Spring Boot de ../../procesos.
No contiene productos ficticios en producción ni credenciales incrustadas.

## Ejecutar

Desde `app/store`, copia la plantilla si todavía no tienes un archivo `.env`:

```powershell
Copy-Item .env.example .env
```

Edita `.env` y pon la URL base del backend, por ejemplo
`API_BASE_URL=https://TU-SERVICIO.onrender.com`. Usa solo la URL base, sin
agregar las rutas de la API.

```powershell
flutter pub get
flutter run --dart-define-from-file=.env
```

En IntelliJ puedes guardar `--dart-define-from-file=.env` en **Additional run args**.
Si cambias el archivo, detén y vuelve a ejecutar la app.

Para desarrollo local en modo debug, puedes omitir el archivo. El emulador
Android usa `http://10.0.2.2:8080` y web usa `http://127.0.0.1:8080`.
En un teléfono físico, usa la IP LAN del equipo que ejecuta el backend.
Fuera de debug se requiere una URL HTTPS explícita.

El archivo `.env` se ignora en Git. Versiona `.env.example`. La URL de la API
queda incluida en el APK, así que el archivo debe contener solo configuración
pública de la app.

Para generar los APK de la demo con el backend de Render:

```powershell
flutter build apk --release --split-per-abi --dart-define-from-file=.env
```
## Web

En la terminal del backend, antes de iniciarlo:

    $env:CORS_ORIGINS = 'http://localhost:5173,http://127.0.0.1:5173'

Después, desde esta carpeta:

    flutter run -d chrome --web-hostname=localhost --web-port=5173 --dart-define=API_BASE_URL=http://localhost:8080

El puerto y el origen deben coincidir con CORS_ORIGINS. La política CORS la controla
el backend; no se desactiva la seguridad del navegador.

## Acceso administrativo

Mantener pulsado el logotipo NOVA de la cabecera para abrir el acceso al panel.
En web también se puede abrir #/admin. Introducir la cuenta única configurada en
ADMIN_USERNAME / ADMIN_PASSWORD del backend.

El acceso discreto es una decisión de interfaz. Todas las escrituras se autentican
en Spring Security. La app verifica las credenciales antes de abrir el panel y
protege sus rutas. Un 401 cierra la sesión.

La credencial Basic se conserva únicamente en memoria durante la sesión: no se
guarda en archivos, preferencias, almacenamiento web ni código fuente. Al cerrar
la app se debe iniciar sesión otra vez. Las consultas públicas nunca adjuntan
la credencial. Las operaciones administrativas envían X-Admin-Request: true.

El panel permite:
- Crear, editar y eliminar celulares.
- Publicarlos u ocultarlos como borradores.
- Administrar marcas (el backend impide borrar marcas con celulares).
- Añadir y eliminar imágenes. Se guarda primero el celular; luego se añaden fotos.
- Ver todos los registros con búsqueda, orden y paginación.
- Cerrar sesión.

Las fotos se seleccionan desde la galería, con límite de 8 imágenes y 5 MB cada una.
El backend valida, corrige orientación y convierte a WebP; Flutter no se limita a
cambiar la extensión. La imagen con menor orden es portada. La recuperación de
selecciones interrumpidas en Android se ofrece al reabrir un editor existente.

## Estructura

    lib/
      app/                         navegación, inyección y ciclo de vida
      core/config/                 URL del backend por entorno
      core/network/                cliente HTTP y errores
      core/realtime/               lector SSE y reconexión
      core/theme/                  tema visual
      features/
        auth/application/          sesión administrativa en memoria
        auth/presentation/         inicio de sesión
        catalog/domain/            modelos inmutables y filtros
        catalog/data/              repositorio de acceso a la API
        catalog/application/       controladores del catálogo y detalle
        catalog/presentation/      pantallas y widgets del catálogo
        admin/application/         estado del editor
        admin/presentation/        panel, marcas y formulario
      shared/widgets/              componentes visuales comunes
    test/                          pruebas de estado, API, navegación y diseño
    assets/fonts/                  Inter y licencia OFL

Se usan ViewModels con ChangeNotifier, repositorio e inyección explícita mediante
Provider. Los widgets no contienen peticiones HTTP. GoRouter protege las rutas.
No se agregan capas de casos de uso ni generación de código que este proyecto
pequeño no necesita.

## Actualización en vivo

Una conexión SSE por aplicación escucha /api/catalogo/eventos.
El catálogo y el detalle se actualizan al recibir sincronizar o catalogo-actualizado.
Se conserva página, marca, texto, rango de precio y orden.

Si llega un aviso durante una consulta, queda una recarga pendiente.
Las respuestas de búsquedas antiguas se descartan. Si desaparece la última página
por una eliminación, se consulta la última página válida. Un producto eliminado
o despublicado se retira del detalle abierto.

El lector procesa eventos SSE completos, UTF-8 y datos multilínea; no supone que
cada chunk HTTP sea un evento. Usa latidos del servidor, tiempo de espera y reconexión
con espera progresiva y variación aleatoria. Al pausar la aplicación cierra el canal;
al regresar vuelve a conectarse y sincroniza. Los editores no sobrescriben cambios
del formulario por eventos remotos.

## Verificar y compilar

    dart format lib test
    flutter analyze
    flutter test
    flutter build web
    flutter build apk --debug

Las pruebas usan repositorios/clientes simulados y NO necesitan un backend.
Los datos de demostración existen solo en test/support/fakes.dart.
Las capturas de referencia de test/goldens se verifican en las pruebas de widgets.
Para regenerarlas deliberadamente después de un cambio visual:

    flutter test --update-goldens

La tipografía y los iconos se cargan explícitamente en esas pruebas para que las
capturas no dependan de fuentes instaladas en el sistema.

Para comprobar además el contrato real con Spring Boot y PostgreSQL aislados:

    .\tool\smoke-backend.ps1

Este script crea un PostgreSQL temporal en 127.0.0.1:55449 y un backend temporal en
127.0.0.1:18080, usa datos y una cuenta exclusivos de prueba y los detiene al terminar.
Requiere PostgreSQL 18, Java 18 y el JAR ya compilado en procesos/target.
No utiliza la base de datos ni la cuenta habituales. Sus archivos quedan en build/backend-smoke.

## Referencias

- Arquitectura Flutter: https://docs.flutter.dev/app-architecture/recommendations
- Redes: https://docs.flutter.dev/data-and-backend/networking
- Selector de imágenes: https://pub.dev/packages/image_picker
- Tipografía Inter: https://github.com/google/fonts/tree/main/ofl/inter

### Compilacion Android en Windows

En android/gradle.properties se desactiva la compilacion incremental de Kotlin para
que el proyecto en D: y Pub Cache en C: no provoquen el error de raices diferentes.
Esto no cambia la version de Java del backend ni las opciones de lenguaje Android.
Referencia: https://kotlinlang.org/docs/gradle-compilation-and-caches.html
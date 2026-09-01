# ClaudeBar

<p align="center">
  <img src="../assets/icons/claudebar-macOS-Dark-1024x1024@1x.png" alt="ClaudeBar Ícono" width="128" height="128">
</p>

<p align="center">
  <strong>Una aplicación nativa de barra de menú de macOS para monitorear los límites de uso de Claude en tiempo real.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="Licencia">
</p>

<p align="center">
  <a href="../README.md">English</a> •
  <a href="README-TR.md">Türkçe</a> •
  <a href="README-ZH.md">中文</a> •
  <a href="README-HI.md">हिन्दी</a> •
  <a href="README-ES.md">Español</a> •
  <a href="README-FR.md">Français</a> •
  <a href="README-AR.md">العربية</a> •
  <a href="README-PT.md">Português</a> •
  <a href="README-JA.md">日本語</a> •
  <a href="README-RU.md">Русский</a> •
  <a href="README-IT.md">Italiano</a>
</p>

> **Nota:** Esta traducción fue generada por IA y puede contener errores o inexactitudes. Envíe un Pull Request para correcciones.

---

## Características

- **Monitoreo de Uso en Tiempo Real** - Vea los límites de sesión actual y semanales de un vistazo
- **Insignia de Plan** - Muestra su suscripción actual (Pro, Max 5x, Max 20x, Team, Enterprise)
- **Límites Semanales por Modelo** - Filas separadas para Fable, Opus y Sonnet cuando su plan las reporta
- **Créditos de Uso** - Muestra los créditos únicos y cuándo vencen
- **Soporte de Uso Extra** - Rastree el gasto de pago por uso y vea por qué está deshabilitado cuando su organización lo desactiva
- **Barras de progreso con código de color** - Verde, amarillo, naranja, rojo según el porcentaje de uso
- **Soporte multiidioma** - Inglés, turco, chino, español, ruso con selector de idioma en la app
- **Notificaciones Personalizables** - Alertas nativas del Centro de Notificaciones al 50%, 75%, 100% o al reiniciarse, para cada límite monitoreado
- **Actualización Automática** - Intervalo de actualización configurable (30s, 1m, 2m, 5m)
- **Iniciar al Arrancar** - Opcionalmente inicie con su Mac
- **Porcentaje en Barra de Menú** - Mostrar/ocultar porcentaje junto al ícono
- **Experiencia Nativa** - Construido con SwiftUI, sigue las directrices de diseño de macOS
- **Ligero** - Mínimo uso de recursos, sin Electron
- **Enfocado en Privacidad** - Sin análisis, sin telemetría

## Capturas de Pantalla

<p align="center">
  <img src="../screenshots/app-screenshot.png" alt="Vista General de ClaudeBar" width="380">
</p>

<p align="center">
  <em>Monitoreo de uso en tiempo real con insignia de plan</em>
</p>

<details>
<summary><strong>Más Capturas de Pantalla</strong></summary>

<br>

| Configuración | Notificaciones | Acerca de |
|:-------------:|:--------------:|:---------:|
| <img src="../screenshots/settings-screenshot.png" alt="Configuración" width="250"> | <img src="../screenshots/notifications-screenshot.png" alt="Notificaciones" width="250"> | <img src="../screenshots/about-screenshot.png" alt="Acerca de" width="250"> |

</details>

## Requisitos

- macOS 14.0 (Sonoma) o posterior
- [Claude Code](https://claude.ai/code) instalado y con sesión iniciada
- Suscripción activa de Claude Pro, Max o Team

## Instalación

### Homebrew (Recomendado)

```bash
brew install --cask kemalasliyuksek/claudebar/claudebar-monitor
```

Esto maneja automáticamente la seguridad de macOS Gatekeeper — no se necesitan pasos adicionales.

### Descargar Binario Precompilado

Descargue el último `.app` desde la página de [Releases](https://github.com/kemalasliyuksek/claudebar/releases), luego arrástrelo a su carpeta de Aplicaciones.

> **Nota:** Si macOS muestra "ClaudeBar está dañado y no se puede abrir", ejecute el siguiente comando para eliminar la marca de cuarentena:
> ```bash
> xattr -cr ClaudeBar.app
> ```

### Compilar desde el Código Fuente

```bash
git clone https://github.com/kemalasliyuksek/claudebar.git
cd claudebar
./build.sh
```

El paquete de la aplicación se creará en `.build/release/ClaudeBar.app`.

Para instalar:
```bash
cp -r .build/release/ClaudeBar.app /Applications/
```

## Uso

1. Asegúrese de haber iniciado sesión en Claude Code (el comando `claude` debe funcionar en la terminal)
2. Inicie ClaudeBar desde Aplicaciones o Spotlight
3. Haga clic en el ícono del medidor en su barra de menú para ver los límites de uso

### Configuración

Haga clic en el ícono ⚙️ para configurar:

| Ajuste | Descripción |
|--------|-------------|
| Iniciar al arrancar | Iniciar automáticamente al iniciar sesión |
| Mostrar % en barra de menú | Mostrar porcentaje junto al ícono de la barra de menú |
| Idioma | Elige el idioma de la app (Sistema, English, Türkçe, 中文, Español, Русский) |
| Intervalo de actualización | Con qué frecuencia obtener datos de uso (30s - 5m) |
| Notificar al 50% | Enviar notificación al 50% de uso |
| Notificar al 75% | Enviar notificación al 75% de uso |
| Notificar al alcanzar límite | Enviar notificación cuando se alcance el límite |
| Notificar al reiniciarse | Enviar notificación cuando el límite se reinicie |

### Acerca de

Haga clic en el ícono ⓘ para ver información de la aplicación, créditos y enlaces.

## Cómo Funciona

ClaudeBar lee las credenciales OAuth del Llavero de macOS que Claude Code almacena cuando inicia sesión. Luego consulta el mismo endpoint de uso que utiliza el comando `/usage` de Claude Code.

Cuando el token está por vencer, ClaudeBar lo renueva con el mismo protocolo que Claude Code: primero toma el bloqueo de renovación de Claude Code (`~/.claude.lock`), vuelve a leer el Llavero y usa el token nuevo si Claude Code ya lo renovó; de lo contrario lo renueva por su cuenta y lo actualiza en su lugar. La escritura se pasa a la herramienta `security` por stdin, así que el token nunca aparece en los argumentos del proceso. Si el Llavero no está disponible, se usa `~/.claude/.credentials.json` como respaldo.

### Arquitectura

```
┌─────────────────┐                      ┌───────────────────────────┐
│                 │  Almacena tokens     │                           │
│   Claude Code   │─────────────────────▶│     Llavero de macOS      │
│   (CLI login)   │                      │ "Claude Code-credentials" │
└─────────────────┘                      └───────────────────────────┘
                                                     │
                                                     │ Lee tokens
                                                     ▼
┌─────────────────┐                      ┌───────────────────────────┐
│                 │ GET /api/oauth/usage │                           │
│  Anthropic API  │◀─────────────────────│        ClaudeBar          │
│                 │─────────────────────▶│                           │
└─────────────────┘    Datos de uso      └───────────────────────────┘
```

## Notas Importantes

### Acceso al Llavero

Las lecturas y escrituras pasan por la herramienta `security` del sistema, la misma ruta que usa Claude Code, así que normalmente no aparece ninguna solicitud adicional del Llavero. Si macOS la muestra, haga clic en **Permitir Siempre**.

### Notificaciones

En el primer inicio, macOS pregunta si ClaudeBar puede mostrar notificaciones. Si lo rechaza, puede activarlas más tarde en Ajustes del Sistema › Notificaciones › ClaudeBar.

### Privacidad

- Solo lee las credenciales que Claude Code ya almacenó y escribe únicamente los tokens renovados
- Toda la comunicación usa HTTPS
- No se almacenan datos fuera del Llavero del sistema
- Sin análisis ni telemetría
- Completamente de código abierto

## Contribuir

¡Las contribuciones son bienvenidas! No dude en enviar un Pull Request.

1. Haga fork del repositorio
2. Cree su rama de característica (`git checkout -b feature/característica-increíble`)
3. Haga commit de sus cambios (`git commit -m 'Añadir característica increíble'`)
4. Haga push a la rama (`git push origin feature/característica-increíble`)
5. Abra un Pull Request

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - consulte el archivo [LICENSE](../LICENSE) para más detalles.

## Autor

**Kemal Aslıyüksek** - [@kemalasliyuksek](https://github.com/kemalasliyuksek)

## Descargo de Responsabilidad

Este es un proyecto comunitario no oficial y no está afiliado, mantenido oficialmente ni respaldado por Anthropic. Úselo bajo su propia discreción.

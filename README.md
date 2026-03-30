# 🚵 TrailMate — MTB App

Aplicación web para el mundo de la bicicleta de montaña. Gestiona tu taller, registra actividades, sigue tu plan de entrenamiento y conecta con otros riders.

## 🌐 Demo en vivo

**[trailmate.app](https://tuusuario.github.io/trailmate)** ← actualiza con tu URL

## 🏗️ Stack técnico

| Capa | Tecnología |
|---|---|
| Frontend (actual) | HTML · CSS · JavaScript |
| Frontend (próximo) | Flutter (iOS + Android + Web) |
| Backend / Auth | Supabase (PostgreSQL + Auth + RLS) |
| Despliegue | GitHub Pages (automático en cada push) |
| Región BD | EU West · Frankfurt |

## 📱 Módulos

- **Dashboard** — resumen de actividad y estado de la bici
- **🔧 Taller Virtual** — seguimiento de componentes con alertas de mantenimiento
- **⚡ Entrenamientos** — plan semanal y zonas de entrenamiento *(en desarrollo)*
- **🗺️ Rutas GPS** — rutas guardadas con track *(en desarrollo)*
- **🤖 Coach IA** — entrenador personal con contexto de tus datos
- **👥 Social** — red social de riders *(próximamente)*

## 🚀 Despliegue local

Abre `index.html` directamente en el navegador. No requiere servidor ni dependencias locales — todo corre en el cliente contra Supabase.

## 🗄️ Base de datos

El schema completo está en `supabase/migrations/001_initial_schema.sql`.

Tablas principales:
- `profiles` — perfil del rider (creado automáticamente al registrarse)
- `bikes` — garage del usuario
- `components` — componentes con estado calculado automáticamente en BD
- `service_log` — historial de servicios
- `activities` — actividades registradas
- `training_plans` + `planned_sessions` — plan del Coach IA
- `routes` — rutas GPX guardadas

## 📁 Estructura del repositorio

```
trailmate/
├── index.html                          # App principal (conectada a Supabase)
├── docs/
│   ├── prototype.html                  # Prototipo visual inicial
│   └── taller_v1.html                  # Pantalla Taller standalone
├── supabase/
│   └── migrations/
│       └── 001_initial_schema.sql      # Schema completo con RLS
└── .github/
    └── workflows/
        └── deploy.yml                  # Deploy automático a GitHub Pages
```

## ⚙️ Variables de entorno

Las credenciales de Supabase están embebidas en `index.html` (anon key pública, segura para el frontend gracias a RLS). Para producción se recomienda moverlas a variables de entorno de GitHub Actions.

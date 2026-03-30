-- ═══════════════════════════════════════════════════════════
-- TRAILMATE — Schema completo
-- Pega esto en Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════

-- ── EXTENSIONES ──────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ── TABLA: profiles ──────────────────────────────────────
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  username     text unique not null,
  full_name    text,
  location     text,
  avatar_url   text,
  bio          text,
  riding_style text[] default '{}',
  total_km     numeric(10,2) default 0,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

-- ── TABLA: bikes ─────────────────────────────────────────
create table public.bikes (
  id            uuid primary key default uuid_generate_v4(),
  owner_id      uuid not null references public.profiles(id) on delete cascade,
  name          text not null,
  brand         text,
  model         text,
  year          int,
  frame_size    text,
  wheel_size    text,
  color         text,
  serial_number text,
  purchase_date date,
  total_km      numeric(10,2) default 0,
  total_hours   numeric(8,2)  default 0,
  is_primary    boolean default false,
  photo_url     text,
  notes         text,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- ── TABLA: components ────────────────────────────────────
-- El estado (ok/warn/crit) se calcula automáticamente
create table public.components (
  id             uuid primary key default uuid_generate_v4(),
  bike_id        uuid not null references public.bikes(id) on delete cascade,
  owner_id       uuid not null references public.profiles(id) on delete cascade,
  category       text not null check (category in
                   ('transmision','frenos','suspension','ruedas','cockpit','otro')),
  name           text not null,
  brand          text,
  model          text,
  installed_at   date,
  installed_km   numeric(10,2) default 0,
  interval_type  text check (interval_type in ('km','hours','months','visual')),
  interval_value numeric(10,2),
  current_usage  numeric(10,2) default 0,
  status         text generated always as (
    case
      when interval_type = 'visual'       then 'ok'
      when interval_value is null         then 'ok'
      when current_usage >= interval_value           then 'crit'
      when current_usage >= interval_value * 0.8     then 'warn'
      else 'ok'
    end
  ) stored,
  is_active  boolean default true,
  notes      text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ── TABLA: service_log ───────────────────────────────────
create table public.service_log (
  id              uuid primary key default uuid_generate_v4(),
  component_id    uuid not null references public.components(id) on delete cascade,
  bike_id         uuid not null references public.bikes(id)      on delete cascade,
  owner_id        uuid not null references public.profiles(id)   on delete cascade,
  service_type    text not null check (service_type in
                    ('instalacion','ajuste','servicio','cambio','inspeccion','otro')),
  title           text not null,
  description     text,
  performed_by    text,
  cost            numeric(8,2),
  km_at_service   numeric(10,2),
  service_date    date not null default current_date,
  next_service_km numeric(10,2),
  photos          text[] default '{}',
  created_at      timestamptz default now()
);

-- ── TABLA: activities ────────────────────────────────────
create table public.activities (
  id              uuid primary key default uuid_generate_v4(),
  owner_id        uuid not null references public.profiles(id) on delete cascade,
  bike_id         uuid references public.bikes(id) on delete set null,
  title           text not null,
  activity_type   text default 'trail' check (activity_type in
                    ('trail','enduro','xc','dh','road','commute','other')),
  distance_km     numeric(8,3),
  elevation_m     int,
  duration_sec    int,
  avg_speed_kmh   numeric(5,2),
  max_speed_kmh   numeric(5,2),
  avg_hr          int,
  max_hr          int,
  avg_cadence     int,
  avg_power_w     int,
  tss             numeric(7,2),
  gpx_url         text,
  route_points    jsonb,
  recorded_at     timestamptz default now(),
  external_id     text,
  external_source text,
  created_at      timestamptz default now()
);

-- ── TABLA: training_plans ────────────────────────────────
create table public.training_plans (
  id           uuid primary key default uuid_generate_v4(),
  owner_id     uuid not null references public.profiles(id) on delete cascade,
  name         text not null,
  start_date   date,
  end_date     date,
  is_active    boolean default true,
  created_by   text default 'coach_ia',
  created_at   timestamptz default now()
);

-- ── TABLA: planned_sessions ──────────────────────────────
create table public.planned_sessions (
  id             uuid primary key default uuid_generate_v4(),
  plan_id        uuid not null references public.training_plans(id) on delete cascade,
  owner_id       uuid not null references public.profiles(id) on delete cascade,
  scheduled_date date not null,
  title          text not null,
  session_type   text,
  description    text,
  target_km      numeric(7,2),
  target_zone    text,
  target_tss     numeric(7,2),
  status         text default 'pending' check (status in ('pending','done','skipped')),
  activity_id    uuid references public.activities(id) on delete set null,
  created_at     timestamptz default now()
);

-- ── TABLA: routes ────────────────────────────────────────
create table public.routes (
  id           uuid primary key default uuid_generate_v4(),
  owner_id     uuid not null references public.profiles(id) on delete cascade,
  name         text not null,
  description  text,
  distance_km  numeric(8,3),
  elevation_m  int,
  difficulty   text check (difficulty in ('easy','medium','hard','expert')),
  route_type   text check (route_type in ('trail','enduro','xc','dh','road')),
  gpx_url      text,
  route_points jsonb,
  is_public    boolean default false,
  times_ridden int default 0,
  avg_time_sec int,
  created_at   timestamptz default now()
);

-- ═══════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS) — cada usuario solo ve sus datos
-- ═══════════════════════════════════════════════════════════

alter table public.profiles        enable row level security;
alter table public.bikes           enable row level security;
alter table public.components      enable row level security;
alter table public.service_log     enable row level security;
alter table public.activities      enable row level security;
alter table public.training_plans  enable row level security;
alter table public.planned_sessions enable row level security;
alter table public.routes          enable row level security;

-- profiles: ver y editar solo el propio
create policy "profiles_own" on public.profiles
  using (auth.uid() = id) with check (auth.uid() = id);

-- bikes
create policy "bikes_own" on public.bikes
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

-- components
create policy "components_own" on public.components
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

-- service_log
create policy "service_log_own" on public.service_log
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

-- activities
create policy "activities_own" on public.activities
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

-- training_plans
create policy "plans_own" on public.training_plans
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

-- planned_sessions
create policy "sessions_own" on public.planned_sessions
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

-- routes: propias siempre; públicas solo lectura para todos
create policy "routes_own" on public.routes
  using (auth.uid() = owner_id or is_public = true)
  with check (auth.uid() = owner_id);

-- ═══════════════════════════════════════════════════════════
-- TRIGGER: auto-crear profile al registrarse
-- ═══════════════════════════════════════════════════════════

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, username, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'avatar_url', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ═══════════════════════════════════════════════════════════
-- TRIGGER: actualizar updated_at automáticamente
-- ═══════════════════════════════════════════════════════════

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger bikes_updated_at
  before update on public.bikes
  for each row execute procedure public.set_updated_at();

create trigger components_updated_at
  before update on public.components
  for each row execute procedure public.set_updated_at();

-- ═══════════════════════════════════════════════════════════
-- FUNCIÓN: recalcular current_usage en components
-- Se llama desde la app cada vez que se registra una actividad
-- ═══════════════════════════════════════════════════════════

create or replace function public.update_bike_km(
  p_bike_id uuid,
  p_km      numeric
)
returns void language plpgsql security definer as $$
begin
  -- Actualizar odómetro de la bici
  update public.bikes
  set total_km = total_km + p_km,
      updated_at = now()
  where id = p_bike_id;

  -- Actualizar uso de todos los componentes activos de esa bici
  -- que midan por kilómetros
  update public.components
  set current_usage = current_usage + p_km,
      updated_at = now()
  where bike_id = p_bike_id
    and is_active = true
    and interval_type = 'km';
end;
$$;

-- ═══════════════════════════════════════════════════════════
-- DATOS DE EJEMPLO (demo user — reemplaza el UUID por el tuyo)
-- Para obtener tu UUID: Auth → Users en el dashboard de Supabase
-- ═══════════════════════════════════════════════════════════

-- Descomenta y ajusta cuando tengas tu primer usuario registrado:

/*
-- Insertar bici
insert into public.bikes (owner_id, name, brand, model, year, frame_size, wheel_size, total_km, is_primary)
values (
  'TU-UUID-AQUI',
  'Santa Cruz Hightower CC',
  'Santa Cruz', 'Hightower CC', 2023, 'M', '29"', 4218, true
);

-- Insertar componentes (usa el id de la bici que acabas de crear)
insert into public.components (bike_id, owner_id, category, name, brand, model, installed_at, installed_km, interval_type, interval_value, current_usage)
values
  ('BIKE-UUID', 'TU-UUID', 'transmision', 'Cadena',            'KMC',      'X12',           '2024-03-01', 2978, 'km',    2000, 1240),
  ('BIKE-UUID', 'TU-UUID', 'transmision', 'Cassette',          'Shimano',  'XT 10-51T',     '2024-01-01', 2118, 'km',    5000, 2100),
  ('BIKE-UUID', 'TU-UUID', 'transmision', 'Desviador trasero', 'Shimano',  'RD-M8100',      '2023-02-01', 0,    'km',     800,  840),
  ('BIKE-UUID', 'TU-UUID', 'frenos',      'Pastillas delantera','Shimano', 'XT J05A-RF',    '2024-06-01', 3558, 'visual', null, 0),
  ('BIKE-UUID', 'TU-UUID', 'frenos',      'Pastillas trasera', 'Shimano',  'XT J05A-RF',    '2023-10-01', 1418, 'visual', null, 0),
  ('BIKE-UUID', 'TU-UUID', 'frenos',      'Líquido de frenos', 'Shimano',  'Mineral Oil',   '2023-09-01', 1218, 'months', 12,   18),
  ('BIKE-UUID', 'TU-UUID', 'suspension',  'Horquilla delantera','RockShox','Pike Ultimate', '2022-02-01', 0,    'hours',  200,  208),
  ('BIKE-UUID', 'TU-UUID', 'suspension',  'Amortiguador trasero','Fox',    'Float X2 Factory','2024-02-01',3558, 'hours', 200,  62);
*/

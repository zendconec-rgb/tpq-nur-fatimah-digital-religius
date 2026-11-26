-- TPQ NUR FATIMAH DIGITAL RELIGIUS
-- Supabase PostgreSQL foundation. Review and run in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'staff' check (role in ('admin','kepala_tpq','bendahara','tata_usaha','guru','viewer')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.academic_years (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  start_date date,
  end_date date,
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  level text,
  academic_year_id uuid references public.academic_years(id),
  notes text,
  created_at timestamptz not null default now(),
  unique(name, academic_year_id)
);

create table if not exists public.teachers (
  id uuid primary key default gen_random_uuid(),
  teacher_code text unique,
  full_name text not null,
  phone text,
  email text,
  address text,
  position text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.guardians (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  phone text,
  email text,
  address text,
  relationship text,
  created_at timestamptz not null default now()
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  student_code text not null unique,
  full_name text not null,
  gender text check (gender in ('L','P')),
  birth_date date,
  address text,
  guardian_id uuid references public.guardians(id),
  class_id uuid references public.classes(id),
  enrollment_date date default current_date,
  status text not null default 'aktif' check (status in ('aktif','nonaktif','lulus','pindah')),
  qr_token uuid not null default gen_random_uuid() unique,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.attendance_sessions (
  id uuid primary key default gen_random_uuid(),
  session_date date not null default current_date,
  class_id uuid references public.classes(id),
  subject text,
  starts_at time,
  ends_at time,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references public.attendance_sessions(id) on delete cascade,
  student_id uuid references public.students(id) on delete cascade,
  teacher_id uuid references public.teachers(id) on delete cascade,
  status text not null check (status in ('hadir','terlambat','izin','sakit','alfa')),
  scanned_at timestamptz,
  note text,
  recorded_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  check ((student_id is not null and teacher_id is null) or (student_id is null and teacher_id is not null))
);
create unique index if not exists attendance_student_once on public.attendance_records(session_id, student_id) where student_id is not null;
create unique index if not exists attendance_teacher_once on public.attendance_records(session_id, teacher_id) where teacher_id is not null;

create table if not exists public.fee_types (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  amount numeric(14,2) not null default 0 check (amount >= 0),
  recurring boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  invoice_number text not null unique,
  student_id uuid not null references public.students(id),
  fee_type_id uuid references public.fee_types(id),
  description text not null,
  period text,
  amount numeric(14,2) not null check (amount >= 0),
  due_date date,
  status text not null default 'unpaid' check (status in ('unpaid','partial','paid','void')),
  created_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  receipt_number text not null unique,
  invoice_id uuid references public.invoices(id),
  student_id uuid not null references public.students(id),
  paid_at timestamptz not null default now(),
  amount numeric(14,2) not null check (amount > 0),
  method text not null check (method in ('tunai','transfer','qris','ewallet','lainnya')),
  reference text,
  received_by uuid references public.profiles(id),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.cash_transactions (
  id uuid primary key default gen_random_uuid(),
  transaction_date timestamptz not null default now(),
  direction text not null check (direction in ('masuk','keluar')),
  category text not null,
  description text not null,
  amount numeric(14,2) not null check (amount > 0),
  payment_method text,
  reference text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.letters (
  id uuid primary key default gen_random_uuid(),
  letter_number text not null unique,
  letter_type text not null,
  subject text not null,
  recipient text,
  letter_date date not null default current_date,
  content text not null,
  student_id uuid references public.students(id),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create or replace function public.current_user_role()
returns text language sql stable security definer set search_path = public
as $$
  select role from public.profiles where id = auth.uid() and active = true
$$;

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public
as $$
  select exists(select 1 from public.profiles where id = auth.uid() and active = true)
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$
  select exists(select 1 from public.profiles where id = auth.uid() and active = true and role = 'admin')
$$;

alter table public.profiles enable row level security;
alter table public.academic_years enable row level security;
alter table public.classes enable row level security;
alter table public.teachers enable row level security;
alter table public.guardians enable row level security;
alter table public.students enable row level security;
alter table public.attendance_sessions enable row level security;
alter table public.attendance_records enable row level security;
alter table public.fee_types enable row level security;
alter table public.invoices enable row level security;
alter table public.payments enable row level security;
alter table public.cash_transactions enable row level security;
alter table public.letters enable row level security;

-- Signed-in active staff can read operational records. Writes are role-restricted.
create policy "profiles read self or admin" on public.profiles for select to authenticated using (id = auth.uid() or public.is_admin());
create policy "profiles admin manage" on public.profiles for all to authenticated using (public.is_admin()) with check (public.is_admin());

do $$
declare t text;
begin
  foreach t in array array['academic_years','classes','teachers','guardians','students','attendance_sessions','attendance_records','fee_types','invoices','payments','cash_transactions','letters']
  loop
    execute format('create policy "%s staff read" on public.%I for select to authenticated using (public.is_staff())', t, t);
    execute format('create policy "%s admin write" on public.%I for all to authenticated using (public.is_admin()) with check (public.is_admin())', t, t);
  end loop;
end $$;

-- Admin user must first be created in Supabase Authentication.
-- Promote the intended administrator by replacing the UUID below after first sign-in:
-- update public.profiles set role='admin' where id='AUTH_USER_UUID';

create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles(id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    case when lower(coalesce(new.email,'')) = 'tpq.nurfatimah@gmail.com' then 'admin' else 'staff' end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_auth_user();

create index if not exists students_class_idx on public.students(class_id);
create index if not exists students_status_idx on public.students(status);
create index if not exists invoices_student_idx on public.invoices(student_id);
create index if not exists payments_student_idx on public.payments(student_id);
create index if not exists attendance_date_idx on public.attendance_sessions(session_date);

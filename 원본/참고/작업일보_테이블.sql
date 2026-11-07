-- =====================================================================
-- 작업일보 테이블 · (가상) 동백정밀 · Supabase(PostgreSQL) 실습용
-- 기획서: 참고/작업일보앱_기획서.md
-- 교육용 가상 데이터. 실존 기업·인물과 무관.
--
-- 적용 방법(5차시)
--   · Claude Code + Supabase MCP: read_only 없이 연결한 실습 전용 프로젝트에서
--     "참고/작업일보_테이블.sql 내용을 migration 으로 적용해줘" → apply_migration (승인 후)
--   · 또는 Supabase 대시보드 SQL Editor 에 전체 붙여 넣고 실행 (당일 화면 기준)
--   · 적용 후 get_advisors 로 보안 경고 0건 확인
--
-- 키 구분 (반드시 읽기)
--   · publishable 키(sb_publishable_…) = 예전 이름 anon 키
--       - 브라우저·HTML 파일에 넣는 공개용 키. 누구나 페이지 소스에서 볼 수 있음
--       - 이 키로 할 수 있는 일 = 아래 RLS 정책이 허용한 일뿐 (조회·추가)
--   · secret 키(sb_secret_…) = 예전 이름 service_role 키
--       - RLS 를 무시하는 관리자 키. 조회·수정·삭제·테이블 삭제까지 전부 가능
--       - HTML·JS·GitHub 저장소·캡처 화면·채팅창 어디에도 넣지 않음
--       - 페이지에 넣는 순간 = 공장 출입문 마스터키를 정문에 붙여 둔 상태.
--         GitHub Pages 는 공개 주소라 누구나 소스 보기로 키를 복사해 DB 전체를 지우거나 고칠 수 있음
--       - 노출 시 즉시 대시보드에서 키 폐기·재발급 → 저장소 기록(커밋)에도 남으므로 키 교체가 유일한 해결
-- =====================================================================

create table if not exists public.work_log (
  id            bigint generated always as identity primary key,
  work_date     date        not null,
  line          text        not null,
  machine       text        not null,
  shift         text        not null,
  part_no       text        not null,
  produced_qty  integer     not null,
  defect_qty    integer     not null default 0,
  downtime_min  integer     not null default 0,
  stop_reason   text        not null default '없음',
  note          text,
  writer        text        not null,
  created_at    timestamptz not null default now(),

  -- 목록값 (생산실적_2026Q3.xlsx 설비마스터·품목마스터, 설비가동_2026Q3.xlsx 정지사유)
  constraint work_log_line_chk
    check (line in ('프레스1라인', '가공2라인', '조립3라인')),
  constraint work_log_shift_chk
    check (shift in ('주간', '야간')),
  constraint work_log_stop_reason_chk
    check (stop_reason in ('없음', '금형교체', '고장', '자재대기', '품질점검')),

  -- 라인 ↔ 설비 (설비마스터 `라인`)
  constraint work_log_line_machine_chk
    check ((line, machine) in (
      ('프레스1라인', 'PR-01'), ('프레스1라인', 'PR-02'),
      ('가공2라인',   'CN-01'), ('가공2라인',   'CN-02'), ('가공2라인', 'CN-03'),
      ('조립3라인',   'AS-01'), ('조립3라인',   'AS-02')
    )),

  -- 설비 ↔ 품번 (설비마스터 `생산품번`)
  constraint work_log_machine_part_chk
    check ((machine, part_no) in (
      ('PR-01', 'DB-BR-101'), ('PR-01', 'DB-BR-102'),
      ('PR-02', 'DB-CV-201'), ('PR-02', 'DB-BR-101'),
      ('CN-01', 'DB-HS-301'), ('CN-01', 'DB-FL-501'),
      ('CN-02', 'DB-SH-401'), ('CN-02', 'DB-HS-301'),
      ('CN-03', 'DB-FL-501'), ('CN-03', 'DB-SH-401'),
      ('AS-01', 'DB-AS-601'), ('AS-01', 'DB-AS-602'),
      ('AS-02', 'DB-AS-602'), ('AS-02', 'DB-AS-601')
    )),

  -- 수량·시간 범위
  constraint work_log_produced_chk   check (produced_qty between 0 and 10000),
  constraint work_log_defect_chk     check (defect_qty >= 0 and defect_qty <= produced_qty),
  constraint work_log_downtime_chk   check (downtime_min between 0 and 480),

  -- 정지사유 ↔ 비가동 (없음 = 0분, 그 외 = 1분 이상)
  constraint work_log_stop_pair_chk
    check ((stop_reason = '없음') = (downtime_min = 0)),

  -- 글자 수
  constraint work_log_writer_chk     check (char_length(btrim(writer)) between 1 and 20),
  constraint work_log_note_chk       check (note is null or char_length(note) <= 200)
);

comment on table public.work_log is
  '(가상) 동백정밀 현장 작업일보. 1행 = 일자·설비·조·품번 1건. 수정·삭제 없음(정정은 새 행 + 비고).';

-- 오늘 목록 조회용
create index if not exists work_log_date_idx on public.work_log (work_date, line, machine);

-- ---------------------------------------------------------------------
-- 행 수준 보안(RLS) — 켜지 않으면 publishable 키로 전체 수정·삭제 가능
-- ---------------------------------------------------------------------
alter table public.work_log enable row level security;

-- 조회: 누구나(페이지 방문자) 가능
drop policy if exists work_log_select on public.work_log;
create policy work_log_select
  on public.work_log
  for select
  to anon, authenticated
  using (true);

-- 추가: 최근 7일 ~ 오늘(한국 시간) 일자만 가능
drop policy if exists work_log_insert on public.work_log;
create policy work_log_insert
  on public.work_log
  for insert
  to anon, authenticated
  with check (
    work_date between ((now() at time zone 'Asia/Seoul')::date - 7)
                  and  (now() at time zone 'Asia/Seoul')::date
  );

-- 수정(update)·삭제(delete) 정책 = 만들지 않음 → RLS 가 전부 거부
-- 정정이 필요하면 새 행 입력 + 비고에 '정정: 원 입력 시각' 기록, 또는 관리자가 대시보드에서 처리

-- ---------------------------------------------------------------------
-- 권한 — 테이블 권한도 조회·추가만. created_at·id 는 서버가 채움(직접 입력 불가)
-- ---------------------------------------------------------------------
revoke all on table public.work_log from anon, authenticated;
grant select on table public.work_log to anon, authenticated;
grant insert (work_date, line, machine, shift, part_no,
              produced_qty, defect_qty, downtime_min, stop_reason, note, writer)
  on table public.work_log to anon, authenticated;

-- ---------------------------------------------------------------------
-- 확인용 쿼리 (실행 후 결과 확인)
-- ---------------------------------------------------------------------
-- select relrowsecurity from pg_class where oid = 'public.work_log'::regclass;  -- true 이어야 함
-- select policyname, cmd, roles from pg_policies where tablename = 'work_log';   -- SELECT·INSERT 2개만

# k-skill 추천 목록 — 생산관리·기획업무용

> k-skill = NomaDamas/k-skill, 한국 특화 에이전트 스킬 모음(2026-11 확인 기준 134개).
> 2026-11 확인 기준: CLI `@nomadamas/k-skill` 0.11.0 · 스킬 이름·키 필요 여부는 `list` / `instruct <스킬>` 결과로 확인.
> 예시 요청의 회사·거래처는 모두 가상. 실제 업무 적용 전 결과를 원본·공식 기관 화면과 대조.

## 1. 추천 스킬

| 스킬 | 한 줄 용도 | 동백정밀 예시 요청 | 개인 키 |
|---|---|---|---|
| korean-holiday-calendar | 공휴일·대체공휴일·특일 조회 → 생산일정·가동일 계산 | > 2026년 11~12월 공휴일 조회해서 월~토 기준 가동일수 표로 만들어 줘 | 불필요 (k-skill-proxy 경유) |
| hwp | 한글(.hwp·.hwpx) 문서 읽기 → Markdown·JSON 변환, 문서 비교, 양식 필드 추출 | > 참고/일일보고_양식.hwp 내용을 Markdown 표로 바꿔서 보여 줘 | 불필요 (내 PC에서 kordoc 실행) |
| rhwp-edit | .hwp 표 셀 채우기·본문 치환·표 만들기·새 문서 만들기 | > 참고/일일보고_양식.hwp 를 복사해서 9월 30일 가공2라인 값을 표에 채우고 결과/일일보고_0930.hwp 로 저장해 줘 | 불필요 (내 PC에서 실행) |
| korean-spell-check | 보고서·메일 맞춤법 최종 점검 (바른한글 검사기) | > 결과/주간보고.docx 본문 맞춤법 검사해서 원문·교정안·이유 표로 정리해 줘 | 불필요 · 비상업·저빈도 사용 조건 |
| korean-law-search | 법령·조문·판례·행정규칙 조회 | > 산업안전보건법에서 프레스 방호장치 관련 조문 찾아서 요약해 줘 | 불필요 (k-skill-proxy 경유) |
| nts-business-registration | 거래처 사업자등록 상태(계속·휴업·폐업) 조회 | > 협력업체 사업자등록번호 3개 상태 조회해서 폐업·휴업 업체 있는지 알려 줘 | 불필요 (k-skill-proxy 경유) |
| delivery-tracking | CJ대한통운·우체국 송장 배송 상태 조회 | > 이 송장번호 5건 배송 상태 조회해서 미배달 건만 표로 정리해 줘 | 불필요 (공식 조회 화면 사용) |
| g2b-order-plan-search | 나라장터 발주계획 조회 (영업·수주 기회 탐색) | > 나라장터에서 2027년 자동차 부품 관련 발주계획 찾아서 기관·금액·시기 표로 정리해 줘 | 불필요 (k-skill-proxy 경유) |
| kosis-stats | 국가통계(KOSIS) 통계표 검색·조회 | > KOSIS에서 자동차 부품 제조업 생산지수 최근 12개월 찾아서 표로 정리해 줘 | 일반 조회 불필요 · 대용량(bigdata)·직접 호출만 KOSIS 키 |
| bok-ecos-stats | 한국은행 통계(환율·금리 등) 조회 → 원자재 수입 단가 참고 | > 최근 3개월 원/달러 환율 조회해서 월평균 표로 만들어 줘 | 불필요 (공개 데모 키 · 호출당 10행 제한, 더 필요하면 개인 키) |

### 참고 — 키가 필요한 스킬

- k-dart: 상장 거래처 공시·재무제표 조회. DART OpenAPI 인증키(`API_K_DART`) 필요 → 실습 범위 밖

## 2. 설치

| 방법 | 명령 |
|---|---|
| 전체 목록 보기 | `npx --yes skills add NomaDamas/k-skill --list` |
| 필요한 스킬만 설치 (전역) | `npx --yes skills add NomaDamas/k-skill --skill <스킬명> -g` |
| Claude Code 플러그인 (전체) | 대화창에서 `/plugin marketplace add NomaDamas/k-skill` → `/plugin install k-skill@k-skill` |
| CLI로 스킬 설명 보기 | `npx -y @nomadamas/k-skill@0 instruct <스킬명>` |
| CLI 최신화 | `npx -y @nomadamas/k-skill@0 update` |

- 예: 한글 양식 실습용 2개만 설치 → `npx --yes skills add NomaDamas/k-skill --skill rhwp-edit -g` · `npx --yes skills add NomaDamas/k-skill --skill hwp -g`
- rhwp-edit 실행 도구: `npx --yes k-skill-rhwp <명령>` (Node.js 18 이상 필요)

## 3. 사용 원칙

- 필요한 스킬만 설치. 전체 설치 시 에이전트가 엉뚱한 스킬을 고를 가능성 증가
- 조회 결과 = 참고 자료. 법령·공휴일·사업자 상태는 공식 기관 화면에서 한 번 더 확인
- k-skill-proxy 경유 스킬 = 조회 요청이 외부 서버를 거침 → 사내 기밀·개인정보(대표자명 등)는 넣기 전에 판단
- 한글 문서 편집 결과 = 항상 원본과 다른 파일로 저장. .hwpx 저장 미지원 → .hwp 로 저장 후 한컴오피스에서 최종 서식 확인
- 공용 프록시는 원천 기관 서버 상태에 따라 일시 오류(504 등) 가능 → 시간을 두고 재시도

# Unity CLI · MCP · Pipeline 사전 점검 규칙

이 문서는 [AGENTS.md](../AGENTS.md)가 참조하는 Unity 도구 관리 상세 지침이다. 실제 Unity 작업 세션의 최초 점검과 필요한 재점검 절차를 정의한다. 파일 자체가 명령을 실행하거나 백그라운드에서 업데이트하지는 않는다. AGENTS.md는 Unity 프로젝트 루트에 두고 이 문서는 프로젝트 루트의 MD/ 폴더에 둔다. 아래 명령은 별도 표시가 없으면 Unity 프로젝트 루트에서 실행한다.

## 1. 목적과 실행 시점

- 세션 시작 후 첫 실제 Unity 프로젝트 구현·수정·실행·검증 작업 전에 전체 점검을 한 번 수행한다. 문서 작성·검토·수정이나 일반적인 설명 요청만으로 점검·설치·업데이트를 실행하지 않는다. 사용자가 도구 점검을 직접 요청하면 해당 범위를 수행한다.
- 같은 세션에서는 새로운 작업 지시, 후속 수정 요청, 프로젝트 전환만으로 전체 점검이나 최신 버전 조회를 반복하지 않는다.
- 이후 재점검은 Unity CLI/MCP/Editor 연결 오류가 발생하거나 사용자가 직접 점검을 요청한 경우에만 수행한다. 연결 오류는 관련 항목부터 확인하고, 버전 조회·업데이트는 오류 해결에 필요한 경우에만 진행한다. 직접 요청은 사용자가 지정한 범위를 따른다.
- resume으로 같은 대화를 이어갈 때는 이전 점검 기록을 유지한다. 기록이 있으면 재점검하지 않고, 기록이 없으면 첫 실제 Unity 작업 전에 한 번 수행한다. 대화 요약이나 컨텍스트 정리는 새 세션으로 간주하지 않는다.
- 점검 시각, 대상 프로젝트, 확인한 버전과 완료·미완료 항목을 대화·세션 요약에 남긴다. 이를 위해 별도 점검 파일이나 HTML 이력을 자동 생성하지 않는다. 미완료 항목도 매 요청마다 자동 재시도하지 않으며, 위 재점검 조건을 따른다.
- 프로젝트를 전환하면 작업 대상 경로는 반드시 확인하되 전체 사전 점검을 자동 실행하지 않는다. 다른 프로젝트의 Pipeline 점검 결과를 현재 프로젝트의 결과로 재사용하지 않는다.
- 설치·업데이트·연결 복구 직후의 검증은 해당 점검 절차의 일부이므로 완료까지 수행한다.
- 최신 버전 번호를 문서에 고정하지 않는다. 실행 시 공식 업데이트 정보와 패키지 레지스트리를 조회한다.
- 정상적인 CLI/Pipeline 설치·업데이트 및 누락된 Unity MCP 등록은 이 지침에 따라 진행한다. 사용자가 업데이트 금지나 특정 버전·커밋으로 재현을 지시하면 그 지시를 우선하고, 보류 항목을 보고한다. 실행 환경의 권한 제한이나 조직 정책을 우회하지 않는다.
- 업데이트 대상은 Unity CLI, CLI 내장 Unity MCP, 현재 프로젝트의 com.unity.pipeline이다. Unity Editor, Hub, Codex 및 다른 프로젝트·패키지의 업그레이드는 별도 작업이다.

## 2. 공통 원칙

1. 현재 프로젝트 절대 경로를 확정한다. Assets, Packages/manifest.json, ProjectSettings/ProjectVersion.txt를 확인한다.
2. AGENTS.md에서 적용 조건을 확인하고 READ.md의 안내에 따라 필요한 상세 문서를 읽는다. 파일 수정은 FILE.md, 실제 프로젝트 파일 변경의 기록은 HISTORY.md, Git 처리는 GIT.md, 에셋 변경은 UNITY_ASSET_RULES.md, 빌드 작업은 BUILD.md가 각각 담당한다. 이 문서는 해당 규칙의 우선순위를 변경하지 않는다. 누락된 문서는 존재한다고 가정하지 않고 보고한다.
3. Git 저장소이면 작업 전 `git status`와 `git diff --stat`로 기존 변경을 확인한다. 기존 변경을 덮어쓰거나 되돌리지 않는다.
4. 명령마다 종료 코드와 출력을 확인한다. 앞 단계 실패를 숨긴 채 뒤 명령을 일괄 실행하지 않는다.
5. 아래 명령이 설치 버전에서 지원되는지는 `--help`로 확인한다. 존재하지 않는 옵션·JSON 필드·패키지 이름을 추측하지 않는다.
6. 최신 조회 실패는 “최신”이 아니라 “확인 불가”로 보고한다. 캐시만으로 온라인 최신 확인을 완료했다고 판단하지 않는다.
7. CLI는 현재 릴리스 채널의 최신을 기본으로 한다. beta 사용 중이면 beta 최신을 확인하며, stable/beta 간 이동은 별도 지시 없이 하지 않는다. Pipeline은 공식 레지스트리에서 CLI가 선택하는 최신을 사용한다. experimental 버전이 선택되면 결과에 표시한다.

## 3. 실행 환경과 설치 확인

Windows PowerShell 예시다. **실제 Unity 프로젝트 루트에서 실행**한다. Unity 프로젝트가 VS Code Workspace나 Git 저장소의 하위 폴더에 있다면 먼저 그 프로젝트 루트로 이동한다. 현재 폴더를 확인하지 않고 다른 프로젝트에 명령을 실행하지 않는다.

```powershell
# 실행 전: VS Code 터미널을 실제 Unity 프로젝트 루트로 이동한다.
$UnityProjectRoot = (Get-Location).ProviderPath

$requiredPaths = @(
    'Assets',
    'Packages/manifest.json',
    'ProjectSettings/ProjectVersion.txt'
)
foreach ($relativePath in $requiredPaths) {
    $targetPath = Join-Path $UnityProjectRoot $relativePath
    if (-not (Test-Path -LiteralPath $targetPath)) {
        throw "Unity 프로젝트 루트가 아닙니다. 누락: $targetPath"
    }
}

Set-Location -LiteralPath $UnityProjectRoot
Get-Command unity -All -ErrorAction SilentlyContinue
Get-Command codex -All -ErrorAction SilentlyContinue
```

- CLI와 IDE가 같은 Windows/WSL 환경 및 같은 Codex 설정을 쓰는지 확인한다. WSL에 등록한 설정만 보고 Windows 확장 등록을 완료했다고 판단하지 않는다.
- unity가 없으면 Unity 공식 설치 안내에서 현재 Windows 설치 방법을 확인하여 설치한다. 임의의 동명 npm 패키지를 설치하지 않는다.
- 설치 후 새 셸에서 경로와 버전을 다시 확인한다. 여러 unity 실행 파일이 있으면 실제 호출되는 경로와 업데이트된 경로가 같은지 확인한다.
- codex 실행 파일이 없더라도 IDE 확장이 없는 것은 아니다. 공식 Plugin 및 MCP 설정은 IDE의 실제 실행 환경에서 확인하며, CLI 검증 불가는 별도로 보고한다.
- 이 문서는 도구 점검 지침이다. Unity 공식 Codex Plugin의 신규 설치 또는 재설치는 `AGENTS.md` 3절에 따라 별도 사용자 요청·승인이 필요하며, 사전 점검을 계기로 자동 설치하지 않는다.

## 4. Unity CLI 최신 확인 및 업데이트

다음 명령을 단계별로 실행한다.

```powershell
unity --version
unity self-update --help
unity self-update --check --format json
```

새 버전이 확인된 경우:

```powershell
unity self-update --yes
```

다시 검증한다.

```powershell
unity --version
unity self-update --check --format json
```

- 업데이트 전후 버전, 채널, 온라인 확인 결과를 기록한다.
- 패키지 관리자로 설치되어 자체 업데이트 대신 관리자 명령을 안내하면, 실제 설치에 사용된 관리자의 공식 업데이트 절차를 따른다. 별도 설치본을 중복 생성하지 않는다.
- 실행 중인 MCP 프로세스 때문에 업데이트가 막히면 해당 클라이언트의 정상적인 MCP 재시작 절차를 이용한다. 모든 Unity/Codex 프로세스를 강제 종료하지 않는다.
- 업데이트 후 실행 중인 MCP가 새 바이너리를 사용하도록 재시작하고 연결을 다시 확인한다.
- Unity CLI `1.0.0-beta.16` 이상에서 **Unity Skill 상태를 조회**할 때는 다음 명령을 참고한다. 이 단계는 읽기 전용 점검이며, Skill 설치·동기화를 임의 실행하지 않는다.

```powershell
unity skill --help
unity skill install --list
unity skill sync --help
```

- `unity skill sync codex`는 해당 Codex용 Skill을 갱신하는 **설정 변경 명령**이다. 사용자 요청·승인이 있으면 기존 Plugin/Skill 중복 여부와 변경 대상을 검토한 뒤 실행하며, 자동 CLI·Pipeline 업데이트 정책을 Skill 자동 갱신으로 확대하지 않는다. 설치 버전에서 지원되지 않으면 추측하여 사용하지 않는다.
- 도움말에 명령이 없는 오래된 CLI는 공식 설치 안내를 확인하여 갱신하고, 변경된 명령 체계에 맞춰 이후 절차를 수행한다.

### 4.1. beta.17 Plugin·Skill 미리보기와 결과 판정

- Unity CLI `1.0.0-beta.17` 이상에서는 먼저 `unity plugin --help`, `unity skill refresh --help`로 현재 설치된 명령과 옵션을 확인한다. 다음 예시는 **실제 설치·갱신이 아닌 상태 조회와 미리보기**에만 사용한다.

```powershell
unity plugin --help
unity skill refresh --help
unity skill refresh --dry-run --format json
```

- `unity plugin install`·`unity plugin upgrade`는 **의존 Plugin 자동 설치**와 각 의존성의 라이선스 절차를 수반할 수 있다. 베타 Plugin 경고, JSON `warnings`, 설치 위치(전역·프로젝트 로컬), 필요한 의존 Plugin과 라이선스를 확인한다. 해당 범위를 사용자에게 알리고 설치·갱신 승인을 별도로 받는다. 조회나 세션 최초 점검만으로 실행하지 않는다.
- `unity plugin upgrade`가 갱신하는 Skill은 **이미 설치된 범위**에 한정될 수 있다. 전역 Skill만 갱신한 뒤 프로젝트 로컬 Skill도 갱신되었다고 판단하지 않는다.
- `unity skill refresh --dry-run --format json`은 계획된 결과를 `would-update`·`would-skip`·`would-prune` 등으로 표시한다. 실제 `unity skill refresh --format json`의 `refreshed`·`up-to-date`·`pruned`·`skipped`·`conflict`와 구별하고 `skipReason` 등 실제 반환 필드를 확인한다. 명령 종료 코드가 `0`이어도 모든 Skill이 최신·정상 적용되었다고 결론내리지 않는다.
- `unity skill sync codex`, `unity skill refresh`, `unity setup codex` 및 Plugin 설치·업그레이드는 사용자 요청·승인 후 실행한다. CLI와 `com.unity.pipeline`의 기존 자동 최신화 정책은 **그대로 유지**한다.

## 5. Unity MCP 등록 확인과 보완

Unity 공식 MCP 서버는 unity 실행 파일에 내장된다. 별도의 MCP 버전 업데이트를 추측해서 실행하지 않는다.

Unity CLI beta.16의 새 공식 배포 구성은 Plugin과 Unity Skill을 **별도로 설치·관리**한다. `unity setup codex`는 Plugin 및 Skill을 구성하며, 이전 Plugin에 Skill이 포함된 경우에는 중복을 확인한다. Plugin·Skill·Unity MCP·프로젝트별 Pipeline·Editor 연결은 별도 상태다. Plugin/Skill 설치는 `AGENTS.md` 3절에 따라 사용자 승인 후 수행하며, 이 사전 점검을 계기로 `unity setup codex`나 `unity skill sync codex`를 자동 실행하지 않는다. CLI에서 Plugin 상태 확인이 필요하면 설치 버전의 `codex plugin --help` 등 지원되는 조회 명령을 먼저 확인한다.

Unity CLI beta.16부터 `unity setup all`은 셸 명령을 실행할 수 있는 코딩 에이전트에 Unity MCP를 기본 등록하지 않는다. MCP가 실제로 필요한 경우에만 아래와 같이 명시적으로 점검·설정한다.

```powershell
codex mcp --help
codex mcp list
unity mcp configure --help
unity mcp configure codex --dry-run
```

목록과 등록 예정 설정을 비교하여 Unity 서버의 실행 경로, 인수, 활성화 상태와 적용 범위를 확인한다. 서버 이름은 실제 출력에서 찾는다. 이름이 비슷한 타사 unity-mcp를 공식 서버로 간주하지 않는다.

누락되었으면 등록한다.

```powershell
unity mcp configure codex
```

기존 등록이 낡았으면 변경 예정 내용을 확인한 다음 갱신한다. 지원되는 옵션은 도움말을 따른다. 여러 프로젝트를 사용할 때 전역 설정을 한 프로젝트로 고정하지 않는다. 프로젝트 한정 등록이 필요하면 지원 여부를 확인하여 로컬 범위를 사용한다.

주의: 공식 configure 명령은 Codex의 네트워크 관련 설정도 조정할 수 있다. dry-run 및 적용 전후 차이를 검토하고, 불필요한 권한 확대나 승인 정책 변경은 하지 않는다. 환경 정책이 해당 변경을 금지하면 우회하지 말고 정확히 보고한다.

등록 후 다시 `codex mcp list`로 확인하고 IDE의 MCP 재시작 기능을 사용한다. 실제 MCP 도구 목록을 불러오고, 제공되는 읽기 전용 조회 도구를 한 번 호출한다. 등록만 확인했으면 “등록 완료 / 연결 미확인”으로 구분한다. 꺼짐 또는 권한 철회 상태를 누락으로 취급해 자동 재활성화하지 않는다.

## 6. Pipeline 설치 및 최신 확인

먼저 현재 프로젝트의 Packages/manifest.json에서 com.unity.pipeline 의존성을 확인한다. packages-lock.json과 실제 로드된 패키지도 확인하여 선언 버전과 해결된 버전을 구분한다.

**자동 최신화 정책 유지:** 이 문서의 최초 전체 점검이 실행되는 경우 Unity CLI는 현재 릴리스 채널의 최신을, 현재 프로젝트의 `com.unity.pipeline`은 공식 레지스트리의 최신을 기본 대상으로 한다. 설치되지 않았으면 설치하고, 구버전이면 지원되는 `upgrade` 절차를 실행한다. 패키지의 `manifest.json`에 일반 버전 번호가 적혀 있다는 이유만으로 이를 명시적인 업데이트 금지로 간주하지 않는다. 다만 사용자·팀의 명시적 버전 고정 또는 업데이트 금지, 다른 출처의 의존성, Unity Editor 비호환, 최신·호환성 확인 불가, 권한 제한이 있으면 기존 예외 규칙에 따라 보류하고 보고한다. **자동 최신화를 이유로 Unity Editor·다른 패키지까지 업그레이드하지 않는다.**

```powershell
unity pipeline --help
unity pipeline editors --format json
unity pipeline list-versions --format json
```

미설치인 경우:

```powershell
unity pipeline install --project-path "$UnityProjectRoot"
```

설치되어 있고 공식 최신보다 오래된 경우:

```powershell
unity pipeline upgrade --project-path "$UnityProjectRoot"
```

- 최신이면 파일을 다시 쓰지 않는다. 매번 `install --force`로 덮어쓰지 않는다.
- Git/로컬/embedded 의존성이면 일반 레지스트리 설치로 강제 교체하지 않는다. 출처와 교체가 필요한 이유를 먼저 보고한다.
- 업데이트 후 Unity의 패키지 해결과 컴파일이 끝났는지 확인한다. manifest 수정 성공만으로 설치·연결 완료라고 판단하지 않는다.
- 패키지의 Editor 호환 조건을 확인한다. 호환되지 않으면 최신 버전과 설치 가능한 버전을 구분하여 보고하고, Editor를 임의 업그레이드하지 않는다.
- 호환성 조건을 확인할 수 없으면 강제 업데이트하지 않고 확인 불가로 남긴다. 기존 버전이 공식 최신보다 앞서 있거나 사용자·팀의 명시적인 버전 고정 지시가 있으면 임의 다운그레이드하지 않는다.
- packages-lock.json을 직접 조작해 설치 완료처럼 만들지 않는다. Unity가 해결한 결과를 확인한다.

## 7. 실제 Editor 연결 점검

```powershell
unity status --project-path "$UnityProjectRoot" --format json
unity pipeline editors --format json
unity command --detail full --project-path "$UnityProjectRoot" --format json
```

대상 프로젝트가 맞는지, Editor에 연결되는지, 사용 가능한 명령 목록이 반환되는지 확인한다. MCP에서도 같은 프로젝트에 대한 읽기 전용 조회를 확인한다.

연결 실패 시 다음을 구분한다.

- 대상 Editor가 닫혀 있음
- 패키지 해결 또는 컴파일 진행 중 (`UNAVAILABLE`, 종료 코드 `17` 가능)
- 컴파일 오류 / Safe Mode (`UNAVAILABLE`, 종료 코드 `17` 가능)
- Editor가 입력을 기다리는 모달 팝업 (`AWAITING_INPUT`, 종료 코드 `18` 가능)
- 다른 프로젝트 선택 또는 실행 환경 불일치
- 로컬 통신 제한 / MCP 재시작 필요

같은 오류에 대해 상태 변화 없이 전체 점검·재시작·재설치를 반복하지 않는다. 원인 수정 후 필요한 확인을 수행하고, 해결되지 않으면 오류와 가능한 작업 범위를 보고한다. 연결 실패를 이유로 무조건 재설치하지 않는다. 권한 차단을 “Editor가 실행되지 않음”으로 단정하지 않는다. 저장하지 않은 씬을 잃을 수 있는 강제 종료를 하지 않는다.

### 7.1. beta.16 Editor 대기 상태와 모달 팝업 대응

| 종료 코드 | 오류 이름 | 판정·조치 |
|---|---|---|
| `0` | 성공 | 실제 명령 결과도 확인하고 진행 |
| `1` | 일반 오류·설정 쓰기 실패 가능 | `unity mcp configure` 실패 시 형식·오류 메시지 확인 |
| `2` | 잘못된 인수·입력 검증 실패 가능 | beta.17의 cloud/context/build/pipeline/projects 명령 구문 재확인 |
| `4` | `VCS_TOKEN_REQUIRED` 등 명령별 오류 | `--git-token-from-stdin` 빈 입력인지 확인, 저장된 로그인으로 대체하지 않음 |
| `6` | 일반 실행 실패 등 | 메시지와 원래 원인 확인, 17·18과 구별 |
| `7` | `NETWORK_UNREACHABLE` | 오프라인·DNS·프록시·서비스 접근 확인 (온라인 조회/업데이트 명령 등) |
| `14` | `EDITOR_TIMEOUT` | `unity command`의 실행 시간 초과인지 확인 |
| `17` | `UNAVAILABLE` | Editor 로딩·컴파일·리로드·Safe Mode·과도한 동시 명령 종료 확인 |
| `18` | `AWAITING_INPUT` | 모달 팝업 확인 후 필요한 버튼의 영향 검토 |

- 코드 값은 **발생한 명령과 CLI 버전의 실제 결과**로 판정한다. 종료 코드 `17`, `18`과 `7`은 beta.16에서 관련 상황을 종전의 일반 오류 `6`보다 구체적으로 구별한다. 모든 명령이 항상 같은 코드를 반환하는 것은 아니다.
- 지원 Unity Editor에서 `unity pipeline editors --format json`으로 로딩·Safe Mode·엔드포인트·모달 팝업 상태를 확인한다. Editor가 로딩 중인 것을 죽거나 연결 실패한 상태로 오인하지 않는다.
- 모달 팝업이 있는 경우, **실제 명령 도움말을 확인한 다음** 다음과 같이 조회한다.

```powershell
unity command editor dialog --help
unity command editor dialog --project-path "$UnityProjectRoot"
```

- 버튼 선택은 팝업을 조회하여 **실제 ID·버튼 값과 변경 영향을 확인한 후** 수행한다. 삭제·에셋 변환·프로젝트 설정 변경 등 파괴적이거나 요청 범위를 벗어나는 응답을 자동 승인하지 않는다. 값은 출력으로 확인하며 다음 자리 표시자를 그대로 입력하지 않는다: `unity command editor dialog answer <id> <button>`.
- 지원하지 않는 Editor 버전에서는 해당 팝업 명령을 사용할 수 없다. 성공했다고 가정하지 말고 Editor 호환성·해당 기능 지원 여부를 보고한다.

### 7.2. beta.16 자동화 출력 호환성

- 지원 Editor에 대한 `unity command --format json`의 출력은 종전의 `success`·`command`·`parameters`·`target` 래퍼 대신 **명령 자체의 결과**가 될 수 있다. `--format ndjson`은 같은 결과를 줄 단위로 출력하며, TSV는 헤더 없이 레코드만 출력한다. 기존 파서가 고정 래퍼·헤더에 의존하는지 점검한다.
- `unity command`의 명령 자체 종료 코드 전달 및 스트리밍 출력을 고려한다. 텍스트 로그와 구조화 JSON이 혼합되는지 실제 출력으로 확인하여, 확인되지 않은 필드를 추측하지 않는다.
- `unity docs cache --format json`의 목록은 beta.16에서 `data.items`에 있으므로, 기존 `data` 배열로 해석하는 자동화가 있다면 별도 호환성 점검을 수행한다.
- 이 문서는 **점검 규칙**이며, 특정 프로젝트에 있는 자동화 스크립트를 무단 수정하거나 전체 빌드·테스트를 자동 시작하지 않는다.

### 7.3. beta.17 자동화 출력·인증·테스트 변경

- `unity pipeline install`·`unity pipeline upgrade`의 `--format tsv` 출력은 beta.17부터 **헤더 + 레이블이 있는 key/value 행**이다. TSV 위치·행 수를 가정하는 기존 파서는 실제 출력으로 재검증한다. 현재 템플릿의 CLI·Pipeline 기본 명령은 그대로 사용하며 무조건 TSV로 변경하지 않는다.
- `unity skill refresh --format json` 또는 `ndjson`은 작업 결과를 반환한다. `skipped`·`conflict`·`pruned` 결과가 있는지 확인하고, 조회 성공을 모든 설치본 갱신 성공으로 해석하지 않는다.
- beta.17에서는 일부 인수 오류가 종료 코드 `1` 대신 `2`이고, `unity projects`의 Git 토큰 빈 입력은 `4`, 외부 서비스 접근 실패는 `7`, 시간 초과는 `14`를 반환할 수 있다. **실제 명령과 오류 메시지**를 함께 해석하여 인증 실패·네트워크 실패·인수 오류를 구분한다. Git CLI 자체의 `git push` 종료 코드까지 이 표에 대입하지 않는다.
- Editor 테스트를 MCP로 비동기 실행한 경우 완료·실패 상태를 확인하고 테스트 리포트가 실제로 작성되었는지 검증한다. beta.17의 비동기 대기 수정이 모든 테스트의 통과를 보장하지는 않는다.
- 설치·업그레이드, Plugin·Skill 갱신과 인증·클라우드 연결 설정은 `--help` 및 승인 정책에 따라 수행한다. 이번 릴리스만을 이유로 프로젝트 설정·원격 저장소를 임의 변경하지 않는다.

## 8. 작업 진행과 결과 보고

필수 도구가 정상이면 사용자 작업을 이어서 수행한다. 일부 점검이 막혀도 독립적으로 가능한 코드 분석·수정은 진행할 수 있다. Editor/MCP 검증이 필요한 부분은 미검증이라고 명확히 남긴다.

작업 종료 시 기존 변경과 이번 변경을 구분하고, 패키지 변경이 있으면 manifest.json 및 packages-lock.json 차이를 확인한다.

- 파일 변경 없는 점검은 대화에만 결과를 보고한다. HTML·인덱스·commit/push는 생성하지 않는다. 명시적인 기록 작성 요청은 HISTORY.md를 따른다.
- Pipeline 설치·업데이트 등으로 실제 프로젝트 파일이 변경되면 HISTORY.md에 따라 기록하고 GIT.md의 조건에 따라 Git 후처리를 수행한다. GIT.md가 없으면 명시적 지시 없이 자동 commit/push하지 않는다.
- 사용자 전역 CLI나 MCP 설정만 변경한 경우 프로젝트 파일 변경으로 간주하지 않는다. 전역 설정 파일이나 인증 정보를 프로젝트에 복사·stage하지 않는다.
- 프로젝트 로컬 MCP 설정이 변경되면 변경 범위와 민감 정보 포함 여부를 확인하고 FILE.md·HISTORY.md·GIT.md를 적용한다.
- 문서에서 정한 전체 점검을 생략하더라도 실제 작업 대상 확인, 필요한 API·패키지 정보 확인, 작업 결과 검증은 생략하지 않는다.

실제로 점검한 경우에만 결과를 다음 형식으로 짧게 보고한다. 점검하지 않은 후속 요청에서는 이 표를 반복하지 않는다. 값을 추측해서 채우지 않는다.

| 항목 | 확인 전 | 확인 후 | 판정 |
| --- | --- | --- | --- |
| Unity CLI | 실제 버전·채널 | 실제 버전·채널 | 최신 / 업데이트 / 확인 불가 |
| Codex Unity Skill | 실제 Plugin·Skill 설치 상태 | 설치·인식 확인 결과 | 최신 확인 / 갱신 필요 / 확인 불가 (설치·동기화는 별도 승인) |
| Unity MCP 등록 | 없음 / 있음 / 비활성 | 실제 상태 | 정상 / 보완 / 차단 |
| Unity MCP 호출 | 미확인 | 실제 조회 결과 | 연결 성공 / 실패 / 재시작 필요 |
| Pipeline | 선언·해결 버전 | 선언·해결 버전 | 최신 / 설치 / 업데이트 / 호환 불가 |
| Editor 연결 | 실제 프로젝트·상태 | 실제 조회 결과 | 정상 / 대기 / 실패 |

확인 시각, 변경 파일, 남은 조치도 함께 적는다. “이후에도 항상 최신”이라고 보장하지 않고 “이번 점검 시점에 해당 채널/레지스트리 기준 최신”이라고 표현한다.

## 9. AGENTS.md 및 상세 문서와의 관계

- AGENTS.md의 2절 문서 표와 4.1절이 이 문서의 적용 시점을 안내한다. 점검 명령은 이 문서에서 관리하여 중복을 줄인다.
- 세션 최초 1회, 이후 연결 오류 또는 명시적 요청 시에만 재점검한다는 조건은 두 문서에서 동일하게 유지한다.
- READ.md는 이 문서의 역할과 읽는 시점을 안내한다. 적용 조건 변경 시 AGENTS.md·READ.md의 요약도 함께 맞춘다.
- 도구 점검은 빌드·테스트 전체 실행이나 배포 요청을 뜻하지 않는다. 실제 검증 범위는 요청과 BUILD.md 등 해당 상세 문서에 따른다.
- 파일 형식과 변경 보존은 FILE.md, 기록 여부는 HISTORY.md, stage·commit·push는 GIT.md를 따른다. 이 문서에 별도의 Git·이력 정책을 만들지 않는다.

## 10. 공식 근거와 유지보수

공식 명령 문서 검토일: 2026-11-06  
검토 기준 버전: Unity CLI 1.0.0-beta.17  
검토 방식: 공식 Unity CLI 릴리스 노트·레퍼런스 대조(사용자 PC에서 명령 직접 실행한 검증 아님)

검토 기준 버전은 문서 작성 당시의 명령어 검증 이력이며, 실제 작업 시 사용할 CLI 버전을 고정하거나 자동 업데이트를 제한하지 않는다.

Unity CLI의 명령어와 옵션은 버전 업데이트에 따라 변경될 수 있다.

실제 명령 실행 전에는 설치된 Unity CLI의 `--help` 출력을 우선 확인하고, 공식 명령어 레퍼런스와 릴리스 노트를 참고한다.

특히 기존 명령어가 제거되거나 이름이 변경된 경우 공식 릴리스 노트의 변경 사항을 확인하여 이 문서를 갱신한다.

**공식 참고 문서**

- [Unity CLI 공식 릴리스 노트](https://docs.unity.com/en-us/unity-cli/release-notes)
- [Unity CLI 공식 명령어 레퍼런스](https://docs.unity.com/en-us/unity-cli/reference)
- [Unity CLI 공식 안내: 설치와 기본 명령](https://github.com/Unity-Technologies/skills/blob/main/skills/unity-cli/SKILL.md)
- [CLI 자체 업데이트](https://github.com/Unity-Technologies/skills/blob/main/skills/unity-cli/references/diagnostics-maintenance.md)
- [MCP 등록과 Pipeline 관리](https://github.com/Unity-Technologies/skills/blob/main/skills/unity-cli/references/integration-advanced.md)
- [Codex MCP 설정과 재시작](https://developers.openai.com/codex/mcp/)

**버전 변경 시 확인 원칙**

1. `unity --version`으로 현재 설치 버전을 확인한다.
2. 공식 릴리스 노트에서 명령어 추가·변경·삭제 여부를 확인한다.
3. `unity --help` 및 해당 하위 명령의 `--help`로 실제 지원 여부를 확인한다.
4. 변경된 명령어가 있다면 이 문서의 해당 절을 수정한다.
5. 확인일과 검토 기준 버전을 갱신한다.
6. 지원 여부가 확인되지 않은 명령어를 임의로 추측하여 사용하지 않는다.

이 문서는 실행 지침이며, 작성 시 사용자 PC의 설치 상태를 직접 점검하거나 업데이트한 결과 보고서는 아니다.

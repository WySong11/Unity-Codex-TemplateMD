# Unity + Codex 설치 및 점검 배치 파일

이 폴더의 `UnityCodexSetup.bat`과 `UnityCodexSetup.ps1`은 기존 `GitWorkflow.bat` / `GitWorkflow.ps1`과 독립적으로 동작합니다. **Git Pull·Commit·Push를 실행하지 않습니다.** Windows PowerShell 5.1 이상을 대상으로 작성했습니다.

## 1. 추가 파일

| 파일 | 역할 |
|---|---|
| `UnityCodexSetup.bat` | 더블클릭 또는 명령줄 실행 진입점. PowerShell 스크립트 호출 |
| `UnityCodexSetup.ps1` | Unity CLI, Pipeline, Codex Plugin·Skill, MCP 상태 점검 및 선택적 설치·업데이트 |
| `UnityCodexSetup_README.md` | 적용·사용 설명서 |

파일은 기존 템플릿 저장소의 `Batch/` 폴더에 **같이** 추가합니다. `.bat`은 CRLF, `.ps1`과 `.md`는 LF이며 모두 UTF-8 without BOM입니다. `.bat` 및 `.ps1`의 실행 메시지는 Windows PowerShell 5.1에서 한글 인코딩 문제를 피하도록 영문으로 작성했습니다.

## 2. 사용법

저장소의 `Batch/UnityCodexSetup.bat`을 더블클릭하면 메뉴가 열립니다.

| 메뉴 | 동작 | 프로젝트 파일 변경 여부 |
|---|---|---|
| `1 Check` | 설치 여부·버전·패키지 선언·Codex·MCP 읽기 전용 점검 | 없음 |
| `2 Setup` | 누락된 CLI 설치, CLI 현재 채널 업데이트 확인, 프로젝트별 Pipeline 설치/업그레이드 | **사용자 승인 시** 가능 |
| `3 Codex` | `unity setup codex --dry-run` 확인 후 공식 Plugin·Skill 설정 | **사용자 승인 시** 가능 (사용자/에이전트 설정) |
| `4 Mcp` | `unity mcp configure codex --dry-run` 확인 후 설정 | **사용자 승인 시** 가능 (Codex 설정) |
| `5 All` | 2→3→4 순서, 변경 단계별 승인 | **사용자 승인 시** 가능 |

명령줄에서 바로 실행하려면 PowerShell 또는 CMD에서:

```bat
Batch\UnityCodexSetup.bat -Action Check
Batch\UnityCodexSetup.bat -Action Setup -ProjectPath "D:\Dev\MyUnityProject"
Batch\UnityCodexSetup.bat -Action Codex
Batch\UnityCodexSetup.bat -Action Mcp
Batch\UnityCodexSetup.bat -Action All -ProjectPath "D:\Dev\MyUnityProject"
```

`-ProjectPath` 생략 시 현재 디렉터리 또는 Batch 폴더의 부모 디렉터리에서 Unity 프로젝트인지 검사합니다. 프로젝트 루트가 확인되지 않으면 Pipeline 단계는 건너뛰고, 메뉴에서 경로 입력을 제안합니다. 실제 Unity 프로젝트는 `Assets/`, `Packages/manifest.json`, `ProjectSettings/ProjectVersion.txt`가 존재해야 합니다. 템플릿 문서 저장소 자체는 Unity 프로젝트가 아니므로 **Pipeline 패키지를 템플릿 저장소에 설치하지 않습니다.**

## 3. 점검 및 설치 범위

**Unity CLI:** `Get-Command unity`, `unity --version`, `unity pipeline --help`로 설치를 판별합니다. 누락된 경우 사용자 승인 후 Unity 공식 Windows 설치 스크립트(`https://unity.com/install.ps1`)를 다운로드·실행하여 **beta 채널**의 CLI를 설치합니다. 받은 스크립트의 SHA-256을 표시하고 실행 전에 **다시 승인**받습니다. 현재 채널 업데이트는 `unity self-update --check --format json`을 확인하고 승인 후 `unity self-update --yes`를 실행합니다. `winget`으로 설치한 버전도 Unity CLI가 지원하는 `self-update`를 사용하며, 기존 설치가 비정상인 경우 덮어쓰지 않습니다. CLI 업데이트가 항상 필요한 것은 아니며, 최신이면 no-op일 수 있습니다.

**Pipeline:** 실제 Unity 6 이상 프로젝트에서 `com.unity.pipeline`을 `Packages/manifest.json` 및 `packages-lock.json`으로 확인합니다. 미설치인 경우 `unity pipeline install --project-path <프로젝트>`를 실행하고, 이미 설치된 경우 버전 목록 조회 및 승인 후 `unity pipeline upgrade --project-path <프로젝트>`를 실행할 수 있습니다. 자동 최신화 정책을 위해 공식 CLI가 버전을 선택하게 하되, 비호환·버전 고정·비레지스트리 패키지 출처는 보존해야 합니다. `.meta`, 씬, 프리팹을 직접 편집하지 않습니다. **버전 조회 성공만으로 최신·호환성을 단정하지 않습니다.**

**Codex:** `codex` 실행 파일 및 Plugin과 Unity Skill 표시 상태를 확인합니다. VS Code Codex 확장과 명령줄 `codex` CLI는 환경이 다를 수 있습니다. Plugin·Skill의 설치는 별도의 `Codex` 메뉴로 실행하며 `unity setup codex --dry-run`과 사용자 승인이 선행합니다. CLI를 찾을 수 없다고 VS Code 확장이 설치되지 않았다고 판단하지 않습니다. Codex CLI 자체를 자동 설치하지 않습니다.

**Unity MCP:** Codex MCP 목록 확인 후 `unity mcp configure codex --dry-run`을 표시하고 별도 승인을 받은 경우에만 설정합니다. Codex 설정 파일과 권한에 영향을 줄 수 있습니다. 등록만으로 실제 Unity Editor의 MCP 연결이 검증된 것은 아니며, Codex를 재시작한 후 읽기 전용 Unity MCP 호출을 확인해야 합니다.

## 4. 안전 정책 및 제한

- `Check`는 설치·업데이트·파일 쓰기·Git 작업을 수행하지 않습니다. 단, Unity Editor 상태 조회나 명령 출력에는 로그인·네트워크·Editor 실행 상태가 영향을 줄 수 있습니다.
- `Setup`, `Codex`, `Mcp`, `All`의 **각 설정 변경 직전에는 확인 질문**이 표시됩니다. `y` 또는 `yes`로 승인해야 진행합니다.
- Unity CLI 설치용 온라인 스크립트는 공식 HTTPS URL에서 다운로드하나, 다운로드 파일을 신뢰할 수 있는지 보안 정책에 따라 직접 검토해야 합니다. 이 도구는 게시자 디지털 서명을 독립적으로 검증하지 않습니다.
- Unity CLI가 실행 가능해도 Unity Editor 연결이 보장되지는 않습니다. Editor가 실행 중이고 Pipeline 로딩·컴파일이 끝나야 연결을 확인할 수 있습니다.
- `unity auth login`은 사용자가 필요할 때 직접 실행합니다. 비밀번호·토큰을 이 스크립트에 입력하거나 파일에 저장하지 않습니다.
- 이 스크립트는 Unity Hub, Unity Editor, Git, Codex CLI 자체를 자동 설치하거나 버전을 강제 변경하지 않습니다.
- 기존 `MD/UNITY_TOOLING.md`의 정책을 대체하지 않습니다. 특히 조직의 버전 고정·업데이트 금지, 권한 정책을 존중하세요. 이 스크립트의 확인 메시지는 명령별 실행 승인용입니다.
- 이 스크립트는 **Windows 환경에서 실 실행 검증을 완료하지 않은 배포 파일**입니다. 처음에는 `-Action Check`로 결과를 확인한 다음 별도 테스트 Unity 프로젝트에서 `Setup`을 실행하는 것을 권장합니다.

## 5. 작업 완료 후 점검

```powershell
unity --version
unity pipeline editors --format json
unity status --project-path "D:\Dev\MyUnityProject" --format json
codex mcp list
unity skill install --list
```

실제 Unity Editor에서 패키지 설치·컴파일 완료를 확인하고, VS Code Codex 확장의 새 세션에서 Plugin·Skill 인식 및 MCP 읽기 전용 도구 호출을 점검하세요. 도구는 Git commit/push를 자동 실행하지 않습니다.

공식 참고:
- [Unity CLI 설치 및 사용](https://docs.unity.com/en-us/unity-cli/use-unity-cli)
- [Unity CLI beta.16 릴리스 노트](https://docs.unity.com/en-us/unity-cli/release-notes)
- [Pipeline 패키지 설치](https://docs.unity.com/en-us/unity-cli/unity-pipeline/unity-pipeline-package)
- [Unity 공식 Agent Skill / Codex 연동 안내](https://github.com/Unity-Technologies/unity-agent-plugin)

# 파일 저장·인코딩 및 줄바꿈 규칙

이 문서는 Unity 프로젝트에서 Visual Studio, VS Code, Codex 및 Git이 사용하는 **텍스트 파일의 인코딩과 줄바꿈**을 일관되게 관리하기 위한 공통 규칙이다. 신규 파일과 **실제로 내용을 수정하는 기존 일반 텍스트 파일**에는 파일 유형별 목표 형식을 적용하여 단계적으로 통일한다. 읽기 전용 파일, 작업 범위 밖의 파일, Unity 또는 외부 도구가 생성·관리하는 파일은 변경하지 않는다. 이 문서는 작업 지침이며 그 자체로 파일이나 설정을 자동 수정하지 않는다.

---

## 1. 핵심 규칙

### 1.1 파일 유형별 기본 정책

| 대상 | 신규 생성·기존 수정 시 인코딩 | 신규 생성·기존 수정 시 줄바꿈 | 비고 |
|---|---|---|---|
| C# 스크립트 (`.cs`) | **UTF-8 with BOM** | **LF (`\n`)** | 직접 작성·관리하는 C# 파일은 수정 시에도 적용 |
| Markdown (`.md`), JSON (`.json`, `.jsonc`) | UTF-8 without BOM | LF (`\n`) | JSONC와 주석 포함 설정도 적용 |
| UI Toolkit (`.uxml`, `.uss`) | UTF-8 without BOM | LF (`\n`) | 관련 에셋 참조와 GUID는 별도 보존 |
| Shader 소스 (`.shader`, `.compute`, `.hlsl`, `.cginc`) | UTF-8 without BOM | LF (`\n`) | 직접 작성·관리하는 텍스트 소스 기준 |
| 일반 소스·설정·문서 | UTF-8 without BOM | LF (`\n`) | 생성 또는 실제 내용 수정 시 적용 |
| Windows Batch (`.bat`, `.cmd`) | UTF-8 without BOM 기본 | **CRLF (`\r\n`)** | 한글 출력·실행은 Windows 코드 페이지 등 실제 실행 환경에서 별도 검증 |
| Unity 또는 외부 도구가 생성·관리하는 파일 | **생성 도구의 원본 형식 유지** | **생성 도구의 원본 형식 유지** | `.meta`, 직렬화 에셋, 자동 생성 파일 등을 임의로 재인코딩하지 않음 |

- 모든 일반 텍스트 파일에는 UTF-8을 기본 인코딩으로 적용한다. 다만 생성 도구와 기존 프로젝트의 명시적인 형식 요구사항이 있으면 이를 우선 확인한다.
- **기존 일반 텍스트 파일도 실제 내용 수정 시 해당 확장자의 목표 BOM·인코딩·줄바꿈으로 정규화한다.** 형식이 이미 일치하면 그대로 둔다. 예: 기존 BOM 없는 CRLF `.cs`를 기능 수정할 경우 UTF-8 with BOM + LF로 저장한다.
- 정규화 범위는 **이번 작업에서 실제 내용을 수정하는 파일**에 한정한다. 읽기만 한 파일과 요청 밖의 파일, 저장소 전체는 자동으로 변환하지 않는다.
- 한글 주석·문자열·UXML/USS 텍스트가 손상되지 않도록 변환 전 원본 해석과 변환 후 내용을 비교한다. UTF-8이 아니거나 해석이 불확실하면 추측하여 변환하지 않고 해당 파일의 사유를 보고한다.
- `.editorconfig`, `.gitattributes`, Git LFS·바이너리 규칙 및 도구의 필수 형식을 확인한다. **목표 정책과 실제 프로젝트 설정이 충돌하면 무시하거나 임의로 설정을 덮어쓰지 않고**, 충돌한 파일의 변환을 보류하고 필요한 설정 조정 범위를 보고한다.
- **수정 파일의 점진적 정규화**는 해당 기능 수정 작업의 일부이며 같은 작업·커밋에 포함할 수 있다. **수정하지 않은 파일까지 포함하는 일괄 정규화**는 별도 요청·별도 작업·별도 커밋으로 관리한다.

### 1.2 설정 파일별 역할

Unity 프로젝트 루트, Git 저장소 루트, VS Code 워크스페이스 루트가 서로 다를 수 있으므로 실제 적용 범위를 확인한다. 일반 편집만으로 설정 파일을 생성하거나 덮어쓰지 않는다.

**배포 템플릿 적용 원칙:** 이 배포본에 포함된 `.editorconfig`, `.gitattributes`, `.gitignore` 및 선택적 `.vscode/settings.json`은 *새 프로젝트용 시작 설정*이다. 대상 프로젝트에 동일한 파일이 이미 있으면 덮어쓰지 말고 기존 규칙과 병합한다. 상위 폴더에 설정이 있는 다중 프로젝트 저장소에서는 상위 정책·Git LFS·파일별 예외를 먼저 확인한다. 템플릿을 복사했다는 이유로 미수정 파일을 일괄 재저장하거나 `git add --renormalize .`를 실행하지 않는다.

| 설정 파일 | 담당 영역 | 정책 |
|---|---|---|
| `.editorconfig` | 에디터와 지원 도구의 저장 형식 | 신규·수정 파일에 일반 LF·UTF-8, `.cs` BOM, Batch CRLF |
| `.gitattributes` | Git 정규화·체크아웃 줄바꿈 | 일반 소스·문서 LF, Batch CRLF, 기존 LFS·바이너리 규칙 보존 |
| `.gitignore` | Git 추적 제외 대상 | Unity 캐시·빌드·IDE 생성물만 기본 제외. 필수 소스·`.meta`는 보존 |
| `.vscode/settings.json` | VS Code 기본 저장값(선택적) | 일반 텍스트의 LF 기본값 보완. C# BOM·Batch CRLF는 별도 검증 |

---

## 2. `.editorconfig` 규칙

`.editorconfig`는 새 파일 및 수정한 기존 파일의 저장 형식을 명시하는 데 사용한다. **파일 유형별 목표 형식에 대한 참고 예시**는 다음과 같다. 이미 존재하는 `.editorconfig`를 통째로 교체하지 않으며, 설정을 추가했다는 이유만으로 수정 대상 밖의 파일을 재저장하지 않는다.

```ini
# 독립적인 설정 루트로 확정된 경우에만 주석을 해제한다.
# 상위 저장소의 .editorconfig를 상속해야 하면 주석 상태를 유지한다.
# root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true

[*.cs]
charset = utf-8-bom
indent_style = space
indent_size = 4

[*.{bat,cmd}]
end_of_line = crlf

[*.{json,jsonc}]
indent_style = space
indent_size = 2
```

### 필수 설정 설명

| 설정 | 의미 |
|---|---|
| `charset = utf-8` | UTF-8 without BOM으로 저장 |
| `charset = utf-8-bom` | UTF-8 with BOM으로 저장. **신규 및 수정하는 C# 파일 정책** |
| `end_of_line = lf` | 일반 텍스트 파일의 줄 끝을 LF로 저장 |
| `end_of_line = crlf` | Windows Batch 파일의 줄 끝을 CRLF로 저장 |
| `insert_final_newline = true` | 필요한 파일에 마지막 줄바꿈을 추가. 빈 줄을 하나 더 생성한다는 뜻은 아님 |
| `root = true` | 상위 디렉터리의 `.editorconfig` 탐색을 중단. 기존 프로젝트 범위를 확인한 뒤 사용 |

- **배포본의 `.editorconfig`에서는 `root = true`를 기본적으로 주석 처리한다.** 상위 `.editorconfig`의 규칙을 상속해야 하는 모노레포·다중 Unity 프로젝트에서는 주석 상태를 유지한다. 독립적인 프로젝트이고 상위 설정을 끊어야 한다는 점이 확인된 경우에만 활성화한다. 기존 `.editorconfig`가 있다면 원래 `root` 정책과 다른 설정을 보존하고 필요한 파일별 항목만 병합한다.
- `.editorconfig`는 에디터가 해당 속성을 지원할 때 동작한다. **설정 파일 존재만으로 실제 인코딩과 줄바꿈 적용을 확정하지 않는다.**
- 이 예시의 `[*]`는 기존 파일에도 저장 시 적용될 수 있다. **실제로 수정하는 일반 텍스트 파일에 한해서** 목표 형식이 적용되는지 확인하고, 읽기만 한 파일이나 수정 대상 밖의 파일은 저장하지 않는다.
- Unity가 생성·관리하는 파일에 적용되는 규칙 때문에 원본 형식이 바뀌지 않는지 확인한다. 이러한 파일을 일반 소스와 동일하게 일괄 재저장하지 않는다.
- 기존 파일의 BOM·줄바꿈이 목표와 다른 경우 **내용을 수정한 그 파일만** 정규화한다. 형식 변경으로 전체 줄이 diff에 나타나는 것은 예상 가능한 결과이므로 실제 내용 변경, 한글 보존, 요청 범위를 별도로 검증한다.

---

## 3. `.gitattributes` 규칙

`.gitattributes`는 Git이 체크아웃 및 인덱스 정규화에 사용하는 줄바꿈 설정이다. **인코딩의 BOM 유무를 강제하는 도구는 아니다.** 신규·수정 C# 파일의 UTF-8 BOM은 생성·편집 도구와 실제 바이트 검증으로 보장한다.

이미 Git 저장소에 적용되는 규칙이 있는 경우 이를 우선 확인한다. 다른 프로젝트에 영향을 줄 수 있는 전역 일괄 설정을 추가하기보다는 관리하는 파일 유형을 명시적으로 지정한다.

다음은 기존 규칙이 없는 파일 유형에만 참고하여 병합할 수 있는 예시다.

```gitattributes
# 일반 소스 및 문서는 LF
*.cs       text eol=lf
*.md       text eol=lf
*.json     text eol=lf
*.jsonc    text eol=lf
*.uxml     text eol=lf
*.uss      text eol=lf
*.shader   text eol=lf
*.compute  text eol=lf
*.hlsl     text eol=lf
*.cginc    text eol=lf
*.asmdef   text eol=lf
*.asmref   text eol=lf
*.yml      text eol=lf
*.yaml     text eol=lf
*.toml     text eol=lf
*.ini      text eol=lf
*.ps1      text eol=lf
*.sh       text eol=lf

# Windows Batch만 CRLF
*.bat      text eol=crlf
*.cmd      text eol=crlf
```

### 적용 시 주의 사항

- 이 예시는 모든 확장자를 포괄하는 필수 구성 파일이 아니다. 실제 프로젝트의 텍스트 파일 유형과 기존 `.gitattributes`를 기준으로 필요한 항목만 반영한다.
- Git LFS, 바이너리 파일, 패키지 또는 Unity가 생성·관리하는 파일의 원래 규칙을 덮어쓰지 않는다.
- Unity 직렬화 파일(`.meta`, `.unity`, `.prefab`, `.asset` 등)은 **기존 저장소와 Unity의 관리 형식**을 확인한다. 단순히 전체 파일을 LF로 만들기 위해 재인코딩하거나 일괄 재저장하지 않는다.
- `* text=auto eol=lf` 또는 `* text=auto eol=crlf`와 같은 전역 예시를 기존 저장소에 무조건 추가하지 않는다. 기존 파일·생성 파일의 체크아웃 줄바꿈에 영향을 줄 수 있다.
- Git이 인덱스 내부에서 정규화한 줄바꿈과 **작업 트리의 실제 줄바꿈**은 별개다. `git ls-files --eol`과 실제 바이트 검사 결과로 판단한다.
- `.gitattributes`를 수정하더라도 기존 파일 전체의 정규화나 인덱스 재작성은 별도 요청이 없는 한 하지 않는다. 수정 대상 파일의 작업 트리 실제 바이트와 Git 속성을 각각 확인한다.

---

## 4. `.vscode/settings.json` 규칙

VS Code에서는 직접 생성하거나 수정하는 일반 텍스트 파일의 목표 줄바꿈으로 LF를 사용한다. **배포본에는 선택적 `.vscode/settings.json`이 포함되어 있지만 VS Code를 사용하지 않는 프로젝트에서는 적용할 필요가 없다.** 대상 프로젝트에 해당 파일이 이미 있다면 그대로 교체하지 않고 필요한 `files.eol` 항목만 병합한다. 프로젝트·사용자 설정, JSONC 주석과 기존 확장 기능 설정을 보존한다. 프로젝트 설정의 위치는 다음과 같다.

```text
.vscode/settings.json
```

설정 파일 생성·변경이 요청 범위에 포함된 경우에 사용할 수 있는 예시는 다음과 같다.

```json
{
  "files.eol": "\n"
}
```

기존 JSON 또는 JSONC 설정 파일이 있으면 다른 항목과 주석을 보존하며 필요한 속성만 병합한다. 이 설정만으로 신규 C# 파일의 BOM이나 Windows Batch의 CRLF가 자동 보장되는 것은 아니다. 다른 VS Code 워크스페이스에서 공유하는 경우에도 적용 범위를 확인하고, 임의로 사용자 전역 설정을 변경하지 않는다.

- 새로 생성하거나 수정한 C# 파일은 `.editorconfig` 지원 여부를 확인하고 **UTF-8 with BOM + LF**로 저장했는지 검사한다.
- 새로 생성하거나 수정한 `.bat`, `.cmd`는 CRLF로 저장했는지 확인한다. VS Code가 파일별 설정을 적용하지 않으면 저장 시 형식을 직접 확인한다.
- 기존 파일을 실제 수정했다면 상태 표시줄의 LF/CRLF 및 인코딩을 목표 규칙으로 맞추고, 저장 후 실제 바이트로 재확인한다.
- VS Code의 인코딩 표시와 실제 바이트 검사를 함께 사용해 한글이 손상되지 않았는지 확인한다.

---

## 5. 적용 우선순위와 역할

파일에 적용되는 기본값과 실제 저장 형식은 구분한다.

### `.gitignore` 배포 템플릿 적용 시 주의

배포본의 `.gitignore`는 [GitHub Unity.gitignore](https://github.com/github/gitignore/blob/main/Unity.gitignore)의 **기본 생성물 제외 패턴을 선별한 시작 예시**다. Git 저장소 루트와 Unity 프로젝트 루트가 다르면 `/Library/` 같은 루트 고정 패턴의 적용 위치를 확인한다.

- `.gitignore`가 이미 존재하면 **덮어쓰지 않고 병합**하며, 기존 Git LFS·바이너리·팀 규칙을 보존한다. Git에 이미 추적 중인 파일은 제외 규칙만 추가해도 추적이 해제되지 않는다.
- 기본 제외 대상은 `Library`, `Temp`, `Obj`, 빌드 산출물, `Logs`, `UserSettings`, IDE/Gradle 캐시와 확인 가능한 UI Toolkit 생성 스키마 등으로 제한한다. `Assets/`, `.meta`, `Packages/`, `ProjectSettings/`, UXML·USS·폰트 및 프로젝트 재현에 필요한 파일은 제외하지 않는다.
- Addressables·`StreamingAssets` 콘텐츠, 생성 Gradle 파일, 배포 패키지 산출물 등은 **주석 처리한 후보 규칙**을 확인한 뒤 필요한 경우에만 활성화한다. Unity가 자동 생성하는 `*.csproj`·`*.sln` 등은 기본 제외하되, 수동으로 관리하는 파일이 있다면 기존 추적 정책에 맞춰 해당 제외 패턴을 조정한다.
- 실제 제외 상태는 `git check-ignore -v --no-index -- <경로>`, 이미 추적된 상태는 `git ls-files -- <경로>`로 별도 확인한다. 단순 파일 형식 수정 요청을 `.gitignore` 전체 재작성으로 확대하지 않는다. 상세 안전 정책은 `GIT.md` 7.1절을 따른다.

1. **대상 및 설정 확인:** 현재 작업에서 실제 내용을 수정하는 파일을 확정하고 적용되는 `.editorconfig`·`.gitattributes`, Git LFS·바이너리 규칙, 생성 도구의 필수 형식을 확인한다.
2. **수정 파일의 목표 형식 적용:** 신규 파일뿐 아니라 내용을 수정하는 기존 일반 텍스트 파일에도 `.cs`는 UTF-8 BOM + LF, 일반 문서·설정은 UTF-8 without BOM + LF, `.bat`·`.cmd`는 UTF-8 기본 + CRLF를 적용한다.
3. **미수정 파일 보존:** 읽기만 한 파일, 요청 범위 밖의 파일, Unity·외부 도구의 자동 생성 파일과 직렬화 파일은 임의 변환하지 않는다.
4. **충돌·문자 손상 방지:** 명시적인 프로젝트 설정이 목표 형식과 충돌하거나 기존 인코딩을 안전하게 해석할 수 없으면 해당 파일의 정규화를 보류하고 원인과 조정 방안을 보고한다. 다른 안전한 작업은 계속 진행할 수 있다.
5. **대량 정규화 분리:** 미수정 파일까지 포함한 별도 정규화는 사용자 요청 시 대상·범위·영향·Git diff를 확인해 기능 수정과 별도 작업·커밋으로 관리한다.

`.editorconfig`는 에디터 저장 동작, `.vscode/settings.json`은 VS Code 기본값, `.gitattributes`는 Git의 정규화·체크아웃에 적용된다. **셋의 적용 단계는 다르며 한 파일이 다른 파일을 자동으로 대체하지 않는다.** 설정을 추가한 사실만으로 실제 결과 검증을 생략하지 않는다.

---

## 6. AI 에이전트 및 Codex 작업 규칙

AI 에이전트는 파일 작업 시 다음 규칙을 따른다.

1. 작업 전에 실제 Unity 프로젝트·Git 저장소 루트를 확정하고, 적용되는 `.editorconfig`, `.gitattributes`, `.vscode/settings.json` 및 상위 설정을 확인한다.
2. 신규 일반 텍스트 파일은 확장자별 정책대로 생성한다: `.cs`는 UTF-8 BOM/LF, `.bat`·`.cmd`는 UTF-8 기본/CRLF, 그 외 일반 텍스트는 UTF-8 without BOM/LF.
3. **기존 일반 텍스트의 내용을 수정하면 해당 파일만 목표 형식으로 변환한다.** 내용 변경 없이 읽거나 검토한 파일에는 적용하지 않는다.
4. Unity 또는 외부 도구가 자동 생성·관리하는 파일의 인코딩·줄바꿈을 임의로 수정하지 않는다.
5. 한국어 주석·문자열·UI 텍스트가 깨지지 않았는지 저장 전후 확인한다. 비정상 문자나 치환 문자가 생기면 원본을 보존하고 원인을 조사한다.
6. 기존 Git LFS, 바이너리, 파일별 줄바꿈 규칙을 변경·삭제하지 않는다.
7. `.editorconfig`와 `.gitattributes`의 적용 결과가 목표 정책과 다르면 무시하거나 몰래 바꾸지 않는다. 영향을 받는 파일의 변환을 보류하고 충돌과 최소 조정안을 보고한다.
8. 사용자 요청이 없는 저장소 전체 형식 변경, `git add --renormalize .`, 무관한 파일 일괄 재저장을 실행하지 않는다.
9. **수정한 파일만 정규화한 변경은 기능 수정과 같은 작업·커밋에 포함할 수 있다.** 수정하지 않은 파일까지 포함하는 일괄 형식 변경은 별도 작업·커밋으로 관리한다.
10. 기대된 형식 변환으로 줄 전체가 Git diff에 나타나면 변환 범위·실제 내용 변경·문자 손상 여부를 검증한다. 검증 실패 시 해당 파일의 변환을 보류한다.
11. 실제 바이트 또는 검증 가능한 도구 출력 없이 “BOM 적용 완료”, “LF/CRLF 일치”, “한글 정상”이라고 단정하지 않는다.

---

## 7. 기존 파일 정규화 시 안전 규칙

### 7.1 실제 수정한 파일의 점진적 정규화

- 기능 추가·버그 수정·주석 수정 등으로 **실제로 내용을 변경한 일반 텍스트 파일만** 확장자별 형식으로 저장한다. 같은 파일의 정규화는 그 수정 작업에 포함된다.
- 파일별 원본 인코딩을 정확히 해석한 다음 해당 확장자의 목표 UTF-8 BOM 상태와 LF/CRLF로 저장한다. 한글·특수문자·식별자 및 내용이 정규화 외에 변경되지 않았는지 비교한다.
- LF/CRLF 변환으로 Git diff에 파일 전체 줄이 나타날 수 있으므로, 형식 차이를 제외한 코드/내용 변경과 원래 의도한 수정 범위를 따로 검토한다.
- `.editorconfig`, `.gitattributes`, 생성 도구 제약이 충돌하거나 문자 손상이 예상되면 변환하지 않고 해당 파일의 미적용 사유를 보고한다.
- 수정 대상 외 파일 및 Unity 직렬화 파일·`.meta`·외부 생성 파일·바이너리에는 정규화를 적용하지 않는다.

### 7.2 저장소 일괄 정규화(별도 요청 시)

기존 저장소의 수정하지 않은 파일까지 정규화하는 것은 기본 작업이 아니다. 사용자에게 **명시적으로 요청된 별도 형식 정리 작업**에서만 실행한다. 대상 파일·작업 범위·현재 변경 상태를 먼저 확정한다.

Git 정규화가 필요한 경우 사용할 수 있는 명령은 다음과 같다.

```bash
git add --renormalize .
```

이 명령은 추적 중인 파일의 인덱스에 Git clean 처리를 다시 적용하는 명령이며, 파일을 새 인코딩으로 저장하거나 자동으로 BOM을 추가하지 않는다. 사용자 변경까지 Stage될 수 있으므로 **자동 실행 금지**를 기본으로 한다.

1. 작업 전 `git status`, `git diff --stat`, `git diff --cached --stat`으로 기존 변경을 확인한다.
2. 한 번에 저장소 전체를 대상으로 삼지 말고 요청한 파일 집합과 영향 범위를 확정한다. 사용자 변경이 섞인 경우 자동 변환하지 않는다.
3. 필요한 경우 원본 백업이나 Git의 해당 파일 내용을 확인해 한글과 인코딩 손상이 없도록 한다.
4. 변환 후 `git diff --cached --stat`, `git diff --cached --check`, `git diff --cached` 및 실제 바이트 결과를 확인한다.
5. **미수정 파일까지 포함하는 일괄 정규화는 기능 수정과 다른 커밋**에 기록한다. 반면 실제로 내용을 수정한 파일의 형식 정규화는 해당 수정 작업과 같은 커밋에 포함할 수 있다.
6. 예상하지 못한 전체 파일 변형이나 Unity 관리 파일의 변화가 있으면 중단하고 원인을 확인한다. 기존 사용자 변경을 임의로 덮어쓰거나 되돌리지 않는다.

---

## 8. 확인 방법

### Visual Studio

- 생성하거나 수정한 `.cs`가 **UTF-8 with BOM + LF**로 저장되었는지 확인한다.
- EditorConfig 설정 지원 여부를 확인하고, C# 파일의 한글 주석·문자열을 저장 전후 비교한다.
- 기존 `.cs`를 수정할 때 형식 정규화로 전체 파일 diff가 발생했다면 예상된 형식 차이와 실제 코드 변경을 구별해 검증한다.

### VS Code

- 생성하거나 수정한 `.cs`의 인코딩이 UTF-8 with BOM인지 확인한다. 생성하거나 수정한 Markdown·JSON·UXML·USS·Shader 파일은 UTF-8 without BOM인지 확인한다.
- 생성하거나 수정한 일반 텍스트는 상태 표시줄에서 LF, Batch는 CRLF를 확인한다.
- 기존 파일의 내용을 수정한 경우 해당 파일만 목표 형식으로 변환하고, 수정하지 않은 파일은 변경하지 않는다.

### Git

```bash
# 해당 파일에 실제 적용되는 Git 줄바꿈 속성 확인
git check-attr text eol -- 경로/파일명

# 인덱스와 작업 트리의 줄바꿈 상태 확인
git ls-files --eol -- 경로/파일명

# 공백 오류와 불필요한 전체 변경 여부 확인
git diff --check
git diff --stat
```

위 명령은 BOM 및 UTF-8 유효성 검사를 대신하지 않는다. 생성하거나 수정한 `.cs`의 BOM과 한글 문자 유효성은 실제 바이트로 확인한다.

### PowerShell — 실제 파일 바이트 검증 예시

```powershell
$Path = 'Assets/Scripts/Example.cs'  # 실제 검사할 파일 경로로 변경
$Bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path)
$HasUtf8Bom = $Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF
$StrictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
$Text = $StrictUtf8.GetString($Bytes) # 유효하지 않은 UTF-8은 예외 발생

[pscustomobject]@{
    HasUtf8Bom = $HasUtf8Bom
    CRLF       = [regex]::Matches($Text, '\r\n').Count
    LFOnly     = [regex]::Matches($Text, '(?<!\r)\n').Count
    CROnly     = [regex]::Matches($Text, '\r(?!\n)').Count
}
```

- 생성하거나 수정한 `.cs`: `HasUtf8Bom=True`, `CRLF=0`, `CROnly=0`이 기본 기대값이다.
- 생성하거나 수정한 Markdown·JSON·UXML·USS·Shader: `HasUtf8Bom=False`, `CRLF=0`, `CROnly=0`이 기본 기대값이다.
- 생성하거나 수정한 `.bat`·`.cmd`: `CRLF`을 사용해야 하며 `LFOnly=0`, `CROnly=0`을 확인한다.
- 줄바꿈이 없는 한 줄 파일은 개수만으로 LF/CRLF 사용 여부를 판단할 수 없다.
- UTF-8로 읽을 수 있더라도 원래 한글 내용이 손상되었을 가능성이 있으므로 저장 전후 내용·Git diff도 확인한다.

---

## 9. 권장 프로젝트 구조

다음은 **Unity 프로젝트에 배포 템플릿을 적용한 뒤의 권장 구조**다. `.vscode/settings.json`은 VS Code 사용자만 선택적으로 적용한다. `History/`는 작업 이력이 실제로 생길 때 생성하며, 이 배포 ZIP에는 게임 프로젝트의 `Assets/`, `Packages/`, `ProjectSettings/`나 `History/` 자체가 포함되지 않는다. 실제 설정 파일이 존재하지 않더라도 일반 파일 작업만을 이유로 자동 생성하지 않는다.

```text
<ProjectRoot>/
├── .editorconfig
├── .gitattributes
├── .gitignore
├── .vscode/                    # VS Code 사용 시 선택적
│   └── settings.json           # 기존 파일이 있다면 병합
├── AGENTS.md
├── MD/
│   ├── READ.md
│   ├── FILE.md
│   ├── HISTORY.md
│   ├── GIT.md
│   ├── BUILD.md
│   ├── UNITY_ASSET_RULES.md
│   ├── UNITY_CS_CODING_RULES.md
│   └── UNITY_TOOLING.md
├── History/                    # 최초 이력 작성 시 생성
├── Assets/
├── Packages/
└── ProjectSettings/
```

이전 프로젝트의 검토 기록인 `REVIEW_NOTES.md`는 최종 공통 배포본에서 제외하고 원본 보관본에만 유지한다.

---

## 10. 최종 체크리스트

설정 파일 생성·수정 여부는 사용자의 실제 요청 범위를 따른다. 일반 파일 수정 작업에서는 **실제로 수정한 파일의 목표 형식 적용과 변경 결과**를 검사하며, 누락된 설정을 임의로 생성하지 않는다.

- [ ] `.editorconfig`, `.gitattributes`의 기존·상위 규칙과 Git LFS·바이너리 예외를 확인했다.
- [ ] 상위 `.editorconfig` 상속 여부를 확인하고 `root = true`를 독립적인 설정 루트에서만 활성화했다.
- [ ] `.gitignore`는 기존 파일과 병합했고, Unity 생성물과 실제 소스·`.meta`를 구별하여 추적 상태를 검사했다.
- [ ] `.vscode/settings.json`은 VS Code를 사용하는 경우에만 적용하며 기존 사용자·프로젝트 설정을 보존했다.
- [ ] **신규·수정 `.cs`는 UTF-8 with BOM + LF**로 저장하고 실제 바이트를 검증했다.
- [ ] 신규·수정 Markdown·JSON·UXML·USS·Shader·일반 설정은 **UTF-8 without BOM + LF**로 저장했는지 확인했다.
- [ ] 신규·수정 `.bat`·`.cmd`는 **CRLF**로 저장하고 실행 환경에서 필요한 문자 표시를 확인했다.
- [ ] Unity 및 외부 도구가 생성·관리하는 파일과 미수정 파일은 원래 인코딩·줄바꿈을 보존했다.
- [ ] 기존 파일의 내용 수정 시 그 파일만 목표 형식으로 정규화했고, Git diff의 예상된 대량 줄바꿈 변경과 실제 내용 변경을 구별했다.
- [ ] 한글 주석·문자열이 저장 전후 손상되지 않았음을 확인했다.
- [ ] VS Code, Visual Studio 및 Codex에서 실제로 적용되는 인코딩과 줄바꿈을 검증했다.
- [ ] 미수정 파일까지 포함하는 일괄 형식 변경은 기능 수정과 분리하고 별도 커밋으로 관리했다.
- [ ] Git diff와 파일별 실제 형식 검사에서 예상하지 못한 변경이 없는지 확인했다.

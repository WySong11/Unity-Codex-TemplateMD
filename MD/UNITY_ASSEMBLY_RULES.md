# Unity Assembly Definition(.asmdef·.asmref) 설계 및 검증 규칙

이 `UNITY_ASSEMBLY_RULES.md` 문서는 실제 Unity 프로젝트의 Assembly Definition(`.asmdef`)·Assembly Definition Reference(`.asmref`)를 설계·생성·변경하거나 기존 코드를 다른 어셈블리로 옮길 때 적용한다. [AGENTS.md](../AGENTS.md)와 [READ.md](READ.md)의 적용 조건을 우선하며, C#은 [UNITY_CS_CODING_RULES.md](UNITY_CS_CODING_RULES.md), 에셋·GUID는 [UNITY_ASSET_RULES.md](UNITY_ASSET_RULES.md), 파일 형식은 [FILE.md](FILE.md), 테스트·빌드는 [BUILD.md](BUILD.md)에 따른다.

> **기본 원칙:** 모든 프로젝트·폴더에 asmdef를 강제로 생성하지 않는다. 현재 프로젝트의 코드 경계와 참조 관계를 먼저 분석하고, 필요한 경우에만 도입한다. 기존 프로젝트 전체를 사용자 요청 없이 일괄 어셈블리 분리하지 않는다. 템플릿 저장소에 이 문서를 추가하는 것 자체는 실제 Unity 프로젝트의 컴파일 구성을 바꾸지 않는다.

## 1. 도입 기준

| 프로젝트 상황 | 판단 기준 |
| --- | --- |
| 입문·소규모 프로토타입 | 선택. 복잡도만 늘어나면 도입하지 않음 |
| Core, Gameplay, UI 등 책임이 분리된 중·대형 프로젝트 | 안정적인 API 경계가 있고 컴파일·의존성 분리 가치가 있으면 권장 |
| 재사용 가능한 게임 시스템·UPM 패키지 | Runtime·Editor·Tests의 책임별 분리 권장 |
| Firebase·Photon 등 서드파티 SDK 사용 | 현재 설치 SDK의 asmdef·DLL·버전·플랫폼 지원 확인 후 필요한 참조만 설정 |
| 기존 asmdef·asmref 사용 프로젝트 | 기존 구조 우선, 최소 변경 원칙 |

asmdef는 **컴파일 의존성 분리**를 통해 불필요한 재컴파일을 줄일 수 있지만, 참조가 지나치게 촘촘하거나 과도하게 분할한 경우에는 이점이 작을 수 있다. 런타임 FPS가 자동 개선되는 기능으로 설명하지 않는다.

## 2. 도입 전 필수 조사

1. 실제 Unity 프로젝트 루트(`Assets`, `Packages/manifest.json`, `ProjectSettings/ProjectVersion.txt`)와 Unity 버전을 확인한다.
2. 기존 `.asmdef`, `.asmref`, `.meta`, 관련 패키지 및 테스트 프레임워크의 설치 버전·참조 상태를 조사한다.
3. 스크립트의 현재 어셈블리(`Assembly-CSharp`, `Assembly-CSharp-Editor` 등), 네임스페이스, 외부 SDK 및 실제 호출 방향을 파악한다.
4. Editor 전용 API(`UnityEditor`), Reflection, `SerializeReference`, Inspector·프리팹·씬 직렬화 참조에 미칠 영향을 확인한다.
5. `Include Platforms`, `Auto Referenced`, `Override References`, `Use GUIDs`, `Define Constraints`, `Version Defines`의 기존 설정을 보존한다.
6. 기존 Git 변경 및 Unity Editor 미저장 작업을 보호한다. 많은 스크립트 이동이나 광범위한 asmdef 재편은 영향 목록을 제시하고 별도로 승인받는다.

## 3. 권장 의존성 설계 (예시, 강제 구조 아님)

```text
Assets/MyGame/Scripts/
├── Runtime/
│   ├── Core/MyGame.Core.asmdef
│   ├── Gameplay/MyGame.Gameplay.asmdef
│   └── UI/MyGame.UI.asmdef
├── Editor/MyGame.Editor.asmdef
└── Tests/
    ├── EditMode/MyGame.Tests.EditMode.asmdef
    └── PlayMode/MyGame.Tests.PlayMode.asmdef
```

- 참조 방향의 예: `Gameplay → Core`, `UI → Core`. 실제 프로젝트에서 필요 없는 모듈은 생성하지 않는다.
- `Editor` 어셈블리에는 `Include Platforms = Editor`를 지정하고 필요한 Runtime 어셈블리를 참조한다. Runtime 어셈블리는 Editor 전용 어셈블리와 `UnityEditor` API를 참조하지 않는다.
- 테스트 어셈블리는 테스트 프레임워크 설치 상태를 확인하고, 테스트 대상 어셈블리 및 필요한 테스트 지원 어셈블리를 참조한다. EditMode와 PlayMode의 실행·플랫폼 제약을 구분한다.
- **순환 참조는 금지**한다. 양방향 의존이 발생하면 공통 인터페이스·이벤트·의존성 역전이나 어셈블리 통합을 검토한다.
- 파일·폴더 숫자에 맞춰 기계적으로 asmdef를 생성하지 않는다.

## 4. 생성 및 Inspector 설정

Unity Editor의 **Assets → Create → Scripting → Assembly Definition**에서 asmdef를 생성하고 Inspector에서 확인한다. asmdef가 들어 있는 폴더의 스크립트 및 하위 폴더에 적용되므로 기존 하위 asmdef·asmref와 중첩 구조를 먼저 확인한다.

| 설정 | 역할 및 주의사항 |
| --- | --- |
| `Name` | 중복 없는 고유 어셈블리 이름. 이름 변경 전 외부 참조 영향 확인 |
| `Assembly Definition References` | 다른 **프로젝트 정의 어셈블리**에 대한 직접 참조. 사용 방향으로만 추가 |
| `Use GUIDs` | 참조 대상 asmdef의 GUID 기반 직렬화. 신규 구성에서 권장하되 기존 이름 기반 참조를 무단 변경하지 않음 |
| `Include Platforms` | Editor 전용 asmdef는 Editor로 제한. Runtime 플랫폼 제외는 실제 필요할 때만 |
| `Auto Referenced` | **사전 정의된 어셈블리에서** 이 커스텀 어셈블리를 자동 참조할지 제어. 기본값을 임의 변경하지 않음 |
| `Override References` 및 `Assembly References` | 사전 컴파일된 DLL 참조를 선택하기 위한 옵션. 위 Assembly Definition References와 별개 |
| `Define Constraints`·`Version Defines` | 패키지·플랫폼 버전 확인 후 실제 필요에 한해 사용 |
| `No Engine References`·`Allow Unsafe Code` | 특수한 요구가 확인된 경우에만 변경 |

`.asmref`는 **새 어셈블리를 만드는 것이 아니라**, 별도 폴더의 스크립트를 **기존 asmdef 어셈블리에 포함**시키는 참조 에셋이다. 실제 Unity Editor에서 참조 대상과 적용 범위를 확인한다.

## 5. 필수 참조 제한과 외부 SDK

- 커스텀 asmdef로 만든 어셈블리는 **사전 정의된 `Assembly-CSharp` 등을 참조할 수 없다**. 필요한 공통 타입이 여기에 남아 있다면 이를 적절한 커스텀 asmdef로 이동하거나 의존성 설계를 변경한다.
- 사전 정의된 어셈블리에서 커스텀 어셈블리의 타입을 사용 중이면 `Auto Referenced = false`가 기존 코드를 깨뜨릴 수 있으므로 사전에 검사한다.
- SDK가 제공하는 어셈블리 이름·의존 DLL·플랫폼 제한을 실제 `manifest.json`과 패키지 내 asmdef에서 확인한다. 없는 어셈블리나 예전 SDK 참조를 추측해 추가하지 않는다.
- 기존 asmdef·asmref·`.meta`를 이동·이름 변경할 때 GUID와 이름 기반 참조를 함께 확인한다. Unity 패키지에서 관리하는 원본 파일은 임의 수정하지 않는다.
- `overrideReferences`를 무분별하게 활성화하여 사용 중인 플러그인 DLL을 누락하지 않는다.

## 6. Codex 적용 및 검증 절차

1. **분석:** 현 상태의 어셈블리 그래프와 코드·패키지·플랫폼 의존성 작성.
2. **설계:** 최소 모듈 수, 단방향 참조, Runtime·Editor·Tests 경계를 결정.
3. **실행:** 요청·승인된 범위에서만 asmdef·asmref 생성/변경. 에셋 이동 시 `.meta` GUID 보존.
4. **정적·컴파일:** 실제 Unity Editor가 재컴파일을 마칠 때까지 확인하고 최초 컴파일 오류, 누락 참조·순환 참조·Editor API 혼입을 조사.
5. **테스트:** 영향받는 EditMode·PlayMode 테스트와 관련 씬·프리팹·Inspector 참조 확인. 필요한 경우 해당 플랫폼의 Player 빌드 검증.
6. **보고:** 생성·수정한 어셈블리·참조·플랫폼 조건, 검증 성공·실패 및 미검증 항목 보고. 실제 프로젝트 파일 변경은 HISTORY.md·GIT.md 정책 적용.

작업별 승인 및 도구 점검 주기는 `AGENTS.md`, `UNITY_TOOLING.md`를 따른다. asmdef 문서만 수정할 때 Unity CLI 설치·업데이트, 빌드, 패키지 변경을 자동 실행하지 않는다.

## 7. 최종 체크리스트

- [ ] 기존 asmdef·asmref 및 `.meta`·GUID 상태를 확인했다.
- [ ] 사전 정의된 `Assembly-CSharp` 참조 제한과 순환 참조를 검사했다.
- [ ] Runtime→Editor 역참조가 없고 Editor asmdef에 Editor 플랫폼 조건을 적용했다.
- [ ] 패키지 의존성, GUID/이름 참조 및 Auto Referenced/Override References 설정을 검토했다.
- [ ] 테스트 어셈블리 참조 및 관련 EditMode/PlayMode 테스트를 검증했다(해당 시).
- [ ] Unity 재컴파일·Console 오류, 기존 씬·프리팹·직렬화 연결을 확인했다.
- [ ] 요구된 Player 빌드만 수행하고 미실행 단계는 미검증으로 남겼다.
- [ ] 직접 작성·수정한 asmdef·asmref는 `FILE.md`에 따라 UTF-8 without BOM + LF, Unity 관리 `.meta`는 원형 보존했다.
- [ ] 컴파일 시간 개선을 주장할 때 측정 또는 재컴파일 범위 근거가 있다.

## 공식 Unity 문서

- [어셈블리 정의 개요](https://docs.unity3d.com/kr/current/Manual/assembly-definition-files.html)
- [asmdef·asmref 생성](https://docs.unity3d.com/kr/current/Manual/assembly-definitions-creating.html)
- [어셈블리 간 참조 제한](https://docs.unity3d.com/kr/6000.0/Manual/assembly-definitions-referencing.html)
- [asmdef Inspector 속성](https://docs.unity3d.com/kr/current/Manual/class-AssemblyDefinitionImporter.html)
- [테스트용 어셈블리](https://docs.unity3d.com/kr/current/Manual/cus-tests.html)

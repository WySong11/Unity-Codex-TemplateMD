# Unity C# 파일 생성 및 코딩 규칙

이 문서는 Codex 또는 개발자가 Unity 프로젝트에서 `.cs` 파일을 새로 만들거나 기존 코드를 수정할 때 따라야 하는 공통 규칙이다.

> 적용 원칙: 이 문서보다 프로젝트의 기존 구조, `AGENTS.md`, 팀 규칙, 사용자 지시가 우선한다. 서로 충돌하지 않는 범위에서 이 규칙을 적용한다.

---

## 1. 작업 시작 전 확인

1. 현재 Unity 버전과 사용 중인 렌더 파이프라인을 확인한다.
2. `Packages/manifest.json`을 확인하여 Input System, Cinemachine, Addressables 등 관련 패키지와 버전을 확인한다.
3. 같은 역할을 하는 기존 클래스, 인터페이스, 베이스 클래스가 있는지 먼저 검색한다.
4. 기존 프로젝트의 네임스페이스, 명명 방식과 폴더 구조를 우선 따른다. 인코딩·줄바꿈은 `FILE.md`의 수정 파일 점진적 정규화 규칙과 실제 파일별 예외를 따른다.
5. 설치된 Unity Skill 중 작업과 관련된 Skill이 있으면 해당 Skill의 지침을 먼저 확인하고 적용한다.
6. 요구사항이 불분명하거나 기존 구조를 크게 바꿔야 한다면 임의로 결정하지 말고 사용자에게 확인한다.
7. 요청 수행에 필요한 최소 파일·설정만 변경한다. AGENTS.md가 참조하는 UNITY_TOOLING.md의 적용 조건에 따른 CLI·MCP·Pipeline 준비는 허용된 도구 관리 범위이며 다른 패키지 변경으로 확대하지 않는다.

---

## 2. 파일과 클래스 규칙

- 파일 이름과 대표 클래스 이름을 동일하게 작성한다.
- 한 파일에는 대표 `public` 클래스 하나만 작성하는 것을 원칙으로 한다.
- 파일 이름은 역할을 알 수 있도록 구체적으로 작성한다.
- 의미가 불분명한 이름이나 버전 번호가 붙은 이름을 피한다.
- 기존 스크립트를 수정할 수 있다면 같은 기능의 새 스크립트를 중복 생성하지 않는다.
- 런타임 코드와 Editor 전용 코드를 분리한다.

```text
권장: PlayerMovement.cs      → PlayerMovement
권장: EnemyHealth.cs         → EnemyHealth
권장: LoginPanelController.cs → LoginPanelController

지양: Manager.cs
지양: Test1.cs
지양: Player_New_Final_V2.cs
```

Editor 전용 코드는 다음 위치에 둔다.

```text
Assets/<ProjectName>/Scripts/Editor/
```

프로젝트에서 Assembly Definition을 사용한다면 런타임 어셈블리와 Editor 어셈블리를 분리한다. Editor 폴더를 만드는 것만으로 독립 Editor 어셈블리가 생성되었다고 단정하지 않고 `Include Platforms = Editor`와 실제 참조를 확인한다.

- 스크립트 생성·이동 시 적용되는 `.asmdef`·`.asmref`와 기존 참조를 먼저 확인한다.
- asmdef 설계·생성·수정·모듈 분리는 [UNITY_ASSEMBLY_RULES.md](UNITY_ASSEMBLY_RULES.md)에 따라 `Assembly-CSharp` 역참조·순환 참조·패키지·테스트 의존성을 검토한다.
- 소규모 프로젝트에 asmdef를 강제하지 않고, 기존 코드의 대규모 어셈블리 이동을 사용자 요청 없이 자동 수행하지 않는다.

---

## 3. 권장 폴더 구조

기존 구조가 없다면 다음 구조를 기준으로 한다.

```text
Assets/
└── <ProjectName>/
    ├── Scripts/
    │   ├── Runtime/
    │   │   ├── Core/
    │   │   ├── Player/
    │   │   ├── Enemy/
    │   │   ├── UI/
    │   │   ├── Data/
    │   │   └── Utility/
    │   ├── Editor/
    │   └── Tests/
    ├── Prefabs/
    ├── Scenes/
    └── ScriptableObjects/
```

작은 프로젝트에서는 과도하게 폴더를 나누지 않는다. 프로젝트 규모에 맞게 필요한 구조만 사용한다.

---

## 4. 네임스페이스 규칙

- 전역 네임스페이스 사용을 피하고 프로젝트 전용 네임스페이스를 사용한다.
- 네임스페이스는 `회사명.프로젝트명.기능명` 또는 `프로젝트명.기능명` 형식을 권장한다.
- 기존 프로젝트가 file-scoped namespace를 사용하지 않는다면 임의로 형식을 변경하지 않는다.

```csharp
namespace ItHappyCity.Player
{
    public sealed class PlayerMovement : MonoBehaviour
    {
    }
}
```

---

## 5. 명명 규칙

| 대상 | 규칙 | 예시 |
|---|---|---|
| 클래스, 구조체, 인터페이스 | PascalCase | `PlayerController`, `IDamageable` |
| 메서드 | PascalCase | `TakeDamage()`, `LoadSceneAsync()` |
| 프로퍼티 | PascalCase | `CurrentHealth`, `IsAlive` |
| public 필드 | PascalCase | `MoveSpeed` |
| private/protected 필드 | `_camelCase` | `_currentHealth`, `_rigidbody` |
| 매개변수, 지역 변수 | camelCase | `damageAmount`, `targetPosition` |
| 상수 | PascalCase | `MaxPlayerCount` |
| bool | 선언 위치의 대소문자·접두사 규칙에 맞는 상태나 질문 형태 | 지역 변수 `isGrounded`, private 필드 `_isGrounded`, 프로퍼티 `IsGrounded` |
| 이벤트 | 상태 변화가 드러나는 이름 | `HealthChanged`, `Died` |
| 이벤트 처리 메서드 | `On` + 이벤트명 | `OnHealthChanged()` |

다음 이름은 특별한 이유가 없으면 사용하지 않는다.

```text
data, temp, value, obj, manager, test, aaa, new, final
```

약어는 널리 알려진 경우만 사용한다. `UI`, `ID`, `HP` 등 프로젝트에서 이미 사용하는 약어 규칙을 따른다.

---

## 6. using 문 규칙

- 사용하지 않는 `using`은 제거한다.
- 일반적으로 다음 순서를 사용하고 그룹 사이에 빈 줄을 둔다.

```csharp
using System;
using System.Collections.Generic;

using UnityEngine;
using UnityEngine.UIElements;
```

- 위 예시는 UI Toolkit 기반 코드의 `using` 예시다. 기존 uGUI·TMP 코드에서만 필요에 따라 `UnityEngine.UI`, `TMPro`를 사용한다.
- `UnityEngine.UI.Button`과 `UnityEngine.UIElements.Button` 등 형식 이름이 충돌하면 불필요한 두 네임스페이스 동시 도입을 피하고, 필요한 곳에 명시적 전체 이름 또는 `using` 별칭을 사용한다.
- 이름 충돌이 없다면 불필요한 전체 형식 이름을 반복하지 않는다.
- `using static`과 별칭은 가독성이 실제로 좋아지는 경우에만 사용한다.

---

## 7. 클래스 내부 멤버 배치 순서

기존 프로젝트 규칙이 없다면 다음 순서를 사용한다.

1. 상수와 `static readonly` 필드
2. Inspector에 노출되는 직렬화 필드
3. 일반 private/protected 필드
4. public 프로퍼티
5. 이벤트와 델리게이트
6. Unity 생명주기 메서드
7. public 메서드
8. private/protected 메서드
9. 이벤트 처리 메서드
10. Editor 전용 검증 코드

필드가 많다면 `[Header]`, `[Tooltip]`, `[Range]`, `[Min]` 등을 사용해 Inspector를 이해하기 쉽게 구성한다. 장식용 Attribute를 과도하게 사용하지 않는다.

---

## 8. Inspector와 직렬화 규칙

- 외부 클래스가 직접 변경할 필요가 없는 값은 `public` 필드 대신 `[SerializeField] private`을 사용한다.
- 읽기만 허용할 값은 public 프로퍼티로 제공한다.
- 런타임 상태와 설정값을 명확히 구분한다.
- Inspector에 노출된 필드에는 목적을 알 수 있는 이름과 필요 시 `[Tooltip]`을 작성한다.
- 참조가 반드시 필요하면 `Awake()`에서 검사하고 명확한 오류를 출력한다.
- `ScriptableObject`가 적합한 공유 설정 데이터를 `MonoBehaviour`에 중복 저장하지 않는다.

```csharp
[Header("Movement")]
[SerializeField, Min(0f)] private float _moveSpeed = 5f;
[SerializeField] private CharacterController _characterController;

public float MoveSpeed => _moveSpeed;
```

다음과 같은 무분별한 public 필드는 피한다.

```csharp
public float speed;
public GameObject player;
```

---

## 9. 접근 제한과 캡슐화

- 모든 멤버에 가능한 한 가장 좁은 접근 제한자를 사용한다.
- 외부에서 값을 바꿔야 할 때도 public 필드를 열기보다 의도가 드러나는 메서드나 프로퍼티를 제공한다.
- 상속이 필요하지 않은 클래스는 상황에 따라 `sealed`를 사용한다.
- 상속을 전제로 하지 않는 메서드는 불필요하게 `virtual`로 만들지 않는다.
- 전역 `static` 상태와 Singleton은 꼭 필요한 경우에만 사용한다.

```csharp
public void SetMoveSpeed(float moveSpeed)
{
    _moveSpeed = Mathf.Max(0f, moveSpeed);
}
```

---

## 10. Unity 생명주기 규칙

- `Awake`: 자기 자신과 필수 컴포넌트 초기화
- `OnEnable`: 이벤트 구독, 입력 활성화
- `Start`: 다른 오브젝트와 연결한 뒤 필요한 초기화
- `Update`: 프레임 단위 입력과 일반 로직
- `FixedUpdate`: Rigidbody 기반 물리 이동과 힘 적용
- `LateUpdate`: 카메라 추적 등 다른 업데이트 이후 처리
- `OnDisable`: 이벤트 구독 해제, 입력 비활성화
- `OnDestroy`: 생성한 자원과 장기 참조 정리

중요한 규칙:

- 생성자에서 Unity 오브젝트나 컴포넌트를 초기화하지 않는다.
- `Awake`, `Start`, `OnEnable`의 책임을 섞지 않는다.
- `OnEnable`에서 구독한 이벤트는 `OnDisable`에서 반드시 해제한다.
- `Update`와 `FixedUpdate`의 용도를 구분한다.
- 메서드 이름의 대소문자와 시그니처를 정확히 작성한다.
- 불필요한 빈 Unity 메시지 메서드는 만들지 않는다.

---

## 11. 컴포넌트 참조 규칙

- 반복 호출되는 `GetComponent`, `Find`, 태그 검색 결과는 초기화 단계에서 캐시한다.
- `Update()` 안에서 `FindObjectOfType`, `GameObject.Find`, `GetComponent`를 반복 호출하지 않는다.
- 같은 오브젝트에 반드시 필요한 컴포넌트는 `[RequireComponent]` 사용을 고려한다.
- Inspector 참조와 자동 탐색을 함께 사용할 때는 우선순위를 명확히 한다.
- `Camera.main`도 반복 접근이 필요하면 캐시한다.

```csharp
[RequireComponent(typeof(Rigidbody))]
public sealed class PlayerMotor : MonoBehaviour
{
    private Rigidbody _rigidbody;

    private void Awake()
    {
        _rigidbody = GetComponent<Rigidbody>();
    }
}
```

---

## 12. null과 오류 처리

- Unity 오브젝트는 파괴된 객체 비교 동작이 일반 C# 객체와 다를 수 있으므로 Unity 객체에는 Unity의 null 비교 방식을 사용한다.
- 필수 참조가 없으면 조용히 실패하지 말고 오브젝트 이름과 필드 이름을 포함한 오류를 출력한다.
- 복구할 수 없는 설정 오류에서는 해당 컴포넌트를 비활성화하는 방식을 고려한다.
- `try-catch`로 모든 오류를 숨기지 않는다.
- 예외는 실제로 복구하거나 의미 있는 정보를 추가할 수 있을 때 처리한다.

```csharp
private void Awake()
{
    if (_characterController != null)
    {
        return;
    }

    Debug.LogError(
        $"[{nameof(PlayerMovement)}] CharacterController 참조가 없습니다. Object: {name}",
        this);
    enabled = false;
}
```

---

## 13. 메서드 작성 규칙

- 메서드는 한 가지 책임만 갖도록 작성한다.
- 메서드 이름은 실행하는 행동이 드러나는 동사로 시작한다.
- 매개변수가 많아지면 설정 객체나 구조체로 묶을지 검토한다.
- 중첩된 `if`가 깊어지지 않도록 조기 반환을 활용한다.
- 알 수 없는 숫자와 문자열을 직접 반복하지 말고 상수 또는 설정값으로 분리한다.
- 외부 상태를 예상치 못하게 바꾸는 부수 효과를 줄인다.

```csharp
private bool CanAttack()
{
    if (!_isAlive)
    {
        return false;
    }

    if (_currentTarget == null)
    {
        return false;
    }

    return Time.time >= _nextAttackTime;
}
```

---

## 14. 주석과 문서화 규칙

- 코드를 그대로 읽은 내용을 반복하지 말고, 작성 이유와 주의점을 설명한다.
- 초보자 교육용 프로젝트에서는 핵심 흐름을 이해할 수 있도록 한국어 주석을 작성한다.
- 일반 프로젝트에서는 복잡한 알고리즘, Unity 특유의 제약, 임시 우회 처리에만 주석을 작성한다.
- public API나 재사용 시스템에는 필요에 따라 XML 문서 주석을 사용한다.
- 의미 없는 `TODO`를 남기지 말고 작업 내용이나 조건을 구체적으로 적는다.
- 수정한 코드에 오래된 주석이 남지 않도록 함께 갱신한다.

```csharp
// Rigidbody의 보간 결과가 반영된 뒤 카메라를 이동해야 떨림이 줄어든다.
private void LateUpdate()
{
    FollowTarget();
}
```

---

## 15. 성능 규칙

- 먼저 올바르고 읽기 쉬운 코드를 작성한 뒤 실제 병목을 측정하여 최적화한다.
- `Update`, `FixedUpdate`, `LateUpdate`에서 불필요한 메모리 할당을 피한다.
- 반복 실행 구간에서 LINQ, 문자열 보간, 새 배열·리스트 생성 사용에 주의한다.
- 자주 생성하고 파괴하는 GameObject는 Object Pool 사용을 검토한다.
- 문자열 기반 `Invoke`, `SendMessage`, 코루틴 호출보다 타입 안전한 호출을 우선한다.
- 캐싱 때문에 상태가 오래되어 잘못된 값을 사용하지 않도록 갱신 시점을 명확히 한다.
- 최적화를 이유로 가독성과 정확성을 과도하게 희생하지 않는다.

---

## 16. 입력 처리 규칙

- 프로젝트가 사용하는 입력 방식인 Legacy Input 또는 Input System을 먼저 확인한다.
- 두 입력 시스템을 특별한 이유 없이 혼용하지 않는다.
- 입력 수집과 캐릭터 행동 로직을 가능한 한 분리한다.
- 입력 이벤트를 구독했다면 비활성화 시점에 반드시 해제한다.
- 모바일, 키보드·마우스, 게임패드 대응 여부를 요구사항에서 확인한다.

---

## 17. 물리 처리 규칙

- Rigidbody에 힘을 적용하거나 물리 위치를 바꾸는 작업은 `FixedUpdate`에서 수행한다.
- 일반 `transform` 이동과 동적 Rigidbody 이동을 무분별하게 섞지 않는다.
- 충돌이 필요한 오브젝트의 Collider, Rigidbody, Is Trigger, Layer를 함께 검토한다.
- LayerMask를 사용하여 불필요한 물리 검사를 줄인다.
- `Time.deltaTime`과 `Time.fixedDeltaTime`을 사용하는 위치를 구분한다.
- CharacterController와 Rigidbody 방식 중 프로젝트 구조에 맞는 하나를 선택한다.

---

## 18. 코루틴과 비동기 규칙

- 시간 기반 Unity 연출에는 Coroutine을 우선 검토한다.
- 파일, 네트워크, 인증 등 비동기 작업에는 프로젝트 환경에 맞는 `Task` 또는 패키지를 사용한다.
- `async void`는 Unity 이벤트 또는 UI 콜백처럼 불가피한 진입점 외에는 사용하지 않는다.
- 비동기 작업에는 취소, 오브젝트 파괴, 씬 전환, 예외 처리 방식을 함께 설계한다.
- `Task` 내부에서 Unity API를 백그라운드 스레드로 호출하지 않는다.
- 실행 중인 Coroutine을 중지해야 한다면 핸들을 저장하고 종료 시 정리한다.

---

## 19. 이벤트 규칙

- 이벤트 발행자는 구독자의 구체적인 구현을 알지 않도록 한다.
- 이벤트 이름은 발생한 사실 또는 상태 변화를 표현한다.
- 이벤트 구독과 해제를 한 쌍으로 관리한다.
- 익명 람다를 구독한 뒤 해제하지 못하는 구조를 피한다.
- 이벤트가 필요하지 않은 단순한 직접 호출까지 이벤트로 복잡하게 만들지 않는다.

```csharp
public event Action<int, int> HealthChanged;
public event Action Died;

private void OnEnable()
{
    _health.HealthChanged += OnHealthChanged;
}

private void OnDisable()
{
    _health.HealthChanged -= OnHealthChanged;
}
```

---

## 20. UI 코드 규칙

### 20.1. 기본 정책과 역할 분리

- **신규 런타임 UI는 UI Toolkit 중심**으로 작성한다. 단, 프로젝트의 Unity 버전·플랫폼·기능 요구사항에서 지원되는지 확인하며, 기존 uGUI·TMP 기반 UI를 별도 요청 없이 강제 전환하지 않는다.
- UI 레이아웃과 요소 구조는 UXML, 스타일은 USS, 상태 연결·사용자 입력 처리는 C#으로 분리한다. 씬에 직접 구성해야 하는 UI를 요청받았다면 실행 중 C#으로 전체 화면을 임의 생성해 대체하지 않는다.
- UI 표시와 게임 규칙 계산을 하나의 클래스에 모두 넣지 않는다. 화면 관리 클래스에는 `Panel`, `Popup`, `Window`, `View`, `Controller` 등 역할이 드러나는 접미사를 사용한다.
- UI Toolkit 코드에는 필요한 경우 `UnityEngine.UIElements`를 사용하고 `UIDocument`, `VisualElement`, `Button`, `Label`, `TextField`, `Toggle`, `ListView` 등 실제 프로젝트에 필요한 타입만 사용한다.
- `UIDocument`가 참조하는 UXML·Panel Settings와 USS는 `UNITY_ASSET_RULES.md`를 따른다. C#에서 에셋을 임의로 교체하거나 프로젝트 전체 패널 설정을 무단 변경하지 않는다.

### 20.2. 요소 조회 및 생명주기

- `UIDocument.rootVisualElement`에서 `Q<T>(...)` 등으로 기존 UXML 요소를 조회한다. 조회에 사용하는 `name` 및 USS class는 UXML의 실제 식별자와 일치시킨다. 필수 요소가 없으면 명확히 오류를 보고하고, 중복 요소를 임의 생성해 문제를 숨기지 않는다.
- `UIDocument`의 Visual Tree 준비 시점을 고려하여 `OnEnable()`에서 요소를 조회하고 이벤트를 등록하는 방식을 기본으로 한다. 비활성화·재활성화·씬 전환 등으로 Visual Tree가 재생성될 수 있으므로 오래된 `VisualElement` 참조를 재사용하지 않는다.
- `OnDisable()`에서 등록한 `Button.clicked` 이벤트를 해제하고, `RegisterCallback<TEventType>()`으로 등록한 콜백은 동일한 대상·델리게이트·이벤트 타입의 `UnregisterCallback<TEventType>()`으로 해제한다. 중복 구독과 익명 람다 해제 불가 상태를 피한다.
- `TextField`·`Toggle` 등 값 변경 이벤트는 필요에 따라 `ChangeEvent<T>` 또는 해당 Unity 버전의 지원 API를 사용한다. 초기 값 설정으로 불필요한 콜백을 발생시키지 않아야 한다면 `SetValueWithoutNotify` 지원 여부를 확인한다.
- 매 프레임 UI를 전체 갱신하지 않고 상태 변경 시 필요한 요소만 갱신한다. 대량 목록은 대상 버전의 `ListView` 가상화·재사용 기능을 검토한다.
- USS class의 추가·제거 또는 `style.display` 등 필요한 최소 변경으로 표시 상태를 제어하고, 공통 레이아웃·색상·폰트·스타일을 C# 코드에 중복 하드코딩하지 않는다.

### 20.3. 기존 UI와 한글 텍스트

- 기존 uGUI(Canvas)·TextMeshPro 화면을 유지보수하는 작업은 해당 시스템의 `UnityEngine.UI`, `TMP_Text`, `TMP_InputField`, `TMP_Dropdown` 등을 유지하며 참조·직렬화 데이터·동작을 보존한다. UI Toolkit 신규 UI에 TMP를 기본 의존성으로 강제하지 않는다.
- UI Toolkit은 적용 Unity 버전의 폰트 에셋·UITK Text Settings·fallback 지원을 확인하고, 한글과 특수문자·동적 텍스트에 필요한 글리프를 Editor 및 대상 빌드에서 검증한다. 기존 TMP Font Asset이나 한글 폰트는 실제 참조 여부를 확인하기 전까지 삭제·교체하지 않는다.
- UI Toolkit과 uGUI를 혼용하는 경우 이벤트 입력, 포커스, 화면 정렬, 표시 순서 및 화면 전환의 영향을 검토한다. 마이그레이션은 별도 요청과 호환성 검증을 거쳐 수행한다.

---

## 21. 데이터와 ScriptableObject 규칙

- 변하지 않는 설정값과 런타임 상태를 분리한다.
- 여러 오브젝트가 공유하는 설정 데이터에는 `ScriptableObject` 사용을 검토한다.
- ScriptableObject 원본 에셋에 런타임 상태를 직접 저장하지 않는다.
- 저장 데이터 클래스는 Unity 오브젝트 참조보다 직렬화 가능한 순수 데이터를 우선한다.
- JSON 저장 형식을 변경할 때 기존 저장 파일과의 호환성을 검토한다.

---

## 22. 로그 규칙

- 정상적인 매 프레임 로그를 남기지 않는다.
- 오류 로그에는 클래스, 문제 원인, 대상 오브젝트를 포함한다.
- 개발용 상세 로그는 조건부 컴파일이나 공통 로그 설정을 사용한다.
- 비밀번호, 인증 토큰, 개인정보를 로그에 출력하지 않는다.
- 사용자에게 필요한 오류와 개발자 진단용 오류를 구분한다.

---

## 23. 전처리기 지시문 규칙

- 플랫폼 전용 API는 올바른 플랫폼 조건으로 감싼다.
- Editor API가 빌드에 포함되지 않도록 `UNITY_EDITOR` 또는 Editor 전용 폴더를 사용한다.
- 전처리기 조건이 복잡해지면 플랫폼별 클래스로 분리할지 검토한다.

```csharp
#if UNITY_ANDROID && !UNITY_EDITOR
Handheld.Vibrate();
#endif
```

---

## 24. 코드 스타일과 서식

- 들여쓰기는 공백 4칸을 사용한다.
- 중괄호는 새 줄에 작성한다.
- 한 줄에 하나의 문장만 작성한다.
- 조건문과 반복문의 본문이 한 줄이어도 중괄호를 생략하지 않는다.
- 한 줄이 지나치게 길어지지 않도록 적절히 줄을 나눈다.
- 파일 전체의 불필요한 서식 변경을 피하고 수정한 범위 중심으로 정리한다.
- 코드 서식은 프로젝트의 `.editorconfig`를 따른다. 인코딩과 줄바꿈은 `FILE.md`의 **신규·수정 파일 목표 형식 및 예외**를 적용한다.

```csharp
if (_currentHealth <= 0)
{
    Die();
}
```

---

## 25. 인코딩과 줄바꿈 규칙

인코딩과 줄바꿈 정책의 기준 문서는 `FILE.md`이다.

- 신규 C#(`.cs`) 스크립트와 **실제로 내용을 수정하는 기존 C# 파일**은 **UTF-8 with BOM + LF(`\n`)**로 저장한다. 파일별 예외 및 도구의 필수 형식이 있는지 `FILE.md`에 따라 먼저 확인한다.
- 기존 `.cs`가 BOM 없는 UTF-8 또는 CRLF 등 목표와 다른 형식이면, **수정하는 그 파일만** UTF-8 with BOM + LF로 정규화한다. 읽기만 한 C# 파일이나 작업 범위 밖의 파일은 변환하지 않는다.
- Unity 또는 외부 도구가 생성·관리하는 파일은 생성 도구의 원래 형식과 연결 관계를 보존한다.
- `.editorconfig` 및 `.gitattributes`와 충돌하거나 원본 인코딩을 안전하게 읽을 수 없으면 무리하게 변환하지 않고 해당 파일의 사유를 보고한다. 목표 형식 적용 여부는 실제 바이트로 검증한다.
- 한글 주석·문자열이 저장 전후 손상되지 않았는지 확인한다. 변환으로 전체 줄이 Git diff에 나타나더라도 실제 코드 변경 범위와 형식 차이를 구별한다.
- **수정 파일의 정규화는 같은 기능 수정 작업·커밋에 포함할 수 있다.** 실제 수정하지 않은 파일까지 포함한 일괄 형식 변환만 별도 요청·별도 커밋으로 관리한다.

---
## 26. 안전한 수정 규칙

- 기존 public API, Inspector 연결, Prefab 참조를 임의로 깨뜨리지 않는다.
- 직렬화된 필드 이름을 변경해야 한다면 `[FormerlySerializedAs]` 사용을 검토한다.
- Assets 아래 스크립트의 생성·이동·삭제도 UNITY_ASSET_RULES.md를 적용하며 기존 `.meta`와 GUID를 보존한다.
- 씬·프리팹 변경은 UNITY_ASSET_RULES.md의 Editor 우선 및 최소 수정 원칙을 따른다. 코드 수정에 대량 텍스트 치환을 섞지 않는다.
- 패키지 추가·제거·업데이트는 요청 범위 또는 UNITY_TOOLING.md에서 허용한 도구 준비 범위에 한정한다.
- 임시 코드, 테스트용 치트, 사용하지 않는 백업 클래스를 결과물에 남기지 않는다.
- 비밀키와 서버 비밀번호를 코드에 하드코딩하지 않는다.

---

## 27. 테스트와 검증 규칙

코드 작성 후 다음 항목을 확인한다.

1. C# 컴파일 오류가 없는가?
2. Unity Console에 새 Error 또는 Exception이 발생하지 않는가?
3. 누락된 Inspector 참조가 없는가?
4. 이벤트가 중복 구독되거나 해제되지 않은 곳이 없는가?
5. 오브젝트 비활성화, 파괴, 씬 전환 시 문제가 없는가?
6. 정상 흐름뿐 아니라 실패, 취소, 빈 데이터, null 상황도 처리되는가?
7. `Update` 계열 메서드에서 불필요한 탐색이나 할당이 반복되지 않는가?
8. 기존 기능과 직렬화 데이터가 유지되는가?
9. 사용하는 API가 현재 Unity와 패키지 버전에서 지원되는가?
10. 빌드 대상 플랫폼에서도 사용할 수 있는 API인가?

검증할 수 없는 항목은 완료했다고 단정하지 않고, 확인하지 못한 이유와 Unity Editor에서 수행할 테스트 방법을 알려준다.

---

## 28. Codex 작업 결과 보고 규칙

Codex는 작업 완료 후 다음 내용을 간단히 정리한다.

- 생성하거나 수정한 파일
- 각 파일에서 변경한 핵심 내용
- 설계상 중요한 선택과 그 이유
- Unity Editor에서 사용자가 연결하거나 설정해야 하는 항목
- 실행한 검증과 그 결과
- 직접 확인하지 못한 항목과 확인 방법

코드를 작성하지 않았거나 검증하지 않은 내용을 완료했다고 표현하지 않는다.

---

## 29. 표준 MonoBehaviour 템플릿

다음 코드는 공통 구조 예시이며 프로젝트 요구에 맞게 필요한 부분만 사용한다.

```csharp
using UnityEngine;

namespace ProjectName.Feature
{
    [DisallowMultipleComponent]
    public sealed class ExampleController : MonoBehaviour
    {
        [Header("Settings")]
        [SerializeField, Min(0f)] private float _moveSpeed = 5f;

        [Header("References")]
        [SerializeField] private Rigidbody _rigidbody;

        public float MoveSpeed => _moveSpeed;

        private void Awake()
        {
            if (_rigidbody == null)
            {
                _rigidbody = GetComponent<Rigidbody>();
            }

            if (_rigidbody != null)
            {
                return;
            }

            Debug.LogError(
                $"[{nameof(ExampleController)}] Rigidbody를 찾을 수 없습니다. Object: {name}",
                this);
            enabled = false;
        }

        private void OnEnable()
        {
            SubscribeEvents();
        }

        private void OnDisable()
        {
            UnsubscribeEvents();
        }

        public void SetMoveSpeed(float moveSpeed)
        {
            _moveSpeed = Mathf.Max(0f, moveSpeed);
        }

        private void SubscribeEvents()
        {
        }

        private void UnsubscribeEvents()
        {
        }

#if UNITY_EDITOR
        private void OnValidate()
        {
            _moveSpeed = Mathf.Max(0f, _moveSpeed);
        }
#endif
    }
}
```

---

## 30. 최종 체크리스트

- [ ] Unity와 패키지 버전을 확인했다.
- [ ] 관련 Unity Skill과 기존 코드를 먼저 확인했다.
- [ ] 파일 이름과 클래스 이름이 일치한다.
- [ ] 프로젝트 네임스페이스와 명명 규칙을 따랐다.
- [ ] Inspector 필드는 `[SerializeField] private`을 우선 사용했다.
- [ ] Unity 생명주기 메서드의 역할을 구분했다.
- [ ] 이벤트 구독과 해제를 한 쌍으로 작성했다.
- [ ] UI 수정 시 UI Toolkit을 기본으로 검토하고, `UIDocument`·UXML 식별자·이벤트 생명주기 및 한글 텍스트 표시를 확인했다(해당하는 경우).
- [ ] 반복되는 컴포넌트 탐색과 메모리 할당을 피했다.
- [ ] null, 실패, 취소, 씬 전환 상황을 확인했다.
- [ ] 신규·수정 C# 파일은 UTF-8 with BOM + LF로 저장했다. 실제 수정한 기존 파일만 정규화하고, 미수정 파일과 Unity 관리 파일은 보존하며 한글 주석·문자열 손상 여부를 검증했다.
- [ ] 컴파일 및 Console 오류 여부를 확인했다.
- [ ] 변경 파일, 사용법, 검증 결과를 사용자에게 보고했다.

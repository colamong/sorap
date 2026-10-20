<p align="center">
  <img src="Screenshots/icon.png" width="128" alt="Sorap 아이콘">
</p>

<h1 align="center">Sorap · 서랍</h1>

<p align="center">
  복사한 것을 보드에 나눠 담고, 캡쳐한 글자는 바로 쓰는 macOS 메뉴바 클립보드 앱<br>
  macOS 14 이상 · 무료 · 오픈소스 · <a href="#english">English</a>
</p>

<p align="center">
  <img src="Screenshots/capture-demo.gif" width="640" alt="링크가 걸리지 않은 글자를 캡쳐하자 Sorap이 링크를 읽고 열지 묻는다">
</p>

<p align="center">클릭할 수 없는 링크도 캡쳐 한 번이면 열립니다.</p>

```sh
brew install --cask colamong/tap/sorap
```

## 기능

### 캡쳐한 글자 바로 쓰기

화면을 클립보드로 캡쳐하면(`⌃⇧⌘4`) Sorap이 이미지 속 글자를 읽고, 무엇을 할지 팝업으로 묻습니다.

| 캡쳐에 담긴 것 | 팝업 버튼 |
|---|---|
| 링크 | 링크 열기 · 링크 복사 |
| 실제로 있는 파일 경로 | Finder에서 보기 · 경로 복사 |
| 메일 주소 | 메일 쓰기 · 주소 복사 |
| 전화번호 | 전화 걸기 · 번호 복사 |
| 그 밖의 글자 | 글자 복사 |

QR 코드가 있으면 주변 글자보다 QR 내용을 먼저 씁니다. 링크가 여러 개면 팝업에서 하나를 고릅니다. 기록에 있던 이미지는 우클릭 메뉴에서 같은 동작을 고를 수 있습니다.

<details>
<summary>팝업 설정</summary>

- `다시 묻지 않기`를 고르면 그 종류는 이후 묻지 않고 바로 실행합니다.
- **설정 → 일반 → 캡쳐 이미지**에서 팝업을 끄거나, 종류별 기본 동작(열기/복사)을 바꾸거나, `다시 묻지 않기`를 초기화합니다.
- 기본 동작은 링크·경로가 열기, 메일 주소·전화번호가 복사입니다.

</details>

### 보드로 정리

맨 앞의 `기록`에는 복사한 내용이 쌓이고, 그다음 `즐겨찾기`와 직접 만든 보드가 이어집니다. 보드에 넣은 항목은 기록을 지워도 남습니다.

- **별표**를 누르면 `즐겨찾기`로 들어갑니다.
- **스니펫** — 보드 안의 `+ 새 항목`으로 자주 쓰는 글을 직접 써 둡니다.
- **이름 붙이기** — 우클릭으로 항목에 이름을 붙입니다. 검색은 원래 내용으로도 됩니다.
- **종류 필터** — 전체·텍스트·링크·파일·이미지. 이미지는 썸네일 격자로 봅니다.
- **자동 정리** — **설정 → 저장 → 보관 기간**에서 7·30·90일을 고르면 그보다 오래된 기록을 지웁니다. 고정·보드 항목은 남고, 기본값은 `계속`입니다.

<details>
<summary>지우기 규칙</summary>

- 아래쪽 버튼(`⌥⌘⌫`)은 보고 있는 화면에 따라 달라집니다. `기록`에서는 `기록 모두 지우기…`로, 보드에 담지 않은 항목만 지웁니다. 보드에서는 `“<이름>” 비우기…`로 그 보드를 비웁니다.
- `기록 모두 지우기`는 확인을 묻고, `다시 묻지 않기`를 고르면 이후 묻지 않습니다(설정에서 다시 켬). 보드 비우기는 항상 확인을 묻고 항목 수를 보여 줍니다.
- 항목 하나는 우클릭 → `삭제` 또는 `⌥⌫`로 지웁니다.

</details>

### 붙여넣기 도우미

| 기능 | 쓰는 법 |
|---|---|
| Markdown으로 복사 | 웹·문서에서 복사한 서식 있는 글 우클릭. 문단·목록·굵게·기울임·코드·링크를 옮김 |
| 경로 복사 | 복사한 파일 우클릭. 여러 개면 한 줄에 하나씩 |
| 터미널에 이미지 붙이기 | 터미널이 앞에 있을 때 이미지를 고르면 임시 PNG 경로가 붙음 |
| 이미지 저장 | 우클릭으로 저장하거나, 썸네일을 Finder로 끌어다 놓음 |

<details>
<summary>터미널 이미지 붙이기</summary>

Terminal·iTerm2·Ghostty·Warp·kitty·Alacritty·WezTerm·Hyper가 앞에 있을 때 동작합니다. 이미지를 파일 경로로 받는 CLI 도구에 캡쳐를 바로 넘길 수 있습니다. 같은 이미지는 같은 파일을 다시 쓰고, 1시간 동안 쓰지 않은 임시 파일은 지웁니다. 글자나 파일이 함께 담긴 항목은 원래대로 붙습니다.

</details>

## 스크린샷

<p align="center">
  <img src="Screenshots/history-light.png" width="400" alt="기록 화면 (라이트 모드)">
  <img src="Screenshots/history-dark.png" width="400" alt="기록 화면 (다크 모드)">
</p>
<p align="center">
  <img src="Screenshots/board-light.png" width="400" alt="SQL 보드">
  <img src="Screenshots/images-light.png" width="400" alt="이미지 필터의 썸네일 격자">
</p>

## 단축키

| 키 | 동작 |
|---|---|
| `⇧⌘C` | Sorap 열기 (설정에서 바꿀 수 있음) |
| `⌘1`–`⌘9` | 해당 번호의 항목 붙여넣기 |
| `⌥P` | 즐겨찾기에 넣기·빼기 (설정에서 바꿀 수 있음) |
| `⌥⌫` | 항목 삭제 (설정에서 바꿀 수 있음) |
| `⌥⌘⌫` | 기록 모두 지우기 / 보드 비우기 |
| `⌘Y` | 미리보기 (설정에서 바꿀 수 있음) |
| `Tab` · `⌥←` `⌥→` | 다음 보드 · 이전/다음 보드 |
| `⇧Tab` 또는 `⌘T` · `⇧⌘T` | 다음 종류 필터 · 이전 종류 필터 |
| `←` `→` · `↑` `↓` | 이미지 격자에서 한 칸 · 한 줄 이동 |
| `⌘,` | 설정 |

## 설치

```sh
brew install --cask colamong/tap/sorap
```

Homebrew를 권장합니다. Sorap은 Apple 공증을 받지 않은 앱인데, Homebrew로 설치하면 첫 실행 경고 없이 바로 열립니다. 업데이트는 앱 안에서도, `brew upgrade --cask sorap`으로도 받을 수 있습니다.

<details>
<summary>직접 내려받기</summary>

[GitHub 릴리스](https://github.com/colamong/sorap/releases)에서 최신 zip을 받아 압축을 풀고, `Sorap.app`을 `응용 프로그램` 폴더로 옮깁니다.

처음 열 때 "'서랍'을(를) 열지 않음" 창이 뜹니다. **휴지통으로 이동**을 누르면 앱이 지워지니 주의하세요.

1. 경고 창에서 **완료**를 누릅니다.
2. **시스템 설정 → 개인정보 보호 및 보안**을 엽니다.
3. 아래쪽 보안 항목에서 '서랍' 옆의 **그래도 열기**를 누릅니다.

</details>

<details>
<summary>메뉴 막대 아이콘이 안 보이거나 붙여넣기가 안 되면</summary>

- **아이콘**: macOS 26부터는 메뉴 막대 아이콘을 앱마다 허용합니다. **시스템 설정 → 메뉴 막대 → 메뉴 막대에서 허용**에서 **서랍**을 켜세요. 아이콘이 없어도 `⇧⌘C`로 열 수 있습니다.
- **붙여넣기**: 고른 항목을 쓰던 앱에 바로 붙이려면 Sorap이 `⌘V`를 대신 보내야 합니다. **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 Sorap을 켜 주세요. 권한이 없어도 복사는 됩니다.

</details>

## 언어와 데이터

- **언어** — 한국어, English, 日本語, 简体中文, 繁體中文, Español. Mac 언어와 따로 설정에서 고를 수 있습니다.
- **데이터** — 모든 내용은 이 Mac의 `~/Library/Containers/io.github.colamong.sorap`에만 저장됩니다.

## 후원

Sorap이 쓸모 있었다면 개발을 응원해 주세요. 메뉴의 `Sorap 정보` 창에도 같은 링크가 있습니다.

- **[카카오페이](https://qr.kakaopay.com/Ej8VWiQ4o)** — GitHub 계정 없이 바로 보낼 수 있습니다.
- **[GitHub Sponsors](https://github.com/sponsors/colamong)** — 매달 후원도 할 수 있습니다.

## 빌드

Xcode 26 이상이 필요합니다. `Maccy.xcodeproj`를 열고 `Maccy` 스킴을 실행합니다. 타깃 이름은 Maccy에서 물려받은 그대로이고, 만들어지는 앱은 `Sorap.app`입니다. 단위 테스트는 `scripts/test.sh`로 돌립니다.

## 감사의 말

Sorap은 Alex Rodionov의 [Maccy](https://github.com/p0deje/Maccy)를 포크해 만들었습니다. 클립보드를 지켜보고, 저장하고, 붙여넣는 부분은 Maccy의 코드입니다. 좋은 앱을 MIT 라이선스로 공개해 준 Maccy와 기여자들에게 감사드립니다.

## 라이선스

[MIT](LICENSE). Maccy의 저작권 표시와 Sorap의 저작권 표시가 함께 들어 있습니다.

---

## English

Sorap is a macOS menu-bar clipboard manager that keeps your copies in boards and acts on the text in your screenshots. On a Korean Mac it shows up as **서랍** ("drawer"). macOS 14 or later, free and open source.

```sh
brew install --cask colamong/tap/sorap
```

### Features

**Act on captured text.** Take a screenshot to the clipboard (`⌃⇧⌘4`) and Sorap reads the text in it and asks what to do.

| In the capture | Prompt buttons |
|---|---|
| A link | Open Link · Copy Link |
| A path that exists | Show in Finder · Copy Path |
| An email address | Write Email · Copy Address |
| A phone number | Call · Copy Number |
| Anything else | Copy Text |

A QR code wins over the text around it, and with several links you pick one. "Don't ask again" and the default action per kind live in **Settings → General → Captures**. Older images offer the same actions in the context menu.

**Organize with boards.** History collects your copies; Favorites and your own boards keep what matters, even when History is cleared. Star items into Favorites, write snippets with **+ New item**, name items (search still matches the original content), filter by kind (Text, Links, Files, Images — images show as a thumbnail grid), and let **Settings → Storage → Keep history** remove items older than 7, 30 or 90 days. Pinned and board items are never removed.

**Paste helpers.**

| Feature | How |
|---|---|
| Copy as Markdown | Right-click rich text; paragraphs, lists, bold, italic, code and links carry over |
| Copy Path | Right-click a copied file; several files go one per line |
| Images into terminals | Pick an image while a terminal is in front to paste the path of a temporary PNG |
| Save images | From the context menu, or drag a grid tile to Finder |

### Shortcuts

| Key | Action |
|---|---|
| `⇧⌘C` | Open Sorap (configurable) |
| `⌘1`–`⌘9` | Paste the item with that number |
| `⌥P` | Add to / remove from Favorites (configurable) |
| `⌥⌫` | Delete item (configurable) |
| `⌥⌘⌫` | Clear History / Empty board |
| `⌘Y` | Preview (configurable) |
| `Tab` · `⌥←` `⌥→` | Next board · previous/next board |
| `⇧Tab` or `⌘T` · `⇧⌘T` | Next kind filter · previous kind filter |
| `←` `→` · `↑` `↓` | Move one tile · one row in the image grid |
| `⌘,` | Settings |

### Install

Homebrew is recommended: Sorap is not notarized, and the cask clears the download quarantine flag so the app opens without a Gatekeeper warning. Updates arrive in the app or through `brew upgrade --cask sorap`.

<details>
<summary>Manual download, menu bar icon, Accessibility</summary>

- Download the latest zip from [GitHub Releases](https://github.com/colamong/sorap/releases) and move `Sorap.app` to Applications. On first launch click **Done** (not **Move to Trash**), then **System Settings → Privacy & Security → Open Anyway**.
- On macOS 26 and later, allow the icon in **System Settings → Menu Bar → Allow in the Menu Bar**. `⇧⌘C` opens Sorap either way.
- To paste straight into the app you were using, Sorap sends `⌘V` for you, which needs **Accessibility** permission. Copying works without it.

</details>

### Languages and data

Korean, English, Japanese, Simplified Chinese, Traditional Chinese and Spanish, selectable in Settings. Everything stays on your Mac in `~/Library/Containers/io.github.colamong.sorap`.

### Sponsor

If Sorap helps you, support it on [GitHub Sponsors](https://github.com/sponsors/colamong) — or, in Korea, with [KakaoPay](https://qr.kakaopay.com/Ej8VWiQ4o).

### Build, thanks, license

Requires Xcode 26 or later: open `Maccy.xcodeproj` and run the `Maccy` scheme (the product is `Sorap.app`); run tests with `scripts/test.sh`. Sorap is a fork of [Maccy](https://github.com/p0deje/Maccy) by Alex Rodionov, whose clipboard engine it keeps — thank you for releasing it under the MIT license. Licensed under [MIT](LICENSE), with both Maccy's and Sorap's copyright notices.

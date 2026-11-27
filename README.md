<div align="center">
  <img src="App/AppIcon.png" width="160" height="160" alt="Yahoo! KeyKey 2 應用程式圖示">
  <h1>Yahoo! KeyKey 2 — 倉頡調整版</h1>
  <p><strong>Yahoo! KeyKey 2 的分支：調整倉頡的選字，並改用範本模式圖示</strong></p>
</div>

本分支建立在 **Teddy Chan**
（[teddychan/yahoo-keykey-2-macos](https://github.com/teddychan/yahoo-keykey-2-macos)）先前的工作上：那是經典 **Yahoo! KeyKey（Yahoo!奇摩輸入法）** 的獨立、開放原始碼 Swift 重寫，把這套繁體中文輸入法帶回現代 macOS。應用程式本身、四種輸入法——**倉頡**、**速成**、**注音**（ㄅ半）與**拼音**——以及相關工具，功勞都屬於那個專案；該專案也註明了原始 Yahoo! KeyKey 與其資料來源，見 [CREDITS.md](CREDITS.md)。本分支從上游 **v2.20.1** 開始，只調整了 [這個分支改了什麼](#這個分支改了什麼) 裡說明的倉頡選字與顯示（其中有一項設定會一併影響倉頡以外的輸入法，該處有註明）。其餘行為與上游相同。

[![上游](https://img.shields.io/badge/上游-teddychan%2Fyahoo--keykey--2--macos-blue?style=flat-square)](https://github.com/teddychan/yahoo-keykey-2-macos)
![平台](https://img.shields.io/badge/平台-macOS-blue?style=flat-square)
![系統需求](https://img.shields.io/badge/系統需求-macOS%2026%2B-fa4e49?style=flat-square)
[![授權](https://img.shields.io/badge/授權-MIT-blue?style=flat-square)](LICENSE)

## 這個分支改了什麼

### 倉頡選字

只有**倉頡**改變；速成、注音和拼音的空白鍵仍與上游相同。

- **五代可以用 `戈土心` 打出「應」。** `igp` 加進 `Resources/cangjie.txt`。五代原本的 `戈人土心` 仍然有效，三代本來就有 `戈土心`。
- **空白鍵打開候選，而不是直接送出第一個字。** 一個碼有多個*完全符合*的字時——`大月` 有 有 和 冇——第一次按空白鍵只顯示清單，不會送出。接著 `1–9` 選字；再按一次空白鍵或 Return 接受第一個；其他可列印字元會先接受第一個，再照常處理（字母開始下一個碼，標點接在送出的字後面）。只有一個完全符合的字時，第一次按空白鍵仍然直接送出，就算開了**顯示字根開頭相同的字**也一樣。空白鍵之前再打的字根仍會加長這個碼。
- **空白鍵不再用來翻倉頡的候選頁。** 請用方向鍵或 Page Up／Page Down。速成和注音的空白鍵仍然翻頁。
- **候選順序預設固定。** **依選字習慣調整候選字順序** 現在預設關閉，所以用 `2` 選了冇，下次不會排到有的前面。這是全域設定，因此速成、注音、拼音和聯想字詞也維持內建順序。到 **設定… ▸ 一般** 打開，就恢復上游的學習；已經記下來的次數會保留，打開後再度使用。

這段邏輯在 `App/InputController.swift` 和 `App/KeyEventPolicy.swift`（`cangjieSpaceAction`、`isCandidateAcceptCharacter`），預設值在 `App/Preferences.swift`。細節和手動測試步驟見 [docs/handoff-cangjie-result-logic.md](docs/handoff-cangjie-result-logic.md)。

### 圖示

- **倉頡的模式圖示是範本圖示。** 它是一張灰階加透明的倉字（`App/CangjieGlyphTemplate.tiff`，由 `tools/render-cangjie-icons.swift` 繪製）。macOS 著色的方式和 ABC 的「A」、日文的「あ」一樣：淺色切換列是黑字，深色切換列是白字，藍色選取圓是白字，深色選單列也是白字。速成、注音和拼音仍用白底上的全彩紫色 Y（`App/YahooKeyKey.tiff`）。原因和 Info.plist 的鍵見 [docs/adr/0001-cangjie-mode-template-icon.md](docs/adr/0001-cangjie-mode-template-icon.md) 與 [docs/handoff-cangjie-icon.md](docs/handoff-cangjie-icon.md)。

  深色選單列上的白色倉，以及輸入選單裡的同一個字：

  ![深色選單列與輸入選單上的白色倉](docs/images/cangjie-menu-bar.png)

  游標旁的切換列裡，藍色選取圓上的白色倉，旁邊是 ABC 的 A 和日文的あ：

  ![內嵌切換列選取時，藍色圓圈上的白色倉](docs/images/cangjie-inline-switcher.png)

- **輸入法本身的圖示。** `App/Info.plist` 以 `YahooKeyKey.tiff` 作為輸入法自己的圖示（`tsInputMethodIconFileKey`）。
- **除錯版的模式名稱不加後綴。** `./tools/run-debug.sh` 仍會安裝另一個 `.debug` 輸入法，但模式名稱是倉頡／速成／注音／拼音，沒有「(Debug)」。
- `tools/make-icon.sh` 和 `tools/build-app.sh` 會產生並打包這個新字圖。

> [!IMPORTANT]
> 本分支不發布版本，也沒有自己的更新來源。上游的下載、Homebrew cask 和 **檢查更新…** 裝的都是**上游**版本，不含上面的改動；在本分支的建置裡檢查更新，會把它換成上游的版本。要用本分支，請 [從原始碼建置](#從原始碼建置)，再依 [安裝](#安裝) 的步驟裝上。

## 目錄

- [這個分支改了什麼](#這個分支改了什麼)
- [系統需求](#系統需求)
- [安裝](#安裝)
- [功能](#功能)
- [輸入法](#輸入法)
- [疑難排解](#疑難排解)
- [從原始碼建置](#從原始碼建置)
- [測試](#測試)
- [參與貢獻](#參與貢獻)
- [致謝](#致謝)
- [授權條款](#授權條款)

## 系統需求

- **macOS 26 Tahoe** 或更新版本
- **Apple 晶片** 的 Mac——沒有 Intel 版本
- 建置本分支需要 **Xcode 26 工具鏈**（見 [從原始碼建置](#從原始碼建置)）。本機建置是 ad-hoc 簽署，沒有經過公證。

## 安裝

> [!IMPORTANT]
> **安裝後請登出再登入。** macOS 只在登入時尋找新的輸入法——這是 KeyKey 裝好卻不能用時最常見的原因。

先建置輸入法，再複製到 `~/Library/Input Methods`。需要 Apple 晶片上的 **Xcode 26 工具鏈**。`./tools/build-lm.sh` 只需要跑一次：原始碼裡沒有 `Resources/data.txt`。

```sh
git clone https://github.com/machingclee/yahoo-keykey-2-macos-cangjie-adjusted.git
cd yahoo-keykey-2-macos-cangjie-adjusted
./tools/build-lm.sh
./tools/build-app.sh
mkdir -p ~/Library/Input\ Methods
cp -R build/YahooKeyKey2.app ~/Library/Input\ Methods/
```

1. **登出再登入。**
2. 加入輸入來源：**系統設定 ▸ 鍵盤**，在 **輸入來源** 旁按 **編輯…**（`+` 在那個視窗裡，不在設定頁本身），**+ ▸ 繁體中文** → **倉頡**、**速成**、**注音** 及／或 **拼音**。
3. 按 **⌃Space** 切到 Yahoo! KeyKey 2 開始打字。在**倉頡**裡，一個碼有好幾個字時，空白鍵會列出選擇（`1–9` 選字）；只有一個字時則直接送出。接著打別的字元會先接受第一個候選再繼續。方向鍵用來翻頁。
4. **可選：** 打開 **設定… ▸ 一般**，選 **為所有使用者安裝…**。輸入管理者密碼後，它會把自己移到 `/Library/Input Methods`，這樣其他應用程式（例如 1Password）開啟安全輸入時，輸入法仍可使用。見 [已知問題 #2](known_issues.md#2-倉頡-is-greyed-out-and-will-not-turn-on)。

若不想蓋掉已經安裝的正式版，在這個目錄執行 `./tools/run-debug.sh`。它會建置並安裝 `~/Library/Input Methods/Yahoo KeyKey 2 Debug.app`，然後啟動。這是另一個輸入法。若 **倉頡**、**速成**、**注音**、**拼音** 沒有出現，請登出再登入。模式名稱維持中文；應用程式名稱是 **Yahoo! KeyKey 2 Debug**。

沒有出現？見 [已知問題](known_issues.md#1-yahoo-keykey-2-does-not-show-up-after-installing)。

### 更新

在這個目錄重新建置，替換你當初安裝的那個資料夾裡的 app，然後登出再登入。不要用 **檢查更新…**（它跟著上游的 appcast，會裝上上游版本），也不要把本分支裝到上游 Homebrew cask 的位置上：兩者的 bundle id 相同。

### 解除安裝

1. **先移除輸入來源：** **系統設定 ▸ 鍵盤 ▸ 輸入來源**，選取 Yahoo! KeyKey 2 並移除。應用程式自己的解除安裝畫面無法代勞這一步。
2. **再移除應用程式。** 若裝的是上游的 Homebrew cask：`brew uninstall --cask teddychan/tap/yahoo-keykey-2`。否則，在 `~/Library/Input Methods` 的副本可打開 **設定… ▸ 解除安裝**，或把 `~/Library/Input Methods/YahooKeyKey2.app` 拖到垃圾桶。為所有使用者安裝的副本，請在 Finder 把 `/Library/Input Methods/YahooKeyKey2.app` 拖到垃圾桶，系統會要求管理者密碼。**解除安裝** 無法移除這種副本：它會在刪除任何東西之前停下來，並告訴你同樣的做法。
3. **登出再登入。**

**解除安裝** 也會清掉設定、學習資料和快取。若你是自己刪掉應用程式（為所有使用者安裝的副本只能這樣刪），還想一併清掉那些資料：

```sh
rm -rf ~/Library/Application\ Support/YahooKeyKey2
rm -f  ~/Library/Preferences/com.dragonapp.inputmethod.yahoo-keykey.plist
rm -rf ~/Library/Caches/com.dragonapp.inputmethod.yahoo-keykey
rm -rf ~/Library/HTTPStorages/com.dragonapp.inputmethod.yahoo-keykey
```

## 功能

- **四種輸入法** — 在輸入來源裡加入要用的，再用 ⌃Space 切換。每種怎麼打，見 [輸入法](#輸入法)。
  - **倉頡** — 傳統字根輸入法；想不起某個字根時可用 `*` 當萬用字元。
  - **速成** — 倉頡的簡快打法：只打一個字的首尾字根。
  - **注音** — 傳統注音，一次一個字（ㄅ半）。鍵盤有標準（大千）、倚天和許氏。**智慧選字** 可以打一整句，由語言模型選字；預設關閉，要自己打開。
  - **拼音** — 用不標聲調的拼音組出整個詞。
- **候選字預設留在原位** — 清單維持內建順序，選了某個字也不會重排。若希望選過的字往上排，到設定打開 **依選字習慣調整候選字順序**；四種輸入法和聯想字詞都受這項設定影響。
- **聯想字詞** — 送出一個字之後，KeyKey 建議常接在後面的詞，可用 `1–9` 或 `Shift + 1–9` 選。
- **繁轉簡與全形標點** — 兩者都可直接在輸入選單切換。
- **候選視窗跟著游標** — 不會被螢幕邊緣切掉。可用方向鍵或 Page Up／Page Down 翻頁（速成和注音的空白鍵也會翻頁），字級可自訂。
- **反查／拆碼提示** — 在候選字旁顯示倉頡碼，或拼音讀音。在注音裡可以順便查同一個字的倉頡怎麼打。
- **臨時英數** — 按住 **Shift** 再按一個字母，打出那一個英文字，不必切換輸入來源。
- **字根開頭相同的字** — 在設定打開 **顯示字根開頭相同的字** 後，倉頡或速成打「竹」也會出現「我」（竹手戈），就像打了 `竹*`。碼完全符合的字仍排在前面。
- **全形空白** — 在設定打開 **Shift + 空白鍵輸入全形空白** 後，四種輸入法裡 **Shift + Space** 都會打出全形空白（　）。
- **備份與還原** — 在 **設定…** 把設定存到一個資料夾，以後可以還原，換電腦時方便。
- **免費、開放原始碼** — MIT 授權。本分支的本機建置只做 ad-hoc 簽署、沒有公證；請不要用 **檢查更新…**，那會裝回上游版本。

> [!NOTE]
> Yahoo! KeyKey 2 與 Yahoo 沒有從屬或背書關係。它是獨立專案，為了向原來的作品致敬，並讓 KeyKey 式的打字體驗留在現代 macOS 上。

## 輸入法

Yahoo! KeyKey 2 會安裝**四種輸入法**。每一種在 **輸入來源**（繁體中文）裡都是獨立的一項，所以只加入要用的，再用 **⌃Space** 切換。

| 輸入法 | 怎麼打 | 自己的設定（設定… ▸ 輸入方式） |
|---|---|---|
| **倉頡** | 字母鍵打倉頡字根；`*` 是萬用字元 | **倉頡版本** — 五代或三代 |
| **速成** | 一個字的倉頡碼的首尾字根 | 跟著 **倉頡版本** |
| **注音** | 注音符號再加聲調，一次一個字（ㄅ半）；打開 **智慧選字** 時可打整句 | **注音鍵盤** — 大千、倚天或許氏 · **智慧選字**（預設關閉） |
| **拼音** | 不標聲調的拼音，一次組出整個詞 | — |

繁轉簡、全形標點、反查提示和 **依選字習慣調整候選字順序** 對四種輸入法都有效。

### 倉頡與速成

在 **設定… ▸ 輸入方式** 選擇拆字表。倉頡和速成一起使用，而且立刻生效。

| 模式 | 依據 | 候選順序 | 例子 |
|---|---|---|---|
| **五代倉頡**（預設） | ibus `cangjie5` | 語料頻率 | 面 `一田尸中`、鬼 `竹山戈` |
| **三代倉頡**（相容 Yahoo! KeyKey） | 原始 Yahoo! KeyKey 字碼表 | Yahoo 原本的順序 | 面 `一田卜中`、鬼 `竹戈` |

五代也接受用 `戈土心` 打應（五代原本的碼是 `戈人土心`，仍然有效）。三代本來就是 `戈土心`。

一個倉頡碼對到多個字時——`大月` 有 有 和 冇——第一次按空白鍵**打開候選清單並等候**。按 `1–9` 選字（冇按 `2`），或打任何其他字元：先送出有，再照常處理那個字元。字母開始下一個字，標點接在有的後面，再按一次空白鍵則直接接受有。Return 也接受有。只有一個符合的字時，空白鍵直接送出。清單維持內建順序：用 `2` 選了冇，不會把它排到最上面。若要那種學習，請在設定打開 **依選字習慣調整候選字順序**。

**五代** 是預設，所以現有使用者在自己改之前不受影響。兩種順序都是固定的；在倉頡／速成裡，字碼表的順序是同分時的先後，而不是學習層去改的分數。**依選字習慣調整候選字順序** 預設關閉，所以每份清單都維持上表的順序。打開之後，每一份候選清單按你在*那一份清單*裡送出各字的次數排序，次數相同時才用字碼表的順序。再關掉就只剩字碼表的順序——三代且關閉學習時，就是原始 Yahoo! KeyKey 的順序，沒有別的。次數按每一份候選清單分開計算，所以一個倉頡碼、一個倉頡萬用字元組合、一個速成碼各自學習；倉頡和速成對聯想字詞的學習則是共用的。拼音不在這套裡：它仍用自己的排序，而同一項設定也開關它的學習。

Yahoo! KeyKey 的*聯想詞*排序無法重現——那些資料從未開放——所以兩種模式的聯想都用 Yahoo! KeyKey 2 自己的順序。

### 注音

**ㄅ半** 的打法和過去一樣：一個音節一個字。打完注音符號，用聲調結束這個音節，候選視窗就會打開；若這個讀音只有一個字，則直接送出。`1–9` 選字，空白鍵和方向鍵翻頁。接著打下一個字的第一個符號時，畫面上的字會先送出，不必按 Enter 也能繼續。聯想字詞在每次送出之後出現，和倉頡、速成一樣。

| | |
|---|---|
| **一聲** | **空白鍵** — 唯一沒有專用鍵的聲調 |
| **其他聲調** | 大千 `6` ˊ · `3` ˇ · `4` ˋ · `7` ˙　·　倚天 `2` ˊ · `3` ˇ · `4` ˋ · `1` ˙　·　許氏 `d` ˊ · `f` ˇ · `j` ˋ · `s` ˙ |
| **選候選字** | `1–9`（該列沒有候選字時，數字鍵改打注音）· **Return** 取這一頁的第一個 · 空白鍵翻頁（只有一頁時則取第一個） |
| **改錯聲調** | **Backspace** 去掉聲調，留下注音符號 |
| **聯想字詞** | **Shift + 1–9**（單獨的數字鍵是打注音，不能同時拿來選字） |
| **，。** | 大千和倚天用 **Shift + `,`** 與 **Shift + `.`** — `,` 和 `.` 本身打的是 ㄝ 和 ㄡ。許氏這兩個鍵仍是標點 |

鍵盤在 **設定… ▸ 輸入方式 ▸ 注音鍵盤** 選擇，也可以在注音使用中直接從輸入選單選。**標準（大千）** 是預設：台灣鍵盤上印的排列，也是原始 Yahoo! KeyKey 附的那一套。**倚天** 把符號放在拼出它們的字母上。**許氏** 一個鍵上有兩個或三個符號，再依周圍的鍵決定是哪一個，見 [許氏](#許氏)。其他 26 鍵排列（倚天 26 鍵、IBM）沒有提供。

候選字來自原始 Yahoo! KeyKey ㄅ半字碼表（`bpmf-ext.cin`），沿用它自己的順序——一個讀音最常用的字排在前面，上面不再用字典重排。你選過的字會按讀音記住，和倉頡按碼學習的方式相同。

### 許氏

**許氏** 是 26 個英文字母的注音鍵盤：一個鍵代表好幾個符號（`m` 是 ㄇ 或 ㄢ，`j` 是 ㄐ、ㄓ 或四聲），實際符號由周圍的鍵決定。空白鍵是一聲；其他聲調是 `d` ˊ · `f` ˇ · `j` ˋ · `s` ˙。智慧選字關閉時（預設），它仍一次打一個字，和大千、倚天一樣是ㄅ半——`nef` 是 ㄋㄧˇ（你），`hwf` 是 ㄏㄠˇ（好）。這裡的數字鍵和標點鍵不是注音鍵，所以 `1–9` 直接選候選字，，和 。仍在 `,` 和 `.`。讀音規則移植自 McBopomofo 的許氏表（`Mandarin.h`／`Mandarin.cpp`，MIT）。

### 智慧選字

**智慧選字** 預設關閉，可在 設定… ▸ 一般，或注音使用中的輸入選單裡打開。打開後，聲調結束每個音節，因此可以打一整句——許氏上 `jen tem tem vej hnf hwf`（空白鍵是一聲）會成為今天天氣很好——再由語言模型選字。大千、倚天和許氏都可以。← → 一次移動一個字（游標下的字會加底線）。清單先給模型選的詞，再給該音節的每一個單字，然後是更長的詞，所以一個詞裡的單字可以單獨改（太長 → 太常）。`1–9` 換成另一個候選，空白鍵或 Return 送出整句。選過或接受過的字會被記住，下次排在前面。沒有聲調的音節仍顯示為注音。大千和倚天的數字鍵是注音鍵，所以那裡的候選要用方向鍵和空白鍵來選。關閉時，注音回到一次一個字的ㄅ半。

### 拼音

打不標聲調的拼音，拼音會組出整個詞；`'` 用來切開含糊的地方，所以 `xi'an` 是西安。方向鍵在音節之間移動，`1–9` 選游標所在音節的候選並移到下一個，空白鍵或 Return 送出整個詞。

## 疑難排解

常見問題和各自的原因集中在 **[known_issues.md](known_issues.md)**：

| 問題 | |
|---|---|
| 安裝後沒有出現 | [#1](known_issues.md#1-yahoo-keykey-2-does-not-show-up-after-installing) |
| 倉頡是灰色的，無法開啟 | [#2](known_issues.md#2-倉頡-is-greyed-out-and-will-not-turn-on) |
| 某個字的碼和你預期的不同 | [#3](known_issues.md#3-a-characters-code-is-not-what-i-expect) |
| 空白鍵在翻頁，而不是接受你打的碼 | [#4](known_issues.md#4-space-pages-instead-of-accepting-my-code) |
| 打數字卻插入一個詞 | [#5](known_issues.md#5-typing-a-number-inserts-a-word-instead) |
| 注音裡 `,` 和 `.` 打出 ㄝ 和 ㄡ | [#6](known_issues.md#6-in-注音-the-comma-and-period-keys-type-ㄝ-and-ㄡ) |
| 注音裡聲調鍵選了候選字 | [#7](known_issues.md#7-in-注音-my-tone-key-picks-a-candidate) |

該檔也列出 **[先前版本已修好的項目](known_issues.md#8-already-fixed-in-earlier-versions)**，回報問題前請先對一下版本。其他問題請 [開一個 issue](https://github.com/machingclee/yahoo-keykey-2-macos-cangjie-adjusted/issues)（若與本分支無關，可改到上游的 [問題追蹤](https://github.com/teddychan/yahoo-keykey-2-macos/issues)）。

## 從原始碼建置

沒有 Xcode 專案：應用程式由圍繞 `swiftc` 的 shell 腳本組裝，測試則是 SwiftPM 套件。需要 Apple 晶片上的 **Xcode 26 工具鏈**。

```sh
git clone https://github.com/machingclee/yahoo-keykey-2-macos-cangjie-adjusted.git
cd yahoo-keykey-2-macos-cangjie-adjusted
./tools/build-lm.sh    # 第一次才需要：把語言模型寫進 Resources/data.txt
./tools/build-app.sh   # 組裝並 ad-hoc 簽署，產出 build/YahooKeyKey2.app
mkdir -p ~/Library/Input\ Methods
cp -R build/YahooKeyKey2.app ~/Library/Input\ Methods/
```

登出再登入，然後依 [安裝](#安裝) 加入 **倉頡**、**速成**、**注音** 和 **拼音**。

實際試打時，`./tools/run-debug.sh` 會建置並安裝另一個 **Yahoo! KeyKey 2 Debug** 輸入法，bundle id 不同，因此不會和已安裝的正式版撞在一起。它顯示的是**目標版本**——正在開發、準備發布的那個版本——所以為 2.13.0 做的修正會建成 `v2.13.1 Debug`，改過的程式不會掛上已經發布的版號。見 [版本慣例](docs/RELEASE.md#versioning-convention)。有簽署的正式建置來自 `v*` 標籤上的 [`.github/workflows/release.yml`](.github/workflows/release.yml)，見 [docs/RELEASE.md](docs/RELEASE.md)。

## 測試

測試分成兩個 SwiftPM 套件。**KeyKeyEngine** 涵蓋倉頡和速成字碼表（五代與三代）、查碼與萬用字元、頻率排序與調適走訪、聯想字詞、注音鍵盤／組音／ㄅ半字碼表、拼音斷詞，以及繁轉簡。**KeyKeyApp** 涵蓋偏好設定、按鍵策略，以及四種模式的輸入引擎一致性。對 `main` 的每次 push 和 pull request，CI 都會跑這兩套。

[![測試](https://github.com/teddychan/yahoo-keykey-2-macos/actions/workflows/tests.yml/badge.svg)](https://github.com/teddychan/yahoo-keykey-2-macos/actions/workflows/tests.yml)

```bash
swift test --package-path Packages/KeyKeyEngine
swift test --package-path Packages/KeyKeyApp
```

| 項目 | 數值 |
|---|---|
| 測試案例 | 459 個通過（引擎 334、應用程式 125） |
| 行覆蓋率 | `KeyKeyEngine` 97.8%，`KeyKeyApp` 95.8% |
| 測量於 | v2.16.0、Swift 6.4 |

另有一個引擎測試（`RealPinyinWalkerTests`）在 `./tools/build-lm.sh` 尚未產生 `Resources/data.txt` 時會自己跳過。覆蓋率用 `--enable-code-coverage` 測量各套件自己的 `Sources/`，不含測試檔和內含的 DragonKit。

## 參與貢獻

歡迎在 [問題追蹤](https://github.com/machingclee/yahoo-keykey-2-macos-cangjie-adjusted/issues) 回報問題或開 pull request。開 pull request 之前，請先跑兩套測試（見 [從原始碼建置](#從原始碼建置)），並在 [CHANGELOG.md](CHANGELOG.md) 用白話加一則使用者看得到的變更。發布方式寫在 [docs/RELEASE.md](docs/RELEASE.md)。

## 致謝

Yahoo! KeyKey 2 是向原始的 **Yahoo! KeyKey（Yahoo!奇摩輸入法）** 致敬而做的。原始專案、資料來源和引擎的出處見 [CREDITS.md](CREDITS.md)，第三方授權全文見 [docs/THIRD-PARTY-NOTICES.md](docs/THIRD-PARTY-NOTICES.md)。

## 授權條款

Yahoo! KeyKey 2 以 [MIT 授權](LICENSE) 釋出。內含的第三方資料保留各自的寬鬆授權，見 [docs/THIRD-PARTY-NOTICES.md](docs/THIRD-PARTY-NOTICES.md)。

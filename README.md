# LEEEP iOS SDK

## 導入と更新

Xcode の **File → Add Package Dependencies…** で、次の公開URLを指定し、
`leeep-ios-sdk` をアプリのターゲットへ追加します。

```text
https://github.com/REGALITECH/leeep-ios-sdk.git
```

公開バージョンは [Releases](https://github.com/REGALITECH/leeep-ios-sdk/releases) を参照してください。
利用時のモジュール名は `LeeepIosSdk` です。

Dependency Rule によって、更新の対象になる範囲が変わります。`0.13.1` から導入する場合の例です。
この範囲は Dependabot の更新PRと、Xcode の **Update to Latest Package Versions** の両方に適用されます。

| Dependency Rule | 更新の対象 | 向いている使い方 |
| --- | --- | --- |
| Up to Next Major Version（Xcodeの既定） | `0.13.1` 以上 `1.0.0` 未満 | Dependabotの更新PRとアプリのCIで、マイナー更新も含めて確認してから取り込む |
| Up to Next Minor Version | `0.13.x` のパッチのみ | マイナー更新はReleaseの通知で把握し、範囲を変更して手動で取り込む |
| Exact Version | `0.13.1` のみ | 更新は常に手動で行う |

`0.x` のマイナー更新（例: `0.13.x` → `0.14.0`）にはAPI変更が含まれる場合があります。
更新時は [Releases](https://github.com/REGALITECH/leeep-ios-sdk/releases) で、現在のバージョンから採用するバージョンまでの各版の変更内容・更新時の対応を読み、アプリのビルド・表示・リンク遷移を確認してください。
リポジトリの `releases/` にあるファイルは公開前の原稿を含むため、ファイルがあるだけでは配布確認・GitHub Release 公開済みを意味しません。

手動で更新する場合は、Xcode の **File → Packages → Update to Latest Package Versions** を実行します。
範囲外のバージョン（Up to Next Minor Version での `0.14.0` など）を取り込む場合は、先に Dependency Rule の範囲を変更してください。

## 更新通知を受け取る

### Release の通知メール

次の設定をすると、GitHub Release が公開されたときに、変更内容と更新時の対応がメールで届きます。

1. このリポジトリ右上の **Watch → Custom → Releases → Apply** を選択します。
2. GitHub の[通知設定](https://github.com/settings/notifications)の **Watching** で、通知先（Notify me）に **Email** が含まれていることを確認します。
   **On GitHub** だけの場合は GitHub 上の通知だけになり、メールは届きません。
3. 同じ画面の **Default notifications email** が、受け取りたいメールアドレスになっていることを確認します。
   組織ごとに送信先を変えている場合は、**Custom routing** の設定も確認してください。

通知の届き方は各アカウントの設定に従います。タグの追加だけでは Release の通知にはなりません。

### Dependabot の更新PR

利用アプリで更新PRを受け取りたい場合は、そのアプリのリポジトリのデフォルトブランチに `.github/dependabot.yml` を設定します。
次はリポジトリ直下に Xcode プロジェクトがある場合の例です。

```yaml
version: 2
updates:
  - package-ecosystem: "swift"
    directory: "/"
    schedule:
      interval: "daily"
    allow:
      - dependency-name: "github.com/regalitech/leeep-ios-sdk"
```

`directory` は `.xcodeproj` または `Package.swift` があるディレクトリに合わせてください。
既存の Dependabot 設定があれば、その `updates` に統合し、同じ ecosystem/directory の設定を重複させないでください。既に他の依存も更新している場合、この `allow` で対象を SDK だけに絞らないよう既存の方針を維持してください。
この公開SDKの取得に、専用のPATやDependabot用の認証情報は不要です。

Xcode管理のプロジェクトでは `project.pbxproj` に加え、Xcodeで依存を解決した後の
`YourApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
（workspaceを使う場合は `.xcworkspace/xcshareddata/swiftpm/Package.resolved`）をコミットしてください。
GitHub.comのDependabotは、`Package.swift` のない `.xcodeproj` でもこれらを扱えます。
詳しくは [GitHub公式のXcode対応案内](https://github.blog/changelog/2026-03-31-dependabot-now-supports-xcode-projects-using-swiftpm-with-xcodeproj-manifests/)
を参照してください。

更新候補はSPMのバージョンタグから検出され、GitHub Releaseの公開とは別に処理されます。
更新PRになるバージョンは、依存の管理方法によって次のように決まります。

- Xcodeで管理するプロジェクト: `project.pbxproj` の Dependency Rule が尊重され、範囲内の最新版へ
  `Package.resolved` だけが更新されます。範囲外のバージョンは更新PRになりません。
  Up to Next Minor Version では `0.13.x` のパッチだけ、Up to Next Major Version では `1.0.0` 未満のマイナー更新も対象です。
  Exact Version では更新PRは作られず、ブランチ・コミット指定もバージョン更新の対象になりません。
- `Package.swift` で管理するプロジェクト: 必要に応じて `Package.swift` の指定も更新されます
  （`exact: "0.13.0"` が `exact: "0.13.1"` に書き換わることを確認しています）。

マイナー更新もDependabotで受け取る場合は、Up to Next Major Version を設定してください。
更新PRの本文には、GitHub Releaseが公開済みであればそのリリースノートが引用されます。
GitHub Release 未公開のタグが候補になる場合があり、PR の作成時期はチェックのスケジュールにも従います。
自動マージは設定せず、Release が公開されていることと変更内容を確認し、アプリのビルド・表示・リンク遷移を確かめてから更新してください。

参考: [GitHub の通知設定](https://docs.github.com/en/account-and-profile/managing-subscriptions-and-notifications-on-github/setting-up-notifications/configuring-notifications)、[Dependabot 設定](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference)。

## リリース担当者向け手順

SDK の配布と GitHub Release の公開手順は [RELEASING.md](RELEASING.md) にまとめています。

## ライセンス情報

SDK本体の利用条件は[LICENSE](LICENSE)、第三者ソフトウェアの情報は
[THIRD_PARTY_NOTICES.txt](THIRD_PARTY_NOTICES.txt)を参照してください。
両文書はXCFramework内の各`LeeepIosSdk.framework`にも同梱しています。

アプリのライセンス情報画面には両文書を手動で掲載できます。
LicensePlist等で自動抽出できない場合も、同じ文書を手動設定で取り込んでください。
SDKをSPMで追加するだけでは、ライセンス情報画面は生成されません。

実行時に読み込む場合は、`Bundle(for: LeeepTagViewUIKit.self)`から
`LICENSE`および`THIRD_PARTY_NOTICES.txt`を取得できます。

第三者通知にはWebViewで読み込むWeb配信分も含みます。

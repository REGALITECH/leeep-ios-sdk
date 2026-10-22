# LEEEP iOS SDK

## インストール・更新

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
取り込む前にリリースノートの移行手順を読み、アプリのビルド・表示・リンク遷移を確認してください。

手動で更新する場合は、Xcode の **File → Packages → Update to Latest Package Versions** を実行します。
範囲外のバージョン（Up to Next Minor Version での `0.14.0` など）を取り込む場合は、先に Dependency Rule の範囲を変更してください。

## 新しいバージョンの通知

### GitHub Release のメール通知

このリポジトリで **Watch → Custom → Releases → Apply** を選択します。
GitHub の **Settings → Notifications** で Watching の通知先に **Email** を含め、
送信先メールアドレスを確認してください。GitHub Release 公開時にGitHubから通知されます。
タグのpushだけではReleaseの通知にはなりません。

### お客様のアプリで Dependabot の更新PRを受け取る

お客様のGitHubリポジトリのデフォルトブランチへ `.github/dependabot.yml` を追加します。
以下はXcodeプロジェクトがリポジトリ直下にある例です。

```yaml
version: 2
updates:
  - package-ecosystem: "swift"
    directory: "/"
    schedule:
      interval: "daily"
```

`directory` は `.xcodeproj` または `Package.swift` があるディレクトリに合わせてください。
既に設定がある場合は、その `updates` に統合します。この例は同じSwiftプロジェクトの他の依存も更新対象です。
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
更新PRの確認とアプリのCIはお客様側で行います。PR作成だけで実機での動作確認が済むわけではありません。

## メンテナー向けリリース手順

1. 内部リポジトリでSDKをビルドして、このリポジトリのXCFrameworkを更新します。
2. `releases/x.y.z.md` にそのバージョンの変更点、必要な移行手順、対応するPRを記載し、
   バイナリ・ドキュメントと一緒にレビューして `main` にマージします。プレースホルダーだけのノートは公開しません。
   PRのCIで、そのPRのXCFrameworkを使った最小Simulatorアプリのビルドが成功していることを確認してからマージします。
3. リリース対象のコミットへ `x.y.z` 形式のタグを作り、pushします。
   `v` 接頭辞、先頭ゼロ、プレリリースの接尾辞は使いません。公開済みタグは移動・上書きしません。
   タグは1つずつpushします。一度に4つ以上のタグをpushするとGitHubがイベントを作らず、ワークフローが起動しません。
4. [Publish release](https://github.com/REGALITECH/leeep-ios-sdk/actions/workflows/release.yml) が
   公開タグをSPMで取得し、タグのSHA、実機・Simulator用Framework、Xcode 26.6での最小Simulatorアプリのビルドを確認します。
   全て成功した場合のみ、レビュー済みノートでGitHub Releaseを公開します。
5. Actionsの結果とReleaseを確認します。失敗時にはReleaseは公開されませんが、push済みタグ自体はSPMから取得可能です。
   必要に応じてノートやワークフローを修正し、同じタグを再検証します。バイナリを修正する場合は新しいバージョンを作成します。

タグpushの失敗した実行は再実行できます。過去のタグを後から告知する場合は、現在の `main` に対応する
`releases/x.y.z.md` をレビューして追加した上で、Actionsの **Run workflow** からブランチ `main` と対象のタグを指定します。
検証スクリプトとノートはその実行のコミットを使い、バイナリは指定タグのSHAに固定します。
すでに公開済みのReleaseは変更しません。既存のdraftも自動では編集・公開せず、確認を要求して停止します。
Latestには、公開済みの正式な `x.y.z` バージョンより新しいものだけを指定します。過去バージョンの後追い公開ではLatestを変更しません。

このワークフローや `scripts/publish-release.sh` を変更して `main` にマージした後は、Actionsの **Run workflow** から
ブランチ `main` と公開済みのタグ（例: `0.13.1`）を指定して実行します。
公開ジョブがSummaryに `Release x.y.z is already published; leaving it unchanged.` を出して成功すれば、
次のリリース前に公開までの経路が動くことを確認できます。既存のReleaseは変更されません。

PRでは、そのPRのheadコミットをSPMのrevision指定で取得し、タグと同じFramework確認とSimulatorアプリのビルドを行います。
あわせて、公開済みタグ `0.13.1` に対する取得・ビルド経路も検証します。PRからReleaseは公開しません。
`0.13.1` はワークフロー自体の回帰確認のために固定しており、リリースごとに更新する必要はありません。
検証に使うXcodeを変える場合は、`.github/workflows/release.yml` の `DEVELOPER_DIR` と、このREADMEのXcodeのバージョンの記述を変更します。
ランナーに入っているXcodeは [actions/runner-images](https://github.com/actions/runner-images) の macos-26 の一覧で確認できます。
ローカルで同じ検証だけを実行するには、Xcodeを選択した状態で次を実行します。
`--revision` はGitHubへpush済みのコミットが対象です。

```sh
scripts/validate-release.sh 0.13.1 /tmp/leeep-ios-release-validation
scripts/validate-release.sh --revision "$(git rev-parse HEAD)" /tmp/leeep-ios-revision-validation
```

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

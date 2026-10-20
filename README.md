# LEEEP iOS SDK

## インストール・更新

Xcode の **File → Add Package Dependencies…** で、次の公開URLを指定し、
`leeep-ios-sdk` をアプリのターゲットへ追加します。

```text
https://github.com/REGALITECH/leeep-ios-sdk.git
```

公開バージョンは [Releases](https://github.com/REGALITECH/leeep-ios-sdk/releases) を参照してください。
例えば `0.13.1` を導入する場合、Dependency Rule を **Up to Next Minor Version**、
開始バージョンを `0.13.1` とすると `0.13.x` が対象です。利用時のモジュール名は `LeeepIosSdk` です。

更新時はリリースノートを読み、Xcode の **File → Packages → Update to Latest Package Versions**
を実行して、アプリのビルド・表示・リンク遷移を確認します。
次のマイナーバージョン（例: `0.14.0`）を取り込む場合は、Dependency Rule の範囲も変更してください。
`0.x` の更新でもAPI変更が含まれる場合があります。

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

更新候補はSPMのバージョンタグから検出され、GitHub Releaseとは別に処理されます。
Xcodeプロジェクトでは設定済みのバージョン範囲が尊重されるため、Exact Versionや範囲外の新バージョンでは
更新PRが出ない場合があります。ブランチ・コミット固定もバージョン更新の対象にせず、適切なバージョン範囲を設定してください。
更新PRの確認とアプリのCIはお客様側で行います。PR作成だけで実機での動作確認が済むわけではありません。

## メンテナー向けリリース手順

1. 内部リポジトリでSDKをビルドして、このリポジトリのXCFrameworkを更新します。
2. `releases/x.y.z.md` にそのバージョンの変更点、必要な移行手順、対応するPRを記載し、
   バイナリ・ドキュメントと一緒にレビューして `main` にマージします。プレースホルダーだけのノートは公開しません。
3. リリース対象のコミットへ `x.y.z` 形式のタグを作り、pushします。
   `v` 接頭辞、先頭ゼロ、プレリリースの接尾辞は使いません。公開済みタグは移動・上書きしません。
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

PRでは、既存の公開タグ `0.13.1` に対して同じ取得・ビルド経路を検証します。PRからReleaseは公開しません。
これはワークフローの検証用であり、新しい未タグのバイナリの受入れを代替しません。
ローカルで同じ検証だけを実行するには、Xcodeを選択した状態で次を実行します。

```sh
scripts/validate-release.sh 0.13.1 /tmp/leeep-ios-release-validation
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

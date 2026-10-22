# リリース担当者向け手順

SDK 利用者向けの導入・更新方法は [README](README.md) を参照してください。

## 手順

1. 内部リポジトリでSDKをビルドして、このリポジトリのXCFrameworkを更新します。
2. `releases/x.y.z.md` にそのバージョンの変更内容、更新時の対応、対応するPRを記載し、
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
検証に使うXcodeを変える場合は、`.github/workflows/release.yml` の `DEVELOPER_DIR` と、このファイルのXcodeのバージョンの記述を変更します。
ランナーに入っているXcodeは [actions/runner-images](https://github.com/actions/runner-images) の macos-26 の一覧で確認できます。
ローカルで同じ検証だけを実行するには、Xcodeを選択した状態で次を実行します。
`--revision` はGitHubへpush済みのコミットが対象です。

```sh
scripts/validate-release.sh 0.13.1 /tmp/leeep-ios-release-validation
scripts/validate-release.sh --revision "$(git rev-parse HEAD)" /tmp/leeep-ios-revision-validation
```

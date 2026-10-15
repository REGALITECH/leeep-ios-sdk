# LEEEP iOS SDK

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

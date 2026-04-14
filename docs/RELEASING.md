---
summary: '共有のリリースガードレール（GitHub Releases + changelog hygiene）'
read_when:
  - リリース準備をする時、またはリリースノートを編集する時
---

# 共有リリースガードレール

- GitHub Release の title は必ず `<Project> <version>` 形式にし、バージョン番号だけにしない。
- Release body には、そのバージョン向けにキュレートした changelog bullet をそのまま順番通りに入れる。余計なメタ説明は足さない。
- downstream client が期待する配布物（zip / tarball / checksum / dSYM など）があるなら、すべて添付する。
- リポジトリ固有の release doc がある場合はそれに従う。無ければ、このガイドをそのスタック向けに適用し、必要なら repo-local のチェックリストを追加する。
- release を publish したら、GitHub 上で tag / assets / notes を確認してから告知する。ズレがあればすぐ直す（title 修正、asset 再アップロード、必要なら retag）。
- npm release は、ログイン済み前提でも publish 時に 6 桁 OTP が必要で失敗することがある。OTP / TOTP が 1Password にあるなら、`op` を優先する（`docs/npm-publish-with-1password.md` 参照）。

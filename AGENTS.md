# Judgement Game - Development & Release Guidelines

## Build Numbering, Git Tagging & Restoration

All builds in this project follow an explicit Git tagging standard to allow instant restoration to any past build.

### For Every Future Build (Build 4, Build 5, etc.):
1. **Xcode Project Version**:
   - Update `CURRENT_PROJECT_VERSION = <N>;` in `JudgementGame.xcodeproj/project.pbxproj` and `JudgementGame/JudgementGame.xcodeproj/project.pbxproj`.
   - Verify `CFBundleVersion` in `Info.plist` is `$(CURRENT_PROJECT_VERSION)`.
2. **Build Verification**:
   - Build cleanly before committing:
     ```bash
     xcodebuild -scheme "JudgementGame" -destination "generic/platform=iOS" build CODE_SIGNING_ALLOWED=NO
     ```
3. **Commit**:
   - Stage all files: `git add -A`
   - Commit message must specify build number: `git commit -m "Build <N>: <Summary of updates>"`
4. **Git Tag**:
   - Tag the commit:
     ```bash
     git tag -a build-<N> -m "Release Build <N>"
     ```
5. **Push to Remote**:
   - Always push both branch and tags:
     ```bash
     git push origin main
     git push origin --tags
     ```

### Restoring to Any Previous Build:
When requested to restore to a specific build (e.g. "restore to build 3"):
- Execute:
  ```bash
  git reset --hard build-<N>
  ```
- All source files, project configuration, and web assets will instantly revert to that exact tagged build.

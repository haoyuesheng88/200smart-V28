# 200smart-V28

This repository packages a portable Codex skill for Siemens S7-200 SMART / STEP 7-Micro/WIN SMART V2.8 on Windows.

The goal is simple:

- connect to an already-open 200SMART V2.8 session
- import an AWL or STL `OB1` file
- compile it
- read the output window
- detect LAD-visible invalid networks such as `无效程序段`

## Repository Layout

- `skills/s7-200smart/`
  - `SKILL.md` - the installed skill instructions
  - `agents/openai.yaml` - UI metadata
  - `assets/` - bundled example AWL
  - `references/` - case notes and troubleshooting
  - `scripts/` - reusable PowerShell automation helpers
- `scripts/install-skill.ps1` - install the skill into Codex on a new computer
- `scripts/smoke-test-skill.ps1` - structural validation for the packaged skill

## Verified Target

- Software: STEP 7-Micro/WIN SMART V2.8
- Process: `MWSmart`
- Typical import flow: right-click `MAIN (OB1)` -> `Import...`
- Typical compile result:

```text
MAIN (OB1)
块大小 = 902（字节），0 个错误
已编译的块，0 个错误，0 个警告
错误总计：0
```

## Install On Another Computer

Clone the repository:

```powershell
git clone https://github.com/haoyuesheng88/200smart-V28.git
cd 200smart-V28
```

Install the skill into Codex:

```powershell
.\scripts\install-skill.ps1
```

By default the installer copies the packaged skill to:

```text
%USERPROFILE%\.codex\skills\s7-200smart
```

If `%CODEX_HOME%` is set, it installs to:

```text
%CODEX_HOME%\skills\s7-200smart
```

## Validate The Package

Run the structural smoke test:

```powershell
.\scripts\smoke-test-skill.ps1
```

## Direct Script Usage

If you want to run the V2.8 automation directly without waiting for skill invocation:

```powershell
.\skills\s7-200smart\scripts\import_and_compile_200smart_v28.ps1 `
  -UseBundledBagPulse4 `
  -ScreenshotPath .\mwsmart_v28_result.png
```

Or import your own AWL:

```powershell
.\skills\s7-200smart\scripts\import_and_compile_200smart_v28.ps1 `
  -AwlPath C:\path\to\your\program.awl `
  -ScreenshotPath .\mwsmart_v28_result.png
```

## Notes

- The bundled bag pulse example is split into many small `NETWORK` blocks to keep the LAD view displayable.
- Zero compile errors alone are not enough. The automation also checks for visible invalid networks.
- The scripts are written for Windows PowerShell and a Chinese-language V2.8 desktop session.

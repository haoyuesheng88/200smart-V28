---
name: s7-200smart
description: Use when working with Siemens S7-200 SMART or STEP 7-Micro/WIN SMART V2.8 on Windows, especially to automate AWL or STL POU import into MAIN (OB1), compile the program, read the output window, and detect LAD-visible invalid networks. Trigger on requests mentioning 200smart, STEP 7-Micro/WIN SMART, V2.8, MWSmart, 自动输入, 导入, 编译, 验证, 无效程序段, 脉冲除尘, or 布袋除尘器.
---

# S7-200 SMART

Use this skill for STEP 7-Micro/WIN SMART V2.8 desktop automation on Windows.

Prefer attaching to an already-open `MWSmart` session instead of launching the software yourself.

## Workflow

1. Run [scripts/find_open_200smart_process.ps1](./scripts/find_open_200smart_process.ps1) to locate the visible V2.8 window.
2. If the user needs a ready-made case, use the bundled AWL in [assets/bag-pulse-dust-collector-4bags-ob1.awl](./assets/bag-pulse-dust-collector-4bags-ob1.awl).
3. If writing or editing AWL, keep it LAD-friendly:
   - wrap the logic in `ORGANIZATION_BLOCK OB1`
   - prefer ASCII text
   - keep one `NETWORK` to one rung or action
   - split independent `MOV`, `TON`, `S`, `R`, and output assignments into separate networks
4. For direct automation, use [scripts/import_and_compile_200smart_v28.ps1](./scripts/import_and_compile_200smart_v28.ps1).
5. Treat success as a combination of:
   - import output contains a success line
   - compile output contains zero errors
   - visible invalid network count is zero
6. Do not save or overwrite the `.smart` project unless the user explicitly asks.

## Bundled Case

Use the bundled four-bag pulse dust collector example when the user asks for a default working program.

- AWL: [assets/bag-pulse-dust-collector-4bags-ob1.awl](./assets/bag-pulse-dust-collector-4bags-ob1.awl)
- Address and parameter notes: [references/bag-pulse-dust-collector-4bags.md](./references/bag-pulse-dust-collector-4bags.md)

## Reusable Commands

Find the open V2.8 process:

```powershell
& "$PSScriptRoot\scripts\find_open_200smart_process.ps1"
```

Capture the current 200SMART window:

```powershell
& "$PSScriptRoot\scripts\capture_200smart_window.ps1" `
  -OutputPath ".\mwsmart_window.png"
```

Read the output window:

```powershell
& "$PSScriptRoot\scripts\read_200smart_output_window.ps1"
```

Import the bundled example and compile it:

```powershell
& "$PSScriptRoot\scripts\import_and_compile_200smart_v28.ps1" `
  -UseBundledBagPulse4 `
  -ScreenshotPath ".\mwsmart_v28_compile.png"
```

Import a custom AWL and compile it:

```powershell
& "$PSScriptRoot\scripts\import_and_compile_200smart_v28.ps1" `
  -AwlPath "C:\path\to\your.awl" `
  -ScreenshotPath ".\mwsmart_v28_compile.png"
```

## Important Rules

- The verified UI path for V2.8 is the legacy project-tree import flow, not the V3 ribbon flow.
- A compile summary of zero errors does not guarantee the LAD editor can display the networks cleanly.
- If the UI still shows `无效程序段`, split the AWL into smaller networks and reimport.
- `TITLE = ...` lines are risky for this environment; avoid them unless the user has already verified them locally.

## Read When Needed

- For the bundled example logic and addresses, read [references/bag-pulse-dust-collector-4bags.md](./references/bag-pulse-dust-collector-4bags.md).
- For common failure modes like save prompts, import dialog issues, and invalid networks, read [references/troubleshooting.md](./references/troubleshooting.md).

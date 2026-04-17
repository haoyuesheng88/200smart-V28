# Troubleshooting

## Compile says zero errors but LAD shows invalid networks

This is the most important V2.8 trap.

The compiler can accept a block while the LAD editor still cannot render one or more networks cleanly.

If the UI shows `无效程序段`:

1. split the AWL into smaller `NETWORK` blocks
2. keep one rung or action per network
3. separate independent `MOV`, `S`, `R`, timer, and output operations
4. reimport and check the LAD view again

## Import dialog does not appear

Common causes:

- the project window lost focus
- a save prompt is already open
- screen offsets no longer match the current UI layout

Check for a visible modal dialog first. If a save prompt is present and the user did not ask to save, choose `No` or cancel it before opening the import dialog again.

## Output window cannot be found

The V2.8 helper scripts read the output listbox by UIAutomation id `20260`.

If the output window is closed or docked differently, reopen or show the output pane and retry.

## Import succeeds but behavior is wrong

Check the bundled case assumptions:

- `VB100` must stay in `1..4`
- `VW102`, `VW104`, and `VW106` must be positive
- `VB108` must point to a valid bag for manual pulse
- input mapping is `I0.0..I0.7` to `V0.0..V0.7`

## TITLE lines break import

In the verified V2.8 environment, `TITLE = ...` network title lines caused import problems. Avoid them unless the local installation already accepts them.

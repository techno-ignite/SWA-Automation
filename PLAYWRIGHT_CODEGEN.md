Playwright Codegen — quick guide

This project already includes Playwright and the browser binaries.

Use the Playwright codegen tool to record actions and generate test code.

Common commands (run from the project root):

PowerShell / Terminal:

  # Open the interactive recorder (opens a browser and logs actions)
  npx playwright codegen

  # Save auth storage while recording (writes to playwright/.auth.json)
  npx playwright codegen --save-storage=playwright/.auth.json https://example.com

  # Run codegen with a specific device preset (Desktop Chrome)
  npx playwright codegen --device="Desktop Chrome"

NPM script shortcuts (available via `npm run <script>`):

  npm run codegen        # starts recorder
  npm run codegen:save   # record and save auth storage to playwright/.auth.json
  npm run codegen:auth   # example: record on https://example.com and save auth
  npm run codegen:chrome # open recorder with Desktop Chrome device

Notes:
- The recorder will show generated code in the right-hand panel; you can copy it into your test files.
- `--save-storage` writes a JSON file that you can reuse in tests to pre-authenticate sessions.
- The codegen CLI is included in the `playwright` package; there is no separate installation step.

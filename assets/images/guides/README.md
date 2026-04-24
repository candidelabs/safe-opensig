# Guide screenshots

Annotated PNG screenshots used by the Manual Input guide sheets.

Each screenshot is captured from the current live `app.safe.global` (and, for
calldata, the MetaMask signing popup). Screenshots are annotated with a red
circle or arrow on the exact element the step references, then saved here.

Filenames used by the guide sheets:

- `guide_json_1_create.png` — the "Create new transaction" screen in app.safe.global (e.g., the send form or contract-interaction form).
- `guide_json_2_confirm.png` — the confirmation step between creating the transaction and the Review details screen.
- `guide_json_3_review.png` — the Review details screen with the JSON tab selected and the copy affordance visible.
- `guide_calldata_1_execute.png` — Review details screen with the Execute button highlighted (before signing with the wallet).
- `guide_calldata_2_copy_data.png` — the signer wallet popup showing the Data (hex) field with the copy action visible.

Until these files exist, the guide sheets render a placeholder box with the
filename — this keeps the layout testable without blocking on the content
capture task.

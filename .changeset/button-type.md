---
"witify-skills": minor
---

`frontend-development`: every button gets an explicit `type`. A button with no `type` inside a form submits it on click, so anything that is not the form's submit now gets `type="button"`. `sprintify-ui` now notes that `BaseButton`'s `type` defaults to `"submit"`.

---
"witify-skills": patch
---

`sprintify-ui` now documents BaseSelect's built-in empty option and the `<option :value="null">` trap: Vue strips the `value` attribute for null bindings, so the option's text content becomes its submitted value and backend validation rejects it. The fix is labeling the built-in empty option via the `placeholder` prop.

---
name: authorization-stays-quiet
description: A login/session problem is out of the authorization skill's scope and must not load it.
tags: [no-trigger, sprintify]
allowed_tools: [Read, Glob, Grep, Skill]
expected_outcome: No sprintify skill is invoked; the answer deals with sessions and cookies only.
---
Users of our Laravel app get logged out every time they switch browser tab, even though "remember me" is checked. Sessions are stored in Redis and SESSION_LIFETIME is 120. Where should I look?

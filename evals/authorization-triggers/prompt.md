---
name: authorization-triggers
description: A nested-resource permission bug in a sprintify-derived Laravel app should load the authorization skill.
tags: [trigger, sprintify]
allowed_tools: [Read, Glob, Grep, Skill]
expected_outcome: The authorization skill is invoked before any answer about policies.
---
In our Laravel app, a project manager can open /projects/42/comments and see the tab, but when they click "Resolve" on a comment they get a 403. The CommentPolicy has a resolve() method and the ProjectPolicy has view(). The controller is nested under projects. What's wrong with the authorization and how should it be structured?

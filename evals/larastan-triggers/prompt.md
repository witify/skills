---
name: larastan-triggers
description: A PHPStan error about relationship generics should load the larastan skill.
tags: [trigger, sprintify]
allowed_tools: [Read, Glob, Grep, Skill]
expected_outcome: The larastan skill is invoked before proposing a PHPDoc fix.
---
PHPStan level 8 fails on our Laravel model with:

```
Method App\Models\Invoice::lines() return type with generic class Illuminate\Database\Eloquent\Relations\HasMany does not specify its types: TRelatedModel, TDeclaringModel
```

How do I annotate the relation, and what's the pattern for the rest of our models?

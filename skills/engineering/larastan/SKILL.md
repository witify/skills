---
name: larastan
description: PHPStan/Larastan static analysis patterns for Laravel models, relationships, generics, custom builders, factories, and collections. Activates when fixing PHPStan errors, adding type annotations, or working with generic PHPDoc tags.
---

# Larastan

## Applicability (check first)

- If the project ships its own `.ai/skills/larastan/`, defer to that copy.
- **Read `phpstan.neon` first** — level, baseline, and custom rules vary by project age. Current sprintify runs level 6 with custom rules (`ModelLocationRule`, `NoFacadeAliasRule`, `NoRequestAllRule`, `NoCascadeOnDeleteRule`, plus audit rules); older forks run lower levels with none. Fix to the project's configured level, not this skill's examples.
- The `HasBuilder` / `HasCollection` traits require **Laravel 11+**. On older projects, keep `newEloquentBuilder()` / `newCollection()` overrides — don't migrate.

## When to Activate

- Activate when fixing PHPStan or Larastan errors.
- Activate when adding or correcting `@return`, `@var`, `@param`, `@extends`, `@use`, or `@template` PHPDoc tags.
- Activate when working with generic type annotations on models, builders, factories, collections, or relationships.
- Activate when the user mentions PHPStan, Larastan, static analysis, or type-level errors.

## Scope

- In scope: PHPDoc generics for relationships, factories, builders, collections, Attribute accessors; fixing PHPStan errors; understanding Larastan-specific rules.
- Out of scope: runtime bugs, general Laravel patterns unrelated to static analysis.

## Project Configuration

- Config: `phpstan.neon` — read it for the level, includes, and baseline (`phpstan-baseline.neon`).
- Custom rules, when present, live in `src/Support/PHPStan/Rules/` (or `phpstan/Rules/`).

## Generics Cheat Sheet

### Model Relationships

Return types must include the related model and `$this`:

```php
/** @return BelongsTo<User, $this> */
public function user(): BelongsTo

/** @return HasMany<Post, $this> */
public function posts(): HasMany

/** @return BelongsToMany<Role, $this, RoleUser> */
public function roles(): BelongsToMany

/** @return MorphMany<Comment, $this> */
public function comments(): MorphMany

/** @return MorphTo<Model, $this> */
public function model(): MorphTo
```

### Factories (`HasFactory`)

```php
/** @use HasFactory<UserFactory> */
use HasFactory;
```

### Custom Eloquent Builders

QueryBuilders live in `src/Domain/*/QueryBuilders/` and extend `Support\QueryBuilder\BaseQueryBuilder`:

```php
/**
 * @template TModel of \Illuminate\Database\Eloquent\Model
 *
 * @extends BaseQueryBuilder<Invoice>
 */
class InvoiceQueryBuilder extends BaseQueryBuilder { }
```

**Preferred on Laravel 11+ (`HasBuilder` trait):**

```php
use Illuminate\Database\Eloquent\HasBuilder;

/** @use HasBuilder<WorkOrderQueryBuilder> */
use HasBuilder;

protected static string $builder = WorkOrderQueryBuilder::class;
```

**Legacy (`newEloquentBuilder` override) — on Laravel 11+, migrate to `HasBuilder` when touching a model; on older projects, keep it:**

```php
public function newEloquentBuilder($query): InvoiceQueryBuilder
{
    return new InvoiceQueryBuilder($query);
}
```

#### Migration path: `newEloquentBuilder` → `HasBuilder` (Laravel 11+)

1. Import `use Illuminate\Database\Eloquent\HasBuilder;`
2. Add the trait with its generic: `/** @use HasBuilder<XQueryBuilder> */ use HasBuilder;`
3. Add `protected static string $builder = XQueryBuilder::class;`
4. Remove the `newEloquentBuilder()` method

#### Scope methods in QueryBuilders

All scope/filter methods on custom QueryBuilders must follow these rules:

1. **Return `static`, not `self`** — ensures correct type for subclasses.
2. **Add `/** @return $this \*/`\*\* — tells PHPStan the return is the exact same instance, enabling proper fluent chaining.
3. **Separate query modification from return** — do NOT chain query calls into `return`. Modify `$this`, then `return $this` on its own line.

```php
// CORRECT
/** @return $this */
public function active(): static
{
    $this->where('active', true);

    return $this;
}

// WRONG — chaining into return
/** @return $this */
public function active(): static
{
    return $this->where('active', true);
}

// WRONG — using self
public function active(): self
{
    $this->where('active', true);

    return $this;
}
```

### Custom Collections

```php
/** @extends Collection<array-key, User> */
final class UserCollection extends Collection { }

// In the model (Laravel 11+ HasCollection trait):
/** @use HasCollection<UserCollection> */
use HasCollection;

// Or via newCollection() override (required pre-11):
/** @param array<array-key, Model> $models
 *  @return UserCollection<int, static> */
public function newCollection(array $models = []): UserCollection
```

### Attribute Accessors

Annotate with `Attribute<GetType, SetType>`. Use `never` for read-only:

```php
/** @return Attribute<string[], string[]> */
protected function scopes(): Attribute

/** @return Attribute<bool, never> */
protected function isActive(): Attribute
```

## Common Pitfalls

### Collection/array generics

Use `array<key-type, value-type>` for arrays and `Collection<key-type, value-type>` for collections. Avoid untyped arrays:

```php
/** @param array<int, string> $ids */
/** @return Collection<int, User> */
```

### @var on inline variables

Use `@var` for local variables only when PHPStan cannot infer the type. Prefer `@return` on the called method instead.

### `whereHas()` callback builder type narrowing

`whereHas` callback params are often inferred as `Builder<Model>`.
Do not use `@var Builder<SpecificModel>` (invariant generic; causes `varTag.nativeType`).

Need custom query-builder methods?

- Keep callback param type as `EloquentBuilder`.
- Narrow with `instanceof` to your custom builder.
- For soft-delete macros on custom builders, document them on the custom builder class. Real custom methods work too:

```php
/**
 * @method $this withTrashed(bool $withTrashed = true)
 * @method $this onlyTrashed()
 * @method $this withoutTrashed()
 */
class ProductionTaskQueryBuilder extends BaseQueryBuilder
{
    /** @return $this */
    public function forWorkOrder(int $workOrderId): static
    {
        $this->where('work_order_id', $workOrderId);

        return $this;
    }
}
```

Then use the narrowed type:

```php
use Domain\Manufacturing\QueryBuilders\ProductionTaskQueryBuilder;
use Illuminate\Database\Eloquent\Builder as EloquentBuilder;

->whereHas('productionTask', function (EloquentBuilder $query): void {
    if (! $query instanceof ProductionTaskQueryBuilder) {
        throw new \LogicException('Expected ProductionTaskQueryBuilder.');
    }

    $query->withTrashed()->forWorkOrder($this->workOrder->id);
});
```

## Running PHPStan

```bash
./vendor/bin/phpstan
```

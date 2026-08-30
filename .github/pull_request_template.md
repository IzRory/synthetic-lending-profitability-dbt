## Scope

Describe the business change and affected dbt layers.

## Model grains

List each changed model and its grain.

## Validation

- [ ] Synthetic generator completed with the fixed seed
- [ ] Sensitive-term validation passed
- [ ] SQLFluff passed
- [ ] `dbt build --target ci --fail-fast` passed
- [ ] dbt documentation was generated and inspected

## Expected impact

Describe row-count, schema, calculation, or documentation changes.

## Evidence

Add relevant output or screenshots when the change affects a final mart or CI behavior.


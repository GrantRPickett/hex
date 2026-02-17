## 1. Preparation
- [ ] 1.1 Configure logging in `json_to_tres.py`
- [ ] 1.2 Define new `level-generation` specification

## 2. Refactor Output Structure
- [ ] 2.1 Modify `convert_json_to_tres` to use a flat output directory
- [ ] 2.2 Update all resource generator functions to respect the flattened path

## 3. Implement Graceful Error Handling
- [ ] 3.1 Wrap key generation logic in try/except blocks
- [ ] 3.2 Add validation checks for required JSON keys

## 4. Implement Idempotency
- [ ] 4.1 Ensure existing files are overwritten only when necessary or correctly replaced
- [ ] 4.2 Verify script can rerun without side effects

## 5. Validation
- [ ] 5.1 Run conversion on `sample_level.json`
- [ ] 5.2 Verify flattened directory structure
- [ ] 5.3 Verify log output for successful and partial conversions

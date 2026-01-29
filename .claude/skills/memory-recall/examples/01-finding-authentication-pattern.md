# Memory Recall Example: Finding Authentication Pattern

## Scenario
Starting new client project that needs user authentication. Want to recall proven authentication patterns to avoid reinventing the wheel.

## User Input
```
/recall authentication
```

## Execution

### Step 1: Parse Query
- **Keywords**: "authentication"
- **Inferred intent**: Find authentication patterns/solutions
- **Search domains**: dev-patterns, client-patterns (likely tech-related)

### Step 2-4: Search Memory (Parallel)

**Semantic Memory Search**:
```bash
Grep(
  pattern="authentication",
  path="memory/semantic/patterns/",
  output_mode="content"
)
```

**Results**:
- `dev-patterns.md`: JWT Authentication (HIGH confidence, 5 examples)
- `dev-patterns.md`: OAuth 2.0 Integration (MEDIUM confidence, 3 examples)
- `client-patterns.md`: Session Management (MEDIUM confidence, 3 examples)

**Episodic Memory Search**:
```bash
Grep(
  pattern="authentication",
  path="memory/episodic/",
  output_mode="content"
)
```

**Results**:
- `2025-01-work-log.md`: "Implemented JWT auth for Client A (Jan 7)"
- `2025-01-work-log.md`: "Debugged OAuth flow for Client B (Jan 5)"

**Procedural Memory Search**:
```bash
Grep(
  pattern="authentication",
  path="memory/procedural/",
  output_mode="content"
)
```

**Results**:
- `dev-setup.md`: "Auth Testing Checklist"

### Step 5: Rank Results
1. JWT Authentication (HIGH confidence, 5 examples) → Score: 95
2. OAuth 2.0 Integration (MEDIUM, 3 examples) → Score: 65
3. Session Management (MEDIUM, 3 examples) → Score: 63
4. Recent experience: "JWT auth for Client A" → Score: 60

### Step 6: Format Output

```markdown
🔍 Memory Recall: "authentication"

📚 SEMANTIC MEMORY (Proven Patterns)

1. **JWT Authentication** ⭐ HIGH CONFIDENCE
   - **Confidence**: HIGH (5 examples, proven reliable)
   - **Time saved**: 4-6 hours (vs building from scratch)
   - **When to use**: API authentication, stateless auth
   - **Pattern**: Issue JWT on login, verify on each request
   - **Gotchas**: Token expiration handling, refresh tokens

   📖 Full details: `Read memory/semantic/patterns/dev-patterns.md` (line 45)

2. **OAuth 2.0 Integration** ⭐ MEDIUM
   - **Confidence**: MEDIUM (3 examples)
   - **When to use**: Third-party login (Google, GitHub)
   - **Time saved**: 3-4 hours

   📖 Full details: `Read memory/semantic/patterns/dev-patterns.md` (line 112)

3. **Session Management** ⭐ MEDIUM
   - **Confidence**: MEDIUM (3 examples)
   - **When to use**: Traditional web apps, server-side sessions

   📖 Full details: `Read memory/semantic/patterns/client-patterns.md` (line 78)

📝 EPISODIC MEMORY (Past Experiences)

1. **Client A - JWT Implementation** (Jan 7, 2025)
   - Context: E-commerce dashboard needed secure API
   - Solution: JWT with refresh tokens
   - Outcome: 2 hours to implement (vs 6 hours first time)
   - Pattern applied: "JWT Authentication" (HIGH)

   📖 Full experience: `Read memory/episodic/2025-01-work-log.md` (line 234)

2. **Client B - OAuth Debugging** (Jan 5, 2025)
   - Context: Social login integration issues
   - Solution: Fixed redirect URI configuration
   - Lesson: Always whitelist exact URLs, wildcards don't work

   📖 Full experience: `Read memory/episodic/2025-01-work-log.md` (line 189)

🔧 PROCEDURAL MEMORY (How-To Guides)

1. **Auth Testing Checklist**
   - 12-step testing process for auth flows
   - Covers: login, logout, token refresh, expiration

   📖 Full checklist: `Read memory/procedural/dev-setup.md` (line 56)

🌐 KNOWLEDGE GRAPH

**Authentication** connects to:
- API Design (used in 4/5 JWT examples)
- Error Handling (auth failures need clear messages)
- Database Schema (user tables, token storage)

**Pattern Evolution**:
```
Session Management (2023)
  ↓ learned limitations
JWT Authentication (2024)
  ↓ client requested social login
OAuth Integration (2024)
```

💡 RECOMMENDATION

For your new client project:
✅ **Use JWT Authentication** (HIGH confidence)
- Proven reliable (5 successful implementations)
- Fast setup (2 hours vs 6 hours from scratch)
- Stateless (scales well for APIs)

Next steps:
1. Read full JWT pattern: `memory/semantic/patterns/dev-patterns.md:45`
2. Review Client A implementation: `memory/episodic/2025-01-work-log.md:234`
3. Run auth testing checklist: `memory/procedural/dev-setup.md:56`
```

## Outcome
- **Time**: 3 seconds search + display
- **Result**: Found 3 relevant patterns, 2 experiences, 1 procedure
- **Next action**: User reads JWT pattern details and implements solution
- **Time saved**: ~4 hours (proven solution vs trial-and-error)

## Pattern Confidence After This Recall
- JWT Authentication: HIGH (5 examples) → Applied in new project → Will become 6 examples
- This recall proves the system works: compound knowledge in action

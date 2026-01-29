# Idea Capture - Categorization Logic

Rules for automatic category and priority detection.

## Category Keywords

### Product (Features, UI, UX)
**Keywords**: feature, product, user, ui, ux, dashboard, design, interface, experience, screen

**Example ideas**:
- "Add export feature to dashboard"
- "Improve user onboarding flow"
- "Design new settings page"

### Content (Blog, Video, Social)
**Keywords**: blog, post, article, video, social, tweet, linkedin, content, newsletter, podcast

**Example ideas**:
- "Write blog post about AI patterns"
- "Create video tutorial for authentication"
- "LinkedIn post about client success story"

### Business (Strategy, Revenue, Pricing)
**Keywords**: pricing, business model, revenue, strategy, sales, marketing, growth, partnership, monetization

**Example ideas**:
- "New pricing tier for enterprise"
- "Partnership with Company X"
- "Revenue sharing model for affiliates"

### Tech (Code, Architecture, Infrastructure)
**Keywords**: refactor, code, technical, architecture, api, database, infrastructure, deploy, bug, performance

**Example ideas**:
- "Refactor authentication module"
- "Migrate to serverless architecture"
- "Fix N+1 query problem"

### Client (Client-Specific)
**Keywords**: client, project-specific names, [client-a, client-b, etc.]

**Example ideas**:
- "Client A wants custom reporting"
- "Acme Corp integration requirements"
- "Project X scope change"

### Process (Workflow, Efficiency)
**Keywords**: process, automation, workflow, efficiency, optimize, streamline, automate, tool

**Example ideas**:
- "Automate deployment process"
- "Streamline code review workflow"
- "Create project setup checklist"

## Priority Keywords

### HIGH Priority
**Indicators**:
- urgent, critical, asap, now, today
- client requested, blocking, blocker
- important, must have, required
- deadline, due date

**Example ideas**:
- "URGENT: Fix production bug"
- "Client requested dashboard by Friday"
- "Critical security update needed"

### MEDIUM Priority (Default)
**Indicators**: Standard ideas without urgency or low-priority signals

**Example ideas**:
- "Add export feature"
- "Improve error messages"
- "Create documentation"

### LOW Priority
**Indicators**:
- nice to have, someday, maybe, explore
- consider, investigate, research
- future, long-term, eventually

**Example ideas**:
- "Nice to have: dark mode"
- "Someday: mobile app"
- "Explore blockchain integration"

## Edge Cases

### Multiple Categories
If idea matches multiple categories, prioritize:
1. Client (if client mentioned)
2. Product (if user-facing)
3. Tech (if technical implementation)
4. Content/Business/Process (by keyword count)

### No Clear Category
Default to "general" category, saved to `general-ideas.md`.

### Multiple Priorities
If both HIGH and LOW indicators present, use context:
- "Urgent: explore blockchain" → HIGH (urgency wins)
- "Someday fix critical bug" → MEDIUM (conflicting signals = default)

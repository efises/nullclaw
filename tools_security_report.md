# Tools and Autonomy Policy Analysis

This report details the architectural security measures implemented in NullClaw to gate tool execution and enforce autonomy constraints.

## 1. Tool Execution Architecture

Tool execution follows a strictly layered dispatch flow:

1.  **Agent Loop Dispatch**: `Agent.executeTool` receives a tool call.
    *   **Gate A (Read-Only)**: If the agent is in `read-only` mode, it rejects any tool not explicitly allowed in that mode (currently most state-changing tools are blocked).
    *   **Gate B (Rate Limiting)**: `policy.recordAction()` checks if the agent has exceeded the configured actions-per-minute or actions-per-hour limits.
2.  **Tool-Specific Preamble**: The tool's `execute` method is called.
3.  **Security Gate Integration**: The tool calls context-specific security helpers:
    *   **Shell Tools**: Call `policy.validateCommandExecution(command)`.
    *   **FS Tools**: Call `isResolvedPathAllowed(...)` and `isPathSafe(...)`.
    *   **Network Tools**: Use SSRF/DNS-rebinding protection layers.

## 2. Security Policy Engine (`src/security/policy.zig`)

The central `SecurityPolicy` manages the "Autonomy Level" and command-risk assessment.

### Autonomy Levels
- `read_only`: No modifications allowed.
- `supervised`: Requires approval for `medium` risk actions; `high` risk actions are blocked by default.
- `full`: Allows `low` and `medium` risk actions; `high` risk still requires policy explicit flag.

### Command Risk Classification
The policy classifies shell commands using a heuristic map:
- **Low Risk**: `ls`, `grep`, `cat`, `git status`, `pwd`.
- **Medium Risk**: `mkdir`, `cp`, `mv`, `git commit`, `curl`, `wget`.
- **High Risk**: `rm`, `sudo`, `chmod`, `chown`, `kill`, `crontab`.

> [!IMPORTANT]
> Risk assessment is not just by binary name; the policy identifies dangerous flags and patterns (e.g., `rm -rf /` or `sudo` usage).

## 3. Path Security (`src/tools/path_security.zig`)

NullClaw implements a robust path-gating system that applies to `file_*`, `git`, and `shell` tools.

### Protection Layers
- **Traversal Prevention**: Rejects any path containing `..` or URL-encoded variants (e.g., `%2f..`).
- **Absolute Path Lockdown**: Rejects absolute paths unless they are within the `workspace_dir` or `allowed_paths`.
- **System Blocklist**: Even if a path is theoretically allowed, the following prefixes are **HARD-BLOCKED**:
  - **Unix**: `/etc`, `/bin`, `/sbin`, `/usr/bin`, `/System`, `/Library`, `/dev`, `/proc`.
  - **Windows**: `C:\Windows`, `C:\Program Files`, `C:\System32`.

## 4. Tool Categorization

| Category | Tools | Primary Risk | Mitigation |
| :--- | :--- | :--- | :--- |
| **Shell / Execution** | `shell`, `spawn`, `git` | Host compromise, privilege escalation | Command risk assessment, flag sanitization. |
| **FS Write** | `file_write`, `file_edit`, `file_append`, `cron_add` | Ransomware, system instability, data loss | Path security gates, system blocklist. |
| **Internet Access** | `http_request`, `web_fetch`, `web_search`, `composio` | SSRF, data exfiltration, credential leakage | SSA, host verification, error sanitization. |
| **Hardware / Bus** | `i2c`, `spi` | Physical hardware damage | Locked to specific bus IDs (usually requires root). |
| **Privacy / Identity**| `memory_store`, `pushover`, `composio` | Credential leakage, identity theft | Redaction of secrets in errors, entity isolation. |

## 5. Specialized Tool Sanitization

- **GitTool (`src/tools/git.zig`)**: Implements `sanitizeGitArgs` which blocks dangerous flags like `--exec=`, `--upload-pack=`, and `--pager=`.
- **ComposioTool (`src/tools/composio.zig`)**: Implements `sanitizeErrorMessage` which automatically redacts long alphanumeric strings (suspected API keys/tokens) from error responses.
- **WebFetchTool (`src/tools/web_fetch.zig`)**: Includes a dedicated check for SSRF-vulnerable hostnames (localhost, private IP ranges).

## 6. Recommendations for Approval Layer

To implement a robust human-in-the-loop (HITL) approval layer, NullClaw should:
1.  **Hook into `SecurityPolicy.validateCommandExecution`**: Instead of just returning an error for `medium`/`high` risk, it should trigger an `ApprovalRequest` event.
2.  **Add `PathApproval`**: Extend `path_security.zig` to request approval when writing outside the workspace even if the path is in `allowed_paths`.
3.  **Centralize Dispense**: Move the "Can I do this?" logic from individual tools into a central `AccessController` that the `Agent` calls before tool dispatch.

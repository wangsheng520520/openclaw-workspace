## Description:

Control Home Assistant devices and automations via REST API across lights, climate, locks, presence, weather, calendars, notifications, scripts, and other smart-home domains.

This skill is ready for commercial/non-commercial use.

## Publisher:

[anotb](https://clawhub.ai/user/anotb)

### License/Terms of Use:

MIT

## Use Case:

External users and developers use this skill to let an agent discover Home Assistant entities, read smart-home state, and prepare REST API actions for devices, automations, notifications, presence, weather, calendars, history, templates, and related home-control workflows.

### Deployment Geography for Use:

Global

## Known Risks and Mitigations:

Risk: The skill depends on a long-lived Home Assistant token that can expose private home state and enable broad smart-home control.

Mitigation: Use HTTPS, store HA_TOKEN securely, and create the least-privileged dedicated Home Assistant user or token available for the intended tasks.

Risk: Actions involving locks, alarms, covers, scripts, automations, notifications, TTS, presence, calendars, templates, or generic service calls can have physical, privacy, or security impact.

Mitigation: Require explicit user confirmation before those actions and verify target entity IDs before making service calls.

Risk: Tokens, alarm codes, and other sensitive values may leak through chat transcripts or shell history.

Mitigation: Avoid placing secrets in prompts or command history, use environment variables, and rotate credentials if exposure is suspected.

## Reference(s):

- [ClawHub Skill Page](https://clawhub.ai/anotb/skills/homeassistant-skill)
- [Publisher Profile](https://clawhub.ai/user/anotb)
- [Home Assistant Skill Homepage](https://github.com/anotb/homeassistant-skill)

## Skill Output:

**Output Type(s):** [text, markdown, shell commands, configuration, guidance]

**Output Format:** [Markdown with inline bash and JSON examples]

**Output Parameters:** [1D]

**Other Properties Related to Output:** [Requires HA_URL, HA_TOKEN, curl, jq, and network access to the user's Home Assistant instance.]

## Skill Version(s):

2.1.0 (source: server release metadata and skill frontmatter)

## Ethical Considerations:

Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment.

import * as core from "@actions/core";
import type { RunContext } from "./context.js";
import { statusOf, statusUpdatedAt } from "../util/project.js";
import { daysBetween } from "../util/dates.js";

const marker = (status: string) => `<!-- boardly:stale-nudge:${status.toLowerCase()} -->`;

/**
 * Stale-card nudges.
 *
 * For each configured rule, find cards that have sat in a status longer than
 * `days` and @-mention the owners with a nudge comment. A hidden marker in the
 * comment body prevents re-nudging the same card until its status changes.
 */
export async function runStaleNudge(ctx: RunContext): Promise<void> {
  const { cfg, graph, client, audit, now } = ctx;
  const rules = cfg.features.staleNudge.rules;
  if (rules.length === 0) {
    core.info("stale-nudge: no rules configured.");
    return;
  }

  for (const item of graph.items) {
    const content = item.content;
    if (!content) continue; // draft items have nowhere to comment

    const status = statusOf(item, cfg);
    if (!status) continue;
    const rule = rules.find((r) => r.status.toLowerCase() === status.toLowerCase());
    if (!rule) continue;

    const since = statusUpdatedAt(item, cfg) ?? item.updatedAt;
    const age = daysBetween(new Date(since), now);
    if (age < rule.days) continue;

    // De-dupe: skip if we've already nudged since the status last changed.
    const existing = await client.listComments(content.repoOwner, content.repoName, content.number);
    const alreadyNudged = existing.some(
      (c) => c.body.includes(marker(status)) && new Date(c.createdAt) >= new Date(since),
    );
    if (alreadyNudged) continue;

    const mentions = resolveMentions(rule.notify, content.assignees);
    const template =
      rule.message ?? "This item has been in **{status}** for {days} day(s) with no status change. Any update?";
    const body =
      `${marker(status)}\n${fill(template, { status, days: Math.floor(age), number: content.number, title: content.title })}` +
      (mentions ? `\n\n${mentions}` : "");

    const label = `#${content.number} ${content.title}`;
    audit.record("stale-nudge", "comment", label, `in "${status}" for ${Math.floor(age)}d${mentions ? `, pinged ${mentions}` : ""}`);

    if (!ctx.dryRun) {
      await client.comment(content.repoOwner, content.repoName, content.number, body);
    }

    // Also broadcast the alert to any external channels (Slack/email).
    await ctx.notifier.broadcast({
      feature: "stale-nudge",
      title: `Stale card: ${label}`,
      markdown:
        `⏳ [#${content.number}](${content.url}) **${content.title}** has been in ` +
        `**${status}** for ${Math.floor(age)} day(s)${mentions ? ` — ${mentions}` : ""}.`,
    });
  }
}

// `notify` is either the literal "assignees" or a list of logins. Inside the
// list, an "assignees" entry expands to the item's assignees, so a rule can ping
// assignees *and* extra people (a reviewer, a project manager, …):
//   notify: [assignees, project-manager, some-reviewer]
function resolveMentions(notify: "assignees" | string[], assignees: string[]): string {
  const logins = notify === "assignees" ? assignees : notify.flatMap((l) => (l === "assignees" ? assignees : l));
  return [...new Set(logins.map((l) => `@${l.replace(/^@/, "")}`))].join(" ");
}

function fill(template: string, vars: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (_, key) => (key in vars ? String(vars[key]) : `{${key}}`));
}

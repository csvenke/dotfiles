import assert from "node:assert/strict";
import test from "node:test";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import extension from "../index.ts";

interface FakePi {
  events: Map<string, (event: unknown, ctx: unknown) => unknown>;
  commands: Map<
    string,
    {
      description: string;
      handler: (args: string, ctx: never) => Promise<void>;
    }
  >;
}

function register(): FakePi {
  const events: FakePi["events"] = new Map();
  const commands: FakePi["commands"] = new Map();
  const pi = {
    on: (name: string, fn: (event: unknown, ctx: unknown) => unknown) => {
      events.set(name, fn);
    },
    registerCommand: (
      name: string,
      def: { description: string; handler: never },
    ) => {
      commands.set(name, def);
    },
  };
  extension(pi as unknown as ExtensionAPI);
  return { events, commands };
}

function fakeCtx(mode = "tui") {
  const notifications: string[] = [];
  let customCalls = 0;
  const ctx = {
    mode,
    ui: {
      custom: () => {
        customCalls++;
        return new Promise(() => {}); // overlay stays open
      },
      notify: (message: string) => notifications.push(message),
    },
  };
  return { ctx, notifications, customCalls: () => customCalls };
}

test("registers lifecycle events and commands", () => {
  const { events, commands } = register();
  for (const name of ["agent_start", "agent_settled", "session_shutdown"]) {
    assert.ok(events.has(name), `handler registered: ${name}`);
  }
  assert.ok(commands.has("chess"));
  assert.ok(commands.has("chess-auto"));
});

test("/chess opens the overlay manually", async () => {
  const { commands } = register();
  const { ctx, customCalls } = fakeCtx();
  // The fake overlay never resolves; open/close toggling is covered by the
  // controller tests. Not awaited on purpose (a pending promise is fine).
  void commands.get("chess")!.handler("", ctx as never);
  await new Promise((r) => setTimeout(r, 0));
  assert.equal(customCalls(), 1);
});

test("/chess-auto toggles and notifies", async () => {
  const { commands } = register();
  const { ctx, notifications } = fakeCtx();
  await commands.get("chess-auto")!.handler("", ctx as never);
  assert.match(notifications.join("\n"), /auto-open off/);
  await commands.get("chess-auto")!.handler("", ctx as never);
  assert.match(notifications.join("\n"), /auto-open on/);
});

test("lifecycle handlers are safe without a prior open", () => {
  const { events } = register();
  const { ctx } = fakeCtx();
  // no open overlay, no pending timer: all must be harmless no-ops
  events.get("agent_settled")!({}, ctx);
  events.get("session_shutdown")!({}, ctx);
  events.get("agent_start")!({}, ctx);
  events.get("agent_settled")!({}, ctx);
});

/** @jsxImportSource @opentui/solid */
import type { TuiPlugin, TuiPluginApi, TuiPluginModule } from "@kilocode/plugin/tui"
import { createEffect, createMemo, createResource, createSignal, For, onCleanup, Show } from "solid-js"

const id = "deepseek-balance"
const REFRESH_MS = 60_000

type BalanceInfo = {
  currency: string
  total_balance: string
  granted_balance?: string
  topped_up_balance?: string
}

type BalanceState =
  | { kind: "ok"; available: boolean; entries: BalanceInfo[] }
  | { kind: "error"; reason: "no-key" | "http" | "network" }

function deepseekProvider(api: TuiPluginApi) {
  return api.state.provider.find((item) => item.id === "deepseek")
}

function apiKey(api: TuiPluginApi): string | undefined {
  const provider = deepseekProvider(api)
  const options = provider?.options as Record<string, unknown> | undefined
  const fromOptions = typeof options?.apiKey === "string" ? options.apiKey : undefined
  const fromKey = typeof provider?.key === "string" ? provider.key : undefined
  const configOptions = api.state.config.provider?.deepseek?.options as Record<string, unknown> | undefined
  const fromConfig = typeof configOptions?.apiKey === "string" ? configOptions.apiKey : undefined
  return fromOptions ?? fromKey ?? fromConfig
}

async function loadBalance(api: TuiPluginApi): Promise<BalanceState> {
  const key = apiKey(api)
  if (!key) return { kind: "error", reason: "no-key" }
  const options = deepseekProvider(api)?.options as Record<string, unknown> | undefined
  const baseURL = typeof options?.baseURL === "string" ? options.baseURL : "https://api.deepseek.com"
  const host = baseURL.replace(/\/+$/, "").replace(/\/v\d+$/, "")
  try {
    const response = await fetch(`${host}/user/balance`, {
      headers: { Authorization: `Bearer ${key}` },
    })
    if (!response.ok) return { kind: "error", reason: "http" }
    const data = (await response.json()) as { is_available?: boolean; balance_infos?: BalanceInfo[] }
    return { kind: "ok", available: data.is_available !== false, entries: data.balance_infos ?? [] }
  } catch {
    return { kind: "error", reason: "network" }
  }
}

function formatBalance(entry: BalanceInfo): string {
  const amount = Number(entry.total_balance)
  if (Number.isFinite(amount)) {
    try {
      return new Intl.NumberFormat("en-US", { style: "currency", currency: entry.currency || "USD" }).format(amount)
    } catch {
      // unsupported currency code, fall through
    }
  }
  return `${entry.currency || "USD"} ${entry.total_balance}`
}

function View(props: { api: TuiPluginApi }) {
  const theme = () => props.api.theme.current
  const [open, setOpen] = createSignal(true)
  const [tick, setTick] = createSignal(0)
  const [state] = createResource(
    () => [tick(), props.api.state.ready, props.api.state.provider.length] as const,
    () => loadBalance(props.api),
  )
  createEffect(() => {
    const timer = setInterval(() => setTick((value) => value + 1), REFRESH_MS)
    onCleanup(() => clearInterval(timer))
  })
  const noKey = createMemo(() => {
    const current = state()
    return current?.kind === "error" && current.reason === "no-key"
  })
  const ok = createMemo(() => {
    const current = state()
    return current?.kind === "ok" ? current : undefined
  })
  return (
    <Show when={!noKey()}>
      <box gap={1}>
        <box flexDirection="row" gap={1} onMouseDown={() => setOpen((value) => !value)}>
          <text fg={theme().text}>{open() ? "▼" : "▶"}</text>
          <text fg={theme().text}>
            <b>Balances</b>
          </text>
        </box>
        <Show when={open()}>
          <Show
            when={ok()}
            fallback={<text fg={theme().textMuted}>{state.loading ? "Loading balance..." : "Balance unavailable"}</text>}
          >
            {(data) => (
              <For each={data().entries}>
                {(entry) => (
                  <box flexDirection="row" justifyContent="space-between">
                    <text fg={theme().textMuted}>
                      {data().entries.length === 1 ? "DeepSeek" : entry.currency || "DeepSeek"}
                    </text>
                    <text fg={data().available ? theme().success : theme().warning}>{formatBalance(entry)}</text>
                  </box>
                )}
              </For>
            )}
          </Show>
        </Show>
      </box>
    </Show>
  )
}

const tui: TuiPlugin = async (api) => {
  api.slots.register({
    order: 250,
    slots: {
      sidebar_content() {
        return <View api={api} />
      },
    },
  })
}

const plugin: TuiPluginModule & { id: string } = {
  id,
  tui,
}

export default plugin

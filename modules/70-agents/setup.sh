#!/usr/bin/env bash
# third-party AI coding agents: omp (oh-my-pi) and kilocode. api keys
# come in via SETUP_DEEPSEEK_APIKEY (set by ./setup.sh --deepseek-apikey).

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../lib/common.sh"

APIKEY="${SETUP_DEEPSEEK_APIKEY:-}"

#---------------------------------------------------------------------
# omp (oh-my-pi)
#---------------------------------------------------------------------
install_omp() {
    if has omp; then
        echo "omp already installed: $(omp --version 2>/dev/null | head -1 || true)"
    else
        info "installing omp (oh-my-pi)..."
        curl -fsSL https://omp.sh/install | sh
    fi
}

#---------------------------------------------------------------------
# kilocode
#---------------------------------------------------------------------
install_kilocode() {
    if has kilo; then
        echo "kilocode already installed: $(kilo --version 2>/dev/null | head -1 || true)"
        return
    fi
    info "installing kilocode (npm install -g @kilocode/cli)..."
    if ! npm install -g @kilocode/cli; then
        echo "plain npm install failed, retrying with sudo..."
        sudo npm install -g @kilocode/cli
    fi
}

#---------------------------------------------------------------------
# deepseek key -> omp: custom provider in ~/.omp/agent/models.yml
# (scraped from the machine this all came from) + default model role
#---------------------------------------------------------------------
configure_omp_deepseek() {
    local agent_dir="$HOME/.omp/agent"
    local models="$agent_dir/models.yml"
    local config="$agent_dir/config.yml"
    mkdir -p "$agent_dir"

    if [ -f "$models" ]; then
        cp "$models" "$models.bak.$(date +%Y%m%d%H%M%S)"
    fi
    cat > "$models" <<YAML
providers:
  deepseek:
    baseUrl: https://api.deepseek.com
    api: openai-completions
    apiKey: $APIKEY
    authHeader: true
    models:
      - id: deepseek-v4-pro
        name: DeepSeek V4 Pro
        reasoning: true
        thinking:
          minLevel: high
          maxLevel: xhigh
          mode: effort
        input: [text]
        contextWindow: 1000000
        maxTokens: 384000
        compat:
          supportsDeveloperRole: false
          supportsReasoningEffort: true
          maxTokensField: max_tokens
          reasoningEffortMap:
            high: high
            xhigh: max
          supportsToolChoice: false
          requiresReasoningContentForToolCalls: true
          requiresAssistantContentForToolCalls: true
          extraBody:
            thinking:
              type: enabled
      - id: deepseek-v4-flash
        name: DeepSeek V4 Flash
        reasoning: true
        thinking:
          minLevel: high
          maxLevel: xhigh
          mode: effort
        input: [text]
        contextWindow: 1000000
        maxTokens: 384000
        compat:
          supportsDeveloperRole: false
          supportsReasoningEffort: true
          maxTokensField: max_tokens
          reasoningEffortMap:
            high: high
            xhigh: max
          supportsToolChoice: false
          requiresReasoningContentForToolCalls: true
          requiresAssistantContentForToolCalls: true
          extraBody:
            thinking:
              type: enabled
YAML
    chmod 600 "$models"
    info "omp: deepseek provider written to $models"

    if [ -f "$config" ] && grep -q 'modelRoles' "$config"; then
        echo "omp: $config already has modelRoles, leaving it alone"
    else
        printf 'modelRoles:\n  default: deepseek/deepseek-v4-flash\n' >> "$config"
        info "omp: default model role set in $config"
    fi
}

#---------------------------------------------------------------------
# deepseek key -> kilocode: merge into ~/.config/kilo/kilo.json[c]
# (node is present because this module just installed kilocode via npm)
#---------------------------------------------------------------------
configure_kilocode_deepseek() {
    local dir="$HOME/.config/kilo" cfg
    mkdir -p "$dir"
    if [ -f "$dir/kilo.json" ]; then cfg="$dir/kilo.json"
    elif [ -f "$dir/kilo.jsonc" ]; then cfg="$dir/kilo.jsonc"
    else cfg="$dir/kilo.json"; fi

    if [ -f "$cfg" ]; then
        cp "$cfg" "$cfg.bak.$(date +%Y%m%d%H%M%S)"
    fi

    SETUP_DEEPSEEK_APIKEY="$APIKEY" node -e '
        const fs = require("fs");
        const file = process.argv[1];
        const key = process.env.SETUP_DEEPSEEK_APIKEY;
        let cfg = {};
        try { cfg = JSON.parse(fs.readFileSync(file, "utf8")); } catch (e) { cfg = {}; }
        cfg.provider = cfg.provider || {};
        cfg.provider.deepseek = cfg.provider.deepseek || {};
        cfg.provider.deepseek.options = cfg.provider.deepseek.options || {};
        cfg.provider.deepseek.options.apiKey = key;
        cfg.provider.deepseek.options.baseURL = cfg.provider.deepseek.options.baseURL || "https://api.deepseek.com/v1";
        if (!cfg.model) cfg.model = "deepseek/deepseek-v4-flash";
        fs.writeFileSync(file, JSON.stringify(cfg, null, 2) + "\n");
    ' "$cfg"
    info "kilocode: deepseek key written to $cfg"
}

install_omp
install_kilocode

if [ -n "$APIKEY" ]; then
    configure_omp_deepseek
    configure_kilocode_deepseek
else
    info "no deepseek api key given; skipping key config (use --deepseek-apikey=KEY)"
fi

ok "agents done"

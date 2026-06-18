# frozen_string_literal: true

module FlowMcp
  # Build identity reported by `ping` / `serverInfo` (EARS-FLOW-098). The `-ruby`
  # suffix distinguishes this interpreted reference from the retired compiled
  # builds so a session can prove which implementation is live.
  VERSION = "0.3.0-ruby"
end

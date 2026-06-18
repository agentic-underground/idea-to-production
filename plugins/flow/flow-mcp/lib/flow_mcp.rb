# frozen_string_literal: true

# flow-mcp — Ruby reference implementation (Ruby >= 3.3.8, standard library only).
# The behavioural contract is the EARS spec in spec/EARS.md; this library conforms
# to it. Public entry point: FlowMcp::Server.run(ARGV).

require_relative "flow_mcp/version"
require_relative "flow_mcp/errors"
require_relative "flow_mcp/ids"
require_relative "flow_mcp/model"
require_relative "flow_mcp/event"
require_relative "flow_mcp/annotation"
require_relative "flow_mcp/roadmap_view"
require_relative "flow_mcp/telemetry"
require_relative "flow_mcp/history"
require_relative "flow_mcp/store"
require_relative "flow_mcp/config"
require_relative "flow_mcp/mcp"
require_relative "flow_mcp/server"

module FlowMcp
end

# frozen_string_literal: true

require_relative "errors"

module FlowMcp
  # Server configuration parsed from CLI args (EARS-FLOW-079/080/081). `--mcp` is
  # accepted as a harmless no-op (stdio is the only transport).
  Config = Struct.new(:data_dir, :roadmap_path, :mcp) do
    def self.default = new(".flow", nil, false)

    # Parse --data, --roadmap, --mcp from an argv array. A known flag without a
    # value, or an unknown flag, is a fatal ConfigError.
    def self.from_args(argv)
      cfg = default
      args = argv.dup
      until args.empty?
        flag = args.shift
        case flag
        when "--data"
          cfg.data_dir = require_value(args, flag)
        when "--roadmap"
          cfg.roadmap_path = require_value(args, flag)
        when "--mcp"
          cfg.mcp = true
        else
          raise ConfigError, "unknown flag #{flag}"
        end
      end
      cfg
    end

    def self.require_value(args, flag)
      raise ConfigError, "flag #{flag} requires a value" if args.empty?

      args.shift
    end
  end
end

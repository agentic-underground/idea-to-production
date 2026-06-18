# frozen_string_literal: true

require "json"
require_relative "config"
require_relative "store"
require_relative "mcp"

module FlowMcp
  # Process wiring + the newline-delimited stdio JSON-RPC loop (the sole MCP
  # transport). Startup order is fixed (EARS-FLOW-077/078): open (replay) ->
  # ingest source -> restore gates -> serve.
  module Server
    module_function

    # Boot from CLI args and serve until EOF. Returns the process exit code.
    # Startup is ingest→replay (EARS-FLOW-077): open an empty store, ingest the tree
    # (which owns item identity), then replay the event log (which owns runtime state
    # — gate/tokens/model/draft — and is layered on top without clobbering).
    def run(argv, input: $stdin, output: $stdout)
      cfg = Config.from_args(argv)
      store = Store.open(cfg.data_dir)
      ingest_source(store, cfg)
      store.replay!
      serve(store, input, output)
      0
    end

    # Resolve and ingest the roadmap source (EARS-FLOW-082..085). A directory is
    # the file-per-item tree; a file is the legacy ROADMAP.md. Absent/unreadable
    # degrades to an empty board (logged, never fatal).
    def ingest_source(store, cfg)
      source = cfg.roadmap_path
      source ||= ".i2p/roadmap" if File.directory?(".i2p/roadmap")
      unless source
        warn "flow-mcp: no roadmap source (no --roadmap and no .i2p/roadmap/ under #{Dir.pwd}); starting empty"
        return
      end

      if File.directory?(source)
        n = store.ingest_roadmap_tree(source)
        warn "flow-mcp ingested #{n} roadmap item(s) from the #{source} tree"
      elsif File.file?(source)
        n = store.ingest_roadmap(File.read(source))
        warn "flow-mcp ingested #{n} roadmap item(s) from #{source}"
      else
        warn "flow-mcp: no roadmap ingested (#{source} not found); starting empty"
      end
    end

    # The stdio read loop (EARS-FLOW-001/009/012). One request per line; one
    # response line per request that carries an id; -32700 for an unparseable or
    # blank line; clean exit on EOF.
    def serve(store, input, output)
      while (line = input.gets)
        trimmed = line.strip
        if trimmed.empty?
          write(output, parse_error)
          next
        end

        req =
          begin
            JSON.parse(trimmed)
          rescue JSON::ParserError
            write(output, parse_error)
            next
          end

        is_notification = !req.is_a?(Hash) || !req.key?("id")
        resp = Mcp.dispatch(store, req)
        next if is_notification || resp.nil?

        write(output, resp)
      end
    end

    def parse_error
      { "jsonrpc" => "2.0", "id" => nil, "error" => { "code" => -32700, "message" => "Parse error" } }
    end

    def write(output, obj)
      output.write("#{JSON.generate(obj)}\n")
      output.flush
    end
  end
end

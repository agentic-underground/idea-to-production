# frozen_string_literal: true

require_relative "helper"
require_relative "feature_support/gherkin"
require_relative "feature_support/steps"

# Executes the canonical Gherkin FEATURE suite (../spec/features) with a stdlib
# runner — no cucumber gem (EARS-FLOW-099). Regular verb scenarios run end-to-end;
# the rest are reported PENDING (never silently skipped) and are covered by the
# other minitest files. Also enforces the spec<->test traceability invariant.
class TestFeatures < Minitest::Test
  SPEC_DIR = File.expand_path("../spec", __dir__)
  FEATURE_GLOB = File.join(SPEC_DIR, "features", "*.feature")

  def features = Dir[FEATURE_GLOB].sort

  def test_every_feature_parses_and_is_well_formed
    refute_empty features, "no feature files found"
    features.each do |path|
      feat = Gherkin.parse_file(path)
      assert feat.name, "#{path}: missing Feature:"
      refute_empty feat.scenarios, "#{path}: no scenarios"
      feat.scenarios.each do |sc|
        tags = sc.tags.grep(/\AEARS-FLOW-\d{3}\z/)
        assert tags.any?, "#{path}: scenario #{sc.name.inspect} has no @EARS-FLOW tag"
        if sc.outline
          assert sc.examples && !sc.examples[:rows].empty?,
                 "#{path}: outline #{sc.name.inspect} has no Examples rows"
        end
        assert sc.steps.any?, "#{path}: scenario #{sc.name.inspect} has no steps"
      end
    end
  end

  def test_traceability_features_to_ears_and_tests
    defined = scan(File.join(SPEC_DIR, "EARS.md"), /EARS-FLOW-\d{3}/).to_set
    tagged  = features.flat_map { |p| scan(p, /(?<=@)EARS-FLOW-\d{3}/) }.to_set
    in_tests = Dir[File.expand_path("test_*.rb", __dir__)]
               .flat_map { |p| scan(p, /(?<=@)EARS-FLOW-\d{3}/) }.to_set

    assert_equal defined, tagged, "feature tags must cover exactly the EARS ids:\n" \
      "  only in EARS.md: #{(defined - tagged).to_a.sort}\n  only in features: #{(tagged - defined).to_a.sort}"

    # The launcher (Ruby resolution) and the markdown fallback runbook land in the
    # cutover PR; their EARS ids are not executable from this library yet.
    deferred_to_cutover = %w[EARS-FLOW-100 EARS-FLOW-101].to_set
    missing = (tagged - in_tests - deferred_to_cutover).to_a.sort
    assert_empty missing, "every feature-tagged EARS id needs an executable minitest (# @EARS-FLOW-NNN); missing: #{missing}"
  end

  def test_executes_regular_scenarios_end_to_end
    executed = 0
    pending = []
    failures = []

    features.each do |path|
      feat = Gherkin.parse_file(path)
      feat.scenarios.each do |raw|
        Gherkin.expand(raw).each do |sc|
          world = FeatureSteps::World.new
          begin
            (feat.background + sc.steps).each { |step| FeatureSteps.run(world, step) }
            executed += 1
          rescue FeatureSteps::Pending => e
            pending << "#{File.basename(path)} :: #{sc.name} :: #{e.message}"
          rescue FeatureSteps::Failure, FlowMcp::Error => e
            failures << "#{File.basename(path)} :: #{sc.name} :: #{e.class}: #{e.message}"
          end
        end
      end
    end

    warn "\n[features] executed=#{executed} pending=#{pending.length} failed=#{failures.length}"
    warn "[features] pending steps (covered by other minitest files):\n  #{pending.first(20).join("\n  ")}" unless pending.empty?

    assert_empty failures, "executed feature scenarios must pass:\n  #{failures.join("\n  ")}"
    assert_operator executed, :>=, 30, "the runner should execute a meaningful subset end-to-end"
  end

  private

  def scan(path, re)
    File.read(path).scan(re) # array; callers .to_set after flattening
  end
end

require "minitest/autorun"
require "yaml"

class WorkflowContractTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)

  def workflow(name)
    YAML.safe_load(File.read(File.join(ROOT, ".github/workflows/#{name}.yml")))
  end

  def test_distribution_requires_the_complete_reusable_quality_gate
    jobs = workflow("dev-distribution").fetch("jobs")
    assert_equal "./.github/workflows/ci.yml", jobs.fetch("quality_gate").fetch("uses")
    %w[android ios].each do |platform|
      job = jobs.fetch(platform)
      assert_includes Array(job.fetch("needs")), "quality_gate"
      refute job.fetch("continue-on-error", false)
      refute_includes job.fetch("if", ""), "always()"
    end
  end

  def test_quality_gate_does_not_receive_distribution_secrets
    ci_path = File.join(ROOT, ".github/workflows/ci.yml")
    refute_match(/secrets\./, File.read(ci_path))
    ci = workflow("ci")
    triggers = ci["on"] || ci[true] # Psych also accepts YAML 1.1 boolean keys.
    assert triggers.key?("workflow_call")
    assert ci.fetch("jobs").key?("validate_ios")
    ci.fetch("jobs").each_value do |job|
      refute job.key?("environment")
      job.fetch("steps").each { |step| refute step.fetch("continue-on-error", false) }
    end
  end

  def test_ios_publishes_only_after_build_and_artifact_validation
    steps = workflow("dev-distribution").fetch("jobs").fetch("ios").fetch("steps")
    commands = steps.map { |step| step.fetch("run", "") }
    build = commands.index { |command| command.include?("make ios-build") }
    publish = commands.index { |command| command.include?("make ios-testflight") }
    assert build
    assert publish
    assert_operator build, :<, publish
    refute steps.any? { |step| step.fetch("uses", "").include?("import-codesign-certs") }
    steps.select { |step| step.fetch("uses", "").start_with?("actions/upload-artifact@") }.each do |step|
      assert_equal "error", step.fetch("with").fetch("if-no-files-found")
    end
  end
end

require "minitest/autorun"
require_relative "../../fastlane/ios_release_configuration"

class IosReleaseConfigurationTest < Minitest::Test
  def test_dev_uses_its_own_bundle_and_profile
    config = IosReleaseConfiguration.load("dev")
    assert_equal "br.usp.digitavox-criancas.dev", config.fetch(:bundle_id)
    assert_equal "Digitavox Criancas Dev App Store", config.fetch(:profile_name)
    assert_equal "SYF585KJR7", config.fetch(:team_id)
  end

  def test_prod_does_not_select_dev_signing
    config = IosReleaseConfiguration.load("prod")
    assert_equal "br.usp.digitavox-criancas", config.fetch(:bundle_id)
    assert_equal "Digitavox Criancas App Store", config.fetch(:profile_name)
    refute_equal IosReleaseConfiguration.load("dev").fetch(:profile_name), config.fetch(:profile_name)
  end

  def test_missing_or_unknown_flavor_does_not_default_to_an_app
    [nil, "", "staging", "../dev"].each do |flavor|
      assert_raises(ArgumentError) { IosReleaseConfiguration.load(flavor) }
    end
  end

  def test_environment_does_not_override_flutter_identity
    previous = ENV["APP_IDENTIFIER"]
    ENV["APP_IDENTIFIER"] = "another.application"
    assert_equal "br.usp.digitavox-criancas.dev", IosReleaseConfiguration.load("dev").fetch(:bundle_id)
  ensure
    previous ? ENV["APP_IDENTIFIER"] = previous : ENV.delete("APP_IDENTIFIER")
  end
end

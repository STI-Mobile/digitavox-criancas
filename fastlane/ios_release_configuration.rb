require "json"
require "open3"

# Read identity and signing from the same native configuration Flutter selects.
module IosReleaseConfiguration
  def self.load(flavor, root: File.expand_path("..", __dir__))
    unless %w[dev prod].include?(flavor)
      raise ArgumentError, "Informe flavor:dev ou flavor:prod, como no --flavor do Flutter."
    end

    project_path = File.join(root, "ios/Runner.xcodeproj/project.pbxproj")
    output, status = Open3.capture2("plutil", "-convert", "json", "-o", "-", project_path)
    raise "Não foi possível ler o projeto iOS." unless status.success?

    objects = JSON.parse(output).fetch("objects")
    runner = objects.values.find { |node| node["isa"] == "PBXNativeTarget" && node["name"] == "Runner" }
    configurations = objects.fetch(runner.fetch("buildConfigurationList")).fetch("buildConfigurations")
    configuration_name = "Release-#{flavor}"
    configuration = configurations.map { |id| objects.fetch(id) }.find { |node| node["name"] == configuration_name }
    raise "Configuração #{configuration_name} ausente." unless configuration

    settings = configuration.fetch("buildSettings")
    keys = %w[PRODUCT_BUNDLE_IDENTIFIER DEVELOPMENT_TEAM PROVISIONING_PROFILE_SPECIFIER]
    if keys.any? { |key| settings[key].to_s.empty? }
      raise "Bundle ID, time e profile precisam estar definidos em #{configuration_name}."
    end

    {
      flavor: flavor,
      bundle_id: settings.fetch("PRODUCT_BUNDLE_IDENTIFIER"),
      team_id: settings.fetch("DEVELOPMENT_TEAM"),
      profile_name: settings.fetch("PROVISIONING_PROFILE_SPECIFIER")
    }
  end
end

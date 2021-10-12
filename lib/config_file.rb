require 'json' # to symbolize keys of nested hash
require 'yaml'

# Provides configuration from YAML file
module ConfigFile
  # Loads YAML file as symbolized hash
  # @param filename [String] filename to load
  # @return [Hash] YAML converted into symbolized hash
  def self.load_file_as_symbolized_hash(filename)
    yaml = YAML.load_file(File.expand_path("../#{filename}", __dir__))

    JSON.parse(yaml.to_json, symbolize_names: true)
  end

  # Gets configuration of enabled VMs
  # @param config [Hash] configuration from file
  # @return [Array<Hash>] enabled VMs
  def self.get_enabled_vms(config)
    # exclude disabled VMs
    enabled_vms = config[:vms].select { |vm| [true, 1].include?(vm[:enabled]) }

    enabled_vms.each do |vm|
      # apply defaults
      config[:defaults][:vm].each do |attribute, value|
        vm[attribute] = value unless vm.key?(attribute)
      end
      # ensure hostname
      vm[:hostname] = vm[:name] unless vm.key?(:hostname)
    end

    enabled_vms
  end
end

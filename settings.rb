class Settings
  attr_accessor :environment, :key_pair_name, :gateway_user
  def initialize(environment, key_pair_name,gateway_user = '')
    self.environment = environment
    self.key_pair_name = key_pair_name
    self.gateway_user = gateway_user
  end

  def ssh
    ssh_settings_defaults  = YAML::load(parse_config('defaults.yml'))
    ssh_settings_environment  = if File.exists?(File.join(File.dirname(File.expand_path(__FILE__)), "#{environment}.yml"))
      YAML::load(parse_config("#{environment}.yml"))
    else
     {}
    end
    ssh_settings_defaults.merge(ssh_settings_environment)
  end

  def parse_config(file)
    root_path = File.dirname(File.expand_path(__FILE__))
    file_content = File.new(File.join(root_path, file)).read

    ERB.new(file_content).result(binding)
  end
end
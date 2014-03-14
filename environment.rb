module Environment
	def set_environment(environment)
		environments[environment]
	end

	def environments
		YAML::load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'config.yml'))
	end

	def get_environment
		index = menu('environment', environments.keys)
		environments.keys[index]
	end	
end
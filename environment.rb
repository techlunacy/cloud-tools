module Environment
	require 'psych'	

	def set_environment(environment)
		environments[environment]
	end

	def environments
		Psych::load(File.read(File.join(File.dirname(File.expand_path(__FILE__)), 'config.yml')))
	end

	def get_environment
		index = menu('environment', environments.keys.sort)
		environments.keys.sort[index]
	end	
end
class SshInstance
	attr_accessor :key_pair_name, :user,:instance, :gateway

	def initialize(aws_instance)
		self.key_pair_name = aws_instance.key_pair.name
		self.instance = aws_instance
		self.user = 'ec2-user'
	end

	def key_path
		"~/keys/#{key_pair_name}.pem"
	end

	def self.get(settings, regex)
		connection = Fog::Compute::AWS.new(settings)
	  	instances = connection.servers
	  	instances.select!{|i| i.state == 'running' }
	  
	  	instances.select!{|i| get_name(i) =~ Regexp.new(regex)} unless regex.nil?

		aws_instance  = if instances.size == 1
			instances.first
		else
		  	instances.sort!{|x,y| get_name(x) <=> get_name(y)}
		  	instance_index = menu('server', instances.map { |e| get_name(e) })
  		  	instances[instance_index]
		end
		instance = self.new(aws_instance)
		instance.gateway = get_gateway(settings)
		instance
	end


	def url
		if bypass_gateway
			self.instance.public_ip_address || self.instance.dns_name
		else
			self.instance.private_ip_address
		end
	end

	def remote_key_path
		"/home/#{gateway.user}/keys/#{key_pair_name}.pem"
	end

	def cmd	
		return ssh_cmd if bypass_gateway
		return ssh_cmd_with_gateway
	end

	def user_at_url
		"#{user}@#{url}"
	end

	def login
		puts self.cmd

		exec(self.cmd)
	end



	private 

	def self.get_name(aws_instance)
		last_octet = aws_instance.private_ip_address.split('.').last
		name = aws_instance.tags['Name'] || aws_instance.id
		"#{name}#{last_octet}"
	end	

	def self.get_gateway(settings)
		connection = Fog::Compute::AWS.new(settings)
		instances = connection.servers
		instances.reject!{|i| i.state !='running'}

		instance = instances.reject { |e| e.tags['gateway'].nil? }.first

		SshInstance.new(instance) unless instance.nil?
	end		

	def bypass_gateway
	 	gateway.nil? || i_am_gateway
	end 

	def i_am_gateway
		self.gateway.instance.public_ip_address == self.instance.public_ip_address
	end

	def ssh_cmd
		"ssh -i #{key_path} -A #{user_at_url}"	
	end

	def gateway_ssh
		"ssh  -i #{gateway.key_path} -A -t #{gateway.user_at_url}"
	end

	def remote_ssh
 		"ssh -A -i #{remote_key_path} #{user_at_url}"
	end

	def ssh_cmd_with_gateway
		"#{gateway_ssh} #{remote_ssh}"
	end
end
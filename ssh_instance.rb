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
		if bypass_gateway
			ssh_cmd
		else
			ssh_cmd_with_gateway
		end	
	end

	def user_at_url
		"#{user}@#{url}"
	end

	def login
		puts self.cmd

		exec(self.cmd)
	end

	private 

	def bypass_gateway
	 	gateway.nil? || i_am_gateway
	end 

	def i_am_gateway
		self.gateway.instance.public_ip_address == self.instance.public_ip_address
	end

	def ssh_cmd
		"ssh #{user_at_url} -i #{key_path}"	
	end

	def ssh_cmd_with_gateway
		"ssh  -i #{gateway.key_path} -A -t #{gateway.user_at_url} ssh -A -i #{remote_key_path} #{user_at_url}"	
	end
end
class ScpInstance < SshInstance 
	attr_accessor :local_path, :remote_path

	def get_cmd
		return get_scp_cmd if bypass_gateway
		return get_cmd_with_gateway
	end

	def put_cmd
		return put_scp_cmd if bypass_gateway
		return put_cmd_with_gateway
	end

	def get_scp_cmd
		"scp -i #{self.key_path} -r #{self.user_at_url}:#{self.remote_path} #{self.local_path}"
	end

	def put_scp_cmd
		"scp -i #{self.key_path} -r #{self.local_path} #{self.user_at_url}:#{self.remote_path}"
	end

	def get_cmd_with_gateway
		"scp -i #{self.key_path} #{gateway_code} -r #{self.user_at_url}:#{self.remote_path} #{self.local_path}"
	end

	def put_cmd_with_gateway
		"scp -i #{self.key_path} #{gateway_code} -r #{self.user_at_url} #{self.user_at_url}:#{self.remote_path}"
	end

	def gateway_code
		###### NOT WORKING SOMETHING SOMETHING NETCAT/SOCAT ##########
		"-Cp -o \"ProxyCommand ssh -i #{self.gateway.key_path} #{self.gateway.user_at_url} nc #{self.url} 22\""
	end



	private 

end
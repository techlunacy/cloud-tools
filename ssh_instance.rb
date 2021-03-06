require 'erb'
require_relative 'settings.rb'
class SshInstance
	attr_accessor :key_pair_name, :instance, :gateway, :environment, :user_name, :is_verbose, :on_vpn
	def initialize(aws_instance, environment)
		self.key_pair_name = aws_instance.key_pair.name 
		self.instance = aws_instance
		self.environment = environment
		self.on_vpn = false
	end

	def user
		self.instance.tags['user'] || self.user_name || ssh_settings["user"]
	end

	def user=(user_name)
		self.user_name = user_name
	end

	def ssh_settings
		Settings.new(environment,key_pair_name, gateway_user).ssh
	end

	def vpc_id
		self.instance.vpc_id
	end

	def key_path
		ssh_settings["key_path"]
	end

	def self.get(environment, settings, regex)
		instances = all(environment, settings, regex)
		if instances.size == 1
			instances.first
		else
		  	instance_index = menu('server', instances.map { |e| get_name(e.instance) })
  		  	instances[instance_index]
		end
	end

	def self.all(environment, settings, regex)
		instances = running_instances(settings)
	  	instances.select!{|i| get_name(i) =~ Regexp.new(regex)} unless regex.nil?

	  	raise "No Instances Found" if instances.nil? or instances.size == 0

	  	instances.sort!{|x,y| get_name(x) <=> get_name(y)}
	  	vpcs = instances.map{|i| i.vpc_id }.uniq
	  	gateways = {}
	  	vpcs.each do |v|
	  		gateways[v] = get_gateway(settings, environment, v)
	  	end

	  	instances.map do |e|  
			instance = self.new(e, environment)
			instance.gateway = gateways[e.vpc_id]
			instance
	  	end

	end

	def url
		if bypass_gateway && !on_vpn
			self.instance.public_ip_address || self.instance.dns_name || self.instance.private_ip_address
		else
			self.instance.private_ip_address
		end
	end

	def remote_key_path
		ssh_settings["remote_key_path"]
	end

	def cmd	
		return ssh_cmd if bypass_gateway
		return ssh_cmd_with_gateway
	end

	def user_at_url
		"#{user}@#{url}"
	end

	def login()
		puts self.cmd

		exec(self.cmd)
	end

	def gateway_user
		return gateway.user unless gateway.nil?
	end
	

	private 

	def self.running_instances(settings, filters={'instance-id' => []})
		connection = Fog::Compute::AWS.new(settings)
			filters['instance-state-name'] = 'running'
	  	instances = connection.servers.all(filters)
	  	instances.select{|i| i.tags['Name'] !~ /NAT/i }
	end

	def self.get_name(aws_instance)
		last_octet = aws_instance.private_ip_address.split('.').last
		name = "#{aws_instance.tags['Name']}" || aws_instance.id
		public_ip_string = aws_instance.private_ip_address == '' ? '' : "#{aws_instance.public_ip_address}"
		env_array = name.split('-')
		"#{env_array[1] if env_array.size > 0 } - #{name} (#{aws_instance.private_ip_address}) #{public_ip_string}"
	end	

	def self.get_gateway(settings, environment, vpc_id)
		instances = running_instances(settings, {'vpc-id' => vpc_id, 'tag:gateway'=>'true'})

		# instances.reject!{|i| i.tags['gateway'].nil? }

		SshInstance.new(instances.first, environment) unless instances.size == 0
	end		

	def bypass_gateway
	 	on_vpn || gateway.nil? || i_am_gateway || gateway_in_another_castle
	end 

	def gateway_in_another_castle
		vpc_id !=gateway.vpc_id
	end

	def i_am_gateway
		self.gateway.instance.public_ip_address == self.instance.public_ip_address
	end

	def verbose_command
		@is_verbose ? '-v' : ''
	end

	def ssh_cmd
		"ssh #{verbose_command} -o StrictHostKeyChecking=no -i #{key_path} -A #{user_at_url}"	
	end

	def gateway_ssh
		"ssh  #{verbose_command} -i #{gateway.key_path} -A -t #{gateway.user_at_url}"
	end

	def remote_ssh
 		"ssh #{verbose_command} -A -o StrictHostKeyChecking=no -i #{remote_key_path} #{user_at_url}"
	end

	def ssh_cmd_with_gateway
		"#{gateway_ssh} #{remote_ssh}"
	end
end

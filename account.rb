module Account
	def set_account_alias(settings, name)
		begin
			connection = Fog::AWS::IAM.new(settings)
			if connection.list_account_aliases.body["AccountAliases"].empty?
				connection.create_account_alias(name) 
			else
				name = connection.list_account_aliases.body["AccountAliases"].first.to_s.strip
			end
			puts name
		rescue Fog::AWS::IAM::EntityAlreadyExists
			attempt = input("the name #{name} already exists please input another name")
			set_account_alias(settings, attempt)
		end
		name
	end
end
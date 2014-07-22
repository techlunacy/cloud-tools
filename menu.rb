module Menu
	def menu(type, list_values)
		list_values.each_with_index do |key, index|
			puts "#{index + 1}) #{key}"
		end
		value = input "please select the #{type}"
		value.to_i - 1
	end
	
	def get_path(where)
		input "please select the #{where} path"
	end	

	def input(something)
		puts something
		STDIN.gets.delete("\n")
	end
end
module Menu
	def menu(type, list_values)
		list_values.each_with_index do |key, index|
			puts "#{index + 1}) #{key}"
		end
		puts "please select the #{type}"
		STDIN.gets.to_i - 1
	end
	
	def get_path(where)
		puts "please select the #{where} path"
		STDIN.gets.delete("\n")
	end	
end
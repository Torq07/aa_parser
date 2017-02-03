require "activeadmin"

module AaParser
	def parse
		puts 'Run parsing'
	end
end

ActiveAdmin::DSL.send :include, AaParser

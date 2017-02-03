require "activeadmin"

module AaParser
	module Parser
		def testing_aa
			puts 'do something'
		end
	end	
end

ActiveAdmin::DSL.send :include, AaParser::Parser

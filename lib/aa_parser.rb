require "activeadmin"

module AaParser
	module Parser
		def parse
			puts 'Run parsing'
		end
	end
end

ActiveAdmin::DSL.send :include, AaParser::Parser

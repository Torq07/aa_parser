require "activeadmin"

module Parser
	def self.parse
		puts 'Run parsing'
	end
end

ActiveAdmin::DSL.send :include, Parser

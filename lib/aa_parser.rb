require "activeadmin"

module Parser

	class ImportUrl

		def initialize(url)
			@url = url
		end
		
	end	

	def self.parse
		puts 'Run parsing'
	end
end

ActiveAdmin::DSL.send :include, Parser

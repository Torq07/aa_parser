require_relative './types/new_catalog'
require_relative './types/old_catalog'
require 'uri'
require 'httparty'
require 'open-uri'
require 'nokogiri'
require "activeadmin"

module ParserModule
	class Client

		include HTTParty

		attr_reader :lang
		
		def initialize(url)
			@url = "#{URI(url).scheme}://#{URI(url).host}" 
			@catalog = {}
			@lang = country_code.to_sym
		end

		def run
			@catalog[@lang] = new_catalog? ? NewCatalog.new(@url) : OldCatalog.new(@url)
			@catalog[@lang].execute
			@catalog
		end

		private 

			def new_catalog?
				new_catalog_url = "#{@url}/production-new/catalog"
				response_code = HTTParty.get(new_catalog_url).code
				response_code == 200 ? true : false
			end

			def country_code
				page = Nokogiri::HTML(open(@url,"User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1)"))
				path = 'form#header_lang_selector select[name="countries"] option[selected="yes"]'
				page.css(path).first['date-lang1'].to_sym
			end
	end
end

ActiveAdmin::DSL.send :include, ParserModule



class OldCatalog

	def initialize(url)
		@url = url
		@user_agent_list = [
												"Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1)",
												"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36",
												"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36",
												"Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36",
												"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36",
												"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36",
												"Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36",
												"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/602.3.12 (KHTML, like Gecko) Version/10.0.2 Safari/602.3.12",
												"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36",
												"Mozilla/5.0 (Windows NT 10.0; WOW64; rv:50.0) Gecko/20100101 Firefox/50.0",
												"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:50.0) Gecko/20100101 Firefox/50.0"
											 ]
		@structure = []
	end

	def execute
		grab_second_level_category_links
		grab_third_level_category_links
		parse_all_products(@structure)
	end

	def grab_second_level_category_links
		url = set_url("/production/catalog")
		page=Nokogiri::HTML(open(url,"User-Agent" => @user_agent_list.sample))
		page.css('div#main_content_navigation ul li')
				.reject do |li| 
					# if 'class' attribute exist then it's third level category
					third_level = li.parent.attributes.any?  
					# if url not include 'catalog' then it's not a category
					not_category = !(li.at('a')['href'].include?('catalog')) 
					third_level || not_category
				end	
				.each do |li| 
					url = set_url(li.at('a')['href'])
					@structure << wrap_as_category(category_name:li.at('a').text.strip.capitalize,
																				 link:url)
				end	
	end

	def grab_third_level_category_links
		@structure.each do |category|
			page=Nokogiri::HTML(open(category[:link],"User-Agent" => @user_agent_list.sample))
			
			# Save second level category image
			imgs = page.css('div.catalog_page img')
			category[:image] = "#{@url}#{imgs.first['src']}" if imgs.any?

			# Save second level category description
			category[:description] = page.css('div.catalog_page p')
																	 .map(&:to_s).join("\n")

			# Grab third level categories column														 
			third_level_categories = page.css('div.catalog_page_column')
			third_level_categories.each do |cat|
				
				#if no catalog links then third category links is product link
				if category_links?(cat)

					cat_url = set_url(cat.at('strong').parent['href'])

					# Parsing image,description and product list
					#	from third level categories
					cat_info = grab_category_info(cat_url)
					category[:childs] << wrap_as_category(category_name:cat.at('strong').text.strip.capitalize,
																								link:cat_url,
																								parent:category[:category_name],
																								products:cat_info[:products],
																								description:cat_info[:description],
																								image:cat_info[:image])
				else
					cat_url = set_url(cat.at('strong').parent['href'])
					category[:products]	<< wrap_as_product(link:cat_url,product_name:cat.at('strong').text.strip.capitalize)
				end													 
			end
		end
	end

	private

		def set_url(url_fragment)
			new_url = url_fragment
			unless URI(url_fragment).host
				new_url = "#{@url}#{url_fragment}"
			end	
			new_url
		end

		def parse_all_products(categories)
			categories.each do |category|
				parse_category_products(category[:products])
				parse_all_products(category[:childs]) if category[:childs].any?
			end
			categories
		end

		def parse_category_products(product_list)
			product_list.reject{|e| e[:link].nil?}
				.each do |item|
				ue = @user_agent_list.sample
				page = Nokogiri::HTML(open(item[:link],"User-Agent" => ue ))
				image_node = page.css('div#main_cnt_sidebar img').first
				desc_node = page.css('div#main_content_block')
				desc_node.css('div#main_shortnav').remove
				desc_node.css('div#main_cnt_sidebar').remove
				
				if image_node
					image_address = "#{@url}#{image_node['src']}"
					item[:product_image] =  image_address 
				end
					
				if desc_node.any?
					item[:long_description] = desc_node.to_s
				end	
			end
		end

		def category_links?(category_node)
			category_products = category_node.css('ul.catalog_links li')
			category_links = category_products.any?
		end

		def grab_category_info(url)
			products = []
			image = ''
			description = ''
			page = Nokogiri::HTML(open(url))

			# Save category image
			imgs = page.css('div.catalog_page img')
			image = "#{@url}#{imgs.first['src']}" if imgs.any?

			# Save category description
			description = page.css('div.catalog_page p')
			description = description.map(&:to_s).join("\n") if description.any?

			# Save category products
			products = page.css('div.catalog_page_productcell a')
										 .map{ |item| wrap_as_product(product_name:item.text,link: set_url(item['href']) ) }

			{products:products,image:image, description:description}
		end

		def wrap_as_product(opt={})
			{ 
				link:opt[:link], 
				product_name:opt[:product_name],
		    price:opt[:price],
		    legacy_id:opt[:legacy_id],
		    product_image:opt[:product_image],
		    label_image:opt[:label_image],
		    short_description:opt[:short_description],
		    long_description:opt[:long_description],
		    availability:false,
		    rating:nil,
		    certificates:[]
			}
		end

		def wrap_as_category(opt={})
			 {
				category_name:opt[:category_name],
				link:opt[:link],
				parent:opt[:parent],
				childs:opt[:childs]||[],
				products:opt[:products]||[],
				image:opt[:image],
				description:opt[:description]
			 }
		end

end
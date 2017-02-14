class NewCatalog
	
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
		grab_main_category_links
		grab_category_content(@structure)
		parse_all_products(@structure)
	end


	def grab_main_category_links
		url = "#{@url}/production/catalog"
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
					@structure << wrap_as_category( category_name:li.at('a').text.strip.capitalize,
																				  link:url )
				end	
	end

	def grab_category_content(parent_categories)
		parent_categories.each do |category|
			page=Nokogiri::HTML(open(category[:link],"User-Agent" => @user_agent_list.sample))
			
			# Save category image
			imgs = page.css('div.SectionPicture img')
			category[:image] = "#{@url}#{imgs.first['src']}" if imgs.any?

			# Save category description
			category[:description] = page.css('div.SectionText p')
																	 .map(&:to_s).join("\n")

			# Grab sub categories if exist														 
			third_level_categories_node = page.css('table.SubSections div strong a')
			if third_level_categories_node.any? 
				sub_categories = third_level_categories_node.map do |cat|
						cat_url = set_url(cat['href'])
					  wrap_as_category(category_name:cat.text.strip.capitalize,
														 link:cat_url,
														 parent:category[:category_name])
				end													 
				category[:childs] = sub_categories
				grab_category_content(sub_categories)
			else
				save_products_links(page,category)
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

		def save_products_links(page,category)
			# Grab products from category 
			product_list_node = page.css('div.ProductsList div.row')
			if product_list_node.any?
				product_list_node.each do |product|
					url_node = product.css('div.name a').first
					url = "#{@url}#{url_node['href']}"
					name = url_node.text.strip.capitalize
					short_description = product.css('div.preview').text
					category[:products]	<< wrap_as_product(link:url,
																								 product_name:name,
																								 short_description:short_description)
				end
			end	
		end

		def parse_category_products(product_list)
			product_list.reject{|e| e[:link].nil?}
				.each do |item|
				ue = @user_agent_list.sample
				page = Nokogiri::HTML(open(item[:link],"User-Agent" => ue ))
				image_node = page.css('div.picture img').first
				desc_node = page.css('div#main_content_block')
				desc_node.css('div#main_shortnav').remove
				desc_node.css('div.ProductCard div.picture').remove
				desc_node.css('div.ProductPrint').remove
				desc_node.css('div.ProductAltTitle').remove
				desc_node.css('div.TogetherTitle').remove
				desc_node.css('div.TogetherList').remove
				desc_node.css('div#main_cnt_sidebar').remove
				
				if image_node
					item[:product_image] =  "#@url#{image_node['src']}"
				end
					
				if desc_node.any?
					item[:long_description] = desc_node.to_s
				end	
			end
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

			{image:image, description:description}
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